# SQL에서 Trigger의 의미
- 데이터베이스에서 어떤 이벤트가 발생했을 때 자동적으로 실행되는 프로시저
- ex) 데이터의 변경이 생겼을 때(INSER, UPDATE, DELETE), 이것이 계기가 되어 자동적으로 실행되는 프로시저

## 예제 1
- 사용자가 닉네임을 변경할 때 변경이력을 저장하는 프로시저를 작성하자.

```sql
delimiter $$
    CREATE TRIGGER log_user_nickname_trigger 
    BEFORE UPDATE 
    ON user FOR EACH ROW 
    BEGIN
        INSERT INTO users_log 
        VALUES (OLD.id, OLD.nickname, NOW());
    END 
$$
delimiter ;
```
- OLD
  - update 되기 전의 tuple을 가리킴
  - delete된 tuple을 가리킴

## 예제 2
- 사용자가 마트에서 상품을 구매할 때마다 지금까지 누적된 구매 비용을 구하는 트리거를 작성하자.

```sql
delimiter $$
    CREATE TRIGGER log_user_purchase_trigger 
    AFTER INSERT 
    ON purchase FOR EACH ROW 
    BEGIN
        UPDATE user 
        SET total_purchase_price = total_purchase_price + NEW.price 
        WHERE id = NEW.user_id;
    END
$$
```
- NEW
  - insert된 tuple을 가리킴
  - update된 후의 tuple을 가리킴

# trigger를 정의할 때 알고있으면 좋은 내용
- update, insert, delete 등을 한 번에 감지하도록 설정하는 것이 가능하다
  - MySQL은 이게 불가능하다.

Postgres의 예시를 보자.

```sql
CREATE TRIGGER avg_empl_salary_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON employee FOR EACH ROW 
    EXECUTE FUNCTION update_avg_empl_salary();
```

근데 번외로 위 트리거는 문제가 있다.

```sql
UPDATE employee SET salary = salary + 1000 WHERE dept_id = 1003;
```
이 쿼리로 employee의 tuple 5개가 변경되면 트리거가 5번 실행된다. 그럼 의미없이 4번 실행되므로 비효율적이다.

이를 아래처럼 수정하면 그런 비효율이 없어진다.

```sql
CREATE TRIGGER avg_empl_salary_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON employee FOR EACH STATEMENT
    EXECUTE FUNCTION update_avg_empl_salary();
```
1003 부서에 임직원이 5명이 있어도 트리거가 1번만 실행된다.

- row 단위가 아니라 statement 단위로 trigger가 실행될 수 있도록 할 수 있다.
  - MySQL은 FOR EACH STATEMENT를 사용할 수 없다.
  - 위 예시는 Postgres의 예시이다.
- trigger를 발생시킬 디테일한 조건을 지정할 수 있다.
  - MySQL은 불가능하다.

```sql
CREATE TRIGGER log_user_purchase_trigger
    BEFORE UPDATE 
    ON users FOR EACH ROW
    WHEN (NEW.nickname IS DISTINCT FROM OLD.nickname)
    EXECUTE FUNCTION log_user_nickname();
```
새 닉네임이 전 닉네임과 달랐을 때만 트리거가 작동하도록 디테일한 조건이 지정되어 있다.

# trigger 사용 시 주의사항
- 소스 코드로는 발견할 수 없는 로직이기 때문에 어떤 동작이 일어나는지 파악하기 어렵고 문제가 생겼을 때 대응하기 어렵다.
  - 함수나 프로시저는 소스 코드 상에서 호출하는 부분이 있어 그게 연결고리가 되어 그 함수나 프로시저의 코드를 보면 된다.
  - 트리거는 호출하는 부분이 없어 그 트리거와 관련된 것을 소스 코드상에서 어떤 것도 찾을 수 없다.
- 과도한 트리거 사용은 DB에 부담을 주고 응답을 느리게 만든다.
- 디버깅이 어렵다.
- 문서 정리가 특히나 중요하다.

# trigger에 대한 개인적인 견해
트리거는 최후의 카드로 남겨두는 것이 좋다..