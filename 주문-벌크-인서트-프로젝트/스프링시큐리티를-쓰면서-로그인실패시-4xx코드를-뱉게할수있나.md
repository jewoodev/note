# 스프링 시큐리티를 쓰면서 로그인 실패시 4xx 코드를 뱉게 할 수 있나?
스프링 시큐리티는 로그인에 실패했을 때 FailureUrl으로 리다이렉션하는 구조로 설계되었다.  
시큐리티 내부 로직을 수정해서 이를 고치는 것도 방법이겠지만, 그렇게 하면 시큐리티의 업데이트나 버그픽스를 받을 때 문제가 생길 수 있다.

나는 결론적으로 리다이렉션되는 그대로를 받아들여 로직을 구성하는 전략을 택하고 테스트 해보지 못했지만 다음과 같은 방법들을 시도해볼 수 있다.

## 1. ResponseEntity 사용
로그인 컨트롤러에서 ResponseEntity를 반환하도록 변경하면 HTTP 상태 코드도 제어할 수 있다.
```java
class LoginController {
    @PostMapping("/login")
    public ResponseEntity<String> login(@Valid @ModelAttribute LoginForm loginForm, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("로그인 실패: 아이디 또는 비밀번호가 올바르지 않습니다.");
        }

        // 로그인 성공 로직
        return ResponseEntity.ok("로그인 성공");
    }
}
```
이렇게 하면 클라이언트가 AJAX 요청을 보낼 때 상태 코드를 확인하고 적절한 처리를 할 수 있다.

## 2. 예외를 던지고 @ControllerAdvice 활용
스프링의 `@ExceptionHandler`와 `@ControllerAdvice`를 사용하면, 특정 예외 발생 시 자동으로 상태 코드를 변경할 수 있다.
1. 커스텀 예외 만들기
    ```java
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public class LoginFailedException extends RuntimeException {
        public LoginFailedException(String message) {
            super(message);
        }
    }
    ```
2. 로그인 실패 시 예외 던지기
    ```java
    class LoginController {
        @PostMapping("/login")
        public String login(@Valid @ModelAttribute LoginForm loginForm, BindingResult bindingResult) {
            if (bindingResult.hasErrors()) {
                throw new LoginFailedException("아이디 또는 비밀번호가 틀렸습니다.");
            }
            // 로그인 성공 로직
            return "redirect:/home";
        }
    }  
    ```
3. 전역 예외 처리
    ```java
    @ControllerAdvice
    public class GlobalExceptionHandler {
        @ExceptionHandler(LoginFailedException.class)
        public ResponseEntity<String> handleLoginFailed(LoginFailedException ex) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ex.getMessage());
        }
    }
    ```

## 3. 상태 코드 변경 후 HTML 반환
기존처럼 HTML을 반환하면서 상태 코드도 변경하려면 HttpServletResponse를 활용하면 된다.
```java
class LoginController {
    @PostMapping("/login")
    public String login(@Valid @ModelAttribute LoginForm loginForm, BindingResult bindingResult, HttpServletResponse response) {
        if (bindingResult.hasErrors()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return "login";  // 로그인 페이지로 다시 이동
        }

        return "redirect:/home";
    }
}
```

## 4. AuthenticationFailureHandler를 구현해 사용
아마 `SimpleUrlAuthenticationFailureHandler` 자체가 리다이렉션하는 걸 수행하는 핸들러인 것 같은데 이게 아닌 핸들러를 만들면 해결될 것이다.

`SimpleUrlAuthenticationFailureHandler`는 `redirectStrategy.sendRedirect(...)`을 수행하는데  
이 로직을 대신해서 `RequestDispatcher.forward(...)`를 사용해 서버 내부에서 직접 요청을 전달하는 방법이 하나의 해결 방법일 것이다(테스트 안해봄).  
이 방법을 쓴다면 핸들러에서 에러메세지를 전달할 때 세션을 사용해야 할 것이다. `HttpServletRequest.getSession().setAttribute(...)`를 사용해서 핸들러에서 에러메세지를 담고 컨트롤러에서 뷰에 전달하자.
