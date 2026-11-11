# `MockRestServiceServer`로 외부 HTTP API 호출 테스트하기

`MockRestServiceServer`는 Spring의 HTTP 클라이언트가 만드는 요청을 검사하고, 미리 준비한 응답을 돌려주는 테스트 도구다. 실제 외부 서버에 접속하지 않고 URL·HTTP 메서드·헤더·본문과 응답 처리 로직을 검증할 때 사용한다.

이 문서는 외부 상품 API를 호출하는 작은 Java 예제로 설명한다. 특정 프로젝트의 구조나 업무 지식은 필요하지 않다. 예제는 Spring Framework 6.1 이상에서 제공하는 `RestClient`와 JUnit Jupiter를 사용한다.

## 1. 어떤 문제를 해결하는가?

애플리케이션이 다음 API를 호출한다고 가정하자.

```http
GET https://catalog.example.com/products/7/name
Accept: text/plain
X-Client-Name: sample-app
```

정상 응답은 상태 코드 `200`, 본문은 `Desk`다. 우리는 다음을 확인하고 싶다.

- 상품 번호를 올바른 URL에 넣는가?
- 필요한 헤더를 보내는가?
- 응답 본문을 호출자에게 전달하는가?
- 외부 API가 실패하거나 통신 오류가 발생하면 어떻게 동작하는가?
- 예상보다 더 많이 요청하거나 필요한 요청을 누락하지 않는가?

실제 외부 서버를 호출하면 서버 상태, 인증정보, 네트워크에 따라 테스트 결과가 달라질 수 있다. 테스트에서 외부 응답을 직접 정하면 성공·실패 상황을 반복해서 재현할 수 있다. 다만 준비한 응답이 실제 API 계약과 일치하는지는 별도 확인이 필요하다.

## 2. 이름에 Server가 있지만 실제 HTTP 서버는 아니다

기본적인 동작은 다음과 같다.

```text
테스트 대상 코드
  → 실제 RestClient
  → 테스트용 ClientHttpRequestFactory
  → 예상 요청과 비교
  → 준비한 응답 반환
  → 실제 응답 처리 코드 실행
```

`ClientHttpRequestFactory`는 Spring HTTP 클라이언트에서 요청을 생성하는 구성요소다. `MockRestServiceServer`를 연결하면 이 부분이 테스트용 구현으로 교체된다. 일반적인 모의 응답 사용에서는 TCP 포트를 열거나 DNS·TLS 통신을 수행하지 않는다. [Spring의 클라이언트 테스트 설명](https://docs.spring.io/spring-framework/reference/testing/spring-mvc-test-client.html)

여기서 사용하는 용어를 구분하면 동작을 이해하기 쉽다.

| 용어 | 의미 |
| --- | --- |
| 테스트 대상 | 실제 동작을 확인하려는 클라이언트나 서비스 코드 |
| 기대 조건(expectation) | 어떤 요청이 몇 번 와야 하는지에 대한 선언 |
| 요청 검사기(matcher) | URL·메서드·헤더·본문 등을 확인하는 함수 |
| 준비된 응답(stub response) | 외부 서버의 응답 대신 테스트가 반환하는 값 |
| 검증(verification) | 선언한 요청이 실제로 수행되었는지 확인하는 과정 |

클라이언트 객체 전체의 메서드를 가짜로 대체하지 않으므로, 요청 구성과 응답 해석 코드는 실제로 실행된다.

## 3. 도입 버전과 준비할 라이브러리

버전은 **Spring Boot가 아닌 Spring Framework 기준**이다.

| 기능 | 도입 버전 |
| --- | --- |
| `MockRestServiceServer` 클래스 | 3.2 |
| `bindTo(RestTemplate)` | 4.3 |
| `bindTo(RestClient.Builder)` | 6.1 |

출처: [MockRestServiceServer Javadoc](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.html).

예제를 실행하려면 다음 의존성이 필요하다.

| 라이브러리 | 역할 |
| --- | --- |
| `org.springframework:spring-web` | `RestClient`와 HTTP 타입 |
| `org.springframework:spring-test` | `MockRestServiceServer`와 검사기·응답 생성기 |
| `org.junit.jupiter:junit-jupiter` | 테스트 선언과 assertion |
| `org.hamcrest:hamcrest` | Spring 테스트 검사기 API가 사용하는 매칭 라이브러리 |

Spring 모듈은 같은 버전 계열로 맞추고, Spring Boot를 사용한다면 해당 Boot 버전의 의존성 관리를 따른다. Gradle에서 JUnit Jupiter를 실행할 때는 `useJUnitPlatform()`을 설정한다. 예제는 문자열 응답을 사용하므로 JSON 변환 라이브러리는 필요하지 않다.

## 4. 테스트 대상 작성

다음 코드를 `CatalogClient.java`로 저장한다.

```java
package example.httpclient;

import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

public final class CatalogClient {
    private final RestClient client;

    public CatalogClient(RestClient client) {
        this.client = client;
    }

    public String getProductName(long productId) {
        String name = client.get()
                .uri("/products/{id}/name", productId)
                .accept(MediaType.TEXT_PLAIN)
                .retrieve()
                .body(String.class);

        if (name == null || name.isBlank()) {
            throw new IllegalStateException("Product name is missing");
        }
        return name;
    }
}
```

HTTP 클라이언트를 생성자에서 받으면 테스트가 준비한 클라이언트를 전달할 수 있다. 이 클래스가 내부에서 `RestClient.create()`를 호출해 별도의 객체를 만들면, 테스트에서 연결한 모의 서버가 그 요청을 가로채지 못한다.

## 5. 성공·실패·호출 횟수 테스트

다음은 `CatalogClientTest.java`의 전체 코드다. 테스트마다 builder, 모의 서버, 클라이언트를 새로 만든다.

```java
package example.httpclient;

import java.net.SocketTimeoutException;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.test.web.client.ExpectedCount.times;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

class CatalogClientTest {
    private static final String PRODUCT_URL =
            "https://catalog.example.com/products/7/name";

    private MockRestServiceServer server;
    private RestClient restClient;
    private CatalogClient client;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder()
                .baseUrl("https://catalog.example.com")
                .defaultHeader("X-Client-Name", "sample-app");

        // 모의 서버 연결을 먼저 하고, 같은 builder로 클라이언트를 만든다.
        server = MockRestServiceServer.bindTo(builder).build();
        restClient = builder.build();
        client = new CatalogClient(restClient);
    }

    @Test
    void readsProductName() {
        server.expect(requestTo(PRODUCT_URL))
                .andExpect(method(HttpMethod.GET))
                .andExpect(header("Accept", "text/plain"))
                .andExpect(header("X-Client-Name", "sample-app"))
                .andRespond(withSuccess("Desk", MediaType.TEXT_PLAIN));

        String result = client.getProductName(7);

        assertEquals("Desk", result);
        server.verify();
    }

    @Test
    void exposesHttpFailureWithoutRetrying() {
        server.expect(requestTo(PRODUCT_URL))
                .andRespond(withStatus(HttpStatus.SERVICE_UNAVAILABLE));

        RestClientResponseException error = assertThrows(
                RestClientResponseException.class,
                () -> client.getProductName(7));

        assertEquals(503, error.getStatusCode().value());
        server.verify();
    }

    @Test
    void exposesTransportFailure() {
        server.expect(requestTo(PRODUCT_URL))
                .andRespond(withException(
                        new SocketTimeoutException("simulated timeout")));

        ResourceAccessException error = assertThrows(
                ResourceAccessException.class,
                () -> client.getProductName(7));

        assertInstanceOf(SocketTimeoutException.class, error.getCause());
        server.verify();
    }

    @Test
    void rejectsBlankProductName() {
        server.expect(requestTo(PRODUCT_URL))
                .andRespond(withSuccess("   ", MediaType.TEXT_PLAIN));

        assertThrows(IllegalStateException.class,
                () -> client.getProductName(7));
        server.verify();
    }

    @Test
    void requiresExactlyTwoRequests() {
        server.expect(times(2), requestTo(PRODUCT_URL))
                .andRespond(withSuccess("Desk", MediaType.TEXT_PLAIN));

        assertEquals("Desk", client.getProductName(7));
        assertEquals("Desk", client.getProductName(7));
        server.verify();
    }

    @Test
    void readsEachResponseInsteadOfReusingThePreviousValue() {
        server.expect(requestTo(PRODUCT_URL))
                .andRespond(withSuccess("Desk", MediaType.TEXT_PLAIN));
        server.expect(requestTo(PRODUCT_URL))
                .andRespond(withSuccess("Chair", MediaType.TEXT_PLAIN));

        assertEquals("Desk", client.getProductName(7));
        assertEquals("Chair", client.getProductName(7));
        server.verify();
    }

    @Test
    void checksPostBody() {
        server.expect(requestTo("https://catalog.example.com/products"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(content().string("{\"name\":\"Desk\"}"))
                .andRespond(withStatus(HttpStatus.CREATED));

        restClient.post()
                .uri("/products")
                .contentType(MediaType.APPLICATION_JSON)
                .body("{\"name\":\"Desk\"}")
                .retrieve()
                .toBodilessEntity();

        server.verify();
    }
}
```

마지막 POST 테스트는 본문 검사 방법을 설명하기 위해 `RestClient`를 직접 호출한다. 실제 애플리케이션에서 상품 등록 메서드가 있다면 그 공개 메서드를 호출해야 해당 구현까지 검증할 수 있다.

예제의 오류 테스트는 `retrieve()`의 기본 상태 처리 동작을 전제로 한다. 클라이언트가 별도의 상태 처리기를 등록하거나 `exchange()`로 응답을 직접 처리하면, 그 코드가 정의한 결과·예외를 검증해야 한다. [RestClient 오류 처리](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html#rest-restclient-exchange)

## 6. expect, andExpect, andRespond, verify의 차이

```java
server.expect(requestTo(PRODUCT_URL))
        .andExpect(method(HttpMethod.GET))
        .andRespond(withSuccess("Desk", MediaType.TEXT_PLAIN));
```

이 선언은 “이 URL에 GET 요청이 오면, 상태 코드 200과 본문 Desk를 반환하라”는 의미다. 선언하는 시점에는 애플리케이션의 요청이 실행되지 않는다.

| 메서드 | 역할 |
| --- | --- |
| `expect(...)` | 하나의 예상 요청을 등록한다. 횟수를 생략하면 한 번이다. |
| `andExpect(...)` | 같은 요청에 검사 조건을 추가한다. |
| `andRespond(...)` | 해당 요청에 돌려줄 응답 또는 발생시킬 I/O 예외를 정한다. |
| `verify()` | 예상한 요청들이 요구 횟수만큼 수행됐는지 확인한다. |

잘못된 요청이나 예상하지 않은 추가 요청은 요청 실행 중 실패로 드러난다. 반대로 요청 자체가 실행되지 않았다면 호출 중에 검사할 기회가 없으므로 마지막 `verify()`가 누락을 잡는다. 따라서 반환값 검증과 요청 수행 검증을 함께 둔다. [MockRestServiceServer API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.html)

요청 검사기는 URL·메서드·헤더·쿼리·본문 검사에 사용한다. 위 POST 예제의 `content().string(...)`은 문자열 전체를 비교한다. JSON의 필드 순서나 공백을 무시하려면 별도의 `content().json(...)` 검사를 사용할 수 있으며 해당 API에 필요한 JSONassert 의존성을 확인해야 한다. [요청 검사기 API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/match/MockRestRequestMatchers.html), [본문 검사기 API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/match/ContentRequestMatchers.html)

## 7. 순서와 호출 횟수를 의도적으로 정하기

기본 설정은 기대 조건을 등록한 순서대로 첫 요청이 발생하는지 검사한다. 토큰 발급 후 데이터 조회처럼 순서가 계약의 일부라면 이 기본값이 유용하다.

서로 독립적인 요청이라 순서가 중요하지 않을 때는 다음처럼 설정할 수 있다.

```java
MockRestServiceServer server = MockRestServiceServer.bindTo(builder)
        .ignoreExpectOrder(true)
        .build();
```

이 옵션은 순서 검사를 완화한다. URL·본문 조건이나 호출 횟수까지 무시하는 옵션은 아니다. [Builder API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.MockRestServiceServerBuilder.html)

호출 횟수는 `ExpectedCount`로 표현한다.

| 선언 | 의미 |
| --- | --- |
| `once()` | 정확히 한 번 |
| `times(2)` | 정확히 두 번 |
| `between(1, 3)` | 한 번 이상 세 번 이하 |
| `manyTimes()` | 한 번 이상, 매우 큰 상한까지 허용 |
| `never()` | 호출되면 안 됨 |

재시도 횟수가 관심사라면 정확한 횟수를 지정하는 편이 결과를 판단하기 쉽다. `manyTimes()`로 폭넓게 허용하면 과도한 재시도를 발견하기 어렵다. [ExpectedCount API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/ExpectedCount.html)

반복 횟수가 있는 기대 조건의 순서는 **첫 발생**을 기준으로 한다. 예를 들어 A를 두 번, B를 한 번 기대하도록 등록하면 기본 설정에서도 A → B → A가 가능하다. A → A → B라는 엄격한 순서를 검증하려면 A, A, B를 각각 한 번씩 기대하도록 등록한다. [호출 순서 규칙](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.html)

여러 응답을 순서대로 준비해도 모의 서버가 재시도를 실행하지는 않는다. 재시도할지는 테스트 대상 코드가 결정하고, 모의 서버는 실제로 발생한 요청에 대응한다.

## 8. 오류를 재현하는 것과 네트워크를 검증하는 것은 다르다

예제에는 두 종류의 실패가 있다.

- `withStatus(503)`: 외부 서버로부터 HTTP 오류 응답을 받은 상황.
- `withException(new SocketTimeoutException(...))`: 요청 수행 과정에서 I/O 예외가 발생한 상황.

`withException(...)`은 예외를 발생시킨다. 설정된 시간만큼 기다렸다가 소켓 타임아웃이 동작하는지 확인하는 기능은 아니다. [응답 생성기 API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/response/MockRestResponseCreators.html)

같은 이유로 운영 HTTP 클라이언트의 연결 풀, TLS, 리다이렉트, 자동 재시도, 실제 읽기 제한시간이 올바르게 동작하는지는 이 테스트만으로 증명할 수 없다. 요청 factory가 테스트용으로 교체되기 때문이다. 이러한 동작은 실제 HTTP 요청을 받는 로컬 서버와 운영용 클라이언트를 연결해 검증한다. Spring 공식 문서도 전송 계층 검증에는 MockWebServer·WireMock 같은 모의 웹 서버 활용을 안내한다. [전송 계층 테스트 안내](https://docs.spring.io/spring-framework/reference/testing/spring-mvc-test-client.html)

## 9. Mockito, MockMvc와 어떻게 다른가?

| 도구 | 주로 대체하거나 실행하는 지점 | 예시 질문 |
| --- | --- | --- |
| Mockito | 객체의 메서드 호출을 대체하거나 관찰 | 상품 조회가 실패하면 서비스가 어떤 결정을 하는가? |
| MockRestServiceServer | 외부로 나가는 Spring HTTP 클라이언트의 요청·응답 | 올바른 URL과 헤더를 보내고 응답을 처리하는가? |
| MockMvc | Spring MVC 요청 처리 흐름 | 우리 API의 요청 바인딩·컨트롤러·응답이 올바른가? |
| 로컬 모의 HTTP 서버 | 실제 네트워크 요청을 수신 | 실제 HTTP 클라이언트 설정이 의도대로 동작하는가? |

예를 들어 서비스의 업무 분기만 확인할 때는 `CatalogClient`를 mock으로 대체할 수 있다. `CatalogClient`가 외부 API를 호출하는 방법을 확인하려면 실제 객체와 `MockRestServiceServer`를 연결한다. 실제 외부 시스템과의 호환성은 별도 연동 테스트로 확인한다.

도구 이름만으로 단위 테스트·통합 테스트를 단정하기보다는, **어떤 구성요소는 실제로 실행하고 어디부터 대체했는지** 설명하는 것이 검증 범위를 전달하기 좋다.

## 10. 적용할 때 자주 놓치는 부분

1. **연결 순서:** `bindTo(builder).build()`를 먼저 호출하고 같은 builder로 `RestClient`를 만든다. 이미 만들어진 다른 클라이언트에는 연결이 적용되지 않는다.
2. **기대 조건 준비:** 테스트 대상 호출 전에 필요한 기대 조건을 모두 등록한다. 실행 중간에 조건을 추가하기보다 시나리오별로 테스트를 나눈다.
3. **요청 factory 재설정:** 모의 서버를 연결한 뒤 테스트 대상이 별도의 factory를 설정하면 모의 연결을 덮어쓸 수 있다.
4. **테스트 격리:** 각 테스트에 새 서버를 만드는 방식을 우선한다. 재사용한다면 `reset()`이 기존 기대 조건과 기록을 지운다는 점을 고려한다.
5. **실패 검증:** 성공 여부만 보지 말고 예외 타입, 오류 분류, 재시도 횟수와 후속 요청 여부를 확인한다.
6. **검사 강도:** 계약에 중요한 URL·메서드·헤더·본문은 검사하되 의미 없는 헤더 순서까지 고정하지 않는다.
7. **실제 데이터:** 인증정보나 고객 데이터를 복사하지 않고 의미 있는 경계 사례를 가진 합성 자료를 만든다.

`reset()`과 기대 조건 등록 시점은 [공식 API 설명](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.html)을 참고할 수 있다.

## 11. 기존 RestTemplate 코드에 적용하기

`RestTemplate`에는 이미 생성한 객체를 연결한다. 아래는 독립적인 사용 조각이다.

```java
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

// 테스트 메서드 안에서 실행
RestTemplate template = new RestTemplate();
MockRestServiceServer server = MockRestServiceServer.bindTo(template).build();

server.expect(requestTo("https://catalog.example.com/products/7/name"))
        .andRespond(withSuccess("Desk", MediaType.TEXT_PLAIN));

String name = template.getForObject(
        "https://catalog.example.com/products/7/name", String.class);

server.verify();
```

`RestClient`는 builder에, `RestTemplate`은 인스턴스에 연결한다는 차이가 있다. 두 방식 모두 테스트가 사용하는 객체와 애플리케이션 코드가 사용하는 객체가 연결되어 있어야 한다. [연결 메서드 API](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/client/MockRestServiceServer.html)

## 예제 검증 기록

2026-10-15에 4·5절의 전체 Java 코드를 문서에서 그대로 추출해 컴파일하고 실행했다. 테스트 7개가 모두 통과했다. 나머지 코드 블록은 설명용 사용 조각이며, 이 실행 결과가 모든 Spring 버전에서의 호환성이나 실제 네트워크 동작을 검증한 것은 아니다.
