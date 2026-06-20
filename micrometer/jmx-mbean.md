# JMX MBean 이해하기

micrometer #7535 작업 중 짚은 JMX 기초 개념. 비슷한 작업에서 다시 참조하기 위한 노트.

## 1. JMX의 정체

**Java Management Extensions** — Java SE 5(2004)부터 표준 포함된 자바 애플리케이션 런타임 관리 API. `java.management` 모듈에 들어 있어 별도 의존성 없이 사용 가능. Spring/Tomcat/Kafka/Cassandra 등 자바 진영의 거의 모든 미들웨어가 이걸로 자기 상태를 노출한다.

"관리"의 의미는 두 방향:

- **읽기**: 현재 메모리 사용량, GC 통계, 커넥션 풀 상태, 요청 카운트 등을 외부 도구가 들여다보기.
- **쓰기**: 로그 레벨 변경, 캐시 비우기, GC 강제 호출 등 외부 도구가 명령 보내기.

## 2. 4-layer 구조

JMX 스펙은 명시적으로 4개 layer로 정의되어 있다.

```
┌────────────────────────────────────────────────────┐
│ 4. Management Application                          │  ← JConsole, VisualVM,
│    (외부 도구 / 모니터링 시스템)                    │     Prometheus JMX Exporter,
│                                                    │     Datadog Agent, micrometer
└──────────────┬─────────────────────────────────────┘
               │ (JMX Remote API / RMI / JMXMP)
┌──────────────▼─────────────────────────────────────┐
│ 3. Remote / Connector Layer                        │
│    (선택 - 같은 JVM이면 생략 가능)                  │
└──────────────┬─────────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────────┐
│ 2. Agent Layer: MBeanServer                        │
│    (JVM마다 하나 이상, MBean 레지스트리 + 라우터)  │
└──────────────┬─────────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────────┐
│ 1. Instrumentation Layer: MBean                    │
│    (관리 대상 자체. POJO에 약간 규약 더한 것)       │
└────────────────────────────────────────────────────┘
```

micrometer의 `TomcatMetrics`는 layer 4에 해당하는 외부 관찰자이고, 같은 JVM의 MBeanServer를 직접 호출(remote connector 생략).

## 3. MBean = "Managed Bean"

말 그대로 "관리 대상이 되도록 약간의 규약을 더한 자바 객체". 4가지 노출 요소:

| 요소 | 의미 | Java 표현 |
|---|---|---|
| **Attribute** | 읽거나 쓸 수 있는 속성 | getter/setter |
| **Operation** | 호출 가능한 동작 | 일반 메소드 |
| **Notification** | MBean이 발행하는 이벤트 | `NotificationBroadcaster` 구현 |
| **Constructor** | (드물게 사용) | 생성자 |

이번 작업에서 micrometer가 읽는 것은 모두 **Attribute** — `bytesSent`, `bytesReceived`, `requestCount`, `processingTime`, `maxTime`, `errorCount`. MBean의 getter들이다.

## 4. MBean 종류 4가지

### (a) Standard MBean — 가장 흔함

명명 규약만 지키면 끝.

```java
public interface FooMBean {           // 인터페이스 이름은 반드시 <Class>MBean
    long getRequestCount();           // getter → "RequestCount" attribute
    void setMaxConnections(int n);    // setter → "MaxConnections" attribute
    void reset();                     // 그 외 메소드 → operation
}

public class Foo implements FooMBean {
    private long requestCount;
    public long getRequestCount() { return requestCount; }
    // ...
}
```

JMX 런타임이 reflection으로 인터페이스를 읽어 attribute/operation을 자동 도출. Tomcat의 `RequestGroupInfo`가 이 형태.

이번 fix 작업에서 우리가 테스트용으로 만든 `FakeGlobalRequestProcessor` + `FakeGlobalRequestProcessorMBean` 쌍도 정확히 이 규약을 따른다 — 그래서 JMX가 그것을 합법 MBean으로 받아들임.

### (b) Dynamic MBean

attribute/operation을 런타임에 결정하고 싶을 때.

```java
public interface DynamicMBean {
    Object getAttribute(String name);
    void setAttribute(Attribute attribute);
    AttributeList getAttributes(String[] names);
    AttributeList setAttributes(AttributeList attributes);
    Object invoke(String actionName, Object[] params, String[] signature);
    MBeanInfo getMBeanInfo();   // 어떤 attribute/operation이 있는지 자기가 보고
}
```

Tomcat이 자기 MBean을 등록할 때 내부적으로 `ModelMBean`(Dynamic의 변형)을 많이 쓴다. 외부에서 보면 차이를 못 느끼지만, MBean 등록 코드를 읽을 때 `DynamicMBean.getMBeanInfo()` 패턴을 만나면 그게 이 종류.

### (c) Open MBean

Open Data type(`CompositeData`, `TabularData`)만 attribute로 사용. 클라이언트가 자바 클래스를 안 들고 있어도 원격에서 읽을 수 있게 하려는 의도. JVM platform MBean(`MemoryUsage` 등)이 이 패턴.

### (d) MXBean — Open MBean의 편의 버전

Java SE 6부터 추가. Standard MBean 형태로 코드를 쓰면 JMX가 자동으로 Open type 변환을 해준다. `java.lang.management` 패키지의 모든 MBean이 MXBean.

## 5. MBeanServer — 한 JVM의 MBean 레지스트리

모든 MBean은 어떤 MBeanServer에 등록되어야만 외부에서 보인다. JVM은 부팅 시 **Platform MBeanServer** 한 개를 만들어 제공한다.

```java
MBeanServer server = ManagementFactory.getPlatformMBeanServer();
server.registerMBean(myMBean, new ObjectName("my.domain:type=Foo,name=bar"));

Set<ObjectName> matches = server.queryNames(new ObjectName("my.domain:type=Foo,*"), null);
Object value = server.getAttribute(name, "RequestCount");
```

MBeanServer는 **JNDI 비슷한 lookup 서비스 + 원격 호출 라우터** 두 역할을 같이 한다. 등록된 MBean은 ObjectName으로 식별되고(별도 노트 `http-upgrade-header-and-object-pattern.md` 참조), `queryNames(pattern, filter)`로 패턴 검색이 가능 — 이번 작업에서 micrometer가 `:type=GlobalRequestProcessor,name=*,*` 패턴으로 찾는 것이 바로 이 API.

JVM은 추가로 보안/접근 제어를 위해 별도의 MBeanServer 인스턴스를 여러 개 만들 수도 있다 — Tomcat은 자기 도메인용 별도 MBeanServer를 두는 경우가 있어서 micrometer의 `getMBeanServer()`는 `MBeanServerFactory.findMBeanServer(null)`로 후보를 다 뒤지는 형태로 되어 있다(`TomcatMetrics.java:88-94`).

## 6. JVM이 기본 제공하는 platform MBean들

JConsole이나 VisualVM을 켜면 바로 보이는 트리들 — 모두 표준 JMX MBean이다.

| ObjectName | 노출 정보 |
|---|---|
| `java.lang:type=Memory` | heap/non-heap 사용량, GC trigger |
| `java.lang:type=Threading` | 스레드 수, deadlock 탐지 |
| `java.lang:type=GarbageCollector,name=*` | 각 GC 별 통계 |
| `java.lang:type=ClassLoading` | 로드된 클래스 수 |
| `java.lang:type=OperatingSystem` | CPU, load average |
| `java.util.logging:type=Logging` | 동적 로그 레벨 변경 |
| `java.nio:type=BufferPool,name=*` | direct buffer 사용량 |

micrometer의 `JvmMemoryMetrics`, `JvmGcMetrics` 같은 binder들이 이 platform MBean들을 polling해서 메트릭으로 변환한다. 같은 패턴을 Tomcat 도메인에 적용한 게 `TomcatMetrics`다.

## 7. Tomcat이 노출하는 MBean

Tomcat은 자기 상태를 풍부하게 JMX로 노출한다. 도메인은 두 종류:

- `Catalina` — standalone Tomcat (war 배포)
- `Tomcat` — embedded Tomcat (Spring Boot)

이번 작업과 관련된 것들:

```
Catalina:type=Server
Catalina:type=Service,name=*
Catalina:type=ProtocolHandler,port=*
Catalina:type=GlobalRequestProcessor,name="http-nio-8080"                ← HTTP/1.1 통계 (RequestGroupInfo)
Catalina:type=GlobalRequestProcessor,name="http-nio-8080",Upgrade="h2c"  ← HTTP/2 통계 (RequestGroupInfo)
Catalina:type=GlobalRequestProcessor,name="http-nio-8080",Upgrade="websocket" ← WebSocket 통계 (UpgradeGroupInfo, attribute set 다름)
Catalina:type=ThreadPool,name="http-nio-8080"
Catalina:type=StringCache
Catalina:j2eeType=Servlet,WebModule=//localhost/foo,name=default,...
```

각 MBean은 자기 통계 getter들을 expose하고, Tomcat이 요청을 처리할 때마다 그 카운터를 증가시킨다. JMX 외부 호출이 없어도 카운터는 늘 동작.

## 8. micrometer가 JMX MBean을 다루는 방식

micrometer 자체는 메트릭 SDK이지 JMX 클라이언트가 본업이 아니다. 그런데 Tomcat은 자기 통계를 자바 API로 노출하지 않고 JMX로만 노출하므로, micrometer의 `TomcatMetrics`는 **JMX MBean을 polling해서 micrometer Meter로 변환하는 어댑터** 역할을 한다.

핵심 패턴(이번 fix 직전 코드 기준):

```java
// 1. 관심 있는 ObjectName 패턴으로 MBean 검색
Set<ObjectName> objectNames = mBeanServer.queryNames(
    new ObjectName("Catalina:type=GlobalRequestProcessor,name=*"), null);

// 2. 매치된 각 MBean에 대해 Meter 등록 + read 시점에 JMX getAttribute 호출
for (ObjectName name : objectNames) {
    FunctionCounter.builder("tomcat.global.sent",
        mBeanServer,
        server -> server.getAttribute(name, "bytesSent")  // ← 호출될 때마다 JMX read
    ).tags("name", nameTag(name)).register(registry);
}

// 3. bind 시점에 MBean이 아직 없으면 NotificationListener로 늦은 등록 대비
mBeanServer.addNotificationListener(MBeanServerDelegate.DELEGATE_NAME, ...);
```

read 시점마다 `getAttribute` 호출이 발생하기 때문에 비용이 있긴 하지만, Prometheus scrape 간격(보통 15~60초)에 한 번씩이므로 무시 가능한 수준.

## 9. 이번 작업 맥락 정리

지금 우리가 다루는 모든 개념이 한 줄에 매핑된다.

| JMX 개념 | 이번 작업의 구체 인스턴스 |
|---|---|
| MBeanServer | platform MBeanServer (Tomcat이 자기 MBean 등록한 그 서버) |
| ObjectName | `Catalina:type=GlobalRequestProcessor,name="...",Upgrade="h2c"` |
| ObjectName pattern | `:type=GlobalRequestProcessor,name=*,*` |
| Standard MBean | Tomcat의 `RequestGroupInfo`, `UpgradeGroupInfo` |
| Attribute | `bytesSent`, `bytesReceived`, `requestCount` 등 |
| `queryNames` | `registerMetricsEventually`가 호출하는 API |
| `addNotificationListener` | MBean 늦은 등록 대비 (binder가 Tomcat보다 먼저 bind된 경우) |
| `isInstanceOf` | 이번 fix에서 추가할 RequestGroupInfo vs UpgradeGroupInfo 분별 호출 |

`MBeanServer.isInstanceOf(name, "org.apache.coyote.RequestGroupInfo")`는 결국 JMX가 layer 2에서 layer 1의 MBean class를 들여다보고 instance-of 관계를 알려주는 표준 API. 우리가 추가하는 건 정확히 이 한 줄짜리 layer-crossing 호출이다.

---

JMX는 "자바 객체 + 명명 규약 + 중앙 레지스트리 + reflection 기반 호출"의 조합. 처음 보면 양이 많지만 실제로 다루는 일은 대부분 *어떤 ObjectName에 어떤 attribute가 있는가*에 귀결된다. 이번 작업에서 우리가 한 일도 그 한 가지 — Tomcat이 노출하는 ObjectName 명명 규약을 정확히 이해하고, 거기서 우리가 원하는 MBean만 정확히 걸러내는 패턴을 짠 것.
