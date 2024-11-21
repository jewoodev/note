# 스프링 부트의 Auto Configuration

Configuration 클래스에서 빈들을 등록해주지 않고 마치 그 빈들이 등록된 것들인 것처럼 테스트해보면 문제없이 작동할 때가 있다.  
그런 빈들은 스프링이 알아서 빈으로 등록해주는 것들에 포함되기 때문에 그렇게 작동할 수가 있는 것이다.  
이런 기능을 스프링의 Auto Configuration 이라고 한다.  

> 물론 자주 사용되는 빈들을 이런 기능으로 자동 등록해주는 것이지 개발자의 머리 속을 감지해서 빈들을 생성해주는 원리는 아니다.

스프링 docs에서 스프링 부트의 Auto Configuration 기능을 제공하는 빈들을 문서화해두었기 때문에 검색해서 찾아볼 수 있다.  

## 1. @Conditional을 이용하여 Auto Configuration 제어하기

`org.springframework.context.annotation.Condition` 인터페이스의 `boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata);`를 구현해 컴포넌트를 작동시킬지 말지를 제어할 수 있다.

### 1.1 스프링이 제공하는 Conditional 기능, ConditionalOnProperty

위의 작업을 하는 대신 @ConditionalOnProperty(name="memory", havingValue="xxx") 애노테이션을 사용해 xxx 대신 Environment에 할당된 memory 값이 무엇일 때만 작동되게 할 것인지 설정할 수 있다. 

> Environment는 VM Options을 포함한 외부 설정을 통합한 것이다.

## 2. Auto Configuration 기능을 제공하는 라이브러리를 만들어 활용하기

우리도 Auto Configuration 기능을 제공하는 라이브러리를 만들어 활용할 수 있다. 아래와 같은 순서로 작업하면 된다.

1. `@AutoConfiguration`, `@ConditionalOnProperty` 애노테이션으로 설정 클래스를 만들어 Auto Configuration의 작동 조건을 설정.
2. resources 디렉토리 하위에 `META_INF` 디렉토리를 생성해 `org.springframework.boot.autoconfigure.AutoConfiguration.imports` 라는 이름의 파일을 만든다. 
3. 거기에 Auto Configuration 클래스의 패키지 경로를 넣어 jar 파일로 빌드하면 Auto Configuration 기능을 제공하는 라이브러리를 만들 수 있다.

# 참고 자료
- [김영한님의 스프링 부트- 핵심 원리와 활용](https://www.inflearn.com/course/%EC%8A%A4%ED%94%84%EB%A7%81%EB%B6%80%ED%8A%B8-%ED%95%B5%EC%8B%AC%EC%9B%90%EB%A6%AC-%ED%99%9C%EC%9A%A9/dashboard)