# 권장 포멧
```sql
-- format 1
INSERT INTO table_name VALUES (value1, value2, ...);
-- format 2
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...);
```
포멧 2가 더 권장된다. 1은 컬럼이 추가되면 쿼리를 수정해야 할 필요가 생기고 어떤 컬럼에 어떤 값이 들어가는지 명확하지 않기 때문이다. 즉, 유지보수성이 2가 더 뛰어나다.

# 다중 Record 삽입
```sql
INSERT INTO table_name (column1, column2, ...) VALUES 
    (value1, value2, ...),
    (value3, value4, ...),
    (value5, value6, ...);
```
다중 record 삽입은 다음과 같이 한번에 여러 record를 삽입하는 쿼리를 사용해 처리하는게 권장된다. 다음과 이점을 가져오기 때문이다.

- 애플리케이션 서버와 DB 서버 간의 네트워크 트래픽 감소
  - 여러 번 메세지를 보내는 것보다 한 번 보내는 것이 더 효율적
    - 매 연결마다 같은 헤더 정보가 중복적으로 메세지에 포함되어 결국 주고 받는 데이터가 늘어남
    - 커넥션을 물고 끊는 비용이 늘어남
- DB 서버에서 최적화됨
  - 쿼리를 처리할 때 다음 과정을 수행
    - 쿼리 파싱
    - 쿼리 계획 수립
    - 쿼리 실행 계획에 따라 최적화된 실행 경로 선택
    - 데이터 접근 및 조작
    - 결과 반환
  - 쿼리 횟수가 줄어들면 이 과정도 한 번으로 줄어듬

이 방법을 Bulk Write라고도 부름

## STMT(Statement)
커넥션 하나를 물고 있으면서 여러 개의 값을 동적으로 프로그래밍 단에서 코드로 확인하면서 넣을 수 있는 삽입 방법.

```sql
INSERT INTO member (username, email, age, address)
SELECT 
    '새 사용자', 'test@example.com', 29, 'Seoul'
WHERE NOT EXISTS (
    SELECT 1
    FROM member
    WHERE username = '새 사용자'
);
```

# 테이블 간의 migration
```sql
-- 다른 테이블의 레코드를 복사
INSERT INTO member (username, email, age, address)
SELECT username, email, age, address
FROM old_member
where status = 'active';

-- 다른 테이블의 레코드를 복사 후 가공해 저장
-- 실제 마이그레이션 과정에선 확인과정없이 처리하면 위험하기 때문에 잘 사용되지 않는 방식
INSERT INTO member (username, email, age, address)
SELECT 
    CONCAT('new_', username) AS username,
    CONCAT('new_', email) AS email,
    age + 1 AS age,
    'Seoul' AS address
FROM old_member
WHERE age > 25;
```

# 중복 데이터 핸들링
```sql
-- ON DUPLICATE KEY UPDATE
-- -> MongoDB Upsert와 비슷
INSERT INTO member (member_id, username, email, age, address)
    VALUES (100, '김철수', 'chursu@example.com', 20, 'Seoul')
ON DUPLICATE KEY UPDATE
    username = VALUES(username),
    email = VALUES(email),
    age = VALUES(age),
    address = VALUES(address)
    updated_at = NOW();
-- 이벤트 형태로 업데이트가 일어나서 멱등성을 지켜야 하는, 동적으로 진행되어야 하는 경우 사용하면 좋음

INSERT IGNORE INTO member (member_id, username, email, age, address)
    VALUES (100, '김철수', 'chursu@example.com', 20, 'Seoul')
-- 중복이 발생하면 자바의 `continue;`처럼 건너뛰게 하는 방법
-- 두 가지 방법은 "데이터가 존재하는지 미리 확인할" 필요가 없기에 쿼리 효율을 높임
-- 두 쿼리는 SELECT를 먼저 진행함
```

중복을 핸들링하는 쿼리로 `REPLACE INTO` 도 있는데, 이는 기존에 있던 데이터를 완전히 대체해버리는 것으로 삭제하고 삽입하는 것과 같기 때문에  
AUTO_INCREMENT 값이 바뀔 수 있고 외래 키가 참조하던 값이 바뀌어 참조 무결성이 깨질 수도 있다. 그래서 위의 방법을 더 권장한다.

# 트랜잭션으로 성능 향상
```sql
START TRANSACTION;
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...);
COMMIT;
```
이 방법은 원자성과 성능 향상의 이점이 있다. 성능 향상이 되는 이유는 각 삽입마다 커밋하지 않고 마지막에 한 번만 커밋하기 때문에 I/O 관점에서 리소스가 최적화된다.

그런데 매번 이렇게 사용하는게 효율적일까? 그 판단은 배치 크기에 달려있다.  
크기가 너무 작으면 트랜잭션을 열어서 배치 삽입을 묶어 처리하는 잠시 동안 DB에 락을 발생시켜 불필요한 오버헤드를 만드는 게 된다.
크기가 너무 크면 MySQL 레벨에서의 메모리 사용량이 늘어나고 롤백하는 데에 드는 시간이 늘어난다.

일반적으로 배치 크기가 만 개 이하라면 STMT 같은 걸 사용하는게 좋고, 만 개 이상인 경우에만 배치 단위의 처리를 사용하는게 좋다.
실제로 측정해보면 만 개까지는 두 방법의 성능 차이가 미미하고 만 개를 넘어가면서 성능 차이가 유의미해진다.
