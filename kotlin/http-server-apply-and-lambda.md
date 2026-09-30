# Kotlin에서 `apply`와 람다로 테스트용 HTTP 서버 구성하기

외부 HTTP API를 호출하는 코드를 테스트할 때는 로컬 서버가 요청을 받고 미리 정한 응답을 돌려주도록 구성할 수 있다. 이 글에서는 JDK의 `HttpServer`를 Kotlin으로 생성·설정·시작하는 코드를 읽는다. 특정 프로젝트나 외부 API에 대한 지식은 필요하지 않다.

## 전체 예제

아래 클래스는 생성될 때 로컬 서버를 시작한다. `close()`를 호출하면 서버가 종료된다. 테스트 프레임워크가 있다면 테스트 종료 훅에서 `close()`를 호출하면 된다.

```kotlin
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets.UTF_8
import java.util.concurrent.CopyOnWriteArrayList

class LocalHttpFixture : AutoCloseable {
    val requests = CopyOnWriteArrayList<String>()
    private val response = "요청을 받았습니다"

    private val server = HttpServer.create(
        InetSocketAddress("127.0.0.1", 0),
        0,
    ).apply {
        createContext("/") { exchange ->
            val requestText = exchange.requestBody
                .bufferedReader(UTF_8)
                .use { reader -> reader.readText() }
            requests.add(requestText)

            val bytes = response.toByteArray(UTF_8)
            exchange.responseHeaders.set("Content-Type", "text/plain; charset=utf-8")
            exchange.sendResponseHeaders(200, bytes.size.toLong())
            exchange.responseBody.use { output ->
                output.write(bytes)
            }
        }
        start()
    }

    val port: Int
        get() = server.address.port

    override fun close() {
        server.stop(0)
    }
}
```

예제는 JDK의 `jdk.httpserver` 모듈을 사용한다. 모듈 시스템을 사용하는 Java 프로젝트에서는 `requires jdk.httpserver;` 선언이 필요하다.

## 서버 생성: 두 개의 `0`은 서로 다른 인자다

```kotlin
HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
```

- `127.0.0.1`: 같은 컴퓨터에서 접속하는 루프백 주소다.
- `InetSocketAddress`의 `0`: 운영체제가 사용 가능한 포트를 할당하도록 요청한다. 실제 포트는 `server.address.port`로 읽는다.
- `HttpServer.create`의 두 번째 인자 `0`: 대기 연결 큐의 크기인 backlog에 시스템 기본값을 사용한다.

`create()`는 주소에 바인딩된 서버를 만든다. 요청 처리를 시작하려면 `start()`를 호출해야 한다. `stop(0)`은 종료 시 진행 중인 처리를 기다리는 유예 시간을 0초로 지정한다. 종료한 서버는 다시 시작할 수 없다. [JDK HttpServer 문서](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html)

## `apply`: 생성한 객체를 설정하고 그 객체를 반환한다

```kotlin
val server = HttpServer.create(address, 0).apply {
    createContext("/") { exchange -> /* 요청 처리 */ }
    start()
}
```

`apply`는 객체를 수신 객체로 삼아 블록을 실행한다. 이 블록의 `this`는 방금 만든 `HttpServer`이므로 `createContext()`와 `start()` 앞의 `this.`를 생략할 수 있다.

블록의 마지막 호출은 `start()`지만, `apply`의 반환값은 서버 객체다. 따라서 `server` 변수에는 `HttpServer`가 저장된다. `apply`는 객체를 설정하는 의도를 나타내는 Kotlin 범위 함수다. [Kotlin 범위 함수 문서](https://kotlinlang.org/docs/scope-functions.html#apply)

다음처럼 풀어 쓰면 객체 생성과 설정의 관계가 드러난다.

```kotlin
val server = HttpServer.create(address, 0)
server.createContext("/") { exchange -> /* 요청 처리 */ }
server.start()
```

두 표현은 이 예제에서 같은 서버 구성 순서를 나타낸다. 읽기 어려운 중첩이 늘어나면 두 번째 표현처럼 객체 이름을 명시하는 것도 좋다.

## `createContext`: 요청 처리 함수를 등록한다

```kotlin
createContext("/") { exchange ->
    // 요청이 들어왔을 때 실행할 코드
}
```

`{ exchange -> ... }`는 람다다. `->` 앞은 매개변수, 뒤는 실행할 본문이다. `exchange`의 타입은 호출할 메서드가 요구하는 `HttpExchange`로 추론된다.

마지막 인자로 전달하는 람다를 호출 괄호 밖에 쓰는 문법을 **후행 람다**라고 한다. [Kotlin 람다 문서](https://kotlinlang.org/docs/lambdas.html#passing-trailing-lambdas)

Java API인 `createContext`는 `HttpHandler`를 받는다. 이 인터페이스에는 구현할 추상 메서드 `handle(HttpExchange)`가 하나 있으므로 Kotlin에서 람다로 구현을 전달할 수 있다. 이를 **SAM 변환**이라고 한다. SAM은 Single Abstract Method의 약자다. [Kotlin Java SAM 변환 문서](https://kotlinlang.org/docs/java-interop.html#sam-conversions)

명시적으로 객체를 만드는 형태와 비교하면 다음과 같다.

```kotlin
server.createContext("/", object : com.sun.net.httpserver.HttpHandler {
    override fun handle(exchange: com.sun.net.httpserver.HttpExchange) {
        // 요청 처리
    }
})
```

이 코드의 익명 객체를 간결하게 표현한 것이 앞의 람다다. `/` 컨텍스트는 경로 접두어로 매칭하므로, 다른 컨텍스트가 없다면 `/hello` 같은 하위 경로도 처리한다. [JDK HttpServer 문서](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpServer.html)

## 블록의 위치와 실행 시점은 다르다

중괄호가 중첩되어 있어도 모든 본문이 초기화 시 실행되는 것은 아니다.

```text
클래스 인스턴스 생성
  → HttpServer.create(): 서버 생성·바인딩
  → apply 블록 실행
      → createContext(): 요청 처리 람다 등록
      → start(): 서버 시작
  → apply가 서버 객체 반환
  → server 프로퍼티 초기화 완료

이후 클라이언트가 HTTP 요청 전송
  → 등록한 요청 처리 람다 실행
  → 요청 본문 기록·응답 전송
```

`apply`는 초기화 과정에서 바로 실행된다. `createContext` 안의 람다는 서버에 등록되고, 요청이 도착하면 실행된다. `start()`는 요청 처리 람다 밖에 있으므로 각 요청마다 호출되지 않는다.

서버는 별도 스레드에서 요청을 처리한다. 프로퍼티에 서버 객체를 저장하는 행위를 서버가 처리할 모든 요청의 완료를 기다리는 동작으로 이해하면 안 된다.

## 요청 처리 본문의 문법

`HttpExchange`는 한 번의 요청과 응답을 다루는 객체다. 요청 헤더·본문을 읽고 응답 헤더·본문을 쓸 수 있다. [JDK HttpExchange 문서](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpExchange.html)

### 문자열 읽기와 목록에 추가하기

```kotlin
val requestText = exchange.requestBody.bufferedReader(UTF_8)
    .use { reader -> reader.readText() }
requests.add(requestText)
```

본문 스트림을 문자 리더로 감싸 전체 문자열을 읽는다. `requests`는 테스트 코드와 서버 처리 스레드에서 함께 접근할 수 있어 스레드 안전한 목록을 사용했다.

같은 목록에 문자열 하나를 추가할 때 다음 표현도 사용할 수 있다.

```kotlin
requests += requestText
```

이 경우 목록의 내용을 변경한다. `requests`의 선언이 `val`이라는 것은 다른 목록 객체로 재할당할 수 없다는 뜻이며, 가변 목록에 원소를 추가하는 것은 가능하다.

### 응답 길이는 문자 수가 아니라 바이트 수다

```kotlin
val bytes = response.toByteArray(UTF_8)
exchange.sendResponseHeaders(200, bytes.size.toLong())
```

응답 본문을 UTF-8 바이트 배열로 만든 뒤 그 길이를 보낸다. 한글처럼 문자 하나가 여러 바이트인 내용이 있으므로 `response.length`를 본문 길이로 사용하지 않는다. `bytes.size`는 `Int`이고 API는 `Long`을 요구해 `toLong()`으로 변환한다. [JDK HttpExchange 문서](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.httpserver/com/sun/net/httpserver/HttpExchange.html#sendResponseHeaders(int,long))

### `use`와 `it`

```kotlin
exchange.responseBody.use { it.write(bytes) }
```

`use`는 자원을 블록에 전달하고, 블록이 끝나면 정상 종료와 예외 발생 모두에서 자원을 닫는다. 여기서 `it`은 매개변수 하나를 가진 람다의 기본 이름이며, 응답 출력 스트림을 가리킨다. [Kotlin use 문서](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.io/use.html)

다음처럼 이름을 붙여도 같은 의미다.

```kotlin
exchange.responseBody.use { output ->
    output.write(bytes)
}
```

바깥 `apply`의 `this`는 서버, 요청 처리 람다의 `exchange`는 요청·응답 객체, `use`의 `it` 또는 `output`은 스트림이다. 중첩된 코드에서는 각각 무엇을 가리키는지 구분해서 읽는다.

## 테스트에서 응답을 지연시키는 경우

시간 초과 처리를 테스트할 때는 요청 처리 본문에 다음 코드를 넣을 수 있다.

```kotlin
if (responseDelayMillis > 0) {
    Thread.sleep(responseDelayMillis)
}
```

서버 처리 스레드를 지정한 밀리초만큼 멈춘다. 이 지연은 실제 시간을 소비하며 클라이언트의 제한 시간과 비교하는 데 사용된다. 실제 실행 환경의 스케줄링 영향을 받으므로 테스트의 시간 간격을 지나치게 촘촘하게 잡지 않는다.

## 적용 범위

이 구성은 외부 서비스 대신 요청을 관찰하고 응답을 제어하는 테스트에 적합하다. 요청 형식, 인증 헤더, 응답 파싱, 오류 상태, 시간 초과 처리를 검증할 수 있다. 외부 서비스가 실제로 올바른 판단이나 응답을 하는지는 별도의 검증이 필요하다.

예제의 본문 전체 읽기는 작은 테스트 데이터에 맞춘 방식이다. 큰 본문 처리나 여러 요청의 동시 처리가 필요한 서버라면 크기 제한과 실행기 정책을 별도로 설계한다. 서버 종료는 테스트 성공 여부와 관계없이 수행되도록 구성한다.
