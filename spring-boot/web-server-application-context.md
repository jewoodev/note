# Spring Boot의 WebServerApplicationContext 개념과 활용

`WebServerApplicationContext`는 **내장 웹 서버를 생성하고 생명주기를 관리하는 Spring 애플리케이션 컨텍스트의 인터페이스**다. 빈을 조회하는 기능에 더해, 컨텍스트가 생성한 웹 서버에도 접근할 수 있다. [공식 API 문서](https://docs.spring.io/spring-boot/4.0/api/java/org/springframework/boot/web/server/context/WebServerApplicationContext.html)

이 문서는 Spring Boot 4와 Kotlin을 기준으로 설명한다. 특정 서비스나 프로젝트에 대한 사전 지식은 필요하지 않다.

## 먼저 알아둘 세 가지 개념

### 빈과 ApplicationContext

Spring이 생성하고 관리하는 객체를 **빈(bean)**이라고 한다. 예를 들어 컨트롤러, 서비스, 저장소 객체를 빈으로 등록할 수 있다.

`ApplicationContext`는 이러한 빈을 관리하는 컨테이너다. 빈을 생성하고 필요한 의존성을 연결하며, 설정값과 이벤트를 다루는 기능도 제공한다.

```kotlin
val service = context.getBean(MyService::class.java)
```

위 코드는 컨텍스트에서 `MyService` 타입의 빈을 가져오는 예다. `MyService`는 설명을 위한 임의의 서비스 타입이다.

### WebServer

`WebServer`는 내장 웹 서버를 다루는 추상화다. HTTP 요청을 받으려면 실제 서버가 포트를 열고 실행되어야 한다. Spring Boot에서는 내장 Tomcat과 같은 서버를 애플리케이션 프로세스 안에서 실행할 수 있다.

컨텍스트가 관리하는 서비스 객체와, 네트워크 요청을 받는 웹 서버는 서로 역할이 다르다.

### WebServerApplicationContext

`WebServerApplicationContext`는 `ApplicationContext`를 확장한다. 따라서 일반적인 빈 조회 기능을 사용하면서, 자신이 생성한 `WebServer`도 가져올 수 있다.

| 타입 | 주요 역할 |
| --- | --- |
| `ApplicationContext` | 빈과 애플리케이션 실행 환경 관리 |
| `WebServer` | 내장 웹 서버 제어와 실제 포트 정보 제공 |
| `WebServerApplicationContext` | 내장 웹 서버를 관리하는 컨텍스트의 공통 계약 |

이 인터페이스를 직접 생성하는 것은 아니다. 실제 구현체가 인터페이스의 기능을 제공한다. Servlet 기반 애플리케이션의 구현 계열인 `ServletWebServerApplicationContext`는 서버 팩토리 빈을 찾아 웹 서버를 생성·초기화·실행한다. [구현체의 공식 설명](https://docs.spring.io/spring-boot/4.0/api/java/org/springframework/boot/web/server/servlet/context/ServletWebServerApplicationContext.html)

## 대표적인 활용: 자동 배정된 서버 포트 조회

여러 테스트가 모두 `8080` 포트를 사용하면 동시에 실행할 때 충돌할 수 있다. 이때 `server.port=0`으로 설정하면 운영체제가 사용 가능한 포트를 배정한다.

설정에 적힌 `0`은 실제 접속할 포트 번호가 아니다. 서버가 시작된 뒤 배정된 번호를 알아내야 한다. 이때 `WebServerApplicationContext`를 활용할 수 있다.

다음은 Spring Boot와 Spring MVC 의존성이 있는 Kotlin 애플리케이션에서 실행하는 예다. 빈을 검색하는 범위를 이해할 필요 없이 읽을 수 있도록 구성 클래스와 컨트롤러를 명시적으로 연결했다.

```kotlin
import org.springframework.boot.WebApplicationType
import org.springframework.boot.autoconfigure.EnableAutoConfiguration
import org.springframework.boot.builder.SpringApplicationBuilder
import org.springframework.boot.web.server.context.WebServerApplicationContext
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Import
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

@Configuration(proxyBeanMethods = false)
@EnableAutoConfiguration
@Import(GreetingController::class)
class SampleConfiguration

@RestController
class GreetingController {
    @GetMapping("/greeting")
    fun greeting() = "Hello"
}

fun main() {
    SpringApplicationBuilder(SampleConfiguration::class.java)
        .web(WebApplicationType.SERVLET)
        .run("--server.address=127.0.0.1", "--server.port=0")
        .use { context ->
            val webContext = context as WebServerApplicationContext
            val server = checkNotNull(webContext.webServer)
            val port = server.port

            val request = HttpRequest.newBuilder()
                .uri(URI("http://127.0.0.1:$port/greeting"))
                .GET()
                .build()

            HttpClient.newHttpClient().use { client ->
                val response = client.send(
                    request,
                    HttpResponse.BodyHandlers.ofString(),
                )
                check(response.statusCode() == 200)
                check(response.body() == "Hello")
            }
        }
}
```

예제의 Java HTTP 클라이언트에 사용한 `use`는 Java 21 이상을 기준으로 한다. 컨텍스트의 `use` 블록이 끝나면 컨텍스트를 닫아 내장 서버와 관리 자원을 정리한다.

이 예제는 서버를 시작하고, 실제 포트를 조회하고, 그 주소로 HTTP 요청을 보낸다. 같은 방식으로 별도 Python 프로세스나 다른 언어의 클라이언트에 서버 주소를 전달해 연동 테스트를 수행할 수 있다.

## 포트를 가져오는 표현식 해석

위 예제의 세 줄을 하나로 합치면 다음과 같다.

```kotlin
val port = checkNotNull(
    (context as WebServerApplicationContext).webServer
).port
```

실행 순서는 다음과 같다.

1. `as WebServerApplicationContext`로 컨텍스트를 해당 인터페이스 타입으로 캐스팅한다.
2. `.webServer`로 컨텍스트가 생성한 서버를 가져온다.
3. `checkNotNull`로 서버가 존재하는지 확인한다.
4. `.port`로 서버의 실제 포트 번호를 읽는다.

Kotlin의 `.webServer`와 `.port`는 각각 Java의 `getWebServer()`와 `getPort()`에 대응하는 프로퍼티 접근 문법이다. 테스트에서는 `checkNotNull` 대신 테스트 라이브러리의 `assertNotNull`을 사용해 서버가 없을 때 테스트를 실패시킬 수도 있다.

## 사용할 때 구분해야 하는 것

### 캐스팅이 서버를 만들어 주지는 않는다

`as`는 이미 존재하는 객체를 다른 타입으로 취급하는 연산이다. 일반 컨텍스트를 웹 서버 컨텍스트로 변환하거나 서버를 시작하지 않는다.

실제 객체가 `WebServerApplicationContext`를 구현하지 않았다면 캐스팅은 실패한다. 웹 서버 없이 실행하는 명령행 애플리케이션에서는 이 인터페이스를 사용할 수 있다고 가정하면 안 된다.

### 서버의 존재와 서버의 실행 완료는 별개다

`getWebServer()`는 서버가 아직 생성되지 않았다면 `null`을 반환할 수 있다. 따라서 빈 초기화 도중처럼 서버 시작 전일 수 있는 시점에는 조회 시점을 주의해야 한다. [반환값 계약](https://docs.spring.io/spring-boot/4.0/api/java/org/springframework/boot/web/server/context/WebServerApplicationContext.html#getWebServer())

또한 `assertNotNull(server)`는 객체의 존재를 확인하는 검증이다. 요청 처리 성공은 예제처럼 실제 HTTP 응답을 확인해야 판단할 수 있다.

### WebApplicationContext와 이름이 비슷하지만 초점이 다르다

Spring Framework의 `WebApplicationContext`는 Servlet 환경의 컨텍스트를 나타내며 `ServletContext` 접근 같은 기능을 제공한다.

Spring Boot의 `WebServerApplicationContext`는 내장 서버의 생성과 생명주기 관리에 초점을 둔다. Servlet 기반 구현체는 두 계약을 함께 구현할 수 있지만, 두 인터페이스 자체가 같은 의미는 아니다. [Servlet 구현체의 인터페이스 목록](https://docs.spring.io/spring-boot/4.0/api/java/org/springframework/boot/web/server/servlet/context/ServletWebServerApplicationContext.html)

### 버전에 따라 import 경로가 다르다

Spring Boot 4에서는 다음 경로를 사용한다.

```kotlin
import org.springframework.boot.web.server.context.WebServerApplicationContext
```

Spring Boot 3 문서나 예제에서는 `org.springframework.boot.web.context.WebServerApplicationContext`가 등장한다. 코드를 옮길 때 사용하는 Spring Boot 버전의 API를 확인해야 한다. [Spring Boot 3 API](https://docs.spring.io/spring-boot/3.4/api/java/org/springframework/boot/web/context/WebServerApplicationContext.html)
