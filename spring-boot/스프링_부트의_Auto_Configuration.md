# 스프링 부트의 Auto Configuration

Configuration 클래스에서 빈들을 등록해주지 않고 마치 그 빈들이 등록된 것들인 것처럼 테스트해보면 문제없이 작동할 때가 있다.  
그런 빈들은 스프링이 알아서 빈으로 등록해주는 것들에 포함되기 때문에 그렇게 작동할 수가 있는 것이다.  
이런 기능을 스프링의 Auto Configuration 이라고 한다.  

> 물론 자주 사용되는 빈들을 이런 기능으로 자동 등록해주는 것이지 개발자의 머리 속을 감지해서 빈들을 생성해주는 원리는 아니다.

스프링 docs에서 스프링 부트의 Auto Configuration 기능을 제공하는 빈들을 문서화해두었기 때문에 검색해서 찾아볼 수 있다.  



## 1. @Conditional을 이용하여 Auto Configuration 제어하기

### 1.1 `Condition` 인터페이스와 `@Conditional` 어노테이션을 사용하는 방법
Auto Configuration으로 등록되는 빈들을 포함해서 일련의 빈 관리를 할 때 세심하게 할 수 있다. 특정 조건을 만족할 때 등록되도록 하는 것이 가능하기 때문인데, 그 방법 중 하나를 살펴보자.

먼저 `org.springframework.context.annotation.Condition` 인터페이스의 `boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata);`를 구현해야 한다.

```java
public class ConditionExample implements Condition {
    @Overrride
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        String example = context.getEnvironment().getProperty("example");
        return "on".equals(example);
    }
}
```

위의 코드는 구현 예제로써 `context.getEnvironment().getProperty()` java 프로세스를 실행시킬 때 `-D`를 붙여 지정할 수 있는 java 시스템 속성의 값을 불러온다. 만약 `-Dexample=on`으로 지정된 프로세스면은 `matches()`가 `true`를 반환한다. 이 `matches()` 의 반환값을 이용해 `true`이면 빈으로 등록하고, `false`이면 등록되지 않게 설정할 수 있다.

```java
@Configuration
@Conditional(ConditionExample.class)
public class ConfigExample {
    @Bean
    public ExampleBean1 exampleBean1() {
        return new ExampleBean1();
    }
    
    // ExampleBean2, ...
}
```

위와 같이 `@Conditional` 어노테이션에 Condition 구현체를 넣어주면 해당 구현체의 matches의 결과에 따라 해당 Configuration이 적용 여부가 정해진다.

> Spring은 외부 설정을 추상화해서 `Environment` 로 통합했다. 따라서 `Environment` 를 이용해 다양한 외부 설정 정보를 읽어들일 수 있다.


### 1.2 스프링이 제공하는 `@Conditional` 의 확장, `@ConditionalOnProperty`
위의 작업을 하는 대신 @ConditionalOnProperty(name="example", havingValue="xxx") 애노테이션을 사용해 xxx 대신 Environment에 할당된 `example` 값이 무엇일 때만 작동되게 할 것인지 설정할 수 있다.

이를 이용해 1.1절에서의 작업과 동일한 작업이 수행되는 코드를 작성해보면 다음과 같다.
```java
// Condition 구현체는 작성할 필요 x
@Configuration
@ConditionalOnProperty(name="example", havingValue="on")
public class ConfigExample {
    // ...
}
```


### 1.3 스프링이 제공하는 `@ConditionalOnXxx` 
1.2절에서 살펴본 `@ConditionalOnProperty` 외에도 수 많은 `@ConditionalOnXxx` 를 스프링은 제공한다. 이 [링크](https://docs.spring.io/spring-boot/reference/features/developing-auto-configuration.html#features.developing-auto-configuration.condition-annotations.class-conditions)를 참고하자.

> _참고_
> 
> `@Conditional` 는 스프링 부트가 아니라 스프링 프레임워크의 기능이고 스프링 부트가 이를 확장해 `@ConditionalOnXxx` 를 제공한다.


 
## 2. Auto Configuration 기능을 제공하는 라이브러리를 만들어 활용하기

우리도 Auto Configuration 기능을 제공하는 라이브러리를 만들어 활용할 수 있다. 아래와 같은 순서로 작업하면 된다.

1. `@AutoConfiguration`, `@ConditionalOnProperty` 애노테이션으로 설정 클래스를 만들어 Auto Configuration의 작동 조건을 설정.
2. resources 디렉토리 하위에 `META_INF` 디렉토리를 생성해 `org.springframework.boot.autoconfigure.AutoConfiguration.imports` 라는 이름의 파일을 만든다. 
3. 거기에 Auto Configuration 클래스의 패키지 경로를 넣어 jar 파일로 빌드하면 Auto Configuration 기능을 제공하는 라이브러리를 만들 수 있다.



# 참고 자료
- [김영한님의 스프링 부트- 핵심 원리와 활용](https://www.inflearn.com/course/%EC%8A%A4%ED%94%84%EB%A7%81%EB%B6%80%ED%8A%B8-%ED%95%B5%EC%8B%AC%EC%9B%90%EB%A6%AC-%ED%99%9C%EC%9A%A9/dashboard)