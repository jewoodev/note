# stored function이란?
- 사용자가 정의한 함수
- DBMS에 저장되고 사용되는 함수
- SQL의 select, insert, update,delete statement에서 사용할 수 있다.

## stored function 예제 1
- 임직원의 ID를 열자리 정수로 랜덤하게 발급하고 싶다.
- ID의 맨 앞자리는 1로 고정이다.

```sql
delimiter $$
CREATE FUNCTION id_generator() 
RETURNS INT
NO SQL
BEGIN
	RETURN (10000000000 + FLOOR(RAND() * 1000000000));
END
$$
delimiter ;
```
- 함수 안의 delimiter와 구분지어지지 않으면 함수 안의 delimiter로 명령어가 잘려버리므로 delimeter를 수정해서 하나의 함수를 묶어준다.
- 문법
  - `CREATE FUNCTION` 이라고 적어주고 어떤 이름의 함수를 만들 것인지 적어준 후, 파라미터를 적는데 위 예제는 파라미터가 없다.
  - 그 다음 리턴 타입을 적어줘야 한다. 
  - NO SQL은 MySQL에서만 사용되는 키워드로 함수를 생성할 때 써야 한다.
  - 실제 이 함수가 어떻게 동작해야 되는지 서술한 Body 부분이 시작됐음을 `BEGIN`으로 알리고 `END`로 끝났음을 알린다.

## stored function 예제 2
- 부서의 ID를 파라미터로 받으면 해당 부서의 평균 연봉을 알려주는 함수를 작성하자.

```sql
delimiter $$
CREATE FUNCTION dept_avg_salary(d_id INT) 
RETURNS INT
READS SQL DATA 
BEGIN
	DECLARE avg_sal INT;
	SELECT AVG(salary) INTO avg_sal
	FROM employee
	WHERE dept_id = d_id;
	RETURN avg_sal;
END
$$
delimiter ;
```
- `DECLARE` 명령을 사용해서 변수를 선언할 수 있다.
- `INTO` 명령을 통해 변수에 값을 저장할 수 있다.

변수를 선언하지 않고도 동일하게 동작하는 함수를 만들 수 있다.

```sql
delimiter $$
CREATE FUNCTION dept_avg_salary(d_id INT) 
RETURNS INT
READS SQL DATA 
BEGIN
	SELECT AVG(salary) INTO @avg_sal
	FROM employee
	WHERE dept_id = d_id;
	RETURN @avg_sal;
END
$$
delimiter ;
```

## stored function 예제 3
- 졸업 요건 중 하나인 토익 800점 이상을 넘겨야 한다는 조건을 충족했는지 알려주는 함수를 작성하자.

```sql
delimiter $$
CREATE FUNCTION toeic_pass_fail(toeic_score INT) 
RETURNS CHAR(4)
NO SQL 
BEGIN
    DECLARE pass_fail CHAR(4);
    IF toeic_score IS NULL THEN SET pass_fail = 'fail';
    ELSEIF toeic_score >= 800 THEN SET pass_fail = 'pass';
    ELSE SET pass_fail = 'fail';
    END IF;
	RETURN pass_fail;
END
$$
delimiter ;
```

## stored function 정리
- 이외에도 loop를 돌면서 반복적인 작업을 수행하거나, case 키워드를 사용해서 값에 따라 분기 처리하거나, 에러를 핸들링하거나 에러를 일으키는 등의 다양한 동작을 정의할 수 있다.
- 사용은 `function_name(parameter_name, ...)`으로 사용할 수 있으며, CREATE, SELECT 문 등 많은 명령문 안에서 사용하는 것이 가능하다.

---

# stored function 삭제하기
```sql
DROP FUNCTION stored_function_name;
```

---

# 등록된 stored function 파악하기
```sql
SHOW FUNCTION STATUS where DB = 'company';
```
DB를 기준으로 가지고 있는 함수를 조회할 수 있다. 함수를 생성할 때 어떤 DB에 생성할 것인지 명시하지 않으면 활성화되어 있는 DB에 생성되며, 명시하고자 하한다면 `CREATE FUNCTION DB_NAME.FUNCTION_NAME` 의 문법으로 명시할 수 있다.

위 명령어를 실행하면 company 데이터베이스에 저장된 stored function의 이름을 결과로 얻는다.

## 특정 함수가 어떻게 선언됐는지 확인하기
```sql
SHOW CREATE FUNCTION stored_function_name;
```

# stored function은 언제 써야할까?
그 이야기를 하기 전에 three-tier architecture에 대해 먼저 알아보자.

## Three-tier architecture
### Presentation tier
- 사용자에게 보여지는 부분을 담당
- HTML, javascript, CSS, native app, desktop app
### Logic tier
- 서비스와 관련된 기능과 정책 등등 비즈니스 로직을 담당
- application tier, middle tier 라고도 불림
- Java + Spring, Python + Django, ...
### Data tier
- 데이터를 저장하고 관리하고 제공하는 역할을 하는 tier
- MySQL, Oracle, PostgreSQL, ...

## 다시 본래 이야기로 돌아와서..
- util 함수로 쓰기에는 괜찮을 것 같다.
- 비즈니스 로직을 stored function에 두는 것은 좋지 않을 것 같다.
  - 비즈니스 로직이 Logic tier에만 있는 것이 아니라 Data tier에도 스며들면서 유지보수, 관리가 어려워지기 때문이다.
- 그럼 앞서 살펴본 예시들에 이 시각을 도입해보자.
  - | stored function | 비즈니스 로직을 가지는가? |
    |-----------------|----------------|
    | dept_avg_salary | x              |
    | id_generator    | △              |
    | toeic_pass_fail | o              |
  - 개인적인 시각일 뿐, 회사마다 정책이 다를 것이며 상황이 다를 것이기 때문에 정답으로 단정짓지 말고 올바르며 유연한 시각을 가질 수 있도록 하자.
