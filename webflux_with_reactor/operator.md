## 1. Sequence 생성

### 1.1 justOrEmpty()

just() 오퍼레이터를 확장한 것으로, null 값을 커버하는 just() 오퍼레이터라고 볼 수 있다. emit할 데이터가 null일 경우 NullPointException을 발생시키지 않고 onComplete Signal을 전송한다.

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

Upstream에서 emit된 데이터 한 건을 Inner Sequence를 생성한 후에 평탄화 작업을 해서 하나의 데이터로 변환시킨다. 이 오퍼레이터를 통해 Upstream에서 emit된 하나의 데이터가 Downstream으로 여러 개의 데이터로 변환되어 결과적으로 여러 개의 데이터가 발생하는 경우도 있다. Inner Sequence를 몇 개 생성하느냐에 따라 결과적으로 발생하는 데이터의 개수가 달라진다.

### 3.3 concat()

파라미터로 입력되는 Publisher를 순서대로 연결하여 하나의 Sequence로 만든다. 
