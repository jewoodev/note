# `@Mock`과 `@MockBean`의 차이
둘 다 Mockito를 활용해서 Mock 객체를 만들 때 사용하지만, 동작하는 범위와 사용 목적이 다르다.

## 1️⃣ @Mock (Mockito 제공)
- 단순한 Mock 객체를 생성할 때 사용. 
- Spring 컨텍스트와 무관하게 작동. 
- 주입(Inject)되지 않으며, 사용자가 직접 설정해야 함.

### ✅ 예제 (@Mock 사용)
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository; // Mock 객체

    @InjectMocks
    private OrderService orderService; // orderRepository가 자동 주입됨

    @Test
    void testCreateOrder() {
        when(orderRepository.save(any())).thenReturn(new Order());

        Order order = orderService.createOrder(new OrderRequest());

        assertNotNull(order);
    }
}
```
### 🔹 @Mock 특징
✔ MockitoExtension을 활성화하면 @Mock이 적용된 객체를 자동으로 Mocking
✔ 스프링 컨테이너와 관련 없음 (즉, @Autowired 등으로 주입되지 않음)
✔ @InjectMocks와 함께 사용하면 Mock 객체를 특정 클래스에 주입 가능

## 2️⃣ @MockBean (Spring Boot 제공)
- Spring 컨테이너에 등록된 Bean을 Mock 객체로 교체할 때 사용. 
- 통합 테스트(Spring Context가 필요한 테스트)에서 사용. 
- `@Autowired`를 사용해 주입받는 Bean을 Mock으로 대체 가능.

### ✅ 예제 (@MockBean 사용)
```java
@SpringBootTest
class OrderServiceTest {

    @MockBean
    private OrderRepository orderRepository; // 실제 Bean 대신 MockBean이 등록됨

    @Autowired
    private OrderService orderService; // OrderRepository를 MockBean으로 대체

    @Test
    void testCreateOrder() {
        when(orderRepository.save(any())).thenReturn(new Order());

        Order order = orderService.createOrder(new OrderRequest());

        assertNotNull(order);
    }
}
```
### 🔹 @MockBean 특징
✔ 스프링 컨테이너의 실제 Bean을 Mock 객체로 교체
✔ @Autowired로 주입되는 Bean을 Mock으로 대체 가능
✔ Spring Boot 통합 테스트(@SpringBootTest 등)에서 사용

## ✅ 언제 어떤 걸 써야 할까?

| 상황                                          | 추천 방법 |
|---------------------------------------------|-------|
| Spring 컨텍스트가 필요 없음 (`OrderService`만 단위 테스트) |  `@Mock` + `@InjectMocks`     |
| Spring 컨텍스트에서 특정 Bean을 Mock으로 교체해야 함        |  `@MockBean`     |
|  Spring의 실제 빈과 함께 Mock을 조합해서 테스트해야 함                                           |  `@MockBean`     |
