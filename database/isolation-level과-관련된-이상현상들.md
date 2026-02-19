# ANSI/ISO standard SQL 92에서 정의한 isolation level
1992년 11월에 발표된 SQL 표준에서 정의된 내용
## 이상 현상
### Dirty read
commit되지 않은 변화를 읽었을 때 발생하는 이상 현상

commit되지 않은 변화는 rollback 될 수 있는데, 만약 정말 롤백이 되었다면 그 변화는 '정상적이지 않은 값'이 된다. 그래서 '정상적이지 않은 값'을 읽은 트랜잭션이 있다면, 그 트랜잭션이 만들어내는 값도 '정상적이지 않은 값'이 될 가능성이 생기는 것이다.

### Non-repeatable read
같은 데이터의 값이 달라지는 이상 현상

트랜잭션 A가 x를 두 번 읽는 트랜잭션이고, 트랜잭션 B가 x에 40을 더하는 트랜잭션일 때, 두 트랜잭션의 순서가 겹쳐 A가 한 번 읽고난 후 B가 40을 더하면 A가 두 번째 읽을 때 x값이 다른 값이 된다. 이렇듯 하나의 트랜잭션에서 값을 변경하지 않았는데 값이 달라지는 현상을 말한다. 여러 트랜잭션이 동시에 실행되도 마치 하나의 트랜잭션만 실행되는 것처럼 보여야 한다는 트랜잭션의 Isolation 속성을 충족시키지 않는 케이스이다.

### Phantom read
같은 조건으로 여러 차례 조회하는 트랜잭션에 없던 데이터가 생기는 이상 현상

트랜잭션 A가 `(x = 10)` 조건으로 데이터를 두 번 조회하는 트랜잭션이고, 트랜잭션 B가 `(x = 10)` 인 새로운 튜플을 추가(삽입, 수정 모두로 발생 가능함)하는 트랜잭션일 때, A가 한 번 읽고난 후 B가 새로운 튜플을 추가하면 A가 두 번째 읽을 때 x에 새로운 튜플이 추가된 결과가 나타나는 현상을 말한다.

## Isolation level

| Isolation level  | Dirty read | Non-repeatable read | Phantom read |
|------------------|------------|---------------------|--------------|
| Read uncommitted | O          | O                   | O            |
| Read committed   | X          | O                   | O            |
| Repeatable read  | X          | X                   | O            |
| Serializable     | X          | X                   | X            |

이 중에서도 serializable은 세 가지 이상 현상뿐만 아니라 아예 이상 현상 자체가 발생하지 않는 level을 의미한다.

# ANSI/ISO standard SQL 92에서 정의한 isolation level을 비판하는 논문
이 논문은 다음과 같은 비판들을 담고 있다.

1. 세 가지 이상 현상의 정의가 모호하다.
2. 이상 현상은 세 가지 이외에도 더 있다.
3. 상업적인 DBMS에서 사용하는 방법을 반영해서 isolation level을 구분하지 않았다.

## 이상 현상
### Dirty write
commit이 되지 않은 데이터를 write 한 경우에 발생하는 이상 현상

rollback 시 정상적인 recovery는 매우 중요하기 때문에 모든 isolation level에서 dirty write를 허용해선 안 된다.

### Lost update
업데이트를 덮어쓰는 경우에 발생하는 이상 현상

어떤 트랜잭션이 이미 다른 트랜잭션에서 변경되버린 데이터를 덮어쓰는 경우로, 다른 트랜잭션이 커밋한 작업이 아예 사라져버린다.

### Dirty read
commit되지 않은 변화를 읽었을 때 발생하는 이상 현상

commit되지 않은 변화는 rollback 될 수 있는데, 롤백이 되지 않아도 Dirty read는 발생할 수 있다.

### Read skew
inconsistent한 데이터 읽기가 발생하는 이상 현상

Dirty read가 발생할 때 나타난다. Non-repeatable read와 흡사하지만 같은 데이터를 연속으로 조회할 때 발생하는 것이 아니라는 차이가 있다.

### Write skew
inconsistent한 데이터 쓰기가 발생하는 이상 현상

계좌의 잔액이 음수가 되는 것은 허용되나, 한 사람의 계좌 총 잔액은 0보다 커야 한다는 조건이 있을 때, 두 트랜잭션이 동시에 출금 처리를 하며 각각이 커밋되기 전의 잔액을 읽어 결국 총 잔액이 음수가 되는 경우가 그 예이다.

### Phantom read
같은 조건이 아니라도 여러 차례 조회하는 트랜잭션에 없던 데이터가 생기는 이상 현상

같은 조건으로 데이터를 조회하지 않더라도 하나 이상의 트랜잭션이 서로 연관있는 데이터를 다룬다면, 어떤 트랜잭션이 데이터를 추가하는 작업을 포함한다면 이상 현상이 생길 수 있다. 

## SNAPSHOT ISOLATION
MVCC의 한 종류로 동시에 실행된 트랜잭션은 각각 트랜잭션이 시작된 시점을 기준으로 핸들링하는 테이블의 스냅샷을 만들어 그걸 대상으로 작업을 처리한다. 만약 write-write conflict가 발생하면, 먼저 commit된 트랜잭션의 변경만 받아들이고 나머지는 폐기 처분한다. 그로 인해 나중의 write operation을 가진 트랜잭션의 스냅샷 또한 폐기 처분되어진다.

이는 다음과 같은 특징이 있다.

- 'tx 시작 전에 commit된 데이터만'만 보임
- First-committer win

표준 SQL에서 정의한 serializable level이 오라클에서는 SNAPSHOT ISOLATION 방식으로 동작한다고 보면 된다. 그리고 POSTGRES에서는 REPEATABLE READ로 동작한다.
