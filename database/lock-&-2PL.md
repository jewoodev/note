# write-lock(exclusive lock)
- read/write(insert, modify, delete) 할 때 사용한다.
- 다른 tx가 같은 데이터를 read/write 하는 것을 허용하지 않는다.

# read-lock(shared lock)
- read 할 때 사용한다.
- 다른 tx가 같은 데이터를 read 하는 것은 허용한다.
  - write 하는 것은 허용하지 않는다.

# 2PL (Two Phase Locking) protocol
- tx에서 모든 locking operation이 최초의 unlock operation보다 먼저 수행되도록 하는 프로토콜
- serializability를 보장한다.

## Expanding phase(growing phase)
- lock을 취득만 하고 반환하지는 않는 phase

## Shrinking phase(contracting phase)
- lock을 반환만 하고 취득하지는 않는 phase

## conservative 2PL
- 모든 lock을 취득한 뒤 transaction을 시작.
- deadlock-free.
- 실용적이지는 않다.
  - 모든 lock을 취득하는 게 어려울 수 있기 때문에 transaction을 시작하기 어려워진다.

## strict 2PL(S2PL)
- strict schedule을 보장하는 2PL.
  - strict schedule: rollback을 했을 때 이상 현상이 발생하지 않도록 하기 위해 권장되는 스케줄 중 가장 엄격한 스케줄.
    - 어떤 데이터를 write 하는 트랜잭션이 있다면 그 트랜잭션이 commit/rollback이 되기 전까지는 다른 트랜잭션이 그 데이터를 read/write 하지 않는 스케줄.
- **recoverability** 보장.
- write-lock을 commit/rollback 할 때 반환.

## strong strict 2PL(SS2PL or rigorous 2PL)
- strict schedule을 보장하는 2PL.
- **recoverability** 보장.
- read-lock or write-lock을 commit/rollback 할 때 반환.
- S2PL보다 구현이 쉽다.
