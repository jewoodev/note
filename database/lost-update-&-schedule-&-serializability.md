# Lost update
계좌 A에서 B로 2만원을 이체하는 트랜잭션 T1과 계좌 B로 계좌 주인이 1만원을 입금하는 트랜잭션 T2가 동시에 실행될 때, T1이 계좌 B의 금액을 업데이트 하기 전에 T2에서 계좌 B의 잔액(=`20만원`)을 읽고 입금을 처리하는 경우, 입금된 금액이 잔액에 추가된 후(=`21만원`)에 T1의 업데이트가 수행(=`22만원`)되어, T2의 업데이트를 잃어버리는 현상이 발생한다. 이를 "Lost update"라고 한다.

# Operation
- Read
- Write
- Commit

데이터베이스 작업을 구성하는 작업 종류를 위와 같이 세 가지로 정의할 수 있는데, 이를 operation이라 부른다.

# Schedule
여러 transaction들이 동시에 실행될 때, 각 transaction에 속한 operation들의 실행 순서를 의미한다. 각 transaction 내의 operation들의 순서는 바뀌지 않는다.

## Serial schedule
일련의 transaction들이 순차적으로 실행되는 schedule을 의미한다. 즉, 한 transaction이 완료되기 전까지 다른 transaction은 실행되지 않는다.

### 성능
한 번에 하나의 transaction만 실행되기 때문에 좋은 성능을 낼 수 없고 현실적으로 사용할 수 없는 방식이다.

## Nonserial schedule
일련의 transaction들이 겹쳐서(interleaving) 실행되는 schedule을 의미한다.

### 성능
여러 transaction들이 겹쳐서 실행되기 때문에 동시성이 높아져 같은 시간동안 더 많은 transaction들을 처리할 수 있다.

## 고민거리 -> 연구 -> 발견
과거의 개발자들은 "성능 때문에 serial schedule은 사용할 수 없는데, 그렇다고 anomoly(이상 현상)이 발생하게 둘 수는 없다. 어떻게 해야 될까?" 라는 고민을 했다.

그래서 nonserial schedule로 실행해도 anomoly가 발생하지 않을 수 있는 방법을 연구하기 시작했다.

그 결과 "serial schedule과 동일한(equivalent) nonserial schedule을 실행하면 된다." 라는 아이디어를 떠올리게 된다. 그래서 "schedule이 동일하다." 의 의미가 무엇인지부터 정의하는 것이 필요하다고 판단했다. 이것을 정의하는 방법은 여러 가지가 만들어 졌지만 그 중 가장 널리 사용되는 방법이 뭔지 알아보자.

## Conflict
두 개의 operation 에 대해서 사용하는 개념이다. 두 operation이 아래의 세 가지 조건을 모두 만족할 때, 서로가 충돌(conflict)한다고 한다.

- 서로 다른 transaction 소속
- 같은 데이터에 접근
- 최소 하나는 write operation

conflict 종류로는 read-write conflict, write-write conflict 가 있다.

conflict operation은 순서가 바뀌면 결과도 바뀐다.

## Conflict equivalent & conflict serializable
Conflict라는 개념을 써서 schedule이 동일하다는 의미가 무엇인지 정의해보려고 한다.

Conflict equivalent 라는 개념은, 두 개의 스케줄이 아래의 두 조건을 만족하는 걸 말하는 개념이다.

1. 두 schedule은 같은 transaction들을 가진다.
2. 어떤(any) conflicting operation 의 순서도 양쪽 모두 동일하다.

Conflict equivalent한 schedule 중 하나가 serial schedule 이면, 즉 나머지 하나는 nonserial schedule 이면 conflict serializable 이라고 한다. 

Conflict serializable 하면 nonserial schedule로 실행해도 anomoly가 발생하지 않는다.

## 실전
실제로 이 이론을 활용해서 성능과 anomoly 회피를 모두 해낼 수 있을까? 트랜잭션이 동시에 요청되면 겹치는 트랜잭션들이 conflict serializable한지 확인해보며 겹쳐 연산하는 걸 허용하면 될 것이다. 하지만 이 방법은 사용되지 않는다. 아마 실제 DB 사용 케이스에서는 트랜잭션이 동시에 요청되는 빈도 수와 동시 요청 개수가 크기 때문에 그 수만큼의 트랜잭션을 conflict serializable한지 확인하는 것은 비용이 너무 들기 때문일 것 같다.

실제로는 여러 transaction을 동시에 실행해도 schedule이 conflict serializable하도록 보장하는 프로토콜을 사용한다. 즉, 동시에 실행될 때마다 conflict serializable한지 확인하는게 아니라 아예 conflict serializable한 schedule만 실행되도록 하는 프로토콜을 사용한다.

# 정리
Conflict equivalent, conflict serializable은 흔히 view equivalent, view serializable 이라는 용어로도 표현된다. 

그럼 어떤 schedule이 어떤 serial schedule과 conflict equivalent하다면 "conflict serializable 하다." 라고 말할 수 있다. 혹은 "conflict serializability의 속성을 가진다." 라고 말할 수 있다.

지금까지 'serializable' 이라는 개념을 살펴봤는데, schedule이 어떤 schedule이건 그 schedule을 serializable하게 만드는 역할을 수행하는게 concurrency control이다. 그리고 이것과 밀접하게 관련된 트랜잭션의 속성이 Isolation 이다.