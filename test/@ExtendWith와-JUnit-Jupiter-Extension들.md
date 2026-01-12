# `@ExtendWith`의 의미와 역할
`@ExtendWith`는 JUnit 5(Jupiter)의 핵심 확장 메커니즘이다. JUnit 4의 @RunWith를 대체하는 개념이기도 하다.

```java
@ExtendWith(MyCustomExtension.class)
class MyTest {
    // 테스트 코드
}
```

- **주요 기능**:
  - 테스트 실행 전후에 커스텀 로직을 삽입할 수 있다. 
  - 테스트 인스턴스 생성, 파라미터 주입, 조건부 실행 등을 제어한다. 
  - 여러 Extension을 조합해서 사용할 수 있다. (JUnit 4는 하나의 Runner만 가능했음)

# Spring JUnit Jupiter Extension들
## `@SpringExtension`
가장 핵심이 되는 Extension이다.

```java
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = AppConfig.class)
class MySpringTest {
    @Autowired
    private MyService service;
    
    @Test
    void test() {
        // Spring 컨텍스트가 로딩되어 있고
        // DI가 작동한다.
    }
}
```

- **역할**:
  - Spring ApplicationContext를 테스트에서 사용할 수 있게 한다. 
  - `@Autowired`, `@Value` 등 Spring의 DI 기능을 활성화한다. 
  - 테스트 간 컨텍스트를 캐싱하여 성능을 최적화한다. 
  - 트랜잭션 관리, 테스트 컨텍스트 프레임워크를 통합한다.

## `@SpringJUnitConfig` (복합 애노테이션)

```java
// SpringJUnitConfig는 SpringExtension과 함께 자주 사용되는 메타 애노테이션을 묶은 것
@ExtendWith(SpringExtension.class)
@ContextConfiguration
public @interface SpringJUnitConfig {
}

// 따라서 이렇게 간결하게 쓸 수 있다.
@SpringJUnitConfig(classes = AppConfig.class)
class MyTest {
    // SpringExtension + ContextConfiguration 효과
}
```

## `@SpringJUnitWebConfig` (웹 환경용)

```java
@SpringJUnitWebConfig(classes = WebConfig.class)
class WebTest {
    @Autowired
    private WebApplicationContext wac;
    
    // 웹 환경에서 테스트
}
```

- **특징**:
  - `@ExtendWith(SpringExtension.class)` + `@ContextConfiguration` + `@WebAppConfiguration`을 합친 것
  - `WebApplicationContext`를 로딩한다.

# 실제 사용 예시
## 기본 Spring 테스트

```java
@SpringJUnitConfig
@TestPropertySource(properties = {
    "spring.datasource.url=jdbc:h2:mem:test"
})
class ServiceTest {
    @Autowired
    private UserService userService;
    
    @Test
    void createUser() {
        User user = userService.create("test");
        assertNotNull(user.getId());
    }
}
```

## Spring Boot 테스트 (자동으로 Extension 포함)

```java
@SpringBootTest  // 내부적으로 @ExtendWith(SpringExtension.class) 포함
class ApplicationTest {
    @Autowired
    private UserRepository userRepository;
    
    @Test
    void contextLoads() {
        assertNotNull(userRepository);
    }
}
```

## 여러 Extension 조합

```java
@ExtendWith({
    SpringExtension.class,      // Spring 컨텍스트
    MockitoExtension.class      // Mockito 지원
})
@ContextConfiguration(classes = AppConfig.class)
class CombinedTest {
    @Autowired
    private UserService userService;
    
    @Mock  // Mockito의 기능
    private UserRepository mockRepo;
    
    @Test
    void test() {
        // Spring DI와 Mockito를 함께 사용
    }
}
```

# Extension이 하는 일 (내부 동작)

```java
public class SpringExtension implements 
    BeforeAllCallback,           // 전체 테스트 시작 전
    AfterAllCallback,            // 전체 테스트 종료 후
    BeforeEachCallback,          // 각 테스트 시작 전
    AfterEachCallback,           // 각 테스트 종료 후
    BeforeTestExecutionCallback, // 테스트 메서드 실행 직전
    AfterTestExecutionCallback,  // 테스트 메서드 실행 직후
    ParameterResolver {          // 파라미터 주입
    
    @Override
    public void beforeAll(ExtensionContext context) {
        // ApplicationContext 준비
    }
    
    @Override
    public void beforeEach(ExtensionContext context) {
        // 테스트 인스턴스에 DI 수행
    }
    
    @Override
    public boolean supportsParameter(ParameterContext paramContext, 
                                     ExtensionContext extensionContext) {
        // ApplicationContext 파라미터 주입 지원
        return ApplicationContext.class.isAssignableFrom(
            paramContext.getParameter().getType()
        );
    }
}
```

# 주요 차이점: JUnit4 vs JUnit5
## JUnit4

```java
@RunWith(SpringRunner.class)  // 하나의 Runner만 가능
@ContextConfiguration
public class MyTest {
}
```

## JUnit5

```java
@ExtendWith({
    SpringExtension.class,
    MockitoExtension.class,
    CustomExtension.class  // 여러 Extension 조합 가능
})
@ContextConfiguration
public class MyTest {
}
```

# 정리
- `@ExtendWith`: JUnit 5의 확장 메커니즘, 테스트 라이프사이클에 커스텀 로직 추가
- `SpringExtension`: Spring의 DI, 트랜잭션, 컨텍스트 관리를 테스트에서 사용 가능하게 함
- 복합 애노테이션들 (`@SpringJUnitConfig` 등): 자주 쓰는 조합을 간편하게 제공
- Spring Boot의 `@SpringBootTest`, `@WebMvcTest` 등은 내부적으로 이미 `SpringExtension`을 포함하고 있어서 별도로 `@ExtendWith`를 붙일 필요 없음

실무에서는 대부분 Spring Boot의 테스트 애노테이션들을 사용하게 되므로, `@ExtendWith(SpringExtension.class)`를 직접 쓸 일은 많지 않다. 하지만 Spring Boot 없이 순수 Spring을 쓰거나, 커스텀한 테스트 설정이 필요할 때는 직접 사용하게 된다.