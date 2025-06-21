# R2DBC( Reactive Relational Database Connectivity )란?
**R2DBC**는 Spring Data Relational에 속하는 Reactive Relational Database Connectivity Project로 관계형 데이터베이스에 리액티브 API를 제공한다. 

R2DBC가 탄생하기 전엔 몇몇 NoSQL 벤더만 리액티브 API를 제공했었다. 그래서 리액티브 애플리케이션에서 관계형 데이터베이스를 사용할 경우, 완전한 Non-Blocking I/O를 구현하는 것이 불가능했다. JDBC API 자체가 Blocking API 이기 때문이다.

하지만 R2DBC는 JDBC와 완전히 다른 구현을 적용함으로써 클라이언트의 요청부터 데이터베이스 접근까지 완전한 Non-Blocking 구현이 가능케 한다. 

## R2DBC는 기존의 Relational Database Project와 어떤 차이가 있을까? 
### 1. 아키텍처 차이
```java
// JDBC - Blocking 방식
public List<User> getUsers() {
    // 1. 연결 요청 (블로킹)
    Connection conn = DriverManager.getConnection(url);
    
    // 2. 쿼리 실행 (블로킹) - 응답을 받을 때까지 스레드 대기
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");
    
    // 3. 결과 처리 (블로킹)
    List<User> users = new ArrayList<>();
    while (rs.next()) { // 각 행을 읽을 때마다 블로킹
        users.add(new User(rs.getString("name")));
    }
    return users;
}

// R2DBC - Non-blocking 방식
public Flux<User> getUsers() {
    return connectionFactory
            .create() // 1. 비동기 연결 생성
            .flatMapMany(connection ->
                    connection
                            .createStatement("SELECT * FROM users")
                            .execute() // 2. 비동기 쿼리 실행
            )
            .flatMap(result ->
                    result.map((row, metadata) -> // 3. 스트리밍 결과 처리
                            new User(row.get("name", String.class))
                    )
            );
}
```

## 2. 프로토콜 레벨에서의 차이
**JDBC 기반:**
``` 
클라이언트 → [동기 요청] → 데이터베이스
클라이언트 ← [완전한 결과 반환] ← 데이터베이스
```
**R2DBC 기반:**
``` 
클라이언트 → [비동기 요청] → 데이터베이스
클라이언트 ← [스트리밍 결과] ← 데이터베이스 (Backpressure 지원)
```
## 3. 연결 관리
**JDBC:**
``` java
// Connection Pool에서 스레드가 연결을 점유
Connection conn = dataSource.getConnection(); // 블로킹
// 쿼리 완료까지 연결과 스레드가 묶임
```
**R2DBC:**
``` java
// 이벤트 기반 연결 관리
Mono<Connection> connectionMono = connectionFactory.create();
// 스레드와 연결이 분리됨 - 이벤트 루프 방식
```

## 4. 결과 처리 방식
**JDBC - 풀 버퍼링:**
``` java
ResultSet rs = stmt.executeQuery("SELECT * FROM large_table");
// 모든 결과를 메모리에 로드한 후 처리
while (rs.next()) {
    // 이미 메모리에 있는 데이터 처리
}
```
**R2DBC - 스트리밍:**
``` java
connection.createStatement("SELECT * FROM large_table")
    .execute()
    .flatMap(result -> result.map(...)) // 행별로 스트리밍 처리
    .subscribe(); // Backpressure로 메모리 사용량 제어
```

## 5. 동시 요청 처리 방식
```java
// JDBC 방식 - 각 요청마다 스레드 필요
@RestController
public class JdbcController {
    public ResponseEntity<List<User>> getUsers() {
        // 1000개 동시 요청 = 1000개 스레드 필요
        return ResponseEntity.ok(userService.getAllUsers());
    }
}

// R2DBC 방식 - 소수의 이벤트 루프 스레드로 처리
@RestController
public class R2dbcController {
    public Mono<ResponseEntity<Flux<User>>> getUsers() {
        // 1000개 동시 요청을 4-8개 스레드로 처리 가능
        return Mono.just(ResponseEntity.ok(userService.getAllUsers()));
    }
}
```

## 6. 메모리 사용량
```java
// JDBC - 대용량 결과셋 처리
public List<User> getLargeDataset() {
    // 100만 개 레코드를 모두 메모리에 로드
    return userRepository.findAll(); // OutOfMemoryError 위험
}

// R2DBC - 스트리밍 처리 
public Flux<User> getLargeDataset() {
    return userRepository.findAll() // 스트리밍으로 처리
        .buffer(1000) // 배치 단위로 처리
        .flatMap(batch -> processBatch(batch));
}
```

## 7. R2DBC가 Non-blocking을 구현할 수 있는 이유
1. **새로운 SPI (Service Provider Interface)**: JDBC API를 사용하지 않고 처음부터 반응형으로 설계
2. **이벤트 기반 아키텍처**: 스레드-연결 바인딩을 제거
3. **스트리밍 프로토콜**: 결과를 배치로 스트리밍하여 메모리 효율성 확보
4. **Reactive Streams 준수**: Backpressure를 통한 플로우 제어

따라서 R2DBC는 단순히 JDBC 위에 반응형 래퍼를 씌운 것이 아니라, **완전히 새로운 데이터베이스 접근 방식**으로 구현되었다.


# R2DBC 실전
Spring Data R2DBC는 JPA 같은 ORM 프레임워크에서 제공하는 캐싱, 지연 로딩, 그리고 다른 ORM 프레임워크가 가지고 있는 특징이 제거되어 단순하다. 그러면서도 다른 Spring Data Family 프로젝트들처럼 갖는 데이터 접근 계층의 보일러플레이트를 제거할 수 있다. 

25/06/21 일자로 최신 버전은 3.5.1 버전에서 R2DBC가 지원하는 데이터베이스 종류는 다음과 같다.

- [H2](https://github.com/r2dbc/r2dbc-h2), [MariaDB](https://github.com/mariadb-corporation/mariadb-connector-r2dbc),[Microsoft SQL Server](https://github.com/r2dbc/r2dbc-mssql), [MySQL](https://github.com/asyncer-io/r2dbc-mysql), [jasync-sql MySQL](https://github.com/jasync-sql/jasync-sql), [Postgres](https://github.com/pgjdbc/r2dbc-postgresql), [Oracle](https://github.com/oracle/oracle-r2dbc) 

## 1. 테이블 스키마 정의
R2DBC는 JPA처럼 엔티티에 정의된 매핑 정보로 테이블을 자동 생성해주는 기능이 없기 때문에 테이블 생성을 직접 수행해야 한다. Database 스키마 생성을 별도로 해도 좋고 애플리케이션 구동과 연동시켜도 좋다. 이 절에서는 독자들이 더 폭넓게 참고할 수 있도록 스프링이 '테이블 생성 스크립트'를 실행하도록 하는 방법을 선택한다.

스프링 애플리케이션의 `src/main/resources/db/h2` 디렉터리 위치에 schema.sql 파일을 생성한 다음 스크립트를 작성하자. 

```sql
CREATE TABLE IF NOT EXISTS STUDY_PARTICIPANTS (
    sp_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sp_name VARCHAR(5) NOT NULL UNIQUE, -- 스터디원 이름
    warning INT NOT NULL -- 경고 횟수
)
```

생성 스크립트가 성공적으로 작성되었다면 다음과 같이 설정을 함으로써 애플리케이션이 실행되는 시점에 테이블이 생성되도록 만들자.

```
spring:
    sql:
        init:
            schema-locations: classpath*:db/h2/schema.sql
```


## 2. 도메인 엔티티 클래스 생성
이제 데이터베이스의 `STUDY_PARTICIPANTS` 테이블에 액세스하기 위한 도메인 엔티티 클래스를 정의하자. Spring Data Family Project와 닮아있는 스펙이기 때문에 Spring Data 프로젝트 중 하나라도 사용해봤다면 익숙할 것이다.

```java
@Getter
@AllArgsConstructor
@NoArgsConstructor
public class StudyParticipant {
    @Id
    private long spId;
    private String spName;
    private int warning;
}
```

예시의 엔티티 클래스가 어떻게 작성된 것인지 살펴보자.

- '도메인 엔티티 클래스'를 '테이블'과 매핑하기 위해서 테이블의 기본키에 해당하는 필드에 `@Id` 애너테이션을 추가해야 한다.
- `@Table` 애너테이션을 생략하면 기본적으로 클래스 이름을 테이블 이름으로 사용한다.


## 3. R2DBC Repositories를 이용한 데이터 접근
R2DBC는 여타 Spring Data Family Project와 마찬가지로 추상화된 데이터 접근 기술을 손쉽게 사용할 수 있는 Repository API를 제공한다.

### 3.1 Repository 정의
```java
public interface StudyParticipantsRepository extends ReactiveCrudRepository<StudyParticipant, Long> {
    Mono<StudyParticipants> findBySpName(String spName);
    Mono<Boolean> existsBySpName(String spName);
}
```

다른 Spring Data Project의 Repository와 다르게 리액티브 방식으로 동작하는 `ReactiveCrudRepository`를 상속한다는 것과 리턴 타입이 Mono 또는 Flux이다. 이는 여러 리액티브 스트림즈 구현체 중에 Spring이 채택한 `Reactor`의 Publisher 타입이다.


### 3.2 서비스 클래스 구현
```java
@Slf4j
@RequiredArgsConstructor
@Service
public class StudyParticipantService {
  private final StudyParticipantRepository studyParticipantRepository;

  public Mono<StudyParticipant> save(StudyParticipant studyParticipant) {
    return studyParticipantRepository.existsBySpName(studyParticipant.getSpName())
            .flatMap(isExist -> {
                if (isExist)
                    return Mono.error(new DuplicatedSpNameException("This participant name has already been saved."));
                studyParticipantRepository.save(studyParticipant);
            });
  }

  public Mono<StudyParticipant> getBySpName(String spName) {
    return studyParticipantRepository.findBySpName(spName);
  }
}
```

3.1 절에서 정의한 리포지토리를 사용해 데이터베이스와 상호작용하는 서비스 로직을 살펴보자. 각 메서드 코드에 대한 설명은 다음과 같다.

- `existsBySpName(String spName)`
  - 인자 `spName`과 같은 값의 spName을 갖는 레코드가 있는지 여부를 return 한다.
- `flatMap`
  - input sequence를 받아 새로운 inner sequence를 반환하는 오퍼레이터이다. 
  - `existsBySpName` 을 통해 같은 이름으로 등록된 참여자가 '존재하는지'를 확인하고, 
    - 존재한다면 
      - `Mono.error(java.lang.Throwable error)`
        - 구독 후 즉시 지정된 오류와 함께 종료되는 `Mono`를 생성한다. 동기 방식에서 `throw`로 에러를 던지는 것과 흡사하다.
    - 존재하지 않으면
      - `save(StudyParticipant studyParticipant)`
        - 인자로 주어진 엔티티 객체를 데이터베이스에 저장하고, `Mono<'저장된 객체'>`를 return 한다.
- `findBySpName(String spName)`
  - 참여자 이름이 일치하는 레코드를 읽어 return 한다.  


## 4. `R2dbcEntityTemplate`을 이용한 데이터 액세스
R2DBC는 `JdbcTemplate`처럼 템플릿/콜백 패턴이 적용된 `R2dbcEntityTemplate`을 제공한다. `R2dbcEntityTemplate`는 Spring Data R2DBC의 central entrypoint(`insert()`, `select()`, `update()`) 이다. 이 기능으로 R2DBC는 데이터 쿼리, 삽입, 업데이트, 삭제와 같은 일반적인 임시 사용 사례에 대해 엔티티 중심의 직접적인 메서드와 더욱 간결하고 유연한 인터페이스를 제공한다.

모든 terminal(끝에 위치하는) method는 
