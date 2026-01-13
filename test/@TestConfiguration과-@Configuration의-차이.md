# `@TestConfiguration` vs `@Configuration`
Spring에서 두 어노테이션의 핵심 차이는 **적용 범위**(scope)에 있다.

## `@Configuration`
- **프로덕션 코드**에서 사용하는 일반적인 설정 클래스 
- 애플리케이션 전체에서 사용되는 빈(Bean)들을 정의 
- 애플리케이션이 시작될 때 자동으로 스캔되고 로드됨 
- `src/main/java` 경로에 위치

## `@TestConfiguration`
- **테스트 코드**에서만 사용하는 설정 클래스 
- 테스트에 필요한 특정한 빈들을 정의하거나 프로덕션 빈을 오버라이드 
- **명시적으로 Import하지 않으면 자동으로 스캔되지 않음** 
- `src/test/java` 경로에 위치


## 주요 차이점
### 자동 스캔 여부

```java
// @TestConfiguration은 명시적으로 import 필요
@SpringBootTest
@Import(TestConfig.class)  // 이렇게 명시해야 함
class UserServiceTest {
    // ...
}
```

### 사용 목적

- @Configuration: 실제 운영 환경의 빈 설정 
- @TestConfiguration: 테스트 환경에서만 필요한 빈 설정 (Mock, Stub 등)

### 빈 오버라이딩

`@TestConfiguration`을 사용하면 프로덕션의 빈을 테스트용으로 교체할 수 있다:

```java
// 프로덕션 설정
@Configuration
public class AppConfig {
    @Bean
    public PaymentService paymentService() {
        return new RealPaymentService(); // 실제 결제
    }
}

// 테스트 설정
@TestConfiguration
public class TestConfig {
    @Bean
    public PaymentService paymentService() {
        return new MockPaymentService(); // Mock 결제
    }
}
```

