# JDBC로 Repository 레이어 로직을 구성하는 법

## 1. DriverManager를 사용하는 방법

JDBC의 DriverManager를 활용해 데이터를 최신화하는 로직을 구성해보자. 

```java
import java.sql.DriverManager;

public class DBConnectionUtil {

    public static Connection getConnection() {
        DriverManager.getConnection("https~", "username", "password");
    }
}
```

```java
import lombok.extern.slf4j.Slf4j;
import hello.jdbc.domain.Member;

...

@Slf4j
public class EmployeeRepository {

    public Employee save(Employee employee) {
        String sql = "insert member(employee_id, salary) values (?, ?)";

        Connection con = null;
        PreparedStatement pstmt = null;

        try {
            con = getConnection();
            pstmt = con.preparedStatement(sql);
            pstmt.setString(1, member.getMemberId());
            pstmt.setString(2, member.getMoney());
            pstmt.executeUpdate();
            return member;
        } catch (SQLException e) {
            log.error("db error", e);
            throw e;
        } finally {
            pstmt.close();
            con.close();
        }

    }

    private Connection getConnection() {
        return DBConnectionUtil.getConnection();
    }
}
```

예시 코드에 포함된 `Statement` 객체는 쿼리 문자열, `PreparedStatement` 객체는 파라미터를 바인딩할 수 있는 기능이 추가된 쿼리 객체이다. `Employee`는 id값과 월급값 두가지를 가지는 엔티티이다. 
JDBC가 DB 로직에서 반복적으로 사용되는 데이터베이스 연결 과정과 쿼리 결과물을 객체로 변환하는 과정을 표준화하여 추상화함으로써 간편화했지만, 그럼에도 DB 커넥션을 다루는데 보일러 플레이트가 생긴다.
먼저 데이터베이스 연결을 할 때 마다 필요한 url, 호스트 값, 패스워드 값을 추상클래스의 정적 필드 값으로 만든 후, DB 커넥션을 거는 객체를 만들어 이를 재활용하는 방법으로 유지보수성을 높이자.
그렇게 만든 커넥션으로 preparedStatement를 만들어서 동적 쿼리를 사용하자.

그런데 문제는 커넥션을 가져오는 것과 커넥션으로 PreparedStatement를 만드는 것에서 예외가 터질 수 있다. 그래서 이를 처리하기 위해 try-catch로 잡아야 한다. 
그리고 PreparedStatement와 DB 커넥션 객체가 쓸모 없이 남겨지지 않게 close를 해줘야 한다.

여기서 문제는 close 하는 것에서도 에러가 발생될 수 있는데, close를 할 때는 `pstmt.close();` 와 `con.close();` 둘 중 먼저 실행된 것이 에러가 발생되면 다음 `close();` 메서드가 실행되지 않는 경우가 생겨나기 때문에
그 경우를 고려해서 코딩해야 한다. `close();` 에서 일어나는 예외는 `SQLException`이니까 이를 처리해주자.


```java
private void close(Connection con, Statement stmt, ResultSet result) {
    
    if (result != null) {
        try {
            result.close();
        } catch (SQLException e) {
            log.info("error = {}", e);
        }
    }

    if (stmt != null) {
        try {
            stmt.close();
        } catch (SQLException e) {
            log.info("error = {}", e);
        }
    }

    if (con != null) {
        try {
            con.close();
        } catch (SQLException e) {
            log.info("error = {}", e);
        }
    }
}
```

## 2. 데이터소스 + 커넥션풀 조합을 사용하는 방법

DB 커넥션을 거는 작업에 사용되는 리소스와 레이턴시를 줄이기 위해 미리 커넥션을 확보하고 이를 사용, 사용 후 반납, 반납된 커넥션을 재사용 하는 방법이 커넥션풀이다. 

그리고 DriverManager을 사용할 땐 커넥션을 걸 때마다 url, 계정값으로 구성된 설정값이 사용되어 접속 정보를 수정해야할 때 일일히 커넥션을 거는 곳마다 수정해야되는 비효율적인 구조로 작동하기 때문에  
이 문제를 해결하기 위해 DataSource 인터페이스가 만들어졌다. 

DataSource는 인스턴스를 최초 생성할 때만 설정값을 사용하고, 그 인스턴스로 커넥션을 거는 방식으로 작동하는 인터페이스 설계를 갖는다.

```java
import lombok.extern.slf4j.Slf4j;
import hello.jdbc.domain.Member;

...

@Slf4j
public class EmployeeRepository {

    private final DataSource dataSource;

    public EmployeeRepository(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Employee save(Employee employee) {
        String sql = "insert member(employee_id, salary) values (?, ?)";

        Connection con = null;
        PreparedStatement pstmt = null;

        try {
            con = getConnection();
            pstmt = con.preparedStatement(sql);
            pstmt.setString(1, member.getMemberId());
            pstmt.setString(2, member.getMoney());
            pstmt.executeUpdate();
            return member;
        } catch (SQLException e) {
            log.error("db error", e);
            throw e;
        } finally {
            pstmt.close();
            con.close();
        }
    }

    private void close(Connection con, Statement stmt, ResultSet result) {
    
        JdbcUtils.closeResultSet(rs);  // 닫아주는 로직도 보일러플레이트를 생성해내기 때문에 표준으로 만들어진게 있다. 그런 메서드들이 JdbcUtils에 있다.
        JdbcUtils.closeStatement(stmt);
        JdbcUtils.closeConnection(con);
    }
 
    if (con != null) {
        try {
            con.close();
        } catch (SQLException e) {
            log.info("error = {}", e);
        }
    }

    private Connection getConnection() throws SQLException {
        Connection con = dataSource.getConnection();
        return con.getConnection();
    }
}
```

## 3. 쿼리를 트랜잭션으로 묶기 위해 유의할 점

여러 쿼리가 트랜잭션으로 묶이기 위해서는 트랜잭션으로 묶일 쿼리가 모두 실행되는 동안 커넥션이 유지되어야 한다. 커넥션이 끊기거나 중간에 다른 커넥션을 잡아야 한다면 다른 트랜잭션이 되기 때문이다.  
그래서 Jdbc로 쿼리 로직이 담긴 메서드에서 커넥션을 닫는 `close();`를 없애야 한다.  
따라서 메서드를 오버로딩해서 트랜잭션에 사용할 쿼리 메서드가 받는 파라미터에 커넥션을 추가해서 사용하면 유연한 로직을 만들기를 권장한다.


# 참고 자료
- [김영한님의 스프링 DB 1편](https://www.inflearn.com/course/%EC%8A%A4%ED%94%84%EB%A7%81-db-1/dashboard)