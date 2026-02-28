# 실무에서 사용되는 UPDATE 패턴
```sql
-- 단일 패턴
UPDATE member
SET last_login_at = CURRENT_TIMESTAMP
WHERE member_id = 123;

-- 중복 패턴
UPDATE member
SET 
    favorite_color = 'BLUE',
    updated_at = CURRENT_TIMESTAMP
WHERE member_id = 123 AND status = 'ACTIVE';

-- CASE 문을 활용
UPDATE member
SET favorite_color = CASE 
    WHEN favorite_color = 'RED' THEN 'BLUE' 
    ELSE favorite_color 
    END
WHERE member_id = 123;
```

특정 상태를 통해 값을 업데이트하는 작업은 유용하기에 CASE 문은 가치가 있다. CASE 문을 처리하느라 쓰이는 DB 서버의 자원을 고려해야 하지만, DB에서 많이 요청받는 SELECT 쿼리가 아닌  UPDATE 쿼리이기에 무리가 없다.

또 CASE 문은 다음과 같은 용도로도 사용될 수 있다.

```sql
UPDATE post
SET status = CASE 
    WHEN view_count <= 10 THEN 'DRAFT' -- 조회수 낮으면 임시저장
    WHEN view_count >= 1000 THEN 'RECOMMEND' -- 높으면 추천글
    ELSE 'PUBLISHED'
    END,
    updated_at = CURRENT_TIMESTAMP
    WHERE created_at = DATE_SUB(NOW(), INTERVAL 30 DAY);
```
위와 같이 CASE 문을 활용한다면 데이터를 정리하는 작업이나 자동화하는 데에 큰 도움을 받을 수 있다.

## 배치 업데이트
```sql
UPDATE member
SET status = 'INACTIVE'
WHERE last_login_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND status = 'ACTIVE'
LIMIT 1000;
```
위처럼 LIMIT를 사용해 처리해야 하는 데이터의 사이즈를 줄임으로써 대량의 데이터를 나누어서 처리할 수 있다. 이보다 더 점진적인 업데이트를 하고 싶다면 프로시저를 활용할 수 있다.

```sql
DELIMITER //
CREATE PROCEDURE BatchUpdateMemberToInactive()
BEGIN
    DECLARE affected_rows INT DEFAULT 1;
    WHILE affected_rows > 0 DO
        UPDATE member 
        SET status = 'INACTIVE' 
        WHERE last_login_at < DATE_SUB(NOW(), INTERVAL 30 DAY) 
        LIMIT 1000;
            
        SET affected_rows = ROW_COUNT();
        SELECT SLEEP(1);
    END WHILE;
END //
DELIMITER ;
```

이렇듯 배치 단위, 혹은 청크 단위로 나누어서 작업을 진행할 땐 '메모리·락·안정성 vs I/O 작업량' 간의 트레이드-오프가 발생한다. 즉, 이렇게 나누어 처리하는 것이 무조건 정답이 되는 것이 아니라는 것이다. 나누어서 작업하면 I/O를 더 많이 하지만 메모리·락·안정성을 얻고, 한 번에 작업하면 I/O를 더 적게 하지만 메모리·락·안정성을 잃는다.

```sql
UPDATE member 
SET address = 'Busan' 
WHERE address IN ('Incheon', 'Dongtan');
```
이번엔 위의 쿼리에서 `IN` 절의 내부 동작을 알아보자.  
`IN` 연산자는 내부적으로 해시 테이블이나 정렬된 리스트를 사용해 빠르게 매칭을 수행한다.  
옵티마이저는 IN절의 값 갯수와 테이블의 크기를 고려해 최적의 실행 계획을 수립한다. 값 갯수가 적다면 단순 비교로 처리하고 많다면 임시 테이블을 생성해서 해시 조인을 한다. 

```sql
UPDATE member
SET address = 'Seoul'
WHERE age BETWEEN 25 AND 40; -- O(log n + m), n=전체 레코드 수 / m=범위 내 레코드 수
```
이번엔 위 쿼리에서 `BETWEEN` 절의 효용성을 알아보자.  
`BETWEEN` 절은 범위 연산에서 많이 사용되며 옵티마이저가 비교 연산자보다 더 효율적으로 실행 계획을 수립한다.

---

# UPDATE와 X Lock
```sql
UPDATE member
SET username = 'new_' + username
WHERE age > 30;
```
위의 쿼리가 실행되면 X Lock이 어떻게 걸리게 될까?

## `age`에 인덱스가 있는 경우
`age > 30` 조건에 해당하는 레코드(및 해당 인덱스 범위)에만 X Lock이 걸린다. 정확히는 조건을 만족하는 행에 Record Lock과 함께, 범위 스캔 시 Gap Lock / Next-Key Lock이 걸려서 팬텀 리드를 방지한다.

## `age`에 인덱스가 없는 경우
InnoDB는 조건에 맞는 행을 찾기 위해 클러스터드 인덱스 풀 스캔을 수행한다. 이 과정에서 스캔하는 모든 레코드에 X Lock이 걸린다. 조건을 만족하지 않는 행도 일단 락이 잡힌 후, MySQL이 조건 불일치를 확인하면 릴리스하는 최적화(semi-consistent read 등)가 동작할 수 있지만, 이는 격리 수준에 따라 다르다.

- REPEATABLE READ (기본): 스캔한 모든 행에 Next-Key Lock이 유지될 수 있어, 사실상 테이블 전체에 락이 걸리는 효과가 남
- READ COMMITTED: 조건 불일치 행의 락을 조기에 해제하므로, 실제로는 `age > 30`인 행에만 락이 남음

## 정리

| 조건                | 락 범위                  |
|-------------------|-----------------------|
| `age`에 인덱스 O      | 조건 매칭 행 + Gap Lock    |
| `age`에 인덱스 X + RR | 사실상 전체 테이블            |
| `age`에 인덱스 X + RC | 조건 매칭 행만 (나머지는 조기 해제) |

그래서 범위 UPDATE 조건에 사용 빈도가 높은 컬럼이면 인덱스를 걸어두는게 동시성 측면에서 중요하다.

---

# Update와 원자성
MySQL은 단일 Update 문에 대해서 원자성을 보장한다. 이는 InnoDB의 row-level locking 덕분이다.

```sql
UPDATE account SET balance = balance - 100 WHERE id = 1;
```
이 경우 InnoDB가 해당 row에 **배타적 잠금(X Lock)**을 걸고 업데이트하기 때문에, 동시에 같은 row를 수정하려는 다른 트랜잭션은 대기한다.

## 읽고 → 계산하고 → 쓰는 패턴은 안전하지 않다.
```sql
-- TX1
SELECT balance FROM account WHERE id = 1;  -- 1000 읽음
-- 애플리케이션에서 1000 - 100 = 900 계산
UPDATE account SET balance = 900 WHERE id = 1;

-- TX2가 동시에 같은 작업을 하면 Lost Update 발생
```
이 경우 SELECT와 UPDATE 사이에 다른 트랜잭션이 끼어들 수 있어서, 동시성 문제가 그대로 발생합니다.