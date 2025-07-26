## ✅ 1. `httpBasic()`

- HTTP의 기본 인증 방식 (Basic Authentication).
- 클라이언트가 `Authorization: Basic base64(id:pw)` 헤더를 매 요청에 보냄.
- 주로 API 테스트나 간단한 인증에 사용되지만, 보안상 HTTPS와 함께 사용해야 해.

---

## ✅ 2. `formLogin()`

- HTML 폼을 통한 인증.
- 로그인 페이지(`loginPage()`), 로그인 성공/실패 핸들러 등을 커스터마이징 가능.
- 웹 애플리케이션에서 가장 일반적인 방식.

---

## ✅ 3. `oauth2Login()`

- OAuth 2.0 및 OpenID Connect 기반 인증 방식.
- 구글, 카카오, 네이버 같은 소셜 로그인 기능을 구현할 때 주로 사용.
- 스프링 시큐리티가 기본적인 흐름을 지원해 주기 때문에 구현이 비교적 간편.

---

## ✅ 4. `formLogin()` 없이 직접 `UsernamePasswordAuthenticationFilter` 커스터마이징

- REST API 서버에서는 `formLogin()` 대신 JSON으로 아이디/비밀번호를 받아 인증하는 방식이 필요함.
- 이럴 땐 `UsernamePasswordAuthenticationFilter`를 상속한 커스텀 필터를 만들어 사용.

---

## ✅ 5. JWT (JSON Web Token) 기반 인증

- 세션이 아닌 토큰으로 인증 상태를 유지.
- 주로 `OncePerRequestFilter`를 상속한 필터를 통해 JWT 검증 처리.
- REST API나 MSA 환경에서 주로 쓰임.

---

## ✅ 6. `rememberMe()`

- 로그인 상태 유지를 위한 기능.
- 쿠키 기반으로 동작하고, 일정 기간 동안 재로그인 없이 접근 가능하게 해 줌.

---

## ✅ 7. X.509 인증 (`x509()`)

- 클라이언트 인증서 기반 인증.
- 주로 내부망이나 보안이 중요한 시스템에서 사용.

---

## ✅ 8. LDAP 인증 (`ldapAuthentication()`)

- LDAP 서버(예: Active Directory)를 통한 인증.
- 기업 내부 사용자 인증 시스템에 자주 사용됨.

---

## ✅ 9. SAML 인증

- 주로 기업용 싱글사인온(SSO) 환경에서 사용.
- 복잡하지만 IDP(Identity Provider)와의 연동이 가능.

---

필요에 따라 여러 인증 방식을 **조합해서 사용**할 수도 있어. 예를 들어, 일부는 `formLogin()`으로 처리하고, 모바일 앱 쪽은 JWT로 따로 처리하는 식으로 말이지.