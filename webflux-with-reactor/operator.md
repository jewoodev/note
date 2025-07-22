## 1. Sequence 생성

### 1.1 justOrEmpty()

`just()` 오퍼레이터를 확장한 것으로, null 값을 커버하는 `just()` 오퍼레이터라고 볼 수 있다. emit할 데이터가 null일 경우 `NullPointException`을 발생시키지 않고 `onComplete` Signal을 전송한다.

`just()` 오퍼레이터는 체이닝으로 `onErrorResume` 오퍼레이터가 있더라도 null을 파라미터로 받으면 NPE를 발생시키고 시퀀스를 종료한다. 이는 `just()` 오퍼레이터의 동작 방식 때문이다. `just()`는 구독 시점에 이미 데이터를 가지고 있는 상태에서 시퀀스를 생성하는데, 이때 null을 파라미터로 받으면 NPE를 발생시킨다. 이 예외는 `onErrorResume` 오퍼레이터에서 처리할 수 있는 시점보다 더 이른 시점에서 발생하기 때문에, `onErrorResume`의 에러 처리 로직까지 도달하지 못한다.

### 1.2 fromIterable(), fromStream()

각각 Iterable과 Stream에 포함된 데이터를 emit하는 Flux를 생성하는 오퍼레이터이다. 

### 1.3 range(n, m)

n부터 1씩 증가한 연속된 수를 m개 emit하는 Flux를 생성한다.

### 1.4 defer()

Operator를 선언한 시점에 데이터를 emit하지 않고 구독하는 시점에 emit하는 Flux 또는 Mono를 생성한다.

### 1.5 generate(() -> O, (S, sink) -> sink.next(S); return S;)
 
프로그래밍 방식으로 Signal 이벤트를 발생시킨다. 동기적으로 데이터를 하나씩 순차적으로 emit하려는 용도로 특화된 오퍼레이터이다.

### 1.6 create()

generate() 처럼 프로그래밍 방식으로 Signal 이벤트를 발생시키는데, 한 번에 여러 건의 데이터를 비동기적으로 emit하는 게 가능한 오퍼레이터이다.

## 2. Sequence 필터링

### 2.1 filter()

Upstream에서 emit된 데이터 중 조건을 만족하는 것만 Downstream으로 emit하는 거름망 역할을 한다. 

### 2.2 next()

Upstream에서 emit되는 데이터 중 첫 번째 데이터만 Downstream으로 emit한다. Upstream에서 emit되는 데이터가 empty면 empty Mono를 emit한다.

## 3. Sequence 변환

### 3.1 map()

Upstream에서 emit된 데이터를 mapper Function을 통해 변환시킨 후 Downstream으로 emit한다. 

### 3.2 flatMap()

Upstream에서 emit된 데이터 한 건을 Inner Sequence에서 평탄화 작업을 해서 하나의 데이터로 변환시킨다. 이 오퍼레이터를 통해 Upstream에서 emit된 하나의 데이터가 Downstream으로 여러 개의 데이터로 변환되어 결과적으로 여러 개의 데이터가 발생하는 경우도 있다. 결과적으로 발생하는 데이터의 개수는 Inner Sequence를 몇 개 생성하느냐에 따라  달라진다.

### 3.3 concat()

파라미터로 입력되는 Publisher를 순서대로 연결하여 하나의 Sequence로 만든다. 이 때 파라미터로 주어지는 Publisher는 먼저 입력된 게 종료될 때까지 나머지 Publisher의 sequence가 subscribe 되지 않는다.

### 3.4 merge()

concat() 오퍼레이터와 유사하지만, 파라미터로 입력되는 Publisher는 순서대로 연결되는 게 아니라 동시에 subscribe 된다. 따라서 파라미터로 입력되는 여러 개의 Publisher가 발생하는 데이터를 동시에 emit하는 것이 가능하다.

이때 파라미터들로부터 emit 된 데이터의 emit 된 시간 순서대로 결합한다.

### 3.5 zip()

파라미터로 입력되는 각각의 Publisher가 데이터를 하나씩 emit하는 걸 기다렸다가 각 Publisher가 emit한 데이터를 Tuple2 객체로 묶어서 Subscriber에게 전달한다. 

세번째 파라미터로 combinatior를 추가하면 한 쌍의 데이터를 combinator를 거쳐 변환한 후 subscriber에게 전달한다.

두 개 이상의 Publisher가 주어지면 그만큼의 크기의 TupleN 객체로 묶인다.

### 3.6 and()

Mono의 Complete Signal과 파라미터로 입력된 Complete Signal을 결합하여 새로운 Mono<Void>를 반환한다. 그래서 오퍼레이터를 이용하면 Mono와 파라미터의 Publisher Sequence가 모두 종료되었음을 Subscriber에게 알릴 수 있다.

### 3.7 collectList()

Flux에서 emit된 데이터를 모아서 List로 변환한 후 그 List를 emit하는 Mono를 반환한다.

### 3.8 collectMap()

Flux에서 emit된 데이터를 기반으로 key-value 쌍을 생성해 Map으로 변환한 후 그 Map을 emit하는 Mono를 반환한다.

### 3.9 collectSortedList()

## 4. Sequence 내부 동작 확인

Reactor에서는 업스트림에서 emit되는 데이터를 변경하지 않고 부수 효과만을 수행하기 위한 오퍼레이터들이 있다. 그러한 오퍼레이터들은 `doOnXXXX()` 형식의 이름을 갖고 있다.

이 오퍼레이터들은 Consumer 또는 Runnable 타입의 함수형 인터페이스를 파라미터로 갖는 공통점이 있는데, 그래서 모두 리턴값이 없다.

만약 파라미터로 리턴값이 있는 메서드 참조를 주거나 람다식을 주면 함수를 실행하기는 하지만 그 리턴값은 무시하고, 업스트림의 리턴값을 다음 오퍼레이터에 전달한다. 만약 그 함수가 리액티브하다면 구독이 일어나지 않기 때문에 그 함수는 실행되지 않는다.

이런 역할의 오퍼레이터는 가짓수가 꽤 되는데, 트리거되는 시점에 따라서 나뉜다고 볼 수 있다. `doFirst()` 는 구독이 일어나기도 전에 수행되고, 체인의 어디에 위치하든 실행 시점은 변하지 않는데, 이는 `doFinally()`도 동일하다. 제일 마지막에 동작하는데, `doFinally()`가 여러 번 호출될 경우 선언한 시점의 역순으로 동작한다.

구독이 발생하면 `doOnSubscribe()`가 동작하고, Subscriber가 데이터를 요청하면 `doOnRequest()`가 동작한다. Upstream에서 데이터가 emit될 때마다 `doOnNext()`가 동작한다. 

## 5. 예외 처리

### 5.1 error()

`error()`는 파라미터로 지정된 에러로 종료하는 Publisher를 생성한다.

### 5.2 onErrorReturn()

에러 이벤트가 발생했을 때, Downstream으로 전파하지 않고 파라미터로 넘겨준 걸 emit한다. try ~ catch 문의 catch 블록에서 예외마다 리턴값을 다르게 주는 역할을 수행하는 것과 비슷하다.

### 5.3 onErrorResume()

에러 이벤트가 발생했을 때, Downstream으로 전파하지 않고 대체 Publisher를 리턴한다. try ~ catch 문의 catch 불록에서 예외가 발생한 메서드를 대체할 수 있는 다른 메서드를 호출하는 것과 비슷하다.

### 5.4 onErrorContinue()

에러가 발생했을 때 Sequence를 종료시키지 않고 남은 Sequence의 데이터를 이어서 emit하려 할 때 사용한다. 다시 말해, 에러가 발생한 데이터는 무시하고 다음 데이터를 이어서 처리하는 것이다.

이 오퍼레이터에 BiConsumer 함수형 인터페이스를 파라미터를 주면 emit된 데이터를 사용하는 로그를 기록하는 등의 작업을 할 수 있다.

### 5.5 retry()

에러가 발생했을 때 파라미터로 입력한 횟수만큼 원본 Sequence를 다시 구독한다. 만약 Long.MAX_VALUE를 파라미터로 주면 무한히 재구독한다.

## 6. 시간 측정

### 6.1 elapsed()

emit된 데이터 사이의 경과 시간을 측정해서 Tuple<Long, T> 형태로 Downstream에 emit한다. 첫 번째 데이터는 onSubscribe() 이벤트가 발생한 시점과 비교해 측정한다.

---

### collectList()

1. **비동기 작업의 결과 수집**
    - Flux.fromIterable(request.participantIds())로 시작된 스트림은 여러 개의 사용자 ID를 처리한다.
    - 각 ID에 대해 userService.getById()를 호출하면 각각의 결과가 개별적으로 방출된다.
    - 이 개별적인 결과들을 하나의 리스트로 모아서 한 번에 처리해야 한다.
2. **모든 참여자의 존재 여부 확인**
    - 채팅방을 생성하기 전에 모든 참여자가 존재하는지 확인해야 한다.
    - collectList()를 사용하면 모든 사용자 조회가 완료될 때까지 기다린 후, 결과를 한 번에 검증할 수 있다.
    - 만약 collectList()를 사용하지 않으면, 각 사용자 조회 결과를 개별적으로 처리해야 하며, 전체 검증이 어려워진다.
3. **에러 처리의 일관성**
    - collectList()를 사용하면 모든 사용자 조회가 완료된 후에 한 번에 에러를 발생시킬 수 있다.
    - 이는 "하나라도 존재하지 않는 사용자가 있으면 실패"라는 요구사항을 명확하게 구현할 수 있게 해준다.

만약 collectList()를 사용하지 않는다면, 각 사용자 조회 결과를 개별적으로 처리해야 하고, 전체 검증 로직이 더 복잡해질 수 있다. collectList()를 사용함으로써 코드가 더 간단하고 명확해진다.

## flatMap()과 flatMapMany()의 차이

1. **flatMap**
    - Mono를 반환하는 변환 작업에 사용된다
    - 입력 스트림의 각 요소를 Mono로 변환하고, 그 결과를 하나의 Mono로 평탄화한다
    - 예시:
        ```java
        Flux.fromIterable(request.participantIds())
            .flatMap(id -> userService.getById(id))
            .collectList()
            .block();
        ```
2. **flatMapMany**
    - Flux를 반환하는 변환 작업에 사용된다
    - 입력 스트림의 각 요소를 Flux로 변환하고, 그 결과를 하나의 Flux로 평탄화한다
    - 예시:
        ```java
        Flux.fromIterable(request.participantIds())
            .flatMapMany(id -> userService.getById(id))
            .collectList()
            .block();
        ```
다음의 예시 코드의 경우엔

```java
return redisDao.getLastOnlineTime(lastOnlineTimeKey)
        .flatMapMany(lastOnlineTime -> 
            unreadChatRepository.findAllByUnreadUsername(userDetails.getUsername())
                .filter(unreadChat -> unreadChat.getCreatedAt().isAfter(lastOnlineTime))
                .map(UnreadChatResponse::from)
        );
```

여기서 flatMapMany를 사용한 이유는:

1. getLastOnlineTime은 Mono<LocalDateTime>을 반환한다
2. 그 다음 findAllByUnreadUsername은 Flux<UnreadChat>을 반환한다
3. 따라서 Mono에서 Flux로 변환하는 flatMapMany가 적절하다

만약 flatMap을 사용했다면:

```java
return redisDao.getLastOnlineTime(lastOnlineTimeKey)
        .flatMap(lastOnlineTime -> 
            unreadChatRepository.findAllByUnreadUsername(userDetails.getUsername())
                .filter(unreadChat -> unreadChat.getCreatedAt().isAfter(lastOnlineTime))
                .map(UnreadChatResponse::from)
                .next() // Flux를 Mono로 변환
        );
```

이렇게 되면 여러 개의 오프라인 채팅 중 첫 번째 것만 반환하게 된다.

정리하면:
- `flatMap`: `Mono` → `Mono` 변환에 사용
- `flatMapMany`: `Mono` → `Flux` 변환에 사용
- `flatMap`을 `Flux`에서 사용하면 각 요소를 `Mono`로 변환하고 그 결과를 하나의 `Flux`로 평탄화
- `flatMapMany`를 `Flux`에서 사용하면 각 요소를 `Flux`로 변환하고 그 결과를 하나의 `Flux`로 평탄화

---

## 구독 트리거 오퍼레이터

1. subscribe() 계열:
    - subscribe(): 기본 구독
    - subscribe(Consumer<T> consumer): 각 요소 처리
    - subscribe(Consumer<T> consumer, Consumer<Throwable> errorConsumer): 에러 처리 포함
    - subscribe(Consumer<T> consumer, Consumer<Throwable> errorConsumer, Runnable completeConsumer): 완료 처리 포함
    - subscribe(Consumer<T> consumer, Consumer<Throwable> errorConsumer, Runnable completeConsumer, Consumer<Subscription> subscriptionConsumer): 구독 객체 처리 포함
2. block() 계열:
    - block(): 다음 요소가 도착할 때까지 블로킹
    - block(Duration timeout): 타임아웃 지정하여 블로킹
    - blockFirst(): 첫 번째 요소만 블로킹
    - blockFirst(Duration timeout): 타임아웃 지정하여 첫 번째 요소 블로킹
    - blockLast(): 마지막 요소만 블로킹
    - blockLast(Duration timeout): 타임아웃 지정하여 마지막 요소 블로킹
3. toIterable() 계열:
    - toIterable(): Iterable로 변환
    - toIterable(int batchSize): 배치 크기 지정하여 Iterable로 변환
    - toIterable(int batchSize, Supplier<Queue<T>> queueSupplier): 큐 공급자 지정하여 Iterable로 변환
4. toStream() 계열:
    - toStream(): Java 8 Stream으로 변환
    - toStream(int batchSize): 배치 크기 지정하여 Stream으로 변환
5. toFuture() 계열:
    - toFuture(): CompletableFuture로 변환
    - toFuture(T valueIfEmpty): 빈 경우 기본값 지정하여 CompletableFuture로 변환
6. toProcessor() 계열:
    - toProcessor(): Processor로 변환
    - toProcessor(Supplier<Processor<T, T>> processorSupplier): 프로세서 공급자 지정하여 변환
7. toMono() 계열:
    - toMono(): Mono로 변환
toMono(T valueIfEmpty): 빈 경우 기본값 지정하여 Mono로 변환
8. toFlux() 계열:
    - toFlux(): Flux로 변환
9. toList() 계열:
    - toList(): List로 변환
    - toList(int expectedSize): 예상 크기 지정하여 List로 변환
10. toMap() 계열:
    - toMap(Function<T, K> keyMapper): Map으로 변환
    - toMap(Function<T, K> keyMapper, Function<T, V> valueMapper): 키와 값 매퍼 지정하여 Map으로 변환
    - toMap(Function<T, K> keyMapper, Function<T, V> valueMapper, Supplier<M> mapSupplier): 맵 공급자 지정하여 Map으로 변환
11. toMultimap() 계열:
    - toMultimap(Function<T, K> keyMapper): Multimap으로 변환
    - toMultimap(Function<T, K> keyMapper, Function<T, V> valueMapper): 키와 값 매퍼 지정하여 Multimap으로 변환
    - toMultimap(Function<T, K> keyMapper, Function<T, V> valueMapper, Supplier<M> mapSupplier): 맵 공급자 지정하여 Multimap으로 변환
12. toSortedList() 계열:
    - toSortedList(): 정렬된 List로 변환
    - toSortedList(Comparator<T> comparator): 비교자 지정하여 정렬된 List로 변환
13. toSortedList(int expectedSize) 계열:
    - toSortedList(int expectedSize): 예상 크기 지정하여 정렬된 List로 변환
    - toSortedList(int expectedSize, Comparator<T> comparator): 예상 크기와 비교자 지정하여 정렬된 List로 변환
14. toArray() 계열:
    - toArray(): Object[]로 변환
    - toArray(IntFunction<T[]> generator): 배열 생성기 지정하여 변환
15. toArray(Class<T> componentType) 계열:
    - toArray(Class<T> componentType): 특정 타입의 배열로 변환
16. toArray(IntFunction<T[]> generator, Class<T> componentType) 계열:
    - toArray(IntFunction<T[]> generator, Class<T> componentType): 배열 생성기와 타입 지정하여 변환
17. toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize) 계열:
    - toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize): 배열 생성기, 타입, 예상 크기 지정하여 변환
18. toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel) 계열:
    - toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel): 병렬 처리 옵션 추가하여 변환
19. toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel, boolean ordered) 계열:
    - toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel, boolean ordered): 순서 보장 옵션 추가하여 변환
20. toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel, boolean ordered, boolean distinct) 계열:
    - toArray(IntFunction<T[]> generator, Class<T> componentType, int expectedSize, boolean parallel, boolean ordered, boolean distinct): 중복 제거 옵션 추가하여 변환
