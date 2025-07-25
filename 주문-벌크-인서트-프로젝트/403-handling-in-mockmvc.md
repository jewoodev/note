# 403 에러 원인 (MockMVC)

- `403 Forbidden` 에러는 일반적으로 다음 중 하나 때문에 발생
    1. **CSRF 토큰 누락** (`@PostMapping` + `application/json` 요청에서 자주 발생)
    2. **권한 부족** (`@PreAuthorize`, `hasRole()`, `hasAuthority()` 등으로 보호된 API에 권한 없는 유저 접근)
    3. **스프링 시큐리티 설정에서 permitAll 안 됨** 혹은 테스트에서 인증정보가 누락되었을 경우

다음 로그의 경우처럼 mockMVC 테스트 시 csrf 토큰을 따로 지정해주지 않아도

```
Session Attrs = {
  org.springframework.security.web.csrf.HttpSessionCsrfTokenRepository.CSRF_TOKEN=...
}
```

&rarr; CSRF 토큰은 세션에 들어가 있긴 하지만...

```java
mockMvc.perform(post("/example")
                        .with(user(userDetails))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
```

→ JSON 요청은 **기본적으로 브라우저 form 요청이 아니기 때문에**, **Spring Security가 CSRF 토큰을 검증하려고 해도 클라이언트 쪽에 토큰이 없다고 판단**해서 **403 Forbidden**을 던짐.

---

### ✅ 해결 방법 1: 테스트에서 CSRF 토큰 명시적으로 포함

```java
mockMvc.perform(post("/buyer/order")
        .with(user(userDetails))
        .with(csrf()) // CSRF 토큰을 테스트 요청에 추가!
        .contentType(MediaType.APPLICATION_JSON)
        .content(jsonContent))
    .andExpect(status().is3xxRedirection())
    .andExpect(redirectedUrl("/order/list"));

```

> import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf; 이 import도 필요함
>

---

### ✅ 해결 방법 2: 테스트 전용으로 시큐리티에서 CSRF 비활성화 (비추천)

`@WebMvcTest` 환경이나 테스트에서 `@TestConfiguration`으로 임시 시큐리티 설정을 덮어씌울 수 있지만, 이는 보안 테스트가 완전히 빠지므로 보통은 `with(csrf())`를 써주는 게 좋음.

---

### 정리

| 원인 | 해결 |
| --- | --- |
| `@PostMapping` + `application/json` + CSRF 활성화 상태 | `.with(csrf())` 추가 |
| 인증 안 됨 | `.with(user(...))` 확인 |
| 권한 설정 문제 | `@PreAuthorize`, Role 체크 등 확인 |