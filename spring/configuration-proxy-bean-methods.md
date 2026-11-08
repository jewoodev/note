# Spring의 proxyBeanMethods와 명시적 빈 연결 전략

`@Configuration(proxyBeanMethods = false)`는 **설정 클래스의 `@Bean` 메서드를 코드에서 직접 호출할 때, Spring이 그 호출을 가로채지 않도록 하는 옵션**이다. 빈 등록이나 싱글턴 관리를 끄는 설정은 아니다.

이 문서는 특정 프로젝트를 전제로 하지 않는다. 외부 서비스에 접근하는 클라이언트와 이를 사용하는 업무 서비스를 예로, 옵션의 동작과 선택 기준을 설명한다.

## 먼저 알아둘 개념

| 용어 | 의미 |
|---|---|
| Spring 컨테이너 | 객체를 생성·연결하고 수명을 관리하는 구성 요소 |
| 빈 | Spring 컨테이너에 등록되어 관리되는 객체 |
| `@Configuration` | 빈 구성 정보를 선언하는 클래스 |
| `@Bean` | 반환 객체를 빈으로 등록하는 팩터리 메서드 표시 |
| 싱글턴 범위 | 같은 컨테이너의 같은 빈 정의에 대해 하나의 인스턴스를 공유하는 기본 범위 |
| 프록시 | 원래 객체나 메서드 앞에서 호출을 가로채 추가 동작을 수행하는 장치 |
| 의존성 주입 | 필요한 객체를 직접 찾거나 만드는 대신 외부에서 전달받는 방식 |

`@Bean` 메서드는 객체를 만들기 위한 코드와 컨테이너의 빈 등록 정보를 함께 제공한다. [빈 선언 공식 문서](https://docs.spring.io/spring-framework/reference/core/beans/java/bean-annotation.html)

## 기본값 true가 해결하는 문제

예제에서 사용할 객체는 다음과 같다.

```kotlin
class ApiClient : AutoCloseable {
    override fun close() {
        // 실제 구현에서는 연결 등 자원을 정리한다.
    }
}

class ExportService(val client: ApiClient)
```

다음 설정은 다른 `@Bean` 메서드를 직접 호출해 의존성을 연결한다.

```kotlin
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration // proxyBeanMethods의 기본값은 true
open class FullConfiguration {
    @Bean(destroyMethod = "close")
    open fun apiClient(): ApiClient = ApiClient()

    @Bean
    open fun exportService(): ExportService = ExportService(apiClient())
}
```

일반 Kotlin 함수라면 apiClient()를 호출할 때마다 새 객체를 만들 것이다. 하지만 Spring이 관리하는 위 설정 클래스에서는 CGLIB 기반 하위 클래스로 메서드 호출을 가로챈다. 호출이 컨테이너의 빈 관리로 연결되어, 기본 싱글턴 범위의 apiClient 빈을 공유한다. Kotlin 예제에는 하위 클래스 생성이 가능하도록 클래스와 메서드에 open을 명시했다. 프로젝트에 따라 kotlin-spring 플러그인이 이 처리를 지원할 수도 있다. [Configuration API 문서](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/annotation/Configuration.html)

이 동작은 Spring이 관리하는 구성 인스턴스에 적용된다. `FullConfiguration()`을 직접 생성한 일반 객체까지 자동으로 프록시가 되는 것은 아니다.

## false일 때 직접 호출하면 어떻게 되는가

위 코드에서 proxyBeanMethods만 false로 바꾸면 다음 호출은 일반 함수 호출이 된다.

```kotlin
fun exportService(): ExportService = ExportService(apiClient())
```

이 예제의 apiClient() 본문은 매번 ApiClient()를 실행한다. 따라서 컨테이너가 등록한 클라이언트와 ExportService에 전달된 클라이언트가 서로 다른 객체가 될 수 있다. 직접 생성된 추가 객체는 그 호출만으로 별도의 빈이 되지 않으므로, 등록된 빈과 같은 초기화·종료 처리를 자동으로 기대해서도 안 된다. [기본 개념 공식 문서](https://docs.spring.io/spring-framework/reference/core/beans/java/basic-concepts.html)

이는 false가 모든 빈을 매번 새로 만든다는 뜻이 아니다. **컨테이너를 통한 빈 주입과 일반 메서드 호출을 구분해야 한다.**

## false와 매개변수 주입을 함께 사용하기

직접 호출을 제거하면 프록시에 의존하지 않고 같은 빈을 연결할 수 있다.

```kotlin
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration(proxyBeanMethods = false)
class ExplicitConfiguration {
    @Bean(destroyMethod = "close")
    fun apiClient(): ApiClient = ApiClient()

    @Bean
    fun exportService(apiClient: ApiClient): ExportService =
        ExportService(apiClient)
}
```

이 코드에서 Spring은 exportService 빈을 만들 때 필요한 ApiClient 빈을 찾아 매개변수에 전달한다. 코드에서 apiClient()를 직접 호출할 필요가 없다. 공식 문서도 빈 간 직접 호출을 팩터리 메서드의 매개변수로 표현하는 방식을 설명한다. [기본 개념 공식 문서](https://docs.spring.io/spring-framework/reference/core/beans/java/basic-concepts.html)

| 연결 방식 | 의존 객체를 얻는 과정 |
|---|---|
| true + 직접 호출 | 메서드 호출 → 구성 클래스 프록시 → 컨테이너가 관리하는 빈 |
| false + 매개변수 주입 | 컨테이너가 필요한 빈 조회 → 메서드 매개변수에 전달 |
| false + 직접 호출 | 일반 함수 본문 실행 → 이 예제에서는 새 객체 생성 |

true에서도 매개변수 주입을 사용할 수 있다. false는 주입 방식을 강제로 바꾸거나 잘못된 직접 호출을 컴파일 오류로 만들어 주지 않는다.

## false 전략의 장점

**의존성이 메서드 선언에 드러난다.** exportService(apiClient: ApiClient)를 보면 필요한 빈을 알 수 있다. 여러 구성 클래스에 흩어진 빈도 같은 주입 방식으로 연결할 수 있다.

**함수 호출의 의미가 단순해진다.** 빈을 얻기 위해 다른 팩터리 메서드를 호출하는 관례 대신, 필요한 객체는 매개변수로 받는 관례를 유지한다. 구성 코드를 일반 팩터리 함수처럼 읽기 쉽다는 설계상의 이점이다.

**구성 클래스의 CGLIB 처리를 피한다.** 구성 클래스와 빈 메서드를 프록시용으로 재정의할 필요가 없어 final 제약이 완화된다. 불필요한 프록시 생성도 줄지만, 실제 성능 효과는 애플리케이션에서 측정해야 한다. 큰 성능 향상을 보장하는 설정으로 해석하지 않는다. [Configuration API 문서](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/annotation/Configuration.html)

**조립 코드의 테스트가 명시적이다.** 예제의 팩터리 함수에는 준비한 ApiClient를 직접 전달할 수 있다. 다만 이런 직접 호출 테스트만으로 실제 Spring 바인딩·후처리·종료가 검증되는 것은 아니다. 필요하면 별도의 컨텍스트 테스트로 연결을 확인한다.

## false 전략의 단점과 유지 조건

**직접 호출 실수를 프록시가 보완하지 않는다.** 나중에 누군가 exportService() 안에 apiClient() 호출을 추가해도 컴파일될 수 있다. 그 결과 별도의 연결 풀·클라이언트·캐시가 만들어질 수 있으므로 리뷰에서 확인해야 한다.

**기존 코드 전환 시 호출부를 살펴야 한다.** 어노테이션의 true만 false로 바꾸는 것은 충분하지 않다. 같은 구성 클래스뿐 아니라 다른 코드가 해당 `@Bean` 메서드를 직접 호출하는지도 확인해야 한다.

**매개변수가 늘어날 수 있다.** 의존 객체가 많은 조립 메서드는 선언이 길어진다. 이는 의존성을 드러내는 비용이며, 필요하면 구성 책임을 나눌 근거가 된다.

**같은 타입의 빈이 여러 개면 선택을 명시해야 할 수 있다.** Qualifier 등으로 주입 대상을 정한다. 이는 false만의 문제는 아니지만, 매개변수 주입으로 전환할 때 드러날 수 있다.

## 싱글턴·수명 관리·다른 프록시와의 관계

| 질문 | 설명 |
|---|---|
| false이면 싱글턴이 해제되는가? | 아니다. 컨테이너에 등록된 빈의 범위는 유지된다. |
| destroyMethod가 동작하지 않는가? | 아니다. 컨테이너가 관리하는 빈의 종료 설정은 유지된다. |
| 생성된 모든 내부 객체가 빈인가? | 아니다. 팩터리 내부에서 만든 객체가 반환 빈의 의존 객체일 수는 있지만 별도 등록되는 것은 아니다. |
| 트랜잭션 등 다른 AOP 프록시도 꺼지는가? | 아니다. 이 옵션은 구성 클래스의 빈 메서드 가로채기를 대상으로 한다. |
| true이면 모든 객체가 전역 싱글턴인가? | 아니다. 빈 정의의 범위와 컨테이너에 따라 결정된다. |

빈의 생성·주입·초기화·종료는 컨테이너가 관리한다. 예제의 destroyMethod는 등록된 ApiClient에 적용된다. 일반 함수 호출로 추가 생성한 객체의 수명은 별도로 고려해야 한다. [빈 수명과 메서드 매개변수 공식 문서](https://docs.spring.io/spring-framework/reference/core/beans/java/bean-annotation.html)

## 선택 기준

| 상황 | 판단 |
|---|---|
| 의존성을 전부 매개변수·생성자로 주입한다 | false를 사용하기 좋은 구성 |
| 기존 빈 메서드의 직접 호출에 의존한다 | true를 유지하거나 호출 구조부터 바꾼 뒤 전환 |
| false에서 직접 호출이 여러 곳에 남아 있다 | 전환 전에 각 호출이 새 객체를 만들어도 되는지 점검 |

false를 선택할 때의 핵심 유지 원칙은 **다른 빈이 필요하면 해당 `@Bean` 메서드를 호출하지 않고 주입받는다**는 것이다. 프록시 유무보다 객체를 누가 생성하고 관리하는지를 분명하게 유지하는 것이 중요하다.
