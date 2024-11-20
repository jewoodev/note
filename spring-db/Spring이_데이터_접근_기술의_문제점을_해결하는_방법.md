# Index

<!-- TOC -->
* [Spring이 데이터 접근 기술의 문제점을 해결하는 방법](#spring이-데이터-접근-기술의-문제점을-해결하는-방법)
  * [1. 트랜잭션 추상화](#1-트랜잭션-추상화)
  * [2. 트랜잭션 동기화](#2-트랜잭션-동기화)
  * [3. 트랜잭션 템플릿](#3-트랜잭션-템플릿)
  * [4. 트랜잭션 AOP](#4-트랜잭션-aop)
    * [4-1. AOP를 테스트하는 방법](#4-1-aop를-테스트하는-방법)
    * [4-2. 선언적 트랜잭션 관리 vs 프로그래밍 방식 트랜잭션 관리](#4-2-선언적-트랜잭션-관리-vs-프로그래밍-방식-트랜잭션-관리)
* [참고 자료](#참고-자료)
<!-- TOC -->

# Spring이 데이터 접근 기술의 문제점을 해결하는 방법

Jdbc에 의존해 트랜잭션을 사용하는 것은 나중에 데이터 접근 기술을 바꿔야 하는 순간 문제가 된다. Jdbc에 의존해 트랜잭션을 사용하는 모든 코드를 서비스 계층을 뒤져가며 수정해야 하기 때문이다.  
이런 문제의 해결 방법으로 트랜잭션 추상화가 필요하다.

## 1. 트랜잭션 추상화

Spring이 제공하는 표준 인터페이스는 `PlatformTransactionManager` 이다.

```java
package org.springframework.transaction;

public interface PlatformTransactionManager extends TransactionManager {
    
    TransactionStatus getTransaction(@Nullable TransactionDefinition definition) throws TransactionException;
    
    void commit(TransactionStatus status) throws TransactionException;
    void rollback(TransactionStatus status) throws TransactionException;
}
```

## 2. 트랜잭션 동기화

스프링이 제공하는 트랜잭션 매니져는 크게 두 가지 역할을 한다.

1. 트랜잭션 동기화
2. 리소스 동기화

트랜잭션을 유지하려면 트랜잭션의 시작부터 끝까지 같은 커넥션을 사용해야 한다. 즉, 커넥션을 동기화하여 사용한다고 표현할 수 있다.  
순수 자바 코드로 이런 트랜잭션을 구현할 때 파라미터로 커넥션을 넘겨서 전달하는 방법을 사용할 수 있는데  
계속해서 그런 방법으로 개발하면 코드가 지저분해지고 커넥션을 넘겨서 사용할 메서드와 그렇지 않은 메서드를 중복해서 만들어야 하는 등 코드 복잡성이 늘어난다.

스프링은 "**트랜잭션 동기화 매니져**"를 제공한다. 이건 쓰레드 로컬을 사용해서 커넥션을 동기화함으로써 위에서 언급한 복잡성을 없앤다.  
트랜잭션 매니저의 동작은 아래처럼 이루어진다.

1. 트랜잭션 매니저가 데이터소스로 커넥션을 만들고(트랜잭션을 동기화하려면 DataSourceUtils를 사용해야 함) 트랜잭션을 시작한다.
2. 트랜잭션이 시작된 커넥션을 트랜잭션 동기화 매니저에 보관한다.
3. 리포지토리가 커넥션이 필요할 때 트랜잭션 동기화 매니저에 보관된 커넥션을 꺼내 사용한다.
4. 트랜잭션이 종료되면 트랜잭션 매니저가 트랜잭션 동기화 매니저에 보관된 커넥션을 통해 트랜잭션을 종료하고 커넥션을 닫는다.

> ThreadLocal을 사용하면 각각의 Thread마다 고유한 저장소가 부여된다. 해당 쓰레드만 저장소에 접근할 수 있기 때문에 동시성 문제가 발생하지 않는다.

```java
import lombok.extern.slf4j.Slf4j;
import hello.jdbc.domain.Member;
// import ...

// ...

@Slf4j
public class EmployeeRepository {

    private final DataSource dataSource;
    private final PlatformTransactionManager transactionManager;

    public EmployeeRepository(DataSource dataSource, PlatformTransactionManager transactionManager) {
        this.dataSource = dataSource;
        this.transactionManager = transactionManager;
    }

    /**
     * 계좌 이체
     * @param fromId 출금하는 계좌 id
     * @param toId 입급되는 게좌 id
     * @param money 이체되는 금액
     * @throws SQLException
     */
    public void accountTransfer(String fromId, String toId, int money) throws SQLException {
        
        TransactionStatus status = transactionManager.getTransaction(new DefaultTransactionDefinition());
        
        try {
            Employee fromEmp = findById(con, fromId);
            Employee toEmp = findById(con, toId);

            update(con, fromId, fromEmp.getMoney() - money);
            update(con, toId, toEmp.getMoney() - money);
            
            transactionManager.commit(status);
        } catch (Exception e) {
            transactionManager.rollback(status);
            throw new IllegalStateException(e);
        }
    }

    public Employee save(Employee employee) {
        // ...
    }
    
    public Employee findById(String id) {
        // ...
    }

    public Employee findById(Connection con, String id) {
        // ...
    }
}
```

## 3. 트랜잭션 템플릿

트랜잭션을 사용하는 곳에서 트랜잭션 시작, 비즈니스 로직에 성공하면 커밋, 실패하면 롤백하는 것이 반복될 수 밖에 없다. 서비스 로직마다 비즈니스 로직만이 변경되고 나머지 부분은 같은 내용이 반복될 것이다.  
이 문제를 해결하기 위해 스프링은 템플릿 콜백 패턴을 활용한다.

템플릿 콜백 패턴을 적용하기 위해 필요한 템플릿 클래스 `TransactionTemplate`을 제공한다. 

```java
public class TransactionTemplate {
    
    private PlatformTransactionManager transactionManager;
    
    public <T> T execute(TransactionCallback<T> action) { // 응답 값이 있을 때 사용
        // .. 
    }
    
    void executeWithoutResult(Consumer<TransactionStatus> action) { // 응답 값이 없을 때 사용
        // ..
    }
}
```

이를 사용하면 **2. 트랜잭션 동기화**에 있는 코드를 아래처럼 정리할 수 있다.

```java
public class EmployeeRepository {

    private final TransactionTemplate txTemplate;

    public EmployeeRepository(DataSource dataSource, PlatformTransactionManager transactionManager) {
        this.txTemplate = new TransactionTemplate(transactionManager);
    }

    /**
     * 계좌 이체
     * @param fromId 출금하는 계좌 id
     * @param toId 입급되는 게좌 id
     * @param money 이체되는 금액
     * @throws SQLException
     */
    public void accountTransfer(String fromId, String toId, int money) throws SQLException {

        txTemplate.executeWithoutResult((status) ->{
            
            try {
                Employee fromEmp = findById(con, fromId);
                Employee toEmp = findById(con, toId);

                update(con, fromId, fromEmp.getMoney() - money);
                update(con, toId, toEmp.getMoney() - money);
            } catch (SQLException e) {
                throw new IllegalStateException(e);
            }
        });
    }
}
```

트랜잭션 템플릿을 사용하니 트랜잭션을 시작, 커밋 or 롤백하는 코드가 없어졌다.  
트랜잭션 템플릿은 기본적으로 다음과 같이 작동한다.

1. 비즈니스 로직이 정상 수행되면 커밋.
2. 언체크 예외가 발생하면 롤백. 그 외의 경우 커밋.(체크 예외는 커밋)

위의 예시에서 쿼리를 수행하는 동안 체크 예외가 발생될 수 있는 점을 처리하기 위해 `try-catch`가 사용되었다.  
템플릿을 사용할 때 람다식을 써야 하는데 람다식 안에서 체크 예외를 밖으로 던질 수 없기 때문에 언체크 예외로 바꾸어 던져지도록 했다.

## 4. 트랜잭션 AOP

트랜잭션 템플릿을 사용하면 트랜잭션을 처리하는데에 필요한 보일러플레이트는 제거할 수 있었지만,  
데이터를 처리하는 로직이 순수하지 못하고 트랜잭션에 관련된 기능들에 의존해있는 상태이다.  

이런 상태에서 트랜잭션을 사용하지 않는 것으로 수정해야해야 한다면 코드를 대거 수정해야 한다.  
이를 해결하려고 트랜잭션을 사용하는 메서드를 각각 따로 만든다고 하면 복잡성이 커지게 된다.

이럴 때 Spring AOP를 도입하면 이런 문제를 깔끔하게 해결할 수 있다.

이를 사용하면 **3. 트랜잭션 템플릿**에 있는 코드를 아래처럼 정리할 수 있다.

```java
public class EmployeeRepository {

    /**
     * 계좌 이체
     * @param fromId 출금하는 계좌 id
     * @param toId 입급되는 게좌 id
     * @param money 이체되는 금액
     * @throws SQLException
     */
    @Transactional
    public void accountTransfer(String fromId, String toId, int money) throws SQLException {
        
        Employee fromEmp = findById(con, fromId);
        Employee toEmp = findById(con, toId);

        update(con, fromId, fromEmp.getMoney() - money);
        update(con, toId, toEmp.getMoney() - money);
    }
}
```

### 4-1. AOP를 테스트하는 방법

Spring AOP는 컴포넌트들이 빈으로 등록되었을 때 사용되기 때문에(스프링 빈으로 등록된 트랜잭션 매니저를 찾아서 사용하기 때문에) 테스트 코드가 구동될 때 빈으로 등록되도록 구성해야 한다.

```java
@SpringBootTest
class EmployeeRepositoryTest {
    
    @TestConfiguration
    static class TestConfig {
        @Bean
        DataSource dataSource() {
            return new DriverManagerDataSource("https~", "username", "password");
        }
        
        @Bean
        PlatfromTransactionManager transactionManager() {
            return new DataSourceTransactionManager(dataSource());
        }
        
        @Bean
        EmployeeRepository employeeRepository() {
            return new EmployeeRepository(dataSource());
        }
    }
    
    @Test
    void testLogic() {
        // ..
    }
}
```

- `@SpringBootTest`: 스프링 AOP를 적용하기 위해 스프링 컨테이너가 필요하다. 이 애노테이션은 스프링 부트를 통해 스프링 컨테이너를 생성한다. 그리고 `@Autowired`와 같은 걸 통해 스프링 컨테이너가 관리하는 빈들을 쓸 수 있다.
- `@TestConfiguration`: 테스트 클래스 안에 이 애노테이션을 붙여 내부 설정 클래스를 만들면, 해당 클래스 안에 정의된 빈들을 등록하고 테스트를 수행한다.

AOP가 잘 먹었는지 `EmployeeRepository`에 `getClass()`를 해보면 클래스 이름 뒤에 ~CGLIB~ 이 붙는다. 스프링이 AOP를 적용해 서비스 로직을 상속받고 AOP 설정대로 코드를 조작해 프록시 인스턴스를 만들어낸 것이다. Spring AOP가 프록시 인스턴스를 만들 때 CGLIB 이라는 이름을 공통적으로 사용한다. 이는 프록시를 만들 때 CGLIB이라는 라이브러리를 사용하기 때문이다. 

### 4-2. 선언적 트랜잭션 관리 vs 프로그래밍 방식 트랜잭션 관리

선언적 트랜잭션 관리는 `@Transactional` 애노테이션 하나만 선언해서 매우 편리하게 트랜잭션을 적용하는 것을 말한다. 이 방식은 과거에 XML에 설정하기도 했다. 이름 그대로 해당 로직에 트랜잭션을 적용하겠다고 어딘가에 선언하기만 하면 트랜잭션이 적용되는 방식이다.

프로그래밍 방식 트랜잭션 관리는 트랜잭션 매니저 또는 트랜잭션 템플릿을 통해 트랜잭션 관련 코드를 직접 작성하는 것을 의미한다.

간편성과 실용적인 점 때문에 대부분 선언적 트랜잭션 관리를 사용하지만 테스트 시에 가끔 프로그래밍 방식 트랜잭션 관리가 사용된다.


# 참고 자료
- [김영한님의 스프링 DB 1편](https://www.inflearn.com/course/%EC%8A%A4%ED%94%84%EB%A7%81-db-1/dashboard)