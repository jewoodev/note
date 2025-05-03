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
