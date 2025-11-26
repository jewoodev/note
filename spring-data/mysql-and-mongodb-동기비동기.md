# MySQL의 동기/비동기 방식
**MySQL**은 기본적으로 **동기(Synchronous) 방식**을 기반으로 한다.

- 클라이언트가 쿼리를 전송하면 서버가 응답할 때까지 대기
- 전통적인 관계형 데이터베이스의 ACID 특성을 보장하기 위한 설계
- 하지만 MySQL도 비동기 복제(Asynchronous Replication) 기능을 제공

# MongoDB의 동기/비동기 방식
**MongoDB**는 **비동기(Asynchronous) 방식**을 기반으로 한다.

- 비동기 I/O 모델을 사용하여 높은 동시성 처리
- 단일 스레드 이벤트 루프 기반 (Node.js와 유사한 아키텍처)
- Write 작업도 기본적으로 비동기로 처리 (Fire-and-forget) 

하지만 필요시 동기 방식으로도 작업 가능한 MySQL(Write Concern 설정)과 MongoDB의 동기/비동기 방식에 대한 차이점을 살펴보자.

---

# MySQL의 동기/비동기 접근 방식
MySQL은 기본적으로 **동기식 기반**으로 설계되었지만, 비동기 기능도 지원합니다:

## 동기식 특성
- 전통적으로 요청-응답 기반의 동기식 처리
- 클라이언트가 쿼리를 보내면 응답을 받을 때까지 대기

## 비동기 지원
- MySQL X Protocol을 통한 비동기 실행 지원 [[1]](https://dev.mysql.com/doc/x-devapi-userguide/en/synchronous-vs-asynchronous-execution.html)
- 콜백, Promise, 또는 명시적 대기를 통한 비동기 처리
- MySQL C API에서 논블로킹 통신을 위한 비동기 함수 제공 [[3]](https://docs.oracle.com/cd/E17952_01/mysql-8.0-en/mysql-nutshell.html)

## 복제 방식
- **비동기 복제** (기본): 마스터가 슬레이브의 확인을 기다리지 않음
- **반동기 복제**: 최소 하나의 슬레이브가 로그를 받을 때까지 대기 [[4]](https://dev.mysql.com/doc/refman/en/replication-semisync.html)
- **완전 동기 복제**: 모든 슬레이브의 확인을 대기

---

# MongoDB의 동기/비동기 접근 방식
MongoDB는 **이벤트 기반 비동기** 아키텍처를 중심으로 설계되었다.

## 이벤트 기반 아키텍처
- Change Streams를 통한 실시간 데이터 변경 감지 [[5]](https://medium.com/deutsche-telekom-gurgaon/building-event-driven-architecture-with-mongodb-change-streams-e9abbd0a61db)
- 이벤트 기반 애플리케이션 구축을 위한 네이티브 지원 [[2]](https://www.mongodb.com/resources/solutions/use-cases/building-event-driven-applications-with-mongodb)

## 비동기 처리
- 문서 기반 데이터베이스로서 비동기 작업에 최적화
- Change Streams를 통해 데이터베이스 변경사항을 실시간으로 구독 가능

## 복제 방식
- 기본적으로 비동기 복제 지원
- Primary-Secondary 구조에서 비동기적으로 데이터 동기화 [[6]](https://www.mongodb.com/docs/manual/replication/)

---

# 공식 문서
## MySQL 공식 문서
- **MySQL 8.4 Reference Manual**: [[7]](https://dev.mysql.com/doc/en/)
- **동기 vs 비동기 실행**: [[1]](https://dev.mysql.com/doc/x-devapi-userguide/en/synchronous-vs-asynchronous-execution.html)
- **복제 관련**: [[4]](https://dev.mysql.com/doc/refman/en/replication-semisync.html)

## MongoDB 공식 문서
- **MongoDB Documentation**: [[3]](https://www.mongodb.com/docs/)
- **복제 관련**: [[6]](https://www.mongodb.com/docs/manual/replication/)
- **이벤트 기반 애플리케이션**: [[2]](https://www.mongodb.com/resources/solutions/use-cases/building-event-driven-applications-with-mongodb)

---

# 요약
- **MySQL**: 동기식 기반이지만 비동기 기능도 지원하는 하이브리드 접근
- **MongoDB**: 이벤트 기반 비동기 아키텍처를 중심으로 설계

두 데이터베이스 모두 현대적인 애플리케이션의 요구사항에 맞춰 비동기 기능을 제공하지만, MongoDB가 더 네이티브하게 이벤트 기반 및 비동기 패턴을 지원한다고 볼 수 있다.