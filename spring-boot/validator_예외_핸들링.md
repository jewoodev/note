## WebFlux에서 validator 예외 핸들링

Spring WebFlux에서는 유효성 검증 실패 시 `WebExchangeBindException` 예외가 발생한다. WebFlux는 기본적으로 이 예외를 400 Bad Request로 매핑해주는 ExceptionHandler가 내장되어 있다(확인 x). 

그런데 만약 `@RestControllerAdvice`에서 `Exception`이나 `Throwable`을 catch해서 500으로 매핑하는 코드가 있다면, 유효성 검증 예외도 500으로 바뀔 수 있다. 그래서 `WebExchangeBindException`에 대한 예외 처리를 별도로 구성한 `@RestControllerAdvice`에서 처리하는 코드를 추가해줘야 한다.

필자는 그런 현상을 경험했는데 MVC에서는 `@ControllerAdvice`가 `ResponseEntityExceptionHandler`를 상속하면 기본적으로 400 매핑이 잘 작동하는데, WebFlux에서는 `ResponseEntityExceptionHandler`가 적용되지 않아 나타난 것 같기도 하다.

## WebTestClient에서 validator 예외 핸들링

이 친구는 `main/java` 패키지 아래의 애플리케이션 구조와는 분리되어 테스트 용도의 컨텍스트를 구성하는데 그 환경 안에서는 400 매핑이 문제 없이 진행되는 것이 확인됐다. 