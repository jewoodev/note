lock을 이용한 concurrency control은 read-lock만이 존재할 때 동시 작업이 가능하기에 성능적으로 좋지 않다. MVCC는 그런 성능 저하에 대한 문제를 해결하기 위해 고안되었다. read-lock -> write-lock이나 write-lock -> read-lock 순서로 락 취득 시도가 있을 때 block 되지 않고 동시에 작업이 가능하도록 한다.

# 작동 방식
작동 방식을 이해하기 위해 MVCC가 작동하는 순서를 살펴보자. `x=1` 이라는 데이터가 저장되어 있다고 가정하자.

1. tx1 이 write-lock을 취득한 후, 자신만이 볼 수 있는 공간에 `x=3`라고 write 한다.
2. tx2가 read-lock을 취득한 후, `x=1`을 읽는다.
    1. MVCC는 commit 된 데이터만 읽는다.
3. tx1 가 commit을 수행한다.
   1. x에 대한 write-lock을 unlock한다.
   2. 커밋한 후에 unlock 하는 이유는 recoverability를 위해서다.
4. tx2가 x를 다시 한 번 읽는다.
   1. isolation level이 READ COMMITTED이면 3을, REPEATABLE READ이면 1을 읽게 된다.

# MVCC 특징
- MVCC는 데이터를 읽을 때 **특정 시점 기준**으로 가장 최근에 **commit된 데이터**를 읽는다.
  - MySQL에서는 이 읽는 방식을 **consistent read**라고 부른다.
- 데이터 변화(write) 이력을 관리한다.
  - 이 이력을 데이터베이스가 내부적으로 관리해야 하기에 저장 공간을 더 많이 사용한다.
- read와 write는 서로를 block 하지 않는다.

## serializable
해당 isolation level로 동작할 때 

- MySQL
  - MVCC가 아닌 lock으로 동작한다.
- PostgreSQL
  - SSI(Serializable Snapshot Isolation) 기법이 적용된 MVCC로 동작한다.

## read uncommitted
MVCC는 commit 된 데이터를 읽기 때문에 이 level에서는 보통 MVCC가 적용되지 않는다. 

- MySQL
  - MVCC가 적용되는 level에 이 level이 없음.
- PostgreSQL
  - 이 level이 있으나 read committed와 동일하게 동작함.

## repeatable read
'트랜잭션이 시작하는 시점'을 기준으로 데이터를 읽는다.

- MySQL
  - 어떤 update만 받아들이는 방식이 아니라 lost update 혹은 write skew가 발생한다.
  - 이를 해결하려면 데이터 조회 시 추가적으로 lock을 줄 수 있도록 해야 한다.
    - MySQL에서는 이를 Locking read라고 부른다.
      - MySQL에서 Locking read는 가장 최근에 'commit된 데이터'를 읽는다.
    - `SELECT ...` 와 같은 쿼리에 `FOR UPDATE`를 추가하여 이를 해낼 수 있다.
      - `FOR SHARE`를 추가해서도 locking read를 해낼 수 있다.
      - `FOR UPDATE`는 exclusive lock(read-lock), `FOR SHARE`는 shared lock(read-lock)이다.
- PostgreSQL
    - 같은 데이터에 먼저 update한 tx가 commit되면 나중 tx은 rollback된다. (= first update win)
    - Locking read를 하더라도 동일하게 먼저 update한 tx가 commit되면 나중 tx은 rollback된다.
      - 이는 `FOR UPDATE`, `FOR SHARE` 모두 동일하다.

## serializable
- MySQL
  - repeatable read와 유사.
  - tx의 모든 평범한 select 문은 암묵적으로 `SELECT ... FOR SHARE` 처럼 동작.
    - 이 때문에 MVCC가 아닌 lock으로 동작한다고 개발자들이 표현하곤 한다.
    - `FOR UPDATE`가 아닌 `FOR SHARE`로 동작하기에 성능 이점이 있다. (장점)
    - 대신 `FOR UPDATE`보다 데드락이 발생할 확률이 더 훨씬 높다. (단점)
  - 이런 방식은 SS2PL로 동작하는 것처럼 보인다.
- PostgreSQL
  - SSI(Serializable Snapshot Isolation) 기법이 적용된 MVCC로 동작한다.
  - first-committer-winner


