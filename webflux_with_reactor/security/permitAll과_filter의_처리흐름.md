`SecurityWebFilterChain` 빈에 `permitAll()` 설정된 path로의 요청은 지정된 인증 필터를 거치지 않고 넘어갈까?

그렇지 않다. `permitAll()`은 인증(authentication)을 요구하지 않는다는 의미이지, 필터 체인을 건너뛴다는 의미가 아니다.

Spring Security의 필터 체인은 다음과 같은 순서로 동작한다.

1. 먼저 모든 요청이 필터 체인을 통과한다.
2. 각 필터에서 요청을 처리하고 다음 필터로 전달한다.
3. `permitAll()`로 설정된 경로는 인증 여부에 관계없이 접근을 허용한다.

여기에서 인증을 요구하지 않고 통과시킨다는 것은, 인증이 정상적으로 처리되었을 때 `SecurityContextHolder`에 저장되는 `Authentication` 객체를 요구하지 않는다는 뜻이다.

하지만 `permitAll()`로 설정된 경로라도 필터 체인을 거치지 않는 게 아니므로, 클라이언트 요청에 인증 정보(ex. JWT 토큰)이 전달되면 동일하게 필터의 로직을 거쳐 `SecurityContextHolder`에 인증 정보가 저장된다.

`SecurityContextHolder`에 저장된 인증 정보는 Spring Security의 인가(authorization) 처리 과정에서 사용되므로, 유효해야 한다.