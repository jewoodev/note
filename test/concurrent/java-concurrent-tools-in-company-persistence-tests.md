# 동시성 테스트에서 사용하는 CountDownLatch, Executors, TimeUnit

여러 사용자가 같은 정보를 동시에 저장할 때, 시스템은 중복 저장과 변경 덮어쓰기를 막아야 한다. 이를 테스트하려면 작업을 여러 실행 흐름에 맡기고, 출발 조건을 맞춘 뒤, 각각의 결과를 확인해야 한다.

이 글은 Kotlin의 회사 정보 저장 테스트를 예로 들어 `java.util.concurrent`의 세 도구를 설명한다. 회사는 이름과 유형을 가진 일반적인 DB 레코드이며, 렌트카 업무 지식은 필요하지 않다. 원래 저장소 없이도 읽을 수 있도록 용어와 코드를 함께 설명한다.

| 도구 | 개념 | 예제에서 맡는 역할 |
| --- | --- | --- |
| `CountDownLatch` | 정해진 횟수의 신호가 쌓일 때까지 기다리는 동기화 도구 | 작업 두 개의 준비 확인, 출발 신호 전달 |
| `Executors` | 작업 실행기를 만드는 팩터리·유틸리티 클래스 | 작업을 실행할 고정 크기 스레드 풀 생성 |
| `TimeUnit` | 초·밀리초 같은 시간 단위를 표현하는 열거형 | 준비와 결과를 기다릴 시간의 단위 지정 |

세 도구는 역할이 다르다. `TimeUnit` 자체가 작업을 실행하거나 데이터 충돌을 막아 주지는 않는다.

## 1. 먼저 알아둘 실행 구조

**스레드**는 코드를 실행하는 흐름이다. 이 예제에는 테스트를 진행하는 스레드 하나와, DB 작업을 실행하는 작업 스레드 두 개가 등장한다.

**작업**은 스레드에 맡길 코드다. 작업 하나가 스레드 하나와 영구적으로 연결되는 것은 아니다. **스레드 풀**은 여러 작업에 재사용할 실행 스레드를 관리한다.

**Future**는 제출한 작업의 완료 여부와 결과를 확인하는 객체다. `Future.get()`으로 결과를 기다릴 수 있다. 반면 Kotlin의 **Result**는 이미 수행한 코드의 성공 값 또는 예외를 담는다. 이 테스트에서는 `Future<Result<CompanySnapshot>>` 형태로 두 개를 함께 사용한다.

`CompanySnapshot`은 저장된 회사 정보와 버전을 담은 값이다. 이후 예제에서는 “저장 결과”라고 이해하면 된다.

## 2. CountDownLatch: 신호가 정해진 횟수만큼 올 때까지 기다린다

```kotlin
import java.util.concurrent.CountDownLatch

val ready = CountDownLatch(2)
val start = CountDownLatch(1)
```

초깃값은 스레드 수를 등록하는 값이 아니라 **필요한 `countDown()` 호출 횟수**다. 같은 스레드가 두 번 호출해도 두 번 줄어든다. 따라서 누가 어떤 사건에 대해 신호를 한 번 보낼지 정해야 한다.

- `countDown()`: 카운트를 1 줄인다. 호출자는 다른 신호를 기다리지 않는다.
- `await()`: 카운트가 0이 될 때까지 기다린다.
- `await(timeout, unit)`: 제한 시간 안에 0이 되면 `true`, 그렇지 않으면 `false`를 반환한다.
- 0이 된 래치는 이후에도 열린 상태이며 재설정할 수 없다. 새 회차에는 새 객체를 만든다.

대기 중 인터럽트를 받으면 `InterruptedException`이 발생한다. 한 대기자의 타임아웃은 래치를 깨뜨리지 않는다. [Java 17 CountDownLatch API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CountDownLatch.html)

### ready와 start를 나누는 이유

| 래치 | 신호를 보내는 쪽 | 기다리는 쪽 | 0의 의미 |
| --- | --- | --- | --- |
| `ready = CountDownLatch(2)` | 각 작업이 한 번씩 `countDown()` | 테스트 스레드 | 두 작업이 준비 신호를 보냄 |
| `start = CountDownLatch(1)` | 테스트 스레드가 한 번 `countDown()` | 두 작업 | 수정·등록을 시작해도 됨 |

작업의 앞부분은 다음과 같다.

```kotlin
ready.countDown()
start.await()
// 이제 DB 작업을 수행한다.
```

테스트 스레드는 다음 순서로 진행한다.

```kotlin
assertTrue(ready.await(5, TimeUnit.SECONDS))
start.countDown()
```

준비 확인 없이 출발 신호부터 주면 한 작업이 늦게 시작할 수 있다. 반대로 출발 신호를 주기 전에 작업 결과를 기다리면 작업들은 출발을 기다리고 테스트는 완료를 기다리는 구조가 된다.

```text
테스트: 두 작업 제출 → ready가 0인지 확인 → start를 0으로 → 결과 수집
작업 A:               ready 신호 → start 대기 ─────────→ DB 작업 A
작업 B:               ready 신호 → start 대기 ─────────→ DB 작업 B
```

`ready`가 0이라는 것은 두 작업이 `ready.countDown()`을 실행했다는 뜻이다. 둘 다 실제로 `start.await()` 안에서 멈췄다는 뜻은 아니다. 한 작업이 준비 신호 직후 잠시 멈추더라도, 이미 열린 `start`에 나중에 도착하면 통과한다. 출발 신호가 먼저 왔다고 신호를 놓치지는 않는다.

### 올바른 신호 위치

이 테스트의 준비는 “작업 코드가 시작되어 출발 신호를 기다릴 수 있는 상태”다. DB 연결 확보나 트랜잭션 시작을 확인하는 신호는 아니다.

준비 성공을 뜻하는 `ready.countDown()`을 무조건 `finally`에 넣으면, 준비에 실패했는데도 준비가 끝난 것으로 읽힐 수 있다. 반면 성공 여부와 관계없이 작업 종료 횟수를 세는 별도의 완료 래치라면 `finally`에서 신호를 보내는 방식이 적합할 수 있다. 신호 이름과 실제 의미를 먼저 맞춘다.

`CyclicBarrier`가 참여자끼리 같은 지점에 합류하는 구조라면, 이 예제는 준비 신호를 모은 테스트 스레드가 별도로 출발을 허용하는 구조다. 두 래치는 한 테스트 실행에 한 번씩 사용한다.

## 3. Executors: 작업을 실행할 스레드 풀을 만든다

```kotlin
import java.util.concurrent.Executors

val executor = Executors.newFixedThreadPool(2)
```

`Executors`는 실행기를 만드는 클래스다. 반환된 `executor`는 `ExecutorService`이며, 여기에 작업을 제출하고 나중에 종료를 요청한다.

`newFixedThreadPool(2)`는 최대 두 작업을 동시에 실행할 수 있는 고정 크기 풀을 만든다. 실행 여력이 없으면 제출된 작업은 큐에서 기다린다. 이 팩터리는 크기 제한이 없는 대기 큐를 사용하므로, 운영 코드에서 작업을 무제한 제출해도 안전하다고 일반화해서는 안 된다. 이 테스트는 두 작업만 제출한다. [Java 17 Executors API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Executors.html)

### submit과 Future

```kotlin
val future = executor.submit<String> {
    "작업 결과"
}
val value = future.get(10, TimeUnit.SECONDS)
```

`submit`은 결과를 반환하는 작업을 맡기고 `Future`를 돌려준다. `get()`은 필요하면 기다린 뒤 결과를 꺼낸다. 작업에서 처리하지 않은 예외는 `get()`에서 `ExecutionException`으로 전달되며, 원인은 `cause`로 확인한다. [Java 17 Future API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Future.html)

### 이 패턴에는 작업 두 개가 모두 실행될 여력이 필요하다

다음 조합은 올바르지 않다.

```kotlin
val ready = CountDownLatch(2)
val start = CountDownLatch(1)
val executor = Executors.newFixedThreadPool(1) // 이 테스트 구조에서는 부족하다.
```

첫 작업이 유일한 스레드를 차지한 채 `start`를 기다린다. 두 번째 작업은 큐에 남아 `ready` 신호를 보내지 못한다. 테스트는 준비 완료를 확인할 수 없어 타임아웃으로 실패한다.

또한 모든 작업을 제출한 다음 준비를 확인하고 출발 신호를 줘야 한다. 첫 작업을 제출하자마자 `get()`으로 결과를 기다리면 두 번째 작업 제출과 출발 신호 전달에 도달하지 못한다.

### 작업이 끝나면 실행기도 정리한다

원래 테스트는 `finally`에서 `executor.shutdownNow()`를 호출한다. 이 위치 덕분에 단언문이 실패해도 종료를 요청한다.

| 메서드 | 의미 |
| --- | --- |
| `shutdown()` | 새 제출을 거부하고 이미 제출된 작업은 진행하도록 함 |
| `shutdownNow()` | 대기 작업의 실행을 막고 실행 중인 작업의 중단을 시도함 |
| `awaitTermination(timeout, unit)` | 종료 요청 후 실제 종료를 기다리고 완료 여부를 반환함 |

`shutdownNow()`는 강제 종료 완료를 보장하지 않는다. DB 호출이 인터럽트에 즉시 반응하지 않을 수도 있다. 종료 확인을 추가한다면 `awaitTermination()`의 반환값도 검사해야 한다. 인터럽트를 직접 잡고 상위로 전파하지 않는 정리 코드에서는 `Thread.currentThread().interrupt()`로 상태를 복원하는 방식이 필요하다. [Java 17 ExecutorService API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/ExecutorService.html)

이는 원래 코드에 종료 확인까지 구현되어 있다는 뜻은 아니다. 현재 코드는 종료 요청만 수행한다. 실패 후 남은 DB 작업이 다음 테스트의 데이터 삭제와 겹치지 않도록 강화할 때 검토할 부분이다.

## 4. TimeUnit: 시간의 단위를 명시한다

```kotlin
import java.util.concurrent.TimeUnit

ready.await(5, TimeUnit.SECONDS)
future.get(10, TimeUnit.SECONDS)
```

`TimeUnit`은 시간 단위를 나타내는 열거형이다. 위의 `5`와 `10`이 초라는 뜻을 코드에 명시한다. `MILLISECONDS`, `MICROSECONDS`, `NANOSECONDS`, `MINUTES` 등도 제공한다.

단위 변환에도 쓸 수 있다.

```kotlin
val milliseconds = TimeUnit.SECONDS.toMillis(2)       // 2000L
val wholeSeconds = TimeUnit.MILLISECONDS.toSeconds(1500) // 1L
```

큰 단위로 변환하면 소수 부분이 버려질 수 있다. `SECONDS.sleep(1)` 같은 편의 기능도 있지만, 잠시 쉬는 것과 상대 작업의 준비를 확인하는 것은 별개다. [Java 17 TimeUnit API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/TimeUnit.html)

### 같은 단위여도 기다리는 사건과 실패 방식은 다르다

| 표현 | 기다리는 사건 | 시간이 지나면 |
| --- | --- | --- |
| `ready.await(5, SECONDS)` | 준비 신호 두 번 | `false` 반환 |
| `start.await()` | 출발 신호 한 번 | 시간 제한 없음; 인터럽트로 대기 종료 가능 |
| `future.get(10, SECONDS)` | 해당 작업 완료 | `TimeoutException` 발생 |

`TimeUnit`은 단위를 제공하고, 타임아웃 동작은 호출 대상 API가 결정한다. 따라서 `ready.await(...)`의 반환값을 무시하면 준비가 안 됐는데도 출발할 수 있다. 현재 테스트가 `assertTrue(...)`로 감싸는 이유다. [CountDownLatch API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/CountDownLatch.html), [Future API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Future.html)

5초와 10초는 이 테스트가 선택한 대기 한도다. 작업이 반드시 그 시간 동안 실행되거나, CPU 스케줄링 지연까지 포함해 그 시각에 정확히 반환한다는 보장은 아니다. `get(10, ...)`을 여러 번 호출해도 전체 테스트의 공통 마감 시간이 생기지는 않는다.

`Future.get()`의 타임아웃은 작업을 자동으로 취소하지 않는다. 결과 대기 중단과 작업 중단은 분리해서 다뤄야 한다. [Java 17 Future API](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/Future.html)

## 5. 세 도구를 함께 사용하는 실제 패턴

다음은 원래 테스트의 동시 이름 변경 부분을 설명용으로 정리한 코드다. 저장소 객체, 회사 생성 함수, JUnit 단언문은 테스트 환경에서 제공되므로 독립 실행 프로그램은 아니다.

```kotlin
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

val created = create(CompanyType.RENTAL_OPERATOR, "동시수정법인")
val ready = CountDownLatch(2)
val start = CountDownLatch(1)
val executor = Executors.newFixedThreadPool(2)

try {
    // 첫 번째 map에서 두 작업을 모두 제출한다.
    val futures = listOf("첫 변경", "두번째 변경").map { name ->
        executor.submit<Result<CompanySnapshot>> {
            ready.countDown()
            start.await()
            runCatching {
                requireNotNull(
                    commandRepository.update(
                        requireNotNull(created.id),
                        CompanyVersion(0),
                    ) { it.rename(name) },
                )
            }
        }
    }

    assertTrue(ready.await(5, TimeUnit.SECONDS))
    start.countDown()

    val outcomes = futures.map { it.get(10, TimeUnit.SECONDS) }
    assertEquals(1, outcomes.count(Result<CompanySnapshot>::isSuccess))
    assertEquals(
        1,
        outcomes.count { it.exceptionOrNull() is CompanyVersionConflictException },
    )
} finally {
    executor.shutdownNow()
}
```

`CompanyType.RENTAL_OPERATOR`는 회사의 유형이고, `CompanyVersion(0)`은 “버전 0을 기준으로 수정한다”라는 뜻이다. `update`에 전달한 함수는 회사 이름을 변경하며, `requireNotNull`은 조회 대상이 없어서 `null`이 반환된 상황도 실패로 처리한다.

### Future와 Result의 두 단계 실패

작업 내부의 `runCatching`은 Kotlin 기능이다. 실행 중 던져진 `Throwable`을 `Result.failure`에 담고 정상 값은 `Result.success`에 담는다. [Kotlin runCatching API](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run-catching.html)

이 테스트에서 실패가 어디에 발생했는지에 따라 관찰 지점이 달라진다.

| 상황 | 결과를 관찰하는 위치 |
| --- | --- |
| 수정 성공 | `get()`이 반환한 `Result`가 성공 |
| 수정 중 버전 충돌 | `get()`이 반환한 `Result`의 예외가 `CompanyVersionConflictException` |
| `runCatching` 안에서 예상하지 못한 오류 | 실패 `Result`지만 예상 예외 개수 조건을 만족하지 못함 |
| `start.await()`가 인터럽트됨 | `runCatching` 밖이므로 `get()`이 `ExecutionException`을 던짐 |
| 결과를 제한 시간 내 받지 못함 | `get()`이 `TimeoutException`을 던짐 |

현재 테스트는 단순히 “실패 하나”만 검사하지 않고 **정확한 업무 예외 하나**를 검사한다. 따라서 연결 오류나 프로그래밍 오류를 정상적인 버전 충돌로 인정하지 않는다. 다만 이런 오류가 `Result`에 담기면 개수 단언만으로 원인이 잘 드러나지 않을 수 있으므로, 진단을 개선할 때는 예상 밖 예외를 단언 메시지에 표시하는 방법을 고려할 수 있다.

`runCatching`이 모든 예외를 잡는다고 해서 취소·인터럽트까지 일반 업무 실패로 삼아도 된다는 뜻은 아니다. 특히 대기 코드의 범위를 옮기거나 이 패턴을 운영 코드에 재사용할 때는 예외 전파 의도를 다시 정해야 한다.

### 무제한 start.await()를 어떻게 읽어야 하는가

현재 `start.await()` 자체에는 시간 제한이 없다. 다만 준비 확인에 실패하면 테스트 스레드가 `finally`로 이동해 `shutdownNow()`를 호출하고, 출발 신호를 기다리는 작업의 인터럽트를 시도한다.

작업 쪽에도 명시적인 대기 한도를 두려면 다음처럼 바꿀 수 있다. 이는 개선 예시이며 현재 원본 코드가 아니다.

```kotlin
ready.countDown()
check(start.await(5, TimeUnit.SECONDS)) {
    "출발 신호를 제한 시간 안에 받지 못했습니다."
}
// 성공한 경우에만 업무 작업을 수행한다.
```

이 검사도 업무 결과를 수집하는 `runCatching` 밖에 두면 출발 대기 실패를 업무 충돌과 구분할 수 있다. 제한 시간은 실행 환경에 맞게 정하고, 실행기 정리도 유지한다.

## 6. 원래 테스트의 두 시나리오와 데이터 보호 장치

`CompanyPersistenceIT`에서는 동일한 준비·출발 패턴을 두 곳에서 사용한다.

| 시나리오 | 두 작업의 입력 | 실제 단언 |
| --- | --- | --- |
| 같은 버전으로 이름 변경 | 같은 ID와 버전 0, 서로 다른 새 이름 | 성공 하나, `CompanyVersionConflictException` 하나 |
| 중복 등록 | 같은 회사 유형과 이름 | 성공 하나, `CompanyAlreadyExistsException` 하나, 해당 유형의 저장 행 하나 |

동시 이름 변경 테스트에는 최종 이름과 버전을 다시 조회하는 단언이 없다. 최종 저장 상태까지 검증한다고 설명해서는 안 된다. 중복 등록 테스트에는 최종 행 개수 조회가 있다.

실제 데이터 보호는 래치나 스레드 풀이 아닌 저장 계층에서 이루어진다.

- **이름 변경:** 저장소가 요청의 기대 버전을 확인하고, JPA 엔티티의 `@Version`으로 변경 충돌을 감지하는 구조다. 저장소는 `flush()`에서 발생한 낙관적 잠금 예외를 `CompanyVersionConflictException`으로 변환한다.
- **중복 등록:** DB에 회사 유형과 이름 조합의 유일 제약 `uk_companies_type_name`이 있다. 저장소는 이 제약에 해당하는 저장 오류를 `CompanyAlreadyExistsException`으로 변환한다.

`flush()`는 엔티티 변경을 DB에 반영하는 SQL을 실행하도록 하는 단계이며, 그 자체를 트랜잭션 커밋과 같은 뜻으로 사용하면 안 된다. 현재 수정 메서드에는 `@Transactional`이 있고 등록은 Spring Data 저장소의 `saveAndFlush()`를 호출한다.

테스트는 Spring과 Testcontainers의 MySQL을 연결한다. 테스트 클래스와 기반 클래스에는 테스트 전체를 감싸는 `@Transactional`이 없다. 작업 스레드가 테스트 스레드의 트랜잭션을 자동 공유한다고 가정해서는 안 된다. 테스트 전체에 트랜잭션을 추가하면 준비 데이터의 가시성과 정리 방식도 다시 검토해야 한다.

## 7. 동시성 테스트를 해석할 때의 한계

두 작업의 출발을 허용했다고 두 SQL이 정확히 같은 순간 실행되는 것은 아니다. 래치는 출발 조건을 맞추며, 이후 실행 순서는 JVM과 운영체제 스케줄링, DB 상태에 따라 달라진다.

예를 들어 이름 변경 A가 먼저 끝나고 B가 시작해도 B는 여전히 기대 버전 0을 전달한다. 따라서 이미 저장된 새 버전과의 비교만으로 충돌할 수 있다. 중복 등록도 먼저 등록된 행을 두 번째 작업이 뒤늦게 만나 거절될 수 있다.

이 테스트가 통과했다고 두 트랜잭션의 중첩이나 특정 DB 잠금 대기를 직접 입증한 것은 아니다. 특정 실행 순서를 재현하려면 그 사건을 관찰하거나 제어하는 별도 설계가 필요하다. DB 잠금이나 연결을 가진 채 상대 작업의 준비를 기다리게 만들면 상대가 필요한 자원을 얻지 못할 수 있으므로 대기 관계부터 검토한다.

또한 `Thread.sleep()`으로 일정 시간 쉬게 하는 방법은 준비 확인을 대신할 수 없다. 빠른 환경에서 우연히 통과하는 시간 간격이 느린 CI에서도 같은 실행 순서를 만들지는 않는다.

## 8. 적용 전 확인할 항목

- 각 래치의 숫자가 어떤 사건의 횟수인지 설명할 수 있는가?
- 모든 작업이 같은 `ready`와 `start` 객체를 공유하는가?
- 참여 작업 모두 출발 신호까지 도달할 실행 여력이 있는가?
- 모든 작업 제출 → 준비 확인 → 출발 신호 → 결과 수집 순서를 지키는가?
- 제한 시간 있는 `await()`의 반환값을 확인하는가?
- 예상 업무 예외와 실행·동기화 실패를 구분하는가?
- 실패 시에도 실행기 종료를 요청하고, 필요하면 종료 완료까지 확인하는가?
- 테스트가 직접 관찰한 결과와 추정한 실행 순서를 구분하는가?

## 9. 근거와 확인 범위

2026-09-22 작업 트리와 Java 17 공식 API 문서를 기준으로 작성했다. 아래 경로는 원본 출처를 식별하기 위한 것이며, 본문 이해에 원래 저장소는 필요하지 않다.

| 원본 저장소 내 경로 | 확인한 내용 |
| --- | --- |
| `backend/src/test/kotlin/com/icar/erp/company/adapter/out/persistence/CompanyPersistenceIT.kt` | 세 import, 두 동시성 테스트, 타임아웃, 결과 단언, 종료 요청 |
| `backend/src/main/kotlin/com/icar/erp/company/adapter/out/persistence/repository/JpaCompanyRepository.kt` | 버전 검사, flush, 예외 변환 |
| `backend/src/main/kotlin/com/icar/erp/company/adapter/out/persistence/entity/CompanyJpaEntity.kt` | `@Version`, 유형·이름 유일 제약 선언 |
| `backend/src/main/resources/db/migration/V11__create_companies.sql` | 실제 DB 유일 제약 정의 |
| `backend/src/test/kotlin/com/icar/erp/testsupport/MySqlITBase.kt` | Spring과 MySQL 테스트 환경 |
| `backend/build.gradle.kts` | JVM 도구 체인 17 |

이 문서는 소스와 API 계약을 분석한 설명이다. 원본 테스트를 수정하거나 실행한 결과 보고서는 아니며, 개선 예시는 현재 구현과 구분해 표시했다.
