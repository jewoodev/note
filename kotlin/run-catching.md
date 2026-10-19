# Kotlin의 runCatching과 예외 처리 범위

작성일: 2026-10-13

## runCatching은 무엇인가?

`runCatching`은 전달한 코드를 실행하고, **정상 반환값 또는 발생한 예외를 `Result`에 담아 반환하는 Kotlin 표준 함수**다. 파일 읽기, 문자열 변환, 서버 요청처럼 실패할 수 있는 작업의 결과를 값으로 다룰 때 사용한다. [Kotlin 공식 문서](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run-catching.html)

```kotlin
val result: Result<Int> = runCatching {
    "123".toInt()
}
```

중괄호 안은 실행할 코드인 람다다. 마지막 표현식인 `toInt()`의 반환값이 성공 결과에 담긴다. 위 예제는 정수 `123`을 담은 성공 결과가 된다. 입력이 `"abc"`라면 숫자로 변환할 수 없어 발생한 예외가 실패 결과에 담긴다.

| 실행 결과 | Result에 담기는 내용 |
|---|---|
| 정상 반환 | 성공과 반환값 |
| 예외 발생 | 실패와 예외 객체 |

`runCatching`은 예외를 기록하거나 재시도하지 않는다. 실행을 별도 스레드나 큐로 옮기는 기능도 없다. 호출한 자리에서 코드를 실행하고 결과를 반환한다.

## try/catch와의 관계

동작은 다음처럼 이해할 수 있다.

```kotlin
val result: Result<Int> = try {
    Result.success("123".toInt())
} catch (error: Throwable) {
    Result.failure(error)
}
```

`runCatching`은 블록에서 발생한 `Throwable`을 잡는다. `catch (error: Exception)`보다 넓은 범위이며, 예외를 실패 결과로 바꿨다고 해서 모든 실패가 복구 가능한 것은 아니다. 특정 종류의 예외만 처리하려면 명시적인 `try/catch`가 의도를 표현하기 쉽다. [예외 포착 범위](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/run-catching.html)

## onSuccess와 onFailure

성공과 실패에 따라 후속 동작을 연결할 수 있다.

```kotlin
runCatching {
    "123".toInt()
}.onSuccess { number ->
    println("변환 결과: $number")
}.onFailure { error ->
    error.printStackTrace()
}
```

- `onSuccess`: 성공 결과일 때 실행하며, 람다에 반환값을 전달한다.
- `onFailure`: 실패 결과일 때 실행하며, 람다에 예외 객체를 전달한다.

두 함수는 후속 동작을 실행한 뒤 원래 `Result`를 그대로 반환한다. 따라서 `onFailure`에서 로그를 남겼다고 실패 결과가 성공으로 바뀌지는 않는다. [onSuccess](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/on-success.html), [onFailure](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/on-failure.html)

## onSuccess 안의 예외는 어디로 가는가?

**뒤에 붙은 `onFailure`가 앞의 `onSuccess`에서 발생한 예외까지 잡는 것은 아니다.**

```kotlin
runCatching {
    "123".toInt()                  // A: runCatching의 예외 포착 범위
}.onSuccess { number ->
    error("후속 처리 실패: $number") // B: 위 runCatching의 범위 밖
}.onFailure {
    println("숫자 변환 실패")
}
```

이 예제에서는 A가 성공한 뒤 B에서 예외가 발생한다. 예외는 호출부로 전파되며, 뒤의 `onFailure`는 실행되지 않는다. `onSuccess`는 예외를 새 실패 결과로 변환하는 함수가 아니기 때문이다. `onFailure` 내부에서 발생한 예외도 밖으로 전파된다. [Result 설계 문서](https://github.com/Kotlin/KEEP/blob/main/proposals/stdlib/KEEP-0127-result.md)

다음 코드는 위 코드와 예외 처리 범위가 다르다.

```kotlin
try {
    val number = "123".toInt()
    error("후속 처리 실패: $number")
} catch (error: Exception) {
    println("변환 또는 후속 처리 실패")
}
```

여기서는 변환과 후속 처리가 모두 `try` 안에 있으므로 두 위치에서 발생한 `Exception`을 처리한다. 코드를 읽을 때는 함수가 연결된 모양보다 **예외를 잡는 블록의 시작과 끝**을 확인해야 한다.

## null도 성공 결과가 될 수 있다

`runCatching`에서 성공은 “업무를 완료했다”가 아니라 “블록이 예외 없이 반환했다”는 뜻이다.

```kotlin
val result = runCatching<String?> { null }

result.onSuccess { value ->
    println(value) // null이며, 성공 경로가 실행됨
}
```

반환값이 `null`인지, 서버 응답이 원하는 상태인지 등은 별도로 판단해야 한다. 이 차이는 아래 실제 코드에서 응답이 `null`인 경우를 이해하는 데 필요하다.

`getOrNull()`은 성공이면 값을, 실패이면 `null`을 반환한다. 따라서 성공 값 자체가 `null`일 수도 있는 코드에서 이것만 사용하면 두 경우를 구분할 수 없다. 예외 원인을 알아야 한다면 원래 `Result`의 실패 정보를 확인하거나 예외를 호출부에 전달해야 한다. [getOrNull 공식 문서](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/get-or-null.html)

## Android 알림 처리 코드에 적용해 읽기

이 저장소의 Android 앱은 카카오톡 알림에서 요청을 읽고, 서버에서 답변을 받아 알림의 답장 기능으로 전송한다. [KakaoNotificationListenerService의 process 함수](../../android-bridge/src/main/kotlin/com/icar/aicounselor/bridge/notification/KakaoNotificationListenerService.kt)에서 작성 당시 94행에 있는 코드를 축약하면 다음과 같다.

```kotlin
runCatching {
    BotNameFilter.submitIfAddressed(configuration.botName, message.text) {
        trace(message, "submitting")
        apiClient.submitMessage(configuration, message)
    }
}.onSuccess { response ->
    // 처리 대상 여부와 서버 응답 확인, 답변 전송, 결과 보고
}.onFailure { error ->
    // 실패 기록과 미완료 작업의 상태 확인 요청
}
```

여기서 예외를 포착하는 범위는 **호출어 검사, 제출 로그 기록, 서버 요청**이다. 서버 요청이 반환된 이후의 답변 전송과 로컬 기록 저장은 `onSuccess` 안에 있으므로 이 `runCatching`의 예외 포착 범위 밖이다.

| 상황 | 현재 코드의 흐름 |
|---|---|
| 호출어 검사에서 제외되어 null 반환 | `onSuccess`에서 등록 정리 후 종료 |
| 서버 요청에서 예외 발생 | `onFailure`에서 로그 기록 후 복구 요청 |
| 서버 응답을 정상 반환 | `onSuccess`에서 상태와 본문을 추가 검사 |
| `onSuccess`에서 예외가 밖으로 나옴 | `process()` 호출부의 예외 처리로 전달 |

예를 들어 `onSuccess`에서 전송 journal 저장이 예외를 던지면, 바로 아래의 `onFailure`가 받는 것이 아니다. 현재 코드에서는 `process(admittedMessage)`를 감싼 바깥쪽 `catch (Exception)`이 처리하며, `finally`에서 복구 작업을 요청한다. 이 설명은 `Exception`에 해당하는 예외의 경로이며 모든 `Throwable`을 바깥쪽에서 잡는다는 의미는 아니다.

이 코드의 “복구 요청”은 미완료 작업의 서버 상태를 확인하도록 요청하는 동작이다. `runCatching` 자체의 자동 재시도 기능이 아니며, 그 호출만으로 답변을 다시 생성하거나 재전송하지 않는다.

또한 현재 `onFailure`의 로그는 예외 클래스 이름만 남긴다. 예외 메시지와 스택 추적까지 기록하는지는 별개의 구현 사항이다. `runCatching`을 사용했다는 사실만으로 원인 추적 정보가 로그에 남는 것은 아니다.

## return@onSuccess의 의미

실제 코드에는 다음 구문이 있다.

```kotlin
if (response == null) {
    BridgeWork.complete(this, message.externalMessageId)
    return@onSuccess
}
```

`return@onSuccess`는 `onSuccess`에 전달한 람다만 종료한다. 바깥 함수 전체를 종료하는 일반적인 `return`과 범위가 다르다. 원래 결과가 성공이므로 뒤에 연결된 `onFailure`의 동작은 실행되지 않는다. [Kotlin의 라벨을 사용한 반환](https://kotlinlang.org/docs/returns.html#return-to-labels)

## 코드를 읽을 때 확인할 질문

1. `runCatching`의 중괄호 안에는 어떤 작업이 들어 있는가?
2. 예외 없는 반환과 실제 업무 성공을 구분하고 있는가?
3. `onSuccess`·`onFailure` 자체에서 발생한 예외는 누가 처리하는가?
4. 실패 정보를 기록하거나 전달하는가, 아니면 `getOrNull()`로 구분을 없애는가?
5. 복구·재시도·완료 정리는 어떤 코드가 명시적으로 수행하는가?
