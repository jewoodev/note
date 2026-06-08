# `Upgrade="h2c"` 와 ObjectName 패턴 정리

micrometer #7535 작업 중에 짚은 두 개념. 비슷한 작업에서 다시 참조하기 위한 노트.

## 1. `Upgrade="h2c"` — HTTP Upgrade 메커니즘의 JMX 표지

### HTTP/1.1 → HTTP/2 전환 (RFC 7540)

HTTP/1.1에는 같은 TCP 커넥션 위에서 다른 protocol로 전환할 수 있는 [`Upgrade` 헤더](https://datatracker.ietf.org/doc/html/rfc7230#section-6.7) 메커니즘이 있다. 클라이언트가 평문 HTTP/1.1로 첫 요청을 보내면서:

```
GET / HTTP/1.1
Host: example.com
Connection: Upgrade, HTTP2-Settings
Upgrade: h2c
HTTP2-Settings: <base64>
```

서버가 받아들이면 `101 Switching Protocols`로 응답하고, 그 시점부터 같은 커넥션이 HTTP/2 프레임을 주고받는 채널로 바뀐다. WebSocket도 같은 메커니즘으로 동작 — `Upgrade: websocket`.

값별 의미:

- `h2c` = **HTTP/2 over cleartext** (HTTP/2 plain TCP, TLS 없음)
- `h2` = **HTTP/2 over TLS** (ALPN 협상 결과로 쓰이는 protocol name)
- `websocket` = WebSocket protocol
- `h2c` / `h2` 같은 짧은 식별자는 IANA가 관리하는 [TLS Application-Layer Protocol Negotiation IDs](https://www.iana.org/assignments/tls-extension-type-values/tls-extension-type-values.xhtml#alpn-protocol-ids).

### Tomcat이 이걸 JMX MBean 이름에 박는 이유

Spring Boot에서 `server.http2.enabled=true`로 설정한 embedded Tomcat connector는 같은 socket으로 HTTP/1.1 + HTTP/2 트래픽을 동시에 처리할 수 있다(클라이언트마다 다름). Tomcat은 통계를 protocol별로 분리해서 누적한다.

- HTTP/1.1 트래픽 → `RequestGroupInfo` 인스턴스 A
- HTTP/2 (`h2c`) 트래픽 → 별도 `RequestGroupInfo` 인스턴스 B (Tomcat의 `Http2Protocol#setHttp11Protocol` 안에서 만들어짐)

두 인스턴스를 JMX로 노출할 때 ObjectName을 구분해야 하므로, Tomcat은 두 번째 것에 `,Upgrade="h2c"` key를 추가해서 등록한다:

```
Catalina:type=GlobalRequestProcessor,name="http-nio-8080"                     ← HTTP/1.1
Catalina:type=GlobalRequestProcessor,name="http-nio-8080",Upgrade="h2c"       ← HTTP/2 (h2c)
```

즉 `Upgrade="h2c"`는 "이 MBean은 h2c protocol upgrade 경로로 들어온 트래픽 집계"라는 의미. 값이 `"h2"`면 TLS 위의 HTTP/2, `"websocket"`이면 WebSocket — Tomcat은 같은 명명 규칙을 모든 protocol upgrade에 쓴다.

### 함정: 같은 명명 규칙을 두 클래스가 공유

같은 `,Upgrade=<protocol>` 이름 규칙을 두 종류의 클래스가 등록한다.

- HTTP/2 (`h2`/`h2c`) → `RequestGroupInfo` 등록 (`Http2Protocol.java:113, 697-710`)
- WebSocket / 일반 servlet upgrade (`websocket` 등) → `UpgradeGroupInfo` 등록 (`AbstractHttp11Protocol#getUpgradeGroupInfo`)

두 클래스의 노출 attribute는 다르다.

| Attribute | RequestGroupInfo | UpgradeGroupInfo |
|---|---|---|
| `bytesSent`, `bytesReceived` | ✅ | ✅ |
| `requestCount`, `errorCount`, `processingTime`, `maxTime` | ✅ | ❌ |
| `msgsSent`, `msgsReceived` | ❌ | ✅ |

micrometer가 `Upgrade` key 존재만 보고 잡으면 후자도 잡혀버려서, 누락된 attribute 때문에 `safeDouble`은 NaN, `safeLong`은 0을 silent하게 반환하는 잘못된 시리즈가 생긴다. 이게 #7535 fix에서 `UpgradeGroupInfo`를 명시적으로 걸러야 하는 이유.

## 2. ObjectName 패턴 — JMX wildcard 매칭 규칙

### ObjectName 자체

JMX MBean은 `domain:key1=value1,key2=value2,...` 형태의 이름으로 식별된다. 키 순서는 무관(`canonical name` 비교 시 정렬됨).

예시: `Catalina:type=GlobalRequestProcessor,name="http-nio-8080"` — domain `Catalina`, key-value 두 개.

### 두 종류의 wildcard

JMX `ObjectName`은 두 가지 패턴을 지원한다 ([javadoc](https://docs.oracle.com/en/java/javase/11/docs/api/java.management/javax/management/ObjectName.html)).

**(a) Value pattern** — key는 명시, value 자리에 `*`/`?` 사용

- `:type=GlobalRequestProcessor,name=*` 는 "key 셋이 정확히 `{type, name}`이고, `name` 값은 무엇이든 OK"라는 의미.
- 핵심: key 셋은 **정확히** 일치해야 한다. 추가 키가 있는 MBean은 매치 안 됨.

**(b) Property list pattern** — trailing `,*` 추가

- `:type=GlobalRequestProcessor,name=*,*` 는 "key 셋이 `{type, name}`을 **포함**하고, 그 외 추가 키가 0개 이상 있어도 OK"라는 의미.
- 즉 `{type, name}` 매치 + `{type, name, Upgrade}` 매치 + `{type, name, Upgrade, foo, bar}` 매치 모두.

### #7535 작업과의 매핑

- **Before**: micrometer가 쓰던 `:type=GlobalRequestProcessor,name=*` — (a) value pattern, key 셋이 정확히 `{type, name}`인 MBean만 매치. HTTP/2 MBean은 `Upgrade` 키가 추가로 있어서 key 셋이 `{type, name, Upgrade}` — 매치 안 됨. 이게 root cause.

- **After (이번 fix)**: `:type=GlobalRequestProcessor,name=*,*` — (b) property list pattern. HTTP/2 MBean도 매치. servlet 쪽 `:j2eeType=Servlet,name=*,*`도 이미 같은 형태.

- **참고: Tomcat 자체가 쓰는 `,Upgrade=*`** — `AbstractHttp11Protocol#destroy()` 코드는 unregister 시점에 *upgrade MBean만 일괄 정리*하기 위해 `parentRgOname + ",Upgrade=*"`를 쓴다. 이건 우리 fix와 반대 방향 — "key 셋이 `{type, name, Upgrade}`이고 `Upgrade` 값은 무엇이든"으로 좁히는 (a) value pattern. micrometer fix와는 의도가 다르고, codex 평가에서 그걸 인용한 건 "Tomcat 본체가 이 ObjectName 명명 규칙을 어떻게 다루는지" 보여주는 1차 자료로서다.

### 도식

```
:type=GlobalRequestProcessor,name=*              key={type,name}                매치
:type=GlobalRequestProcessor,name=*,*            key⊇{type,name}                매치 (이번 fix)
:type=GlobalRequestProcessor,name=*,Upgrade=*    key={type,name,Upgrade}        매치
```

`:type=GlobalRequestProcessor,name=*,*` 패턴 자체는 Upgrade key가 있어야 매치하는 게 아니라 "추가 키가 있어도 무방"이다. 그래서 HTTP/1.1 base MBean(추가 키 0개)과 HTTP/2 MBean(추가 키 `Upgrade`) 둘 다 잡고, 추가로 WebSocket UpgradeGroupInfo(추가 키 `Upgrade=websocket`)도 잡힌다는 게 우리가 짚은 위험이다. → `MBeanServer.isInstanceOf`로 RequestGroupInfo만 허용해서 해결.

---

요약하면 `Upgrade="h2c"`는 RFC 7540 protocol 전환 메커니즘의 protocol name이 그대로 JMX key에 박힌 것이고, `,*` trailing은 JMX의 property list pattern 문법으로 "이 키들을 포함하고 그 외 추가는 허용"이라는 의미다.
