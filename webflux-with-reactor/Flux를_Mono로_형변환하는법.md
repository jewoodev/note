Flux를 Mono로 변환하는 방법은 여러 가지가 있다. 주요 방법들을 살펴보자.

1. `next()`: Flux의 첫 번째 요소만 Mono로 변환
    ```java
    Mono<T> mono = flux.next();
    ```
2. `last()`: Flux의 마지막 요소만 Mono로 변환
    ```java
    Mono<T> mono = flux.last();
    ```
3. `collectList()`: Flux의 모든 요소를 List로 수집하여 Mono<List<T>>로 변환
    ```java
    Mono<List<T>> mono = flux.collectList();
    ```
4. `reduce()`: Flux의 요소들을 하나로 줄여서 Mono로 변환
    ```java
    Mono<T> mono = flux.reduce((a, b) -> a + b);
    ```
5. `single()`: Flux가 정확히 하나의 요소만 방출할 때 사용
    ```java
    Mono<T> mono = flux.single();
    ```
6. `collect()`: Flux의 요소들을 다른 컬렉션으로 수집
    ```java
    Mono<Set<T>> mono = flux.collect(Collectors.toSet());
    ```

