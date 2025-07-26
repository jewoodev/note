`contextWrite`는 Reactor의 컨텍스트를 수정하는 연산자이다. Spring WebFlux에서 시큐리티 컨텍스트를 설정할 때 동작 방식은 다음과 같다.

1. **불변성(Immutablility) 보장**
    - Reactor의 컨텍스트는 불변(immutable)이다.
    - 따라서 기존 컨텍스트를 수정하는 것이 아니라, 새로운 컨텍스트를 생성한다.
2. **객체 복사 과정**
    ```java
    .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication))
    ```

    - 이 코드가 실행될 때, Spring Security는 내부적으로
        1. 새로운 `SecurityContext` 객체를 생성
        2. 새로운 `Authentication` 객체를 생성
        3. `UserDetails` 객체로 새로운 인스턴스로 복사
3. **스레드 안전성 보장**
    - 이렇게 새로운 객체를 생성하는 이유는 스레드 안전성(thread-safety)을 보장하기 위함이다.
    - Webflux는 비동기/논블로킹 환경에서 동작하므로, 여러 스레드에서 동시에 컨텍스트에 접근할 수 있다.
    - 불변 객체를 사용함으로써 동시성 문제를 방지한다.

