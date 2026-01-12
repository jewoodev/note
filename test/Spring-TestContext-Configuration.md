# Spring TestContext Configuration
Spring의 TestContext Framework는 Spring 자체에서 제공하는 테스트 지원 인프라이다. JUnit이나 TestNG 같은 테스트 프레임워크와 독립적으로 설계되었다.

## 핵심 개념
### TestContext Framework의 주요 구성 요소들

```
TestContextManager
    ↓
TestContext (테스트 실행 상태 관리)
    ↓
SmartContextLoader (ApplicationContext 로딩)
    ↓
TestExecutionListener들 (테스트 라이프사이클 이벤트 처리)
```

### TestContext
현재 실행 중인 테스트의 컨텍스트 정보를 담는 계약이다. 스프링은 이 계약의 구현체인 `DefaultTestContext`를 제공한다.

```java
public interface TestContext {
    ApplicationContext getApplicationContext();
    Class<?> getTestClass();
    Object getTestInstance();
    Method getTestMethod();
    Throwable getTestException();
    // ...
}
```

### TestContextManager
테스트 실행을 관리하는 핵심 클래스이다.

```java
public class TestContextManager {
    private final TestContext testContext;
    private final List<TestExecutionListener> testExecutionListeners;
    
    public void beforeTestClass() throws Exception {
        // 테스트 클래스 실행 전
        for (TestExecutionListener listener : testExecutionListeners) {
            listener.beforeTestClass(testContext);
        }
    }
    
    public void prepareTestInstance(Object testInstance) throws Exception {
        // 테스트 인스턴스 준비 (DI 수행)
        for (TestExecutionListener listener : testExecutionListeners) {
            listener.prepareTestInstance(testContext);
        }
    }
    
    public void beforeTestMethod(Method testMethod) throws Exception {
        // 각 테스트 메서드 실행 전
        for (TestExecutionListener listener : testExecutionListeners) {
            listener.beforeTestMethod(testContext);
        }
    }
    
    // afterTestMethod, afterTestClass 등...
}
```

### TestExecutionListener
테스트 라이프사이클의 각 단계에서 실행되는 리스너들이다.

```java
public interface TestExecutionListener {
    void beforeTestClass(TestContext testContext) throws Exception;
    void prepareTestInstance(TestContext testContext) throws Exception;
    void beforeTestMethod(TestContext testContext) throws Exception;
    void beforeTestExecution(TestContext testContext) throws Exception;
    void afterTestExecution(TestContext testContext) throws Exception;
    void afterTestMethod(TestContext testContext) throws Exception;
    void afterTestClass(TestContext testContext) throws Exception;
}
```

## 주요 TestExecutionListener들
Spring이 기본으로 제공하는 리스너들을 살펴보자

### ServletTestExecutionListener
웹 환경 설정을 담당한다.

```java
@WebAppConfiguration
@ContextConfiguration
class WebTest {
    @Autowired
    private WebApplicationContext wac;
    
    // ServletTestExecutionListener가
    // WebApplicationContext를 준비해줌
}
```

### DependencyInjectionTestExecutionListener
가장 중요한 리스너이다. 테스트 인스턴스에 DI를 수행한다.

```java
class MyTest {
    @Autowired  // 이 주입을 담당
    private UserService userService;
    
    @Value("${app.name}")  // 이것도 담당
    private String appName;
}
```

**내부 동작**:

```java
public class DependencyInjectionTestExecutionListener 
    extends AbstractTestExecutionListener {
    
    @Override
    public void prepareTestInstance(TestContext testContext) {
        // ApplicationContext를 가져와서
        ApplicationContext context = testContext.getApplicationContext();
        
        // 테스트 인스턴스에 DI 수행
        AutowireCapableBeanFactory beanFactory = 
            context.getAutowireCapableBeanFactory();
        beanFactory.autowireBean(testContext.getTestInstance());
    }
}
```

### TransactionalTestExecutionListener
테스트에서 트랜잭션을 관리한다.

```java
@Transactional  // 이 애노테이션 처리
class UserRepositoryTest {
    
    @Autowired
    private UserRepository userRepository;
    
    @Test
    void saveUser() {
        userRepository.save(new User("test"));
        // 테스트 종료 후 자동 롤백
    }
    
    @Test
    @Commit  // 명시적으로 커밋할 수도 있음
    void saveUserAndCommit() {
        userRepository.save(new User("test"));
    }
}
```

**내부 동작**:

```java
public class TransactionalTestExecutionListener 
    extends AbstractTestExecutionListener {
    
    @Override
    public void beforeTestMethod(TestContext testContext) {
        // @Transactional이 있으면 트랜잭션 시작
        if (testContext.getTestMethod()
                .isAnnotationPresent(Transactional.class)) {
            TransactionContext txContext = 
                startTransaction(testContext);
            // 트랜잭션 컨텍스트 저장
        }
    }
    
    @Override
    public void afterTestMethod(TestContext testContext) {
        // 기본적으로 롤백 (테스트 격리)
        // @Commit이 있으면 커밋
        if (shouldCommit(testContext)) {
            commit(testContext);
        } else {
            rollback(testContext);
        }
    }
}
```

### DirtiesContextTestExecutionListener
컨텍스트 캐시 관리를 담당한다.

```java
class MyTest {
    
    @Test
    @DirtiesContext  // 이 테스트 후 컨텍스트 재생성
    void modifyApplicationContext() {
        // 컨텍스트를 변경하는 테스트
    }
}
```

### SqlScriptsTestExecutionListener
SQL 스크립트 실행을 처리한다.

```java
@Sql("/test-data.sql")  // 이것을 실행
class DataTest {
    
    @Test
    @Sql(scripts = "/cleanup.sql", 
         executionPhase = AFTER_TEST_METHOD)
    void testWithData() {
        // 테스트
    }
}
```

## SpringExtension과의 통합
SpringExtension은 JUnit 5와 TestContext Framework를 연결하는 다리 역할을 합니다.

```java
public class SpringExtension implements 
    BeforeAllCallback,
    AfterAllCallback,
    BeforeEachCallback,
    AfterEachCallback,
    // ... 
    {
    
    @Override
    public void beforeAll(ExtensionContext context) {
        // JUnit 5의 beforeAll 콜백
        getTestContextManager(context)
            .beforeTestClass();  // TestContext Framework 호출
    }
    
    @Override
    public void beforeEach(ExtensionContext context) {
        // JUnit 5의 beforeEach 콜백
        Object testInstance = context.getRequiredTestInstance();
        TestContextManager tcm = getTestContextManager(context);
        
        tcm.prepareTestInstance(testInstance);  // DI 수행
        tcm.beforeTestMethod(testInstance, 
                             context.getRequiredTestMethod());
    }
    
    private TestContextManager getTestContextManager(
            ExtensionContext context) {
        // TestContextManager를 JUnit 5 Store에 캐싱
        return context.getStore(NAMESPACE)
            .getOrComputeIfAbsent(
                TestContextManager.class,
                key -> new TestContextManager(
                    context.getRequiredTestClass()
                )
            );
    }
}
```

## 실제 동작 흐름
```java
@SpringJUnitConfig(AppConfig.class)
@Transactional
class UserServiceTest {
    
    @Autowired
    private UserService userService;
    
    @Test
    void createUser() {
        userService.create("test");
    }
}
```

### 1. JUnit 5 시작

```
   @ExtendWith(SpringExtension.class) 감지
```

### 2. `SpringExtension.beforeAll()`

```
   TestContextManager.beforeTestClass()
       → ServletTestExecutionListener.beforeTestClass()
       → DirtiesContextTestExecutionListener.beforeTestClass()
       → ...
```

### 3. ApplicationContext 로딩

```
   AnnotationConfigContextLoader가 AppConfig.class 로딩
   → ApplicationContext 생성
   → Bean들 등록
```

### 4. `SpringExtension.beforeEach()`

```
   TestContextManager.prepareTestInstance()
       → DependencyInjectionTestExecutionListener.prepareTestInstance()
           → @Autowired 필드에 주입 (userService)
   
   TestContextManager.beforeTestMethod()
       → TransactionalTestExecutionListener.beforeTestMethod()
           → 트랜잭션 시작
```

### 5. 테스트 실행

```
   createUser() 메서드 실행
```

### 6. `SpringExtension.afterEach()`

```
   TestContextManager.afterTestMethod()
       → TransactionalTestExecutionListener.afterTestMethod()
           → 트랜잭션 롤백 (기본)
```

## 커스텀 TestExecutionListener 만들기

```java
public class CustomTestListener extends AbstractTestExecutionListener {
    
    @Override
    public void beforeTestMethod(TestContext testContext) {
        System.out.println("테스트 시작: " + 
            testContext.getTestMethod().getName());
        
        // 테스트별 데이터 준비 등
    }
    
    @Override
    public void afterTestMethod(TestContext testContext) {
        System.out.println("테스트 종료: " + 
            testContext.getTestMethod().getName());
        
        // 정리 작업 등
    }
}

// 사용
@TestExecutionListeners({
    CustomTestListener.class,
    DependencyInjectionTestExecutionListener.class,
    TransactionalTestExecutionListener.class
})
class MyTest {
    // ...
}
```

# 정리
- TestContext Framework는:
  - Spring의 테스트 지원 인프라 
  - JUnit/TestNG와 독립적으로 설계됨 
  - TestContextManager가 중심이 되어 여러 TestExecutionListener들을 관리 
  - DI, 트랜잭션, SQL 스크립트 실행 등을 처리

실무에서는 이런 내부 구조를 직접 다룰 일은 적지만, 테스트가 어떻게 동작하는지 이해하면 문제 해결이나 커스터마이징할 때 큰 도움이 된다.