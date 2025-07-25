# `@SpringBootTest`에서 모킹하기
```java
class OrderServiceTest extends SecurityDisabledTestSupport {
    @Autowired
    private OrderService orderService;

    @Mock
    private CustomUserDetails userDetails;

    @Mock
    private UserRepository userRepository;

    @DisplayName("대량 주문 업로드 기능 사용 시 데이터가 잘못되어 있으면 어디가 잘못됐는지 알려준다.")
    @Test
    void filterIncorrectExcelData() throws IOException {
        // given // when
        MockMultipartFile incorrectExcelFile = createIncorrectExcelFile();
        User user = new User(1L);
        CustomUserDetails userDetails = new CustomUserDetails(user);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // then
        StringBuffer sb = new StringBuffer();
        sb.append("0행의 0열의 값이 문자열이 아닙니다.");
        assertThat(orderService.validOrders(incorrectExcelFile, userDetails)).hasSize(4)
                .isEqualTo(sb);
    }
}
```
`@SpringBootTest`에서 `@Mock`을 사용한 객체 모킹이 기본적으로 적용되지 않는다.  
이유는 `@SpringBootTest`가 전체 애플리케이션 컨텍스트를 로드하는 통합 테스트 방식으로 작동하는데, 
Mockito의 `@Mock`은 자동으로 빈으로 등록되지 않기 때문이다.

## 해결 방법 1: @MockBean 사용하기
`@Mock`을 사용한 필드에 `@MockBean`을 사용하면 해결된다.

- `@MockBean`을 사용하면 해당 객체가 `Spring ApplicationContext`의 빈으로 등록되어 `@Autowired`된 객체에서 사용할 수 있다.
- `@Mock`은 Mockito 컨텍스트에서만 동작하며 Spring의 빈으로 등록되지 않기 때문에 `@SpringBootTest` 환경에서는 `@MockBean`을 사용해야 한다.

## 해결 방법 2: @ExtendWith(MockitoExtension.class)와 @InjectMocks 사용하기
만약 @SpringBootTest가 아니라 순수한 단위 테스트를 수행하고 싶다면, @ExtendWith(MockitoExtension.class)를 사용해서 해결할 수 있다.

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest extends SecurityDisabledTestSupport {
    @InjectMocks
    private OrderService orderService;

    @Mock
    private CustomUserDetails userDetails;

    @Mock
    private UserRepository userRepository;

    @Test
    void filterIncorrectExcelData() throws IOException {
        // given
        MockMultipartFile incorrectExcelFile = createIncorrectExcelFile();
        User user = new User(1L);
        CustomUserDetails userDetails = new CustomUserDetails(user);

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // then
        StringBuffer sb = new StringBuffer();
        sb.append("0행의 0열의 값이 문자열이 아닙니다.");
        assertThat(orderService.validOrders(incorrectExcelFile, userDetails)).hasSize(4)
                .isEqualTo(sb);
    }
}
```

- `@ExtendWith(MockitoExtension.class)`를 사용하면 Mockito 기반 단위 테스트가 가능하며 `@SpringBootTest` 없이 빠른 테스트가 가능하다.
- `@InjectMocks`를 사용하면 `@Mock`으로 모킹된 객체들이 `orderService`에 주입된다.
  다만, OrderService 내부에서 @Autowired로 주입받는 빈이 많다면 해당 빈들도 @Mock으로 명시해야 한다.

## 해결 방법 3: @ContextConfiguration을 활용한 Bean 주입
만약 `@SpringBootTest`는 유지하면서도 일부 Mock 객체를 적용하고 싶다면, `@ContextConfiguration`을 사용하여 특정 빈만 설정할 수도 있다.

```java
@SpringBootTest
@ContextConfiguration(classes = {OrderService.class})
class OrderServiceTest extends SecurityDisabledTestSupport {
    @Autowired
    private OrderService orderService;

    @MockBean
    private UserRepository userRepository;

    @Test
    void filterIncorrectExcelData() throws IOException {
        // given
        MockMultipartFile incorrectExcelFile = createIncorrectExcelFile();
        User user = new User(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // then
        StringBuffer sb = new StringBuffer();
        sb.append("0행의 0열의 값이 문자열이 아닙니다.");
        assertThat(orderService.validOrders(incorrectExcelFile, new CustomUserDetails(user))).hasSize(4)
                .isEqualTo(sb);
    }
}
```

- `@ContextConfiguration(classes = {OrderService.class})`을 사용하면 `OrderService`만 빈으로 등록하고 나머지 빈을 수동으로 `@MockBean`으로 모킹할 수 있다.
- 불필요한 컨텍스트 로딩을 줄여 테스트 속도를 높이는 효과가 있다.
