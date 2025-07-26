스프링이 제공하는 AuthenticationManager들은 JWT 토큰 기반 인증에서 적합하지 않다.

보편적인 매니저 중 하나인 `UserDetailsRepositoryReactiveAuthenticationManager`는 주로 폼 로그인(form login)이나 기본 인증(basic authentication) 같은 전통적인 인증 방식에서 사용된다.

이 매니저의 주요 동작은 다음과 같다.

1. `Authentication` 객체에서 credentials(보통 비밀번호)와 username을 추출
2. `ReactiveUserDetailsService`를 통해 사용자 정보를 조회
3. `PasswordEncoder`를 사용하여 credentials를 검증
4. 검증이 성공하면 `Authentication` 객체를 생성하여 반환

하지만 JWT 토큰 기반 인증에서는 이러한 동작이 적합하지 않다. 그 이유는 다음과 같다.

1. JWT 토큰은 자체적으로 서명되어 있어 별도의 credentials 검증이 필요 없음
2. 토큰에서 직접 사용자 정보를 추출할 수 있음
3. 비밀번호 검증이 아닌 토큰 검증이 필요함

따라서 커스텀 매니저나 그에 해당하는 로직을 구현하는 것이 더 적합하다.

그리고 Spring Security 설정에서 `SecurityWebFilterChain` 타입의 빈에 설정하는 `.authenticationManager(authenticationManager())`로 지정하는 것은

1. 주로 폼 로그인이나 HTTP Basic 인증과 같은 기본 인증 방식에서 사용됨
2. Spring Security의 기본 인증 필터들이 이 매니저를 사용

따라서 `.authenticationManager(authenticationManager())`로 매니저를 지정하더라도 Spring Security가 자동으로 필터에 인증 매니저를 연결해주지 않기 때문에 아무런 인증 로직이 작동하지 않게 된다.