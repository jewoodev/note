# CyclicBarrier로 동시성 테스트의 출발점 맞추기

두 사용자가 같은 데이터를 수정하면 어떤 일이 생길까? 먼저 저장한 변경을 나중 요청이 덮어쓰지 않으려면, 서버는 요청이 기준으로 삼은 데이터가 아직 유효한지 확인해야 한다. 이 동작을 테스트하려면 여러 수정 요청을 별도 작업으로 실행하고 결과를 확인해야 한다.

`CyclicBarrier`는 이때 여러 스레드를 정해진 지점에 모으는 Java 동기화 도구다. 이 글은 Kotlin으로 작성된 은행 정보 수정 테스트를 예로 들어 사용법과 검증 범위를 설명한다. 렌트카 업무나 원래 저장소의 구조를 몰라도 읽을 수 있도록 필요한 배경을 함께 설명한다.

## 1. 예제에서 검증하려는 업무 규칙

예제의 은행 정보는 다음 값을 가진 DB 레코드다. 계좌 잔액이나 송금은 다루지 않는다.

| 필드 | 의미 | 최초 예시 |
| --- | --- | --- |
| `id` | 레코드 식별자 | `100` |
| `name` | 은행 이름 | `예시은행` |
| `active` | 사용 여부 | `true` |
| `version` | 수정 기준이 되는 버전 번호 | `0` |

수정 요청은 변경할 값과 함께 `expectedVersion`을 보낸다. 이는 “나는 버전 0을 보고 이 수정을 요청한다”라는 뜻이다. 서버는 현재 버전이 요청의 기대 버전과 같을 때 변경을 허용하고, 변경이 반영되면 버전을 증가시킨다. 오래된 버전을 기준으로 한 요청은 버전 충돌로 거절한다.

두 요청이 모두 버전 0을 기준으로 서로 다른 이름을 저장하려 한다고 하자.

| 요청 | 변경할 이름 | 사용 여부 | 기대 버전 |
| --- | --- | --- | --- |
| A | `예시은행-1` | `false` | `0` |
| B | `예시은행-2` | `false` | `0` |

기대 결과는 **성공 하나, 버전 충돌 하나, 최종 버전 1**이다. 어떤 요청이 이기는지는 정하지 않는다.

## 2. CyclicBarrier의 개념

스레드는 작업을 실행하는 흐름이다. 스레드 두 개를 만들어도 실행 속도와 순서는 다를 수 있다. 먼저 준비된 작업을 잠시 기다리게 하여 두 작업 모두 특정 지점에 도착하게 만드는 것이 배리어의 역할이다.

```kotlin
import java.util.concurrent.CyclicBarrier
import java.util.concurrent.TimeUnit

val barrier = CyclicBarrier(2)

// 서로 다른 작업 스레드 두 개가 각각 호출한다.
barrier.await(10, TimeUnit.SECONDS)
// 두 작업이 모두 도착하면 이후 코드를 진행할 수 있다.
```

`2`는 해당 회차에 도착해야 하는 참여자 수다. 먼저 도착한 스레드는 기다리고, 마지막 참여자가 도착하면 대기가 풀린다. 정상 통과 후 같은 객체를 다음 회차에 다시 사용할 수 있어 이름에 `Cyclic`이 붙는다. 이 예제는 한 회차만 사용한다. 정상적인 반복 사용에 `reset()`은 필요하지 않다. [Java 17 CyclicBarrier API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CyclicBarrier.html)

```text
작업 A: 준비 ── await ───── 대기 ───┬── 수정 요청 A
작업 B: 준비 ─────────── await ────┴── 수정 요청 B
                                  모두 도착
테스트: 두 작업 제출 ─────────────── 결과 수집 ── DB 확인
```

대기가 풀린 뒤의 실제 실행 순서는 운영체제와 JVM의 스케줄링에 달려 있다. 이 그림의 합류 지점은 두 SQL이 같은 순간 실행된다는 뜻이 아니다.

## 3. 실제 테스트 읽기

다음 코드는 `BankPersistenceIT`의 동시 수정 테스트를 설명하기 위해 정리한 발췌다. Spring 설정과 클래스 선언은 생략했으므로 독립 실행 프로그램은 아니다.

- `commands.register`: 은행 정보를 등록하고 생성된 ID와 버전을 반환한다.
- `commands.update`: 수정 서비스를 호출한다. 버전이 맞지 않으면 `BankVersionConflictException`이 발생한다.
- `queries.findAll`: 저장된 은행 목록을 조회한다.
- `ids`: 테스트 후 삭제할 레코드 ID를 보관한다.

```kotlin
import java.util.concurrent.CyclicBarrier
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

val bank = commands.register(
    RegisterBankCommand("은행-${UUID.randomUUID()}")
).also { ids.add(it.id) }

val barrier = CyclicBarrier(2)
val executor = Executors.newFixedThreadPool(2)

try {
    // 먼저 두 작업을 모두 제출한다.
    val futures = (1..2).map { index ->
        executor.submit<Boolean> {
            barrier.await(10, TimeUnit.SECONDS)
            try {
                commands.update(
                    bank.id,
                    UpdateBankCommand(
                        "${bank.name}-$index",
                        false,
                        bank.version,
                    ),
                )
                true
            } catch (exception: BankVersionConflictException) {
                false
            }
        }
    }

    // 제출이 끝난 뒤 각 작업의 결과를 기다린다.
    val results = futures.map { it.get(15, TimeUnit.SECONDS) }

    assertEquals(1, results.count { it })
    val saved = queries.findAll().single { it.id == bank.id }
    assertEquals(1L, saved.version)
    assertFalse(saved.active)
    assertTrue(saved.name in listOf("${bank.name}-1", "${bank.name}-2"))
} finally {
    executor.shutdownNow()
}
```

### 작업을 실행하는 스레드와 결과를 기다리는 스레드

`newFixedThreadPool(2)`는 두 작업을 실행할 스레드 풀을 만든다. 테스트를 실행하는 스레드는 작업을 제출하고 결과를 기다린다. 배리어의 참여자는 작업 스레드 두 개이며, 테스트 스레드는 `await()`를 호출하지 않는다.

`submit<Boolean>`이 반환하는 `Future<Boolean>`은 나중에 얻을 작업 결과를 나타낸다. `get()`은 작업 완료를 기다려 결과를 꺼낸다. 작업에서 처리하지 않은 예외가 발생하면 `get()`에서 `ExecutionException`으로 전달되며 원인은 `cause`로 확인할 수 있다. [Java 17 Future API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Future.html)

### 두 map을 분리하는 이유

원래 코드는 `(1..2).map { submit(...) }.map { get(...) }` 형태다. 이 컬렉션 연산에서는 첫 번째 `map`이 두 작업의 제출을 끝낸 다음 두 번째 `map`이 결과를 기다린다.

다음처럼 바꾸면 첫 작업의 결과를 기다리는 동안 두 번째 작업을 제출하지 못한다.

```kotlin
// 잘못된 예: 첫 작업은 두 번째 참여자를 기다리는데,
// 테스트 스레드는 첫 작업의 완료를 기다리고 있다.
(1..2).map {
    executor.submit<Boolean> {
        barrier.await(10, TimeUnit.SECONDS)
        true
    }.get(15, TimeUnit.SECONDS)
}
```

`asSequence()`로 지연 평가하도록 바꾸는 경우에도 제출과 대기가 항목별로 이어질 수 있다. 이 패턴에서는 모든 작업을 제출하여 `List<Future<...>>`를 만든 후 결과를 수집하는 구조를 유지한다.

### 성공과 실패를 어떻게 판정하는가

`true`는 수정 호출이 정상 반환했다는 뜻이고, `false`는 정확히 `BankVersionConflictException`이 발생했다는 뜻이다. 동기화 실패나 DB 연결 오류까지 `false`로 처리하지 않는다. 따라서 결과 두 개를 정상 수집한 상태에서 성공 개수가 1이면 나머지 하나는 예상한 버전 충돌이다.

최종 DB 조회는 응답뿐 아니라 저장 결과도 확인한다. 이름이 두 후보 중 하나인지 검사하므로 실행 순서를 가정하지 않으며, 버전 1과 `active=false`를 통해 실제 변경 내용을 확인한다.

## 4. 데이터 충돌을 막는 것은 어디인가

이 예제에서 배리어는 `commands.update` **호출 전**에 있다. 실제 저장소 구현의 흐름은 다음과 같다.

1. `SELECT ... FOR UPDATE`로 대상 행을 읽으며 잠금을 얻는다.
2. 읽은 버전과 요청의 `expectedVersion`을 비교한다.
3. 버전이 다르면 `BankVersionConflictException`을 던진다.
4. 변경할 값이 있으면 기대 버전을 조건에 넣어 수정하고 버전을 증가시킨다.

핵심 SQL을 단순화하면 다음과 같다. `:이름`은 바인딩할 값을 표시한 의사 문법이다.

```sql
SELECT id, name, active, version
FROM banks
WHERE id = :id
FOR UPDATE;

UPDATE banks
SET name = :name,
    active = :active,
    version = version + 1
WHERE id = :id
  AND version = :expectedVersion;
```

현재 구현에는 버전 검사와 행 잠금이 함께 있다. 이를 설명할 때 버전 조건만 사용하는 구현이라고 단순화하면 안 된다.

예를 들어 A가 먼저 잠금을 얻어 변경을 커밋하면 버전은 1이 된다. B가 행 잠금을 얻어 읽었을 때 요청의 기대 버전 0과 현재 버전 1이 다르므로 충돌한다. B가 먼저 처리돼도 기대 결과는 같다.

이 테스트는 Spring 서비스와 MyBatis 저장소, Testcontainers의 MySQL을 연결한다. 테스트 클래스와 기반 클래스에는 테스트 전체를 감싸는 `@Transactional`이 없고, 수정 서비스에는 `@Transactional`이 있다. 작업 스레드에서 Spring 프록시를 통해 호출하는 수정은 각각 트랜잭션으로 처리되며, 정상 반환 시 커밋이 완료되는 구조다.

테스트 전체에 트랜잭션을 추가하면 준비 데이터의 가시성과 정리 방식이 달라질 수 있다. 테스트 스레드의 트랜잭션이 작업 스레드에도 공유된다고 가정해서는 안 된다.

## 5. 올바른 사용을 위한 점검 사항

### 참여자가 모두 실행될 수 있어야 한다

이 테스트처럼 동일한 고정 스레드 풀에서 모든 참여자를 실행한다면, 배리어에 도달할 작업 수만큼 실행 여력이 필요하다.

```kotlin
val barrier = CyclicBarrier(2)
val executor = Executors.newFixedThreadPool(1) // 이 구성에서는 부족하다.
```

첫 작업이 유일한 스레드를 차지하고 기다리면 두 번째 작업은 큐에서 나오지 못한다. 이 예제에서는 타임아웃으로 실패하며, 무제한 대기를 사용했다면 계속 기다릴 수 있다. 작업별로 별개의 `CyclicBarrier(2)`를 만들어도 서로 합류할 수 없다. 두 작업이 같은 배리어 객체를 사용해야 한다.

### 대기 시간의 의미를 구분한다

| 코드 | 제한하는 대기 |
| --- | --- |
| `barrier.await(10, SECONDS)` | 작업이 배리어에서 다른 참여자를 기다리는 시간 |
| `future.get(15, SECONDS)` | 호출자가 해당 작업의 결과를 기다리는 시간 |

두 값은 테스트에 정한 제한이며 보편적인 권장값은 아니다. CI의 실행 환경과 DB 응답 시간을 고려해 정한다. 각 `get()`에 주는 15초는 테스트 전체의 공통 마감 시간이 아니다. 전체 실행 시간을 제한하려면 별도의 전체 타임아웃이 필요하다.

또한 `get()`의 타임아웃은 작업을 자동 취소하지 않는다. 중단이 필요하면 취소와 실행기 종료를 별도로 다뤄야 한다. [Java 17 Future API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Future.html)

### 배리어의 실패를 업무 충돌로 세지 않는다

| 예외 | 의미 |
| --- | --- |
| `TimeoutException` | 배리어에서 정한 시간 안에 합류하지 못함 |
| `InterruptedException` | 대기 중인 스레드에 중단 요청이 전달됨 |
| `BrokenBarrierException` | 다른 참여자의 타임아웃·인터럽트 등으로 배리어가 깨짐 |

배리어 대기 실패는 해당 회차의 다른 대기자에게도 영향을 준다. 깨진 배리어를 복구 없이 계속 사용할 수는 없다. `reset()`은 대기자를 정상 진행시키는 수단이 아니며, 대기 중 호출하면 예외가 발생한다. 실패한 테스트를 숨기는 재시도보다 원인을 확인하고 다음 실행에 새 배리어를 사용하는 편이 명확하다. [Java 17 CyclicBarrier API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CyclicBarrier.html)

현재 테스트는 배리어 대기를 업무 예외를 처리하는 `try` 밖에 두며, 버전 충돌만 잡는다. 이 구분을 유지해야 `catch (Exception) { false }` 때문에 동기화 실패가 예상된 충돌로 집계되는 일을 막을 수 있다.

### 실행기 종료 요청과 종료 완료는 다르다

현재 테스트는 `finally`에서 `shutdownNow()`를 호출한다. 이는 실행 중인 작업의 중단을 시도하지만, 반환 시 모든 작업이 종료됐다는 보장은 없다. 종료 완료를 확인하려면 제한 시간을 둔 `awaitTermination()`을 사용하고 반환값을 확인해야 한다. 인터럽트를 직접 처리하고 전파하지 않는 정리 코드에서는 인터럽트 상태 복원도 고려한다. [Java 17 ExecutorService API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/ExecutorService.html)

정상 경로에서는 두 `Future`의 결과를 이미 받았으므로 수정 작업이 끝나 있다. 실패 경로에서는 작업이 남아 있을 수 있다. 이 경우 `@AfterEach`의 데이터 삭제와 수정이 겹칠 가능성을 고려해, 종료 확인 실패가 원래 테스트 오류를 가리지 않도록 정리 절차를 설계한다. 이는 현재 코드에 이미 구현된 기능이 아니라 추가 개선 시 확인할 사항이다.

### 배리어를 잠금 뒤로 무작정 옮기지 않는다

이 구현에서 “더 정확하게 맞추자”라며 행 잠금을 얻은 다음 배리어를 넣으면 문제가 생길 수 있다.

```text
A: 행 잠금 획득 → 배리어에서 B를 기다림
B: 같은 행 잠금을 기다림 → 배리어에 도달하지 못함
```

A는 B의 도착을 기다리고, B는 A의 잠금 해제를 기다린다. 스레드 두 개가 있다는 것만으로 충분하지 않다. 배리어 앞에서 확보하는 DB 연결과 잠금도 다른 참여자의 도착을 막을 수 있다.

## 6. 이 테스트가 보장하는 범위

이 테스트의 소스에서 확인되는 검증은 다음과 같다.

- 같은 초기 버전을 전달하는 수정 작업 두 개를 제출한다.
- 두 작업이 수정 호출 직전의 배리어에 합류한다.
- 결과가 성공 하나와 버전 충돌 하나인지 확인한다.
- 최종 저장 값과 버전이 기대한 상태인지 확인한다.

반면 두 트랜잭션이 실제로 겹쳤는지, 한쪽이 DB 잠금 대기를 경험했는지까지 직접 관찰하지는 않는다. 배리어를 통과한 뒤 A가 전부 끝나고 B가 실행돼도, B의 기대 버전은 여전히 0이므로 테스트는 성공할 수 있다.

따라서 이 결과만으로 모든 실행 순서에서의 안전성, 데드락 부재, 대규모 부하에서의 성능을 입증했다고 말할 수 없다. 특정 잠금 대기나 실행 순서를 검증하려면 해당 사건을 관찰하거나 제어하는 별도 테스트가 필요하다. 이때도 앞 절의 잠금과 배리어 사이 대기 관계를 먼저 검토해야 한다.

## 7. 다른 대기 수단과의 선택

| 수단 | 쓰기 좋은 상황 | 이 예제에서의 판단 |
| --- | --- | --- |
| `CyclicBarrier` | 정해진 참여자들이 같은 지점에 합류 | 두 작업이 서로 준비를 기다리는 목적에 맞음 |
| `CountDownLatch` | 완료·준비 신호가 정해진 횟수만큼 올 때까지 대기 | 테스트 스레드가 준비 완료를 확인하고 출발 신호를 줄 때 사용 가능 |
| `Future.get()` | 개별 작업의 완료와 결과 수집 | 배리어 통과 후 수정 결과를 기다리는 데 필요 |
| `Thread.sleep()` | 일정 시간 실행을 늦춤 | 상대 작업의 준비 여부를 확인할 수 없어 합류 조건을 대체하지 못함 |

`CountDownLatch`는 `countDown()`으로 횟수를 줄이고 `await()`로 0이 되기를 기다린다. 카운트를 줄이는 쪽이 반드시 기다릴 필요는 없고, 한 번 0이 되면 재설정할 수 없다. 준비 확인용 `CountDownLatch(2)`와 출발 신호용 `CountDownLatch(1)`을 나누면 테스트 스레드가 출발 시점을 제어하는 구조도 만들 수 있다. [Java 17 CountDownLatch API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CountDownLatch.html)

## 8. 근거와 확인 범위

작성 기준일은 2026-09-22다. 설명은 당시 작업 트리의 아래 파일과 Java 17 공식 API 문서를 확인해 작성했다. 저장소를 옮겨도 본문을 읽을 수 있도록 파일 경로는 출처 식별용으로만 남긴다.

| 원본 저장소 내 경로 | 확인한 내용 |
| --- | --- |
| `backend/src/test/kotlin/com/icar/erp/bank/adapter/out/persistence/BankPersistenceIT.kt` | 배리어, 작업 제출·결과 수집, 검증, 정리 |
| `backend/src/main/kotlin/com/icar/erp/bank/application/service/BankCommandService.kt` | 수정 서비스의 트랜잭션 경계 |
| `backend/src/main/kotlin/com/icar/erp/bank/adapter/out/persistence/repository/MyBatisBankRepository.kt` | 잠금 조회 후 버전 검사와 수정 |
| `backend/src/main/resources/mybatis/BankMapper.xml` | `FOR UPDATE`, 버전 조건, 버전 증가 SQL |
| `backend/src/test/kotlin/com/icar/erp/testsupport/MySqlITBase.kt` | Spring과 실제 MySQL 테스트 환경 |
| `backend/build.gradle.kts` | JVM 도구 체인 17 |

확인 당시 테스트 파일에는 `import java.util.concurrent.`라는 불완전한 import가 있었다. 본문의 예제에는 의도된 `import java.util.concurrent.CyclicBarrier`를 명시했으며 원본 코드는 수정하지 않았다. 이 문서는 소스 분석을 바탕으로 작성했고, 해당 테스트를 실행해 통과를 확인한 보고서는 아니다.
