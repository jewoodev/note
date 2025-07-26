Spring WebFlux에서 Thymeleaf를 사용하여 서버 사이드 렌더링을 구현할 때는 일반 Spring MVC와는 다른 의존성을 사용해야 합니다.

WebFlux에서는 비동기-논블로킹 방식을 지원하는 Thymeleaf 의존성이 필요합니다. 구체적으로는 다음과 같은 의존성을 추가해야 합니다:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

중요한 점은 Spring Boot 2.0 이상부터는 Thymeleaf가 리액티브 스트림을 자동으로 지원하도록 설계되었습니다. 따라서 기본 `spring-boot-starter-thymeleaf`를 사용해도 WebFlux 환경에서 잘 작동합니다.

컨트롤러에서는 `Model` 대신 `Mono<String>` 또는 `Flux<ServerSideEvent>`와 같은 리액티브 타입을 반환하게 됩니다. 예를 들면:

```java
@GetMapping("/example")
public Mono<String> example(final Model model) {
    model.addAttribute("message", "Hello, WebFlux!");
    return Mono.just("example");
}
```

WebFlux와 Thymeleaf를 함께 사용할 때 이러한 리액티브 스타일의 프로그래밍 모델을 따르게 됩니다.


## WebFlux + Thymeleaf Controller Examples

- **WebFlux + Thymeleaf Controller Examples**

    ```java
    import org.springframework.stereotype.Controller;
    import org.springframework.ui.Model;
    import org.springframework.web.bind.annotation.GetMapping;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.RequestParam;
    import org.springframework.web.server.ServerWebExchange;

    import reactor.core.publisher.Mono;

    @Controller
    public class WebFluxThymeleafController {

        // 뷰를 반환하는 컨트롤러 메서드
        @GetMapping("/home")
        public Mono<String> home(Model model) {
            model.addAttribute("message", "WebFlux와 Thymeleaf를 사용한 서버 사이드 렌더링");
            model.addAttribute("currentTime", System.currentTimeMillis());
            
            // "home"은 templates 폴더 안의 home.html 템플릿을 가리킴
            return Mono.just("home");
        }
        
        // 데이터를 리액티브하게 로딩하는 뷰 컨트롤러
        @GetMapping("/users")
        public Mono<String> users(Model model) {
            // 사용자 데이터를 비동기적으로 가져오는 예시
            Mono<List<String>> usersMono = getUsersAsync();
            
            // flatMap을 사용하여 비동기 데이터를 모델에 추가
            return usersMono
                    .doOnNext(users -> model.addAttribute("users", users))
                    .then(Mono.just("users"));
        }
        
        // 리다이렉션하는 컨트롤러 메서드 - 방법 1: 문자열 리턴
        @GetMapping("/redirect1")
        public Mono<String> redirect1() {
            // "redirect:" 접두사를 사용하여 리다이렉션
            return Mono.just("redirect:/home");
        }
        
        // 리다이렉션하는 컨트롤러 메서드 - 방법 2: ServerResponse 사용
        @GetMapping("/redirect2")
        public Mono<Void> redirect2(ServerWebExchange exchange) {
            // ServerWebExchange를 사용한 리다이렉션
            exchange.getResponse().setStatusCode(org.springframework.http.HttpStatus.FOUND);
            exchange.getResponse().getHeaders().setLocation(URI.create("/home"));
            return Mono.empty();
        }
        
        // 폼 제출 후 리다이렉션하는 예시
        @PostMapping("/submit")
        public Mono<String> submitForm(@RequestParam String name, Model model) {
            // 폼 처리 로직
            return saveUserAsync(name)
                    .then(Mono.just("redirect:/success?name=" + name));
        }
        
        // 성공 페이지
        @GetMapping("/success")
        public Mono<String> success(@RequestParam String name, Model model) {
            model.addAttribute("name", name);
            return Mono.just("success");
        }
        
        // 비동기 사용자 데이터 가져오기 예시 메서드
        private Mono<List<String>> getUsersAsync() {
            return Mono.just(List.of("사용자1", "사용자2", "사용자3"));
        }
        
        // 비동기 저장 예시 메서드
        private Mono<Void> saveUserAsync(String name) {
            System.out.println("사용자 저장: " + name);
            return Mono.empty();
        }
    }
    ```

- Thymeleaf Templates
    ```java
    <!-- home.html -->
    <!DOCTYPE html>
    <html xmlns:th="http://www.thymeleaf.org">
    <head>
        <title>WebFlux + Thymeleaf 예제</title>
        <meta charset="UTF-8">
    </head>
    <body>
    <h1>WebFlux와 Thymeleaf</h1>
    <p th:text="${message}">기본 메시지</p>
    <p>현재 시간: <span th:text="${currentTime}">0</span></p>
    
    <ul>
        <li><a href="/users">사용자 목록</a></li>
        <li><a href="/redirect1">리다이렉션 예제 1</a></li>
        <li><a href="/redirect2">리다이렉션 예제 2</a></li>
    </ul>
    
    <form action="/submit" method="post">
        <label for="name">이름:</label>
        <input type="text" id="name" name="name" required>
        <button type="submit">제출</button>
    </form>
    </body>
    </html>

    <!-- users.html -->
    <!DOCTYPE html>
    <html xmlns:th="http://www.thymeleaf.org">
    <head>
        <title>사용자 목록</title>
        <meta charset="UTF-8">
    </head>
    <body>
        <h1>사용자 목록</h1>
        <ul>
            <li th:each="user : ${users}" th:text="${user}">사용자</li>
        </ul>
        <a href="/home">홈으로</a>
    </body>
    </html>

    <!-- success.html -->
    <!DOCTYPE html>
    <html xmlns:th="http://www.thymeleaf.org">
    <head>
        <title>제출 성공</title>
        <meta charset="UTF-8">
    </head>
    <body>
        <h1>제출 성공!</h1>
        <p><span th:text="${name}">사용자</span>님, 정보가 성공적으로 저장되었습니다.</p>
        <a href="/home">홈으로</a>
    </body>
    </html>
    ```


위 코드에서 볼 수 있듯이, WebFlux와 Thymeleaf를 함께 사용할 때의 주요 특징은:

1. **리액티브 반환 타입**: 컨트롤러 메서드에서 `Mono<String>`을 반환하여 비동기적으로 뷰 이름을 지정합니다.
2. **리다이렉션 방법**:
    - `"redirect:/경로"` 문자열 사용 - Spring MVC와 유사한 방식
    - `ServerWebExchange`를 사용한 상태 코드와 헤더 직접 설정
3. **비동기 데이터 처리**:
    - `Mono`나 `Flux`를 사용하여 데이터를 비동기적으로 가져오고 처리합니다.
    - `.doOnNext()`, `.then()` 등의 연산자를 사용하여 데이터 흐름을 제어합니다.
4. **Thymeleaf 템플릿**: 기본적인 사용법은 Spring MVC와 동일하며 비동기적으로 로드된 데이터도 동일한 방식으로 표시됩니다.

WebFlux 환경에서는 이런 리액티브 스타일의 프로그래밍을 통해 높은 동시성과 논블로킹 처리를 구현할 수 있습니다.