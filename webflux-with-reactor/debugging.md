## 1. Reactor에서의 디버깅 방법

### 1.3 log() Operator를 사용한 디버깅

```java
public class Example {
    public static void main(String[] args) {
        Flux.fromArray(new String[]{"BANANAS", "APPLES", "PEARS", "MELONS"})
                .map(String::toLowerCase)
                .map(fruit -> fruit.substring(0, fruit.length() - 1))
                .log("Fruit.SubString")
                .map(fruits::get)
                .subscribe(
                        log::info,
                        error -> log.error("# onError:", error)
                );
    }
}
```

위와 같은 코드에서 `log("Fruit.SubString")` 오퍼레이터의 두번째 파라미터로 로그 레벨을 기입할 시 Reactor는 SLF4J 가 아닌 java.util.logging(JUL)를 사용하게 된다.

Reactor의 `.log()` 오퍼레이터는 Reactive Stream의 신호 (Signal) 를 로그로 출력하는 디버깅 도구이다.  
말 그대로 "어떤 일이 언제 발생했는지"를 보여주는 추적 로그(trace log)를 생성한다.

출력하는 로그의 종류는 다음과 같다.

#### 🔍 `.log()` 오퍼레이터가 출력하는 로그의 종류

`.log()`는 **Reactor의 각 단계에서 발생하는 신호 (signal)** 를 추적하며, 다음과 같은 이벤트들을 출력합니다:

| Signal Type        | 설명                                                          |
|--------------------|-------------------------------------------------------------|
| `onSubscribe()`    | Publisher가 Subscriber와 연결되었을 때 발생                           |
| `request(n)`       | Subscriber가 n개의 데이터를 요청했을 때                                 |
| `onNext(value)`    | 데이터가 실제로 전달될 때                                              |
| `onError(error)`   | 에러가 발생했을 때                                                  |
| `onComplete()`     | 데이터 스트림이 정상 종료되었을 때                                         |
| `cancel()`         | 구독이 중단되었을 때 (ex. `take(3)` 같은 연산자 사용 시)                     |
| `onDiscard(value)` | 데이터가 필터링되거나 drop 되었을 때 (Reactor의 discard mechanism이 동작한 경우) |

---

#### 📄 예시 로그 출력 (단순화한 형태)

```
[ INFO] (main) | onSubscribe([Synchronous Fuseable] FluxArray.ArraySubscription)
[ INFO] (main) | request(unbounded)
[ INFO] (main) | onNext("banana")
[ INFO] (main) | onNext("apple")
[ INFO] (main) | onNext("pear")
[ INFO] (main) | onNext("melon")
[ INFO] (main) | onComplete()
```

---

#### 💡 용도

- 연산자 체인의 흐름을 눈으로 추적할 수 있음
- 어느 시점에 데이터가 발생하고 소멸되는지 확인
- 예상한 signal이 발생하지 않을 때 문제 원인 파악 가능
- Backpressure 흐름 (`request(n)`) 디버깅

---

#### 📌 정리

> .log() 오퍼레이터는 Reactive Stream의 생명주기 이벤트(onNext, onError, onComplete, etc.)를 출력하여 디버깅을 도와주는 도구입니다. 주로 개발, 테스트 단계에서 흐름 추적과 문제 원인 파악에 활용됩니다.
>

필요하다면 특정 signal만 필터링해서 로깅하거나 커스텀 로깅 연산자도 만들 수 있다.
