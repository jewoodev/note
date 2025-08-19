## 1. onNext Signal이 발생되는 시점은 언제인가?

1. **데이터 소스에서 데이터가 방출될 때**
    - `Mono.just()`, `Flux.just()` 등 정적 데이터 소스에서
    - `Flux.fromIterable()`, `Flux.fromStream()` 등 컬렉션이나 스트림에서
    - `Flux.range()`, `Flux.interval()` 등 동적 데이터 소스에서
2. **연선자 체인에서 실제 데이터 변환이 일어날 때**
    - `map()`, `flatMap()`, `filter()` 등의 연산자가 실제로 데이터를 처리할 때
    - 이때 각 연산자는 새로운 `Publisher`를 생성하고, 이 `Publisher`가 `onNext`를 발생시킨다.
3. **구독이 시작되고 데이터가 흐를 때**
    - `subscribe()`가 호출되어 실제 구독이 시작될 때
    - 이때 데이터 소스가 활성화되어 `onNext` 시그널을 발생시키기 시작한다.

중요한 점은 다음과 같다.

- 모든 연산자 체인에서 `onNext` 시그널이 발생하는 것은 아님
- 실제 데이터가 처리되고 전달될 때만 `onNext` 시그널이 발생
- 연산자 체인은 단순히 데이터 흐름의 파이프라인을 정의하는 것이고, 실제 데이터 흐름은 구독이 시작될 때 발생

### 1.1 예시

```java
Flux.just(1, 2, 3)
    .map(i -> i * 2)
    .filter(i -> i > 3)
    .subscribe(System.out::println);
```

이 경우에는

1. `Flux.just()`에서 1, 2, 3이 `onNext`을 발생
2. `map()`에서 각 값이 2배가 되어 새로운 `onNext`을 발생
3. `filter()`에서 조건에 맞는 값만 새로운 `onNext`을 발생
4. `subscribe()`에서 각 `onNext` 시그널을 받아 처리

이렇게 된다.
