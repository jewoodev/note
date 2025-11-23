"**signal**"은 Reactor (Spring WebFlux 가 기반으로 삼는 리액터 프로그래밍 모델)에서 Publisher 가 Subscriber 에게 보내는 메시지 또는 이벤트의 단위를 의미한다.

리액터(Reactor)나 RxJava 같은 **Reactive Streams**에서는 데이터를 다음과 같은 **시그널(Signal)** 형태로 주고받는다.

| Signal 종류            | 설명                            |
|----------------------|-------------------------------|
| `onNext(T data)`     | 새로운 데이터 1건을 보낼 때              |
| `onError(Throwable)` | 오류가 발생했을 때                    |
| `onComplete()`       | 더 이상 보낼 데이터가 없음을 알릴 때 (완료)    |
| `onSubscribe()`      | 구독이 시작되었음을 알리는 초기 신호 (보통 생략됨) |

이런 시그널들이 Publisher → Subscriber 로 흐르면서 데이터 스트림을 구성하는 것이다.

---

# 예시로 보는 Signal 흐름

```java
Flux<String> flux = Flux.just("A", "B", "C");

flux.subscribe(
    data -> System.out.println("onNext: " + data),
    error -> System.out.println("onError: " + error),
    () -> System.out.println("onComplete")
);
```

이 코드는 아래 순서로 **signal**을 전달한다:

1. `onNext("A")`
2. `onNext("B")`
3. `onNext("C")`
4. `onComplete()`

이처럼 시그널은 데이터 그 자체라기보다는, 데이터를 **어떻게 전달하고, 언제 끝나며, 에러는 어떻게 전달할지에 대한 흐름**을 나타내는 **통신 방식**이다.

---

# Signal을 수동으로 보내는 방법: `Sinks`, `generate`, `create`

이제 다시 처음 얘기로 돌아가면:

- `Sinks`, `generate`, `create`는 **직접 onNext / onComplete / onError 같은 시그널을 푸시할 수 있게 해주는 도구**이다.
- 이 signal은 `Subscriber`에게 흘러가는 데이터의 이벤트 단위이자 알림인 것이다.

---

# 비유로 이해하기

생각해보자. 너가 **배달 기사**고, 너한테 오는 **전화**들이 signal이라고 해보자.

- `onNext`: "OO씨의 짜장면 배달 가주세요" → 새로운 일거리가 생겼다!
- `onError`: "오류났어요! 배달 주소 틀렸어요!" → 문제 생겼다!
- `onComplete`: "오늘 할 일 끝났어요!" → 더 이상 할 일 없음

---

# 요약 정리

- **Signal**은 Reactive Streams에서 데이터를 보내는 **이벤트 알림**의 단위
- 대표적으로는 `onNext`, `onComplete`, `onError` 세 가지
- `Sinks`나 `generate`, `create`는 이런 시그널을 **직접 만들어서 보낼 수 있는 방법**
