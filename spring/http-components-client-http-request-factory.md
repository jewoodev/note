# `HttpComponentsClientHttpRequestFactory` 이해하기

`HttpComponentsClientHttpRequestFactory`는 Spring의 HTTP 클라이언트가 Apache HttpClient를 통해 통신할 수 있도록 요청 객체를 만드는 어댑터다. Spring의 `ClientHttpRequestFactory` 인터페이스를 구현하며, 미리 설정한 Apache HttpClient를 생성자로 전달할 수 있다. [Spring API 문서](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/http/client/HttpComponentsClientHttpRequestFactory.html)

이 글은 Java와 HTTP 요청의 기본 개념을 아는 독자를 대상으로 한다. 특정 서비스나 프로젝트의 구조를 알 필요는 없다.

## 1. 왜 요청 팩토리가 필요한가

외부 API를 호출할 때는 두 종류의 관심사가 있다.

- 어떤 URL에 어떤 헤더와 본문을 보낼 것인가.
- 연결을 어떻게 만들고 재사용하며, 얼마나 기다릴 것인가.

Spring의 `RestClient`는 첫 번째 작업을 표현하기 좋은 API를 제공한다. 실제 요청을 실행할 기반 HTTP 라이브러리는 요청 팩토리를 통해 연결한다. Apache HttpClient 외에도 JDK HttpClient 등을 사용할 수 있다. [Spring REST 클라이언트 안내](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html#rest-request-factories)

```mermaid
flowchart LR
    A[애플리케이션 코드] --> B[Spring RestClient]
    B --> C[HttpComponentsClientHttpRequestFactory]
    C --> D[Apache HttpClient 기반 요청 객체]
    D --> E[Apache HttpClient]
    E --> F[외부 HTTP 서버]
```

| 구성요소 | 맡는 역할 |
|---|---|
| `RestClient` | 요청 구성과 응답 사용을 위한 API 제공 |
| `ClientHttpRequestFactory` | Spring HTTP 요청 객체를 생성하는 인터페이스 |
| `HttpComponentsClientHttpRequestFactory` | Apache HttpClient를 사용하는 요청 객체 생성 |
| Apache `HttpClient` | 설정된 연결 정책으로 실제 통신 수행 |
| 연결 관리자 | 연결 풀에서 연결을 관리하고 대여·반환 처리 |

팩토리가 생성하는 것은 개별 요청 객체다. 요청마다 Apache HttpClient와 연결 풀을 새로 생성한다는 뜻은 아니다.

## 2. 사용 예제의 전제

아래 예제는 Spring Framework 7 계열, Apache HttpClient 5 계열의 동기 방식 API를 사용한다. Apache의 `ConnectionConfig`를 사용하는 구성은 HttpClient 5.2 이상을 전제로 한다. 오래된 HttpClient 4 예제의 `org.apache.http.*`와 여기의 `org.apache.hc.*` 패키지를 섞지 않는다.

필요한 주요 의존성은 다음과 같다.

| 의존성 | 용도 |
|---|---|
| `org.springframework:spring-web` | `RestClient`, 요청 팩토리 |
| `org.springframework:spring-context` | `@Configuration`, `@Bean`, Spring 컨테이너 |
| `org.apache.httpcomponents.client5:httpclient5` | Apache HTTP 클라이언트와 연결 풀 |

Spring Boot를 사용한다면 해당 Boot 버전의 의존성 관리에 맞춰 라이브러리를 선택한다. Boot 없이 구성한다면 호환되는 버전을 직접 지정해야 한다. 아래 코드는 Spring이 관리하는 설정 클래스로 사용하거나, 작은 Spring 컨텍스트에 직접 등록할 수 있다.

## 3. 연결 정책을 명시하는 Java 설정

예제의 숫자는 설명을 위한 설정이다. 실제 서비스에서는 외부 서버의 응답 특성, 동시 요청 수, 전체 요청 제한 시간을 보고 결정한다.

`ExternalHttpConfiguration.java`:

```java
package example.httptransport;

import org.apache.hc.client5.http.config.ConnectionConfig;
import org.apache.hc.client5.http.config.RequestConfig;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManagerBuilder;
import org.apache.hc.core5.util.Timeout;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration(proxyBeanMethods = false)
public class ExternalHttpConfiguration {

    @Bean
    public HttpComponentsClientHttpRequestFactory externalRequestFactory() {
        var connectionConfig = ConnectionConfig.custom()
                .setConnectTimeout(Timeout.ofSeconds(3))
                .setSocketTimeout(Timeout.ofSeconds(10))
                .build();

        var manager = PoolingHttpClientConnectionManagerBuilder.create()
                .setMaxConnTotal(20)
                .setMaxConnPerRoute(10)
                .setDefaultConnectionConfig(connectionConfig)
                .build();

        var requestConfig = RequestConfig.custom()
                .setConnectionRequestTimeout(Timeout.ofSeconds(2))
                .setResponseTimeout(Timeout.ofSeconds(10))
                .build();

        var httpClient = HttpClients.custom()
                .setConnectionManager(manager)
                .setDefaultRequestConfig(requestConfig)
                .disableAutomaticRetries()
                .disableRedirectHandling()
                .build();

        return new HttpComponentsClientHttpRequestFactory(httpClient);
    }

    @Bean
    public RestClient externalRestClient(
            @Qualifier("externalRequestFactory")
            HttpComponentsClientHttpRequestFactory requestFactory) {
        return RestClient.builder()
                .requestFactory(requestFactory)
                .build();
    }
}
```

이 코드는 다음 순서로 객체를 구성한다.

1. 연결 수립과 소켓 대기에 적용할 기본 설정을 만든다.
2. 연결 개수와 기본 설정을 가진 연결 관리자를 만든다.
3. 연결 대여와 응답 대기에 적용할 요청 설정을 만든다.
4. 설정들을 Apache HttpClient에 적용한다.
5. HttpClient를 요청 팩토리로 감싼 뒤 `RestClient`에 연결한다.

`@Qualifier`는 다른 요청 팩토리가 추가되어도 이 클라이언트에 사용할 빈을 명확히 선택한다. `proxyBeanMethods = false`이므로 설정 메서드를 직접 호출해 빈을 가져오지 않고, 메서드 매개변수로 주입받는다.

## 4. 구성한 클라이언트 사용하기

Spring이 관리하는 객체에서 `externalRestClient`를 주입받은 뒤 다음처럼 호출할 수 있다. 아래의 주소는 설명용이므로 실제 API 주소로 바꿔야 한다.

```java
String result = restClient.get()
        .uri("https://api.example.com/products/42")
        .retrieve()
        .body(String.class);
```

URL과 HTTP 메서드는 호출 코드가 결정하지만, 연결 풀과 타임아웃은 앞서 설정한 Apache HttpClient의 정책을 따른다. 이 예제는 `RestClient.builder()`로 직접 구성하므로 Spring Boot가 제공하는 빌더의 공통 커스터마이징은 자동으로 상속하지 않는다. Boot의 관측·공통 설정이 필요하다면 주입받은 빌더를 사용해 요청 팩토리를 지정하는 구성을 검토한다.

`retrieve()`의 기본 오류 처리는 4xx·5xx 응답을 예외로 바꾼다. 3xx까지 오류로 처리하려면 별도 상태 처리 정책이 필요하다. 리다이렉트 추적을 끄는 것과 3xx를 예외로 바꾸는 것은 서로 다른 설정이다. [Spring 응답과 오류 처리](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html)

## 5. 타임아웃은 무엇을 기다리는 시간인가

| 설정 | 의미 | 예제 값 |
|---|---|---:|
| `connectionRequestTimeout` | 풀에서 사용할 연결을 얻기까지 기다리는 시간 | 2초 |
| `connectTimeout` | 새 연결이 수립되기까지의 제한 시간 | 3초 |
| `socketTimeout` | 연결 수준의 기본 소켓 I/O 대기 제한 | 10초 |
| `responseTimeout` | 요청에 대한 응답 대기 제한 | 10초 |

연결을 재사용하면 새 연결 수립 단계가 생략될 수 있다. 반대로 풀의 연결이 모두 사용 중이면 외부 서버에 요청을 보내기 전부터 연결 대여를 기다릴 수 있다. [Apache 연결 설정](https://hc.apache.org/httpcomponents-client-5.6.x/current/httpclient5/apidocs/org/apache/hc/client5/http/config/ConnectionConfig.Builder.html), [Apache 요청 설정](https://hc.apache.org/httpcomponents-client-5.6.x/current/httpclient5/apidocs/org/apache/hc/client5/http/config/RequestConfig.Builder.html)

이 네 값은 독립적인 전체 작업 타이머가 아니다. 동기 통신에서 `responseTimeout`은 메시지 교환 중 연결 수준의 소켓 타임아웃을 덮어쓸 수 있다. 예제에서는 두 값을 동일하게 설정했다.

특히 `responseTimeout = 10초`는 전체 API 호출이나 여러 번의 외부 요청이 반드시 10초 안에 끝난다는 보장이 아니다. 전체 작업의 종료 시한이 필요하면 호출 흐름 전체에 대한 별도 정책이 필요하다. Apache 문서도 응답 타임아웃을 전체 작업의 deadline으로 정의하지 않는다. [응답 타임아웃 설명](https://hc.apache.org/httpcomponents-client-5.6.x/current/httpclient5/apidocs/org/apache/hc/client5/http/config/RequestConfig.Builder.html#setResponseTimeout(org.apache.hc.core5.util.Timeout))

## 6. 연결 풀의 의미

연결 풀은 사용할 수 있는 연결을 보관하고 다시 대여하는 구조다. 예제의 `maxConnTotal = 20`은 해당 풀 전체의 최대 연결 수이고, `maxConnPerRoute = 10`은 같은 경로에 대한 최대 연결 수다. 경로는 단순한 URL 경로(`/products` 등)가 아니라 대상 호스트·포트와 프록시 등의 연결 경로를 뜻한다. [Apache 연결 관리자 빌더](https://hc.apache.org/httpcomponents-client-5.6.x/current/httpclient5/apidocs/org/apache/hc/client5/http/impl/io/PoolingHttpClientConnectionManagerBuilder.html)

예를 들어 같은 서버로 향하는 연결 10개가 모두 사용 중이면 추가 호출은 연결이 반환되기를 기다릴 수 있다. 이 대기에는 `connectionRequestTimeout`이 적용된다.

요청마다 설정 클래스를 직접 생성하고 팩토리를 다시 만들면 풀도 반복 생성된다. 애플리케이션에서 오래 사용하는 빈으로 구성해야 풀을 재사용할 수 있다. 서로 독립적인 외부 서비스가 같은 풀의 연결을 독점하는 문제가 있다면 클라이언트와 풀을 나눌지 검토한다.

## 7. 자동 재시도와 리다이렉트는 별도의 정책이다

예제의 두 설정은 HTTP 클라이언트가 추가 요청을 자동으로 보내는 동작을 제한한다.

```java
.disableAutomaticRetries()
.disableRedirectHandling()
```

첫 번째 설정은 Apache HttpClient 수준의 자동 재시도를 끈다. 호출 코드나 다른 라이브러리에 구현된 재시도까지 제거하지는 않는다. 두 번째 설정은 3xx 응답의 이동 주소를 자동으로 따라가지 않게 한다. [Apache HttpClient 빌더](https://hc.apache.org/httpcomponents-client-5.6.x/current/httpclient5/apidocs/org/apache/hc/client5/http/impl/classic/HttpClientBuilder.html)

이 설정은 모든 서비스에 동일하게 적용해야 하는 규칙은 아니다. 예를 들어 조회 재시도를 허용할지, 쓰기 요청에 중복 방지 키가 있는지, 리다이렉트가 API 계약의 일부인지에 따라 결정한다. 예제는 요청 횟수와 이동 여부를 호출하는 쪽에서 명시적으로 판단하는 구성을 보여 준다.

## 8. 종료할 때 누가 자원을 정리하는가

이 팩토리는 `DisposableBean`을 구현하고 `destroy()`를 통해 내부 연결 풀을 닫는 종료 처리를 제공한다. 위 예제처럼 Spring 빈으로 등록하면 정상적인 컨텍스트 종료 시 Spring이 종료 처리를 호출한다. [팩토리의 destroy 메서드](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/http/client/HttpComponentsClientHttpRequestFactory.html#destroy())

예제에서는 팩토리가 사용하는 클라이언트와 풀을 전용으로 생성했다. 요청이 끝날 때마다 팩토리를 닫지 않는다. Spring 밖에서 직접 생성해 사용한다면 사용 수명이 끝날 때 정리하는 코드를 직접 마련해야 한다.

여러 팩토리가 클라이언트나 연결 관리자를 공유한다면 소유권을 별도로 정해야 한다. 한 객체가 종료되면서 다른 객체가 사용 중인 공용 자원까지 닫지 않도록 공유 설정과 종료 주체를 함께 설계한다.

## 9. 테스트할 때 구분할 것

| 검증할 내용 | 적절한 접근 |
|---|---|
| 요청 URL·헤더·본문과 응답 해석 | `MockRestServiceServer`로 응답 대체 |
| 실제 연결·타임아웃·리다이렉트·재시도 | 로컬 HTTP 테스트 서버에 실제 요청 |
| 빈 생성·주입과 종료 구성 | 작은 Spring 컨텍스트를 생성하고 닫기 |

`MockRestServiceServer`는 요청 팩토리를 테스트용 구현으로 대체한다. 따라서 모의 서버 테스트가 통과했다고 해서 Apache HttpClient의 실제 연결 정책까지 검증된 것은 아니다. [Spring HTTP 클라이언트 테스트 안내](https://docs.spring.io/spring-framework/reference/testing/spring-mvc-test-client.html)

예를 들어 리다이렉트 정책은 로컬 서버가 `302`와 `Location`을 반환하게 하고, 이동 대상에 요청이 도착했는지 확인한다. 재시도 정책은 `503` 응답을 보내고 서버가 받은 요청 수를 확인한다. 타임아웃은 응답을 지연시키는 서버를 사용하되, 전체 실행 시간이 정확히 설정값과 같다고 단정하는 테스트는 피한다.

## 10. 이 객체가 담당하지 않는 것

팩토리는 HTTP 통신 구현을 Spring에 연결하는 역할이다. OAuth 토큰 갱신, 업무 오류 판단, 응답 JSON의 업무 모델 변환, 화면 표시 방식은 호출자나 별도 객체의 책임이다.

예를 들어 `401` 응답 후 토큰을 다시 발급받을지 여부는 인증 처리 정책이고, 응답이 너무 커서 처리를 중단할지 여부는 응답 읽기 정책이다. 요청 팩토리를 등록하는 것만으로 이러한 동작이 생기지는 않는다.

## 검증 범위

공식 문서는 2026-10-15에 확인했다. 공식 링크의 `current` 문서는 이후 버전으로 변경될 수 있으므로 실제 적용 시 사용하는 라이브러리 버전과 대조한다.

같은 날 문서의 `ExternalHttpConfiguration` 코드를 그대로 추출해 Java 25 환경에서 컴파일하고, 작은 Spring 컨텍스트와 로컬 HTTP 서버로 다음 3개 테스트를 실행해 모두 통과했다.

- 구성한 `RestClient`로 문자열 응답을 읽는다.
- `503` 응답을 예외로 전달하며 서버에 요청을 한 번만 보낸다.
- `302` 응답을 그대로 받으며 이동 대상에 추가 요청을 보내지 않는다.

각 테스트는 종료 시 컨텍스트와 로컬 서버를 닫았다. 이 검증은 연결 풀 고갈, 실제 타임아웃 발생, TLS 연결, 종료 후 모든 소켓의 상태까지 확인한 것은 아니다. 숫자로 지정한 타임아웃과 연결 제한은 예제 설정이며 운영 성능을 측정한 결과가 아니다.
