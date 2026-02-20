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

> MySQL과 PostgreSQL은 repeatable read level에서 phantom read를 발생시키지 않는다.
> 
> 즉, 두 벤더는 표준보다 더 엄격한 repeatable read를 구현하고 있다.

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

---

# Isolation level은 MVCC의 결과인가? 아님 독립적인가?
## 격리 수준은 "무엇을 보장할지"의 계약
- Isolation level은 "Dirty read는 허용/금지", "Non-repeatable read는 허용/금지", "Phantom은 허용/금지" 같은 현상 관점의 계약.
- MVCC는 그 계약을 지키기 위한 구현 전략 중 하나. 

## 구현 관점에서 Repeatable Read가 '스냅샷'처럼 보인다?
MVCC 기반 DB에서는 보통 '읽기 작업'이 락을 최소화하면서도 일관성을 유지해야 하므로, 트랜잭션만 볼 수 있는 **버전 집합**(스냅샷)을 정해두고 그 스냅샷에 맞는 버전을 골라 읽는다.

그래서 Repeatable Read는 자연스럽게 **트랜잭션 스냅샷을 고정해서 읽기**로 구현되는 경우가 많다.

## MVCC 없이도 Repeatable Read는 가능
락 기반(예: 2PL) 구현이라면, 트랜잭션이 읽은 레코드(또는 범위)를 공유락/범위락으로 잡고 끝까지 유지하는 방식으로 같은 행을 다시 읽을 때 값이 바뀌지 않게 만들 수 있다.

다만 이 경우엔 "스냅샷을 본다"기보다는 "변경을 못 하게 막아" repeatable하게 만드는 셈이다.

## Isolation level 마다 데이터를 읽는 기준
여기서의 "기준"은 보통 스냅샷 기준(언제의 버전을 보나) + **락/검증 기준**(남이 바꾸는 걸 막거나, 충돌을 감지해 롤백시키나)로 나눠 보면 깔끔하다.

### 한눈에 보는 요약(일반적인 MVCC 계열에서 흔한 형태)
| Isolation Level       | 읽는 기준(스냅샷)                                  | 보통 막는 것                         | 여전히 가능한/제품별 차이                                          |
|-----------------------|---------------------------------------------|---------------------------------|---------------------------------------------------------|
| Read Uncommitted (RU) | "지금 보이는 것" (미커밋도 볼 수 있음)                    | 거의 없음                           | Dirty read 가능                                           |
| Read Committed (RC)   | 각 SQL 문(statement) 시작 시점 스냅샷인 경우가 흔함        | Dirty read 방지                   | 같은 SELECT를 다시 하면 결과가 바뀔 수 있음(non-repeatable/phantom 가능) |
| Repeatable Read (RR)  | 트랜잭션 단위 스냅샷(또는 “첫 consistent read 시점부터 고정”) | Non-repeatable read 방지          | Phantom은 구현에 따라 남을 수도/막힐 수도                             |
| Serializable (SER)    | "직렬 실행과 동일"을 목표                             | Phantom 포함 전반 차단(또는 충돌 시 한쪽 롤백) | 동시성↓, 롤백/재시도↑                                           |

핵심: RC는 보통 ‘문장마다 최신 커밋을 반영’, **RR은 보통 ‘트랜잭션 동안 동일한 과거 시점 유지’**로 이해하면 된다(단, 제품별 예외는 아래 참고).

### 제품별로 "스냅샷 시점"이 실제로 다름 
같은 “Repeatable Read”라도 DB마다 "스냅샷 시점" 달라질 수 있다.

- **PostgreSQL (대표적인 MVCC)**
  - READ COMMITTED: 매 statement마다 새 스냅샷 → 같은 쿼 반복 시 값이 바뀔 수 있음.
  - REPEATABLE READ: 트랜잭션 시작 시점 스냅샷 고정.
  - SERIALIZABLE: 스냅샷 + 충돌 감지(SSI)로 “직렬과 같은 결과”를 강제(충돌 나면 한쪽이 실패하고 재시도 필요).
- **MySQL InnoDB (MVCC + 락이 섞여 복잡)**
  - READ COMMITTED: 대체로 statement 기준 최신 커밋을 더 잘 반영.
  - REPEATABLE READ: “일관 읽기(consistent read)”는 보통 **트랜잭션에서 처음 읽기 시점에 스냅샷이 잡히고 유지**되는 식으로 동작하는 경우가 많다(트랜잭션 start 즉시라기보다 ‘첫 consistent read’에 가깝게 체감될 때가 있음).
  - 또한 InnoDB는 **잠금 읽기(SELECT … FOR UPDATE / LOCK IN SHARE MODE)** 같은 “current read”는 스냅샷이 아니라 **현재 최신 레코드 + 락**으로 동작합니다. 그래서 “RR인데 왜 최신 값이 보이지?” / “RR인데 왜 팬텀이 막히지?” 같은 질문이 여기서 자주 나옵니다.
       
DB가 스냅샷을 언제 채택하는지 + 어떤 읽기(스냅샷 읽기 vs 락 읽기)인지까지 같이 봐야 한다.

## 정리 
- **RC**: 대개 statement 시작 시점 스냅샷(매 쿼마다 최신 커밋 반영)
- **RR**: 대개 트랜잭션 단위 스냅샷(또는 첫 consistent read부터 고정)
- **SER**: 스냅샷만으로 부족한 부분(특히 phantom/쓰기 충돌)을 락이나 충돌 감지로 추가 보완해서 “직렬 실행과 동일”을 만들려고 함 
- **RU**: (지원하는 DB라면) 미커밋도 읽을 수 있음