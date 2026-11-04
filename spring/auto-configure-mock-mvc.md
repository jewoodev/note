# @AutoConfigureMockMvc의 개념과 요청·응답 출력 제어

Spring Boot에서 MVC 컨트롤러를 테스트할 때 `@AutoConfigureMockMvc`로 MockMvc 자동 구성을 적용하고 세부 동작을 조정할 수 있다. 특히 `print = MockMvcPrint.NONE`은 테스트 요청·응답의 자동 상세 출력을 끌 때 사용한다.

예제의 import는 Spring Boot 4.1 계열을 기준으로 한다. 다른 버전에서는 패키지 위치와 지원 옵션을 해당 버전 문서에서 확인해야 한다.

## 1. MockMvc란 무엇인가

MockMvc는 Spring MVC의 요청 처리 흐름을 테스트하는 도구다. 네트워크 포트를 열어 서버에 접속하는 대신, 테스트용 Servlet 요청·응답 객체로 `DispatcherServlet`을 실행한다. 컨트롤러 매핑, 인수 변환, JSON 직렬화, 예외 처리 등 MVC 동작을 검증할 수 있다. [Spring Framework 설명](https://docs.spring.io/spring-framework/reference/testing/mockmvc.html)

```text
테스트 코드
  → MockMvc 요청
  → 등록된 필터
  → DispatcherServlet
  → 컨트롤러와 연결된 서비스
  → 테스트 응답과 검증
```

이름에 Mock이 들어가지만 연결된 서비스와 외부 호출까지 자동으로 가짜가 되는 것은 아니다. 실제 외부 API를 호출하는 서비스를 연결하면 테스트 중에도 그 외부 요청은 발생한다. 대체할 의존성과 실제로 실행할 의존성을 테스트에서 선택해야 한다.

## 2. @AutoConfigureMockMvc의 역할

`@AutoConfigureMockMvc`는 테스트용 MockMvc 구성 옵션을 선언한다. 주요 옵션은 다음과 같다. [어노테이션 API](https://docs.spring.io/spring-boot/api/java/org/springframework/boot/webmvc/test/autoconfigure/AutoConfigureMockMvc.html)

| 옵션 | 기본값 | 의미 |
| --- | --- | --- |
| `addFilters` | `true` | 컨텍스트의 필터를 MockMvc에 등록 |
| `print` | `DEFAULT` | MVC 처리 결과의 자동 출력 방식 |
| `printOnlyOnFailure` | `true` | 자동 출력을 테스트 실패 시점으로 제한 |

`@WebMvcTest`로 MVC 테스트에 필요한 범위를 구성할 때 출력 옵션을 함께 지정하거나, `@SpringBootTest`로 애플리케이션 컨텍스트를 구성하고 MockMvc를 추가할 때 사용할 수 있다. 컨텍스트에 어떤 서비스를 등록할지는 별도의 문제다.

```kotlin
@WebMvcTest(GreetingController::class)
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
class GreetingControllerTest
```

```kotlin
@SpringBootTest
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
class ApplicationMvcTest
```

두 번째 방식은 애플리케이션 설정에 따라 DB 등 추가 의존성이 필요할 수 있다. MockMvc 자동 구성 자체가 이러한 의존성을 제거하지는 않는다.

## 3. Kotlin 선언 문법 읽기

```kotlin
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
```

- `@AutoConfigureMockMvc`: 테스트 클래스에 붙이는 어노테이션이다.
- `print =`: 인수 이름을 명시해서 값을 전달한다.
- `MockMvcPrint`: 출력 방식을 표현하는 enum 타입이다.
- `NONE`: 해당 enum에 정의된 상수다.

Java에서도 같은 형태로 작성한다.

```java
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
class GreetingControllerTest {
}
```

## 4. 출력 방식과 출력 시점을 구별하기

`print`는 출력할 위치 또는 출력하지 않을지를 결정하고, `printOnlyOnFailure`는 출력 시점을 제한한다. [출력 모드 API](https://docs.spring.io/spring-boot/api/java/org/springframework/boot/webmvc/test/autoconfigure/MockMvcPrint.html)

| print 값 | 출력 방식 |
| --- | --- |
| `NONE` | 자동 상세 출력 없음 |
| `SYSTEM_OUT` | 표준 출력 |
| `SYSTEM_ERR` | 표준 오류 출력 |
| `LOG_DEBUG` | DEBUG 수준 로그 |
| `DEFAULT` | 기본 출력 방식 사용. 별도 재정의가 없으면 `SYSTEM_OUT` |

다음 조합의 차이를 이해하면 설정하기 쉽다.

```kotlin
// 자동 상세 출력을 끈다.
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)

// 실패한 테스트의 상세 결과를 표준 출력으로 보낸다.
@AutoConfigureMockMvc(print = MockMvcPrint.SYSTEM_OUT)

// 성공한 테스트도 자동 상세 출력 대상에 포함한다.
@AutoConfigureMockMvc(
    print = MockMvcPrint.SYSTEM_OUT,
    printOnlyOnFailure = false,
)
```

`LOG_DEBUG`를 선택했다면 관련 로거가 DEBUG 로그를 기록하도록 설정되어 있어야 출력이 보인다.

다음 설정에서 두 번째 인수는 불필요하다.

```kotlin
@AutoConfigureMockMvc(
    print = MockMvcPrint.NONE,
    printOnlyOnFailure = false,
)
```

`NONE`으로 출력 자체를 끈 상태에서는 출력 시점 옵션이 결과를 바꾸지 않는다. 따라서 `@AutoConfigureMockMvc(print = MockMvcPrint.NONE)`만 남기면 의도가 더 분명하다. `printOnlyOnFailure = false`만 설정하면 출력을 끄는 효과는 없다.

## 5. 컨트롤러 테스트에서 사용하기

아래는 Spring Boot 애플리케이션의 테스트 소스에 둘 수 있는 예제다. MVC 테스트 의존성과 Spring Security 테스트 의존성이 준비되어 있다고 가정한다. 테스트 대상은 고정된 JSON을 반환하는 컨트롤러다.

```kotlin
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.boot.webmvc.test.autoconfigure.MockMvcPrint
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class GreetingController {
    @GetMapping("/greetings")
    fun greet() = mapOf("message" to "hello")
}

@WebMvcTest(GreetingController::class)
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
class GreetingControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    @WithMockUser
    fun `returns a greeting`() {
        mockMvc.get("/greetings").andExpect {
            status { isOk() }
            jsonPath("$.message") { value("hello") }
        }
    }
}
```

`@WithMockUser`는 테스트용 인증 사용자를 제공한다. 애플리케이션에 별도 권한 규칙이나 사용자 조회 필터가 있다면 그 조건에 맞는 테스트 구성도 필요하다. 이 어노테이션만으로 모든 애플리케이션의 인증 절차가 충족되는 것은 아니다.

출력을 꺼도 상태 코드와 JSON 검증은 그대로 수행된다. 실패한 assertion의 메시지까지 사라지는 설정은 아니다.

## 6. 자동 출력 설정이 제어하지 않는 것

`NONE`은 Spring Boot가 구성하는 MockMvc 자동 상세 출력에 적용된다. 다음 출력은 별도로 관리해야 한다.

- `println()`으로 직접 출력하는 응답 본문
- 컨트롤러·서비스·HTTP 클라이언트의 로그
- assertion 실패 메시지에 포함되는 기대값과 실제 값
- 명시적으로 추가한 `MockMvcResultHandlers.print()` 처리기

예를 들어 다음 코드는 자동 출력 설정과 별개로 결과를 출력한다.

```kotlin
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultHandlers.print

mockMvc.perform(get("/greetings"))
    .andDo(print())
```

실제 사용자 정보나 외부 업무 데이터를 다루는 테스트라면 상세 출력뿐 아니라 assertion의 실패 메시지도 확인해야 한다. 값 자체를 출력하지 않고 검증 항목·좌표·건수 등만 남기는 방식이 도움이 된다.

## 7. 출력 옵션과 필터 옵션을 혼동하지 않기

`addFilters = false`는 필터 등록을 끄는 옵션이다. 로그를 줄이기 위한 대체 수단으로 사용하면 인증·권한 등 필터 기반 동작을 검증하지 못할 수 있다.

```kotlin
// 출력만 끄고 필터 등록의 기본 동작은 유지한다.
@AutoConfigureMockMvc(print = MockMvcPrint.NONE)
```

필터가 등록되어 있다는 사실과 필요한 보안 구성이 모두 포함됐다는 사실도 구별해야 한다. 경로 권한을 검증하려면 실제 보안 설정을 테스트 컨텍스트에 포함하고 미인증·권한 부족·허용 요청을 각각 확인한다.

MockMvc로 확인한 결과는 MVC 처리 흐름에 대한 증거다. 실제 서버의 소켓·TLS·프록시 설정이나 브라우저 표시까지 검증하려면 별도의 실행 환경에서 확인해야 한다.
