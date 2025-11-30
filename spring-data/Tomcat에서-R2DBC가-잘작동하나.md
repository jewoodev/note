# R2DBC와 Tomcat의 조합에서 발생할 수 있는 문제
## R2DBC와 Tomcat 호환성 문제
**일반적으로 R2DBC는 Tomcat에서도 정상적으로 작동한다..** 하지만 몇 가지 주의사항이 있다.

### 1. 서버 시작 실패 가능성
- R2DBC 자체가 Tomcat과 호환되지 않아 서버가 시작되지 않는 경우는 드물다
- **주요 원인**: 설정 오류나 의존성 충돌이 더 일반적인 문제

### 2. 발생 가능한 문제들
#### 의존성 관련
``` xml
<!-- pom.xml에서 충돌 가능성 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-r2dbc</artifactId>
</dependency>
<!-- JDBC와 R2DBC를 함께 사용할 때 주의 -->
```

#### 설정 문제
``` yaml
# application.yml
spring:
  r2dbc:
    url: r2dbc:postgresql://localhost/testdb
    username: user
    password: password
```

### 3. 대안 및 권장사항
#### WebFlux 사용 권장
``` java
@RestController
public class UserController {
    
    @Autowired
    private UserRepository userRepository;
    
    @GetMapping("/users")
    public Flux<User> getUsers() {
        return userRepository.findAll();
    }
}
```
#### Reactor Netty 고려
- R2DBC는 비동기/논블로킹 특성상 Reactor Netty와 더 잘 맞는다
- Spring WebFlux + Reactor Netty 조합이 R2DBC의 성능을 최대화한다

### 4. 실제 에러 패턴
만약 문제가 발생한다면

``` 
Error starting ApplicationContext. To display the conditions report re-run your application with 'debug' enabled.
APPLICATION FAILED TO START
```
- **일반적인 해결책**
  1. Spring Boot 버전과 R2DBC 버전 호환성 확인
  2. WebFlux 스타터 사용 고려
  3. 데이터베이스 드라이버 의존성 확인

**결론**: R2DBC + Tomcat 조합이 반드시 서버 시작 실패를 야기하지는 않지만, 최적의 성능을 위해서는 Reactor Netty 사용을 권장한다.


# R2DBC는 Tomcat 위에서 동작하는 이유, 이벤트 루프 아키텍처로 변신을 하나?
## R2DBC와 서버 아키텍처의 관계
### 1. R2DBC의 설계 철학
R2DBC는 **Reactor 패턴**과 **이벤트 루프 기반의 논블로킹 I/O**를 전제로 설계되었다.

``` java
// R2DBC의 핵심 - Reactive Streams
public interface ConnectionFactory {
    Publisher<? extends Connection> create();
}

// 모든 작업이 Publisher/Mono/Flux 기반
Mono<User> findById(Long id);
Flux<User> findAll();
```

### 2. Tomcat의 아키텍처 진화
#### 전통적인 Tomcat (Thread-per-Request)
``` 
Request → Thread Pool → Blocking I/O → Response
각 요청마다 스레드 할당, 블로킹 방식
```

#### 현대적인 Tomcat (NIO Connector)
Tomcat 8.5+ 부터는 **NIO/NIO2 커넥터**를 지원한다.

``` xml
<!-- server.xml -->
<Connector port="8080" 
           protocol="org.apache.coyote.http11.Http11NioProtocol"
           connectionTimeout="20000" />
```

### 3. 실제 동작 가능성과 한계
#### 기술적으로 가능한 이유
``` java
@RestController
public class UserController {
    
    @Autowired
    private R2dbcUserRepository repository;
    
    // Tomcat에서도 Mono/Flux 반환 가능
    @GetMapping("/users")
    public Mono<List<User>> getUsers() {
        return repository.findAll().collectList();
    }
}
```

#### 하지만 최적화되지 않은 이유
**Event Loop 불일치**

``` java
// Netty: 단일 Event Loop 스레드에서 모든 I/O 처리
EventLoop eventLoop = channel.eventLoop();

// Tomcat: 여전히 스레드 풀 기반, NIO여도 완전한 Event Loop는 아님
```

**Context Switching 오버헤드**
``` 
Tomcat Thread → R2DBC Event Loop → Database → Event Loop → Tomcat Thread
불필요한 스레드 컨텍스트 스위칭 발생
```

### 4. 성능 비교
#### Netty 기반 (최적)
``` 
Request → Event Loop → R2DBC → Database
        ↓
Single Thread, No Context Switching
```

#### Tomcat 기반 (동작하지만 비효율)
``` 
Request → Tomcat Thread → Event Loop → R2DBC → Database
        ↓                    ↓
Context Switch Overhead + Thread Pool Management
```

### 5. 실제 문제점
``` java
// Tomcat에서 R2DBC 사용 시 발생 가능한 문제
@GetMapping("/users")
public Mono<User> getUser(@PathVariable Long id) {
    return userRepository.findById(id)
        .subscribeOn(Schedulers.boundedElastic()) // 추가 스케줄러 필요
        .publishOn(Schedulers.parallel());        // 성능 저하 요인
}
```

### 결론
1. **기술적으로는 가능**: Tomcat NIO + R2DBC 조합 동작
2. **아키텍처 미스매치**: R2DBC의 이벤트 루프 장점을 충분히 활용 불가
3. **성능 손실**: 불필요한 스레드 컨텍스트 스위칭
4. **권장 조합**:
    - **Spring WebFlux + Reactor Netty + R2DBC** (최적)
    - **Spring MVC + Tomcat + JDBC** (전통적이지만 일관성 있음)

R2DBC를 사용한다면 Reactor Netty 기반의 WebFlux를 사용하는 것이 아키텍처적으로 훨씬 합리적이다.

