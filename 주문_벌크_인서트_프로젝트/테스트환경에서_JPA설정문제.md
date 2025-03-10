# 테스트 환경에서 JPA 설정 문제
`@WebMvcTest`는 기본적으로 Controller 레이어만 로드하고, Service나 Repository, JPA 관련 설정은 로드하지 않는다.  
하지만 스프링부트 애플리케이션 클래스에 `@EnableJpaAuditing`을 사용하면 `@WebMvcTest`로 테스트를 설정하더라도 JPA 관련 빈(`JpaMappingContext`, `JpaAuditingHandler` 등)이 필요하기 때문에,  

`Exception encountered during context initialization - cancelling refresh attempt: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'jpaAuditingHandler': Cannot resolve reference to bean 'jpaMappingContext' while setting constructor argument`

와 같은 예외를 야기한다.

`@WebMvcTest`는 Controller 레이어만 로드하니까 애플리케이션 클래스에 영향을 안받고 독립적으로 테스트되지 않을까, 하는 오해를 갖기 쉽지만 그렇지 않다.  
Spring 컨테이너를 요구하는 테스트는 모두 애플리케이션 클래스를 사용하여 컨테이너를 뛰우기 때문이다. 그리고 `@WebMvcTest`는 Spring 컨테이너를 사용하는 테스트이다.

> Spring 컨테이너는 초기화될 때 기본적으로 Application 클래스를 로드한다.

## 해결방법 1: MockBean 추가하기
`@MockBean(JpaMetamodelMappingContext.class)`를 테스트 클래스에 달아주면 문제가 되는 Jpa 빈을 Mock 빈으로 대체할 수 있다.

하지만 이 방법을 사용하면 모든 `@WebMvcTest`마다 추가적인 애노테이션을 달아야 하는 수고스러움과 코드 중복이 발생한다.

## 해결방법 2: `@Configuration` 분리하기
```java
@Configuration
@EnableJpaAuditing
public class JpaAuditingConfiguration {  
}
```
위처럼 설정 클래스를 따로 하위 패키지에 위치시킴으로써 `@WebMvcTest`에서 Auditing에 관련된 빈을 필요로 하지 않도록 만들어주자.

## Reference
- [pudding.log](https://velog.io/@suujeen/Error-creating-bean-with-name-jpaAuditingHandler)