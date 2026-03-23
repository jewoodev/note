백엔드 서버는 API 요청을 받아 API 응답을 보내는 역할을 수행한다. 

API 요청 작업을 수행할 때 DB에 접근해 데이터를 조회하는 일이 생기면, 쿼리 요청을 DB 서버로 보내게 된다. 그럼 DB 서버는 요청된 쿼리를 수행해 결과를 API 응답으로 반환한다.
쿼리를 요청하고 응답받는 이 과정을 더 자세히 살펴보면 백엔드 서버와 DB 서버가 서로 다른 컴퓨터에서 동작하기 때문에 쿼리를 요청하고 응답받는 과정은 결국 네트워크 통신을 하게 되는 과정이다. 그런데 백엔드 서버와 DB 서버는 보통 TCP/기반으로 통신한다.

TCP 통신은 연결지향적이기에 통신을 시작할 때 연결을 맺고, 통신이 끝나면 연결을 끊는다. 이 연결 관련해서 3-way, 4-way handshake를 수행하기에 비용이 큰 통신인데, 그렇기에 매번 이런 비용이 쓰는 것은 서비스 성능에 좋지 않다. 이 문제를 해결하기 위해 고민하다가 생겨난 해결책이 **DBCP**이다.

DBCP는 어떤 것일까? DBCP를 사용하는 백엔드 서버는 서버를 띄울 때, 즉 API 요청을 받기 전에 DB 커넥션을 맺는다. 그리고 만들어 놓은 커넥션은 풀처럼 관리한다.  
백엔드 서버는 DB에 쿼리해야 하는 경우가 생기면, DB 커넥션을 맺지 않고 풀에서 '아직 놀고 있는 커넥션' 하나를 가져와서(get connection) 사용한다. 그리고 사용이 끝나면 close connection을 하는데 이는 연결을 닫는게 아니라 풀에 커넥션을 반납하는 작업이다.

이 풀을 database connection pool이라 부르며 줄여서 DBCP라고 하는 것이다.

# 설정 방법
다양한 데이터베이스와 DBCP가 있지만 여기서는 MySQL과 HikariCP를 기준으로 설명한다.

DB connection은 backend server와 DB server 사이의 연결이기 때문에 두 서버 각각에서의 설정(configuration) 방법 모두를 알아야 한다.

## MySQL
- max_connections
  - client와 맺을 수 있는 최대 connection 수.
  - 이 설정값과 DBCP의 최대 connection 수 설정값이 같으면
    - 백엔드 서버의 부하가 커져 스케일링하려고 할 때 더이상 커넥션을 만들 수 없는 문제가 발생.
- wait_timeout
  - connection이 inactive 할 때 다시 요청이 오기까지 '얼마의 시간'을 기다린 후에 close 할 것인지를 결정.
  - idle connection이 정상적으로 제거되지 않고 이상한 상태에 빠지는 경우를 위해 쓸모가 있는 설정값.
    - '이상한 상태에 빠지는 경우'는 어떤 경우를 말하는 걸까?
      - 비정상적인 connection 종료.
      - connection을 다 사용되었으나 반환이 되지 않음.
      - 네트워크 단절.
      - 즉, 백엔드 서버는 connection close 상태이지만 DB 서버는 connection open 상태로 빠지는 경우를 말한다. 
    - idle: DB 서버 입장에서 커넥션은 맺어져 있지만 active 상태는 아닌, 즉 요청이 오기까지 기다리고 있는 상태.
  - 정상적으로 제거되지 않은 idle connection이 쌓이면 DB에 악영향을 주기 때문에 주기적으로 이를 정리해주어야 하는 것임.

## DBCP
- minimumIdle
  - pool에서 유지하는 최소한의 idle connection 수.
  - idle connection 수가 minimumIdle보다 작고, 전체 connection 수도 maximumPoolSize보다 작다면 신속하게 추가로 connection을 만든다.
  - 기본 값은 maximumPoolSize와 동일.
    - HikariCP 메뉴얼에 따르면 기본 값과 같이 maximumPoolSize와 동일하게 설정하는 걸 권장.
- maximumPoolSize
  - pool이 가질 수 있는 최대 connection 수.
  - idle과 active(in-use) connection 수를 합한 값.
- maxLifetime
  - pool에서 connection의 최대 수명.
  - maxLifetime을 넘기면 idle일 경우 pool에서 바로 제거, active인 경우 pool로 반환된 후 제거.
    - pool로 반환되지 않으면 maxLifetime 동작 안함.
      - 따라서 pool로 반환하는 것이 매우 중요.
  - DB의 connection time limit보다 몇 초 짧게 설정해야 함.
    - 그러지 않으면 백엔드 서버에서 커넥션이 죽기 바로 전에 쿼리를 보내서, 쿼리가 전송되는 도중에 DB의 connection은 close 되는 문제 발생 가능.
- connectionTimeout
  - pool에서 connection을 받기 위한 대기 시간

## 적절한 connection 수를 찾기 위한 방법론
1. 백엔드 서버, DB 서버의 CPU, MEM 등의 리소스 사용률 확인.
2. thread per request 모델이라면 active thread 수 확인.
3. DBCP의 active connection 수 확인.
4. 사용할 백엔드 서버 수를 고려해 DBCP의 max pool size 결정.