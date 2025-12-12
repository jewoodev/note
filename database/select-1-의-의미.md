# `SELECT 1 ...` 예시
```sql
SELECT 1 FROM table;
``` 
- 위 쿼리는 주어진 테이블의 각 행에 대해 숫자 1을 반환한다.
- 만약 테이블에 N개의 행이 있다면, 결과로 N개의 1이 반환된다.
- 여기에서 1은 `TRUE`를 의미한다.

```sql
SELECT 1 FROM table
WHERE 조건;
```
- 실제 값보다 값의 존재 유무가 더 중요한 경우에 사용하기 적합하다.
- 다중행 서브 쿼리문에서 WHERE 조건절에 (NOT)EXISTS 안의 서브쿼리문에 사용되어진다.

## 실제 사용 결과
users라는 3개의 행을 가지는 데이터베이스 테이블이 있다고 가정해보자.

| **id** | **name** | **age** |
|--------|----------|---------|
| 1      | Alice    | 30      |
| 2      | Bob      | 25      |
| 3      | Carol    | 28      |

이 테이블이 있을 때 `SELECT 1 FROM users` 구문을 실행하면 다음과 같은 결과가 반환된다.

| 1 |
|---|
| 1 |
| 1 |
| 1 |

# 시사점
- SQL에서 1은 TRUE를 의미하므로, `SELECT 1 FROM ...` 형식의 구문은 논리식으로 사용될 수 있다.

# 사용 예시 - EXISTS 조건
- **보통 이 구문은 WHERE 절의 (NOT) EXISTS 안에 있는 서브쿼리로 사용된다.**

```sql
-- 예시 쿼리 1: 특정 사용자가 존재하는지 확인
SELECT
    1
FROM
    users
WHERE
    id = 1;

-- 예시 쿼리 2: 데이터의 존재 유무에 따라 동작
SELECT
    *
FROM
    orders
WHERE
    EXISTS (
        SELECT
            1
        FROM
            users
        WHERE
            users.id = orders.user_id
    );
```

첫 번째 예시 쿼리에서, 특정 사용자의 존재 여부를 확인하기 위해 사용할 수 있다. id가 1인 사용자가 존재하면 1을 반환한다. 두 번째 예시 쿼리에서, orders 테이블의 각 주문이 users 테이블의 사용자에 의해서 이루어졌는지 확인하기 위해 사용할 수 있다. 

EXISTS 조건문은 orders 테이블의 각 행에 대해 `users.id = orders.user_id` 조건을 만족하는 행이 존재하면 TRUE를 반환한다. 이때 `SELECT 1 FROM users` 로 존재 여부만 확인하므로, 더 간단하게 쓸 수 있다.

# 장점
- **특정 조건을 만족하는 데이터가 존재하는지 여부만 중요**할 때, `SELECT * FROM ...` 대신 `SELECT 1 FROM ...`을 사용하면 더 간단하다.
- 불필요한 데이터를 **모두 조회하지 않고 존재 여부만 판단**할 수 있어 효율적이다.

# Reference
- [알게된 것을 기록하는 공간](https://toddlerprogrammer.tistory.com/174)
- [mini_mouse_.log](https://velog.io/@mini_mouse_/SELECT-1-FROM-%ED%85%8C%EC%9D%B4%EB%B8%94%EB%AA%85)