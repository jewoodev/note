WebFlux에서는 MVC와 다르게 try-catch 문을 사용할 일이 없고, 예외 처리를 더 다양한 방법으로 하기 때문에 어떻게 처리하는게 좋은지 고민하게 된다. 하지만 결국은 MVC와 크게 다를 바 없는 부분이다.

일반적으로는 어드바이저에서 공통적인 에러 처리를 해주고, 필요 시에만 해당 부분에서만 별도 처리를 해주자. 어떤 이유에서 이 방법이 더 좋은지 한 번 정리해보자.

1. **일관성** (Consistency)
    - 어드바이저를 사용하면 애플리케이션 전체에서 일관된 에러 처리 방식을 유지할 수 있습니다.
    - 모든 컨트롤러에서 동일한 에러 응답 형식을 보장할 수 있습니다.
2. **코드 중복 감소** (Reduced Code Duplication)
    - 각 컨트롤러 메서드마다 onErrorResume을 작성하면 코드 중복이 발생합니다.
    - 어드바이저를 사용하면 에러 처리 로직을 한 곳에서 관리할 수 있습니다.
3. **관심사의 분리** (Separation of Concerns)
    - 컨트롤러는 비즈니스 로직에만 집중할 수 있습니다.
    - 에러 처리 로직은 별도의 계층에서 관리됩니다.
4. **유지보수성** (Maintainability)
    - 에러 처리 로직을 변경할 때 한 곳만 수정하면 됩니다.
    - 새로운 에러 타입을 추가하거나 처리 방식을 변경하기 쉽습니다.

예시 코드를 보면서 이해해보자.

```java
@Configuration
public class GlobalErrorHandler implements ErrorWebExceptionHandler {
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        if (ex instanceof BusinessException) {
            return handleBusinessException(exchange, (BusinessException) ex);
        }
        if (ex instanceof ValidationException) {
            return handleValidationException(exchange, (ValidationException) ex);
        }
        return handleGenericException(exchange, ex);
    }

    private Mono<Void> handleBusinessException(ServerWebExchange exchange, BusinessException ex) {
        exchange.getResponse().setStatusCode(HttpStatus.BAD_REQUEST);
        return exchange.getResponse().writeWith(
            Mono.just(exchange.getResponse()
                .bufferFactory()
                .wrap(createErrorResponse(ex).getBytes())));
    }
    
    // ... 다른 예외 처리 메서드들
}
```

다음과 같은 경우에는 컨트롤러 레벨에서 onErrorResume을 사용하는 것이 더 적절할 수 있습니다:
특정 컨트롤러에만 적용되는 특수한 에러 처리가 필요한 경우
컨트롤러별로 다른 에러 응답 형식이 필요한 경우
에러 발생 시 특정 비즈니스 로직을 실행해야 하는 경우

```java
@GetMapping("/users/{id}")
public Mono<User> getUser(@PathVariable String id) {
    return userService.findById(id)
        .onErrorResume(UserNotFoundException.class, 
            ex -> Mono.error(new CustomApiException("User not found", ex)));
}
```

결론적으로, 대부분의 경우 전역 에러 핸들러(어드바이저)를 사용하는 것이 좋은 방법이며, 특수한 경우에만 컨트롤러 레벨의 에러 처리를 추가하는 것이 바람직합니다. 이렇게 하면 코드의 일관성과 유지보수성을 높일 수 있습니다.

--- 

에러 핸들러는 여러 메서드로도 나누어 아래와 같이 구현할 수도 있다. 

```java
@Configuration
public class GlobalErrorHandler implements ErrorWebExceptionHandler {
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        return switch (ex) {
            case BusinessException e -> handleBusinessException(exchange, e);
            case ValidationException e -> handleValidationException(exchange, e);
            case AuthenticationException e -> handleAuthenticationException(exchange, e);
            default -> handleGenericException(exchange, ex);
        };
    }
    
    private Mono<Void> handleBusinessException(ServerWebExchange exchange, BusinessException ex) {
        exchange.getResponse().setStatusCode(HttpStatus.BAD_REQUEST);
        return writeErrorResponse(exchange, createBusinessErrorResponse(ex));
    }
    
    private Mono<Void> handleValidationException(ServerWebExchange exchange, ValidationException ex) {
        exchange.getResponse().setStatusCode(HttpStatus.BAD_REQUEST);
        return writeErrorResponse(exchange, createValidationErrorResponse(ex));
    }
    
    private Mono<Void> handleAuthenticationException(ServerWebExchange exchange, AuthenticationException ex) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return writeErrorResponse(exchange, createAuthErrorResponse(ex));
    }
    
    private Mono<Void> handleGenericException(ServerWebExchange exchange, Throwable ex) {
        exchange.getResponse().setStatusCode(HttpStatus.INTERNAL_SERVER_ERROR);
        return writeErrorResponse(exchange, createGenericErrorResponse(ex));
    }
}
```

하지만 어드바이저와 `@ExceptionHandler` 어노테이션 조합이 가장 좋다.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(ValidationException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthenticationException(AuthenticationException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.UNAUTHORIZED.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return new ResponseEntity<>(error, HttpStatus.UNAUTHORIZED);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(Exception ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "An unexpected error occurred",
            LocalDateTime.now()
        );
        return new ResponseEntity<>(error, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
```

리액티브 방식을 적용하기 위해 Mono 타입으로 래핑하면 에러 처리가 미뤄질 수 있다고 공식 문서에서 이야기 한다. 권장되는 방식은 MVC 처럼 동일한 시그니처를 사용하는 것이다. WebFlux는 return value를 `HandlerAdatper`에 의해 `HandlerResult`로 래핑해서 `HandlerResultHandler`에 처음으로 처리되도록 한다. 
