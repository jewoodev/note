# MockMvc 인증 설정
MockMvc 테스트를 할 때 해당 API에 인증이 필요하면 시큐리티에 사용하고 있는 UserDetails의 구현체를 `mockMvc.perform()`의 결과 객체에 `with(user(userDetails))` 를 사용해서 인증을 모킹할 수 있다.

```java
class ExampleTest {
    void getOrders() throws Exception {
        // ....
        
        mockMvc.perform(get("/order/list")).with(user(userDetails))
                .andExpect(status.isOk())
                .andExpect(view().name("order/list"))
                .andExpect(model().attribute("orderList", List.of(order1, order2)));
    }
}
```

아니면 `@WithMockUser` 애노테이션을 사용해서 테스트에서 인증된 사용자를 적용할 수도 있다.

```java
@WithMockUser(username = "Elen", roles = {"SELLER"})
class ExampleTest { }
```

이렇게 인증된 사용자를 사용할 땐 Spring Security가 `ROLE_` prefix를 요구하는지에 따라서 역할 값으로 `Role.SELLER`가 `"SELLER"`인지 `"ROLE_SELLER"`인지 확인해서 애노테이션의 roles 파라미터에 알맞은 값을 줘야 한다.

---

## `@WebMvcTest`에서 Spring Security는 언제 적용될까? 비활성화할 수는 없나?
`SecurityConfig`같은 보안 설정이 `@Component`와 `@Service` 빈들과는 다르게 `@Configuration`으로 등록되어 있으면 이를 로드하는 것 같다.

하지만 테스트에서 Security 필터를 아예 비활성화하면 인증 없이 접근 가능하도록 만들 수도 있다.

```java
@WebMvcTest(OrderController.class)
@AutoConfigureMockMvc(addFilters = false) // Security 필터 비활성화
class ExampleTest { }
```

## 관련 문서
- [1](https://chatgpt.com/c/67b6d817-af30-8012-bb8d-2bf6c65e0e9b)
