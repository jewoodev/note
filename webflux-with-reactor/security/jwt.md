Webflux도 MVC와 같은 라이브러리를 사용한다(Security도, 왜냐면 Spring Boot 프로젝트에서는 웹플러스 시큐리티에 대한 의존성도 spring-boot-starter-security에 포함됨). 

```build.gradle
dependencies {
 
    // JWT
    implementation 'io.jsonwebtoken:jjwt-api:0.11.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.11.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.11.5'

    // Spring Security
    implementation 'org.springframework.boot:spring-boot-starter-security'
}
```

이제 JWT 설정을 위한 클래스를 만들어주자.

```java
import io.jsonwebtoken.security.Keys;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@Configuration
public class JwtConfig {
    
    private final String SECRET_KEY = "your-secret-key-must-be-at-least-256-bits-long-for-HS256-algorithm";

    @Bean
    public SecretKey secretKey() {
        return Keys.hmacShaKeyFor(SECRET_KEY.getBytes(StandardCharsets.UTF_8));
    }
} 
```

그리고 JWT 토큰을 생성하고 검증하는 서비스를 구현하자.

```java
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    private final SecretKey secretKey;

    public JwtService(SecretKey secretKey) {
        this.secretKey = secretKey;
    }

    public String generateToken(String username) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, username);
    }

    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 10)) // 10 hours
                .signWith(secretKey, SignatureAlgorithm.HS256)
                .compact();
    }

    public Boolean validateToken(String token, String username) {
        final String tokenUsername = extractUsername(token);
        return (tokenUsername.equals(username) && !isTokenExpired(token));
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }
} 
```

다음으로 JWT 인증을 위한 필터를 구현해보자. 이 필터는 요청의 헤더에서 JWT 토큰을 추출하고 검증하는 역할을 한다.

```java
import lombok.RequiredArgsConstructor;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.core.userdetails.ReactiveUserDetailsService;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;

import com.heri2go.chat.web.service.auth.JwtService;

import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Slf4j
@RequiredArgsConstructor
@Component
public class JwtAuthenticationFilter implements WebFilter {

    private final JwtService jwtService;
    private final ReactiveUserDetailsService userDetailsService;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        return Mono.just(exchange)
                .flatMap(this::extractToken)
                .flatMap(token -> authenticateRequest(exchange, chain, token))
                .switchIfEmpty(chain.filter(exchange));
    }

    private Mono<String> extractToken(ServerWebExchange exchange) {
        if (isWebSocketRequest(exchange)) {
            String token = exchange.getRequest().getQueryParams().getFirst("token");
            log.info("WebSocket request, token : {}", token);
            return Mono.justOrEmpty(token);
        } else {
            String token = exchange.getRequest().getHeaders().getFirst("Authorization");
            log.info("HTTP request, token : {}", token);
            return Mono.justOrEmpty(token)
                    .filter(header -> header.startsWith("Bearer "))
                    .map(header -> header.substring(7));
        }
    }

    private boolean isWebSocketRequest(ServerWebExchange exchange) {
        String upgradeHeader = exchange.getRequest().getHeaders().getFirst("Upgrade");
        return upgradeHeader != null && upgradeHeader.equalsIgnoreCase("websocket");
    }

    private Mono<Void> authenticateRequest(ServerWebExchange exchange, WebFilterChain chain, String token) {
        return Mono.justOrEmpty(jwtService.extractUsername(token))
                .flatMap(username -> userDetailsService.findByUsername(username)
                        .filter(userDetails -> jwtService.validateToken(token, username))
                        .flatMap(userDetails -> {
                            Authentication authentication = new UsernamePasswordAuthenticationToken(
                                    userDetails,
                                    null,
                                    userDetails.getAuthorities()
                            );
                            return chain.filter(exchange)
                                    .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication));
                        }))
                .switchIfEmpty(chain.filter(exchange));
    }
}
```

SecurityConfig은 다음과 같이 설정하면 되겠다.

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UserDetailsRepositoryReactiveAuthenticationManager;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.core.userdetails.ReactiveUserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.context.NoOpServerSecurityContextRepository;

import com.heri2go.chat.filter.JwtAuthenticationFilter;

import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final ReactiveUserDetailsService userDetailsService;

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .authorizeExchange(exchanges -> exchanges
                        .pathMatchers("/api/auth/**").permitAll()
                        .anyExchange().authenticated())
                .authenticationManager(authenticationManager())
                .addFilterAt(jwtAuthenticationFilter, SecurityWebFiltersOrder.AUTHENTICATION)
                .securityContextRepository(NoOpServerSecurityContextRepository.getInstance())
                .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public ReactiveAuthenticationManager authenticationManager() {
        return new UserDetailsRepositoryReactiveAuthenticationManager(userDetailsService);
    }
}
```

