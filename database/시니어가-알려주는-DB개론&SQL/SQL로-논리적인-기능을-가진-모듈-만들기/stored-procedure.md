# stored procedure이란?
- 사용자가 정의한 프로시저
- RDBMS에 저장되고 사용되는 프로시저
- 구체적인 하나의 태스크(task)를 수행한다.

## 예제 1
- 두 정수의 곱셉 결과를 가져오는 프로시저를 작성하자.

```sql
delimiter $$
CREATE PROCEDURE product(IN a INT, IN b INT, OUT result INT)
BEGIN
	SELECT result = a * b;
END
$$
delimiter ;

CALL product(10, 20, @result);
SELECT @result;
```
- `@`를 붙이면 사용자가 정의한 변수가 된다. 

## 예제 2
- 두 정수를 맞바꾸는 프로시저를 작성하자.

```sql
delimiter $$
CREATE PROCEDURE swap(INOUT a INT, INOUT b INT)
BEGIN
	SET @temp = a;
	SET a = b;
	SET b = @temp;
END
$$
delimiter ;

SET @a = 5, @b = 7;
CALL swap(@a, @b);
```
- 파라미터의 키워드를 `INOUT`으로 주면 입력값이자 출력값이 될 수 있게 정의할 수 있다.

## 예제 3
- 각 부서별 평균 연봉을 가져오는 프로시저를 작성하자.

```sql
delimiter $$
CREATE PROCEDURE get_dept_avg_salary()
BEGIN
	SELECT dept_id, AVG(salary) 
	FROM employee 
	GROUP BY dept_id;
END
$$
delimiter ;

CALL get_dept_avg_salary();
```

## 예제 4
- 사용자가 프로필 닉네임을 바꾸면 이전 닉네임을 로그에 저장하고 새 닉네임으로 업데이트하는 프로시저를 작성하자.

```sql
SELECT * FROM users;
```

| id | nickname |
|----|----------|
| 1  | Dingyo   |

```sql
SELECT * FROM nickname_logs;
```

| id | prev_nickname | until               |
|----|---------------|---------------------|
| 1  | Messi         | 2022-07-12 16:55:45 |

```sql
delimiter $$
CREATE PROCEDURE change_nickname(user_id INT, new_nickname VARCHAR(30))
BEGIN
	INSERT INTO profile_logs (
        SELECT id, nickname, now()
        FROM users
        WHERE id = user_id;
    );
	UPDATE employee 
	SET nickname = new_nickname 
	WHERE id = user_id;
END
$$
delimiter ;

CALL change_nickname(1, 'Zidane');
```
- 파라미터에 `IN` 키워드를 적어주지 않아도 입/출력 키워드 중 아무것도 적혀있지 않으면 default로 `입력`으로 설정된다.

## 추가 활용방법
- 이외에도 조건문을 통해 분기처리를 하거나
- 반복문을 수행하거나
- 에러를 핸들링하거나 에러를 일으키는 등의 다양한 로직을 정의할 수 있다.

## stored function과 차이

|                    | stored procedure                   | stored function                     |
|--------------------|------------------------------------|-------------------------------------|
| create 문법          | CREATE PROCEDURE ...               | CREATE FUNCTION ...                 |
| return 키워드로 값 반환   | 불가능(SQL server는 상태코드 반환용으로는 사용 가능) | 가능(MySQL, SQL server는 값 반환하려면 필수)   |
| 파라미터로 값(들) 반환      | 가능(값(들)을 반환하려면 필수)                 | 일부 가능(oracle 가능하나 권장x, Postgres 가능) |
| 값을 꼭 반환해야 하나?      | 필수x                                | 필수                                  |
| SQL statement에서 호출 | 불가능                                | 가능                                  |
| transaction 사용     | 가능                                 | 대부분 불가능(oracle은 가능)                 |
| 주된 사용 목적           | business logic                     | computation                         |

### 이외에 확인해보면 좋을 것들
- 다른 function/procedure를 호출할 수 있는지
- resultset(=table)을 반환할 수 있는지
- precompiled execution plan을 만드는지
- try-catch를 사용할 수 있는지