Webflux에서 `Authentication` 객체를 생성하는데 사용되는 `UserDetails`와 `UserDetailsService`는 어떻게 구현해야 할까?

UserDetails의 구현체는 MVC에서와 동일하게 동기식으로 작성하고, UserDetailsSerivce를 구현할 때 `UserDetailsService`가 아닌 `ReactiveUserDetailsService`를 상속해서 `Mono<UserDetails> findByUsername(String username)` 메서드를 reactive 처리해주면 된다.