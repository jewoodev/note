http 연결에 대한 session을 stateless하게 처리하고 싶다면 다음의 작업이 필요하다.

## 1. `SecurityWebFilterChain` 에서 securityContextRepository 설정

```java
http
    .securityContextRepository(NoOpServerSecurityContextRepository.getInstance())
```

`NoOpServerSecurityContextRepository`는 `ServerSecurityContextRepository`의 do nothing 하는 구현체이다. stateless application에 사용된다.

이 구현체의 주요 특징은 다음과 같다.

1. 상태 저장 방식
    - 요청마다 새로운 SecurityContext를 생성
    - 이전 요청의 SecurityContext를 유지하지 않음
    - 각 요청이 독립적으로 처리됨
2. 사용 사례
    - 상태를 저장할 필요가 없는 경우 (예: JWT 인증)
    - 각 요청이 독립적인 인증 정보를 가져야 하는 경우
    - 서버 측 세션을 사용하지 않는 경우
3. 장점
    - 메모리 사용량 최소화
    - 서버 확장성 향상 (상태 공유 불필요)
    - 각 요청의 독립성 보장

## 2. 상태 관리를 위한 session에 대한 것도 stateless하게

1번 작업에서 인증 세션은 stateless하게 설정되었지만, 그 외의 session이 사용되고 있을 수 있다. 개발자가 필요하다 판단하여 사용하는 것이라면 문제될 것이 없지만, 그러한 session은 어떻게 stateless하게 만들 수 있는지 살펴보자.

1. 프로젝트에 `@EnableRedisWebSession`이 사용되고 있는지 살펴보자. 있다면 제거해야 한다. 이 어노테이션이 사용되면 기본적으로 Redis에 세션을 저장한다.
2. build.gradle에 'org.springframework.session:spring-session-data-redis' 의존성이 사용되고 있는지도 확인하자.

session이 저장되도록 하는 다른 케이스들이 더 있을 것이다. 발견하게 되면 추가하겠다.