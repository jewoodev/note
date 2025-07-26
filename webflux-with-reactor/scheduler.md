## 2. Scheduler 란?

Reactor 에서 Scheduler 는 비동기 프로그램에 사용되는 스레드를 관리하는 관리자 역할을 한다. 

멀티스레드 환경에서 스레드 간의 race condition 같은 문제들을 고려하려면 코드가 복잡해져 기술적인 비용이 높아지는데 스레드를 관리하는 역할을 Scheduler 에 모두 넘겨서 개발자가 직접 스레드를 제어해야 하는 부담에서 벗어나게 해준다.

## 3. Scheduler 를 위한 전용 Operator

우리는 Scheduler 전용 Operator 를 사용함으로써 Scheduler 의 기능을 사용할 수 있다. 그런 Operator 는 `subscribeOn()` 과 `publishOn()` 이다. 

일반적으로 `subscribeOn()` 과 `publishOn()` 이 가장 많이 사용되지만 `parallel()` Operator 도 사용된다.

### 3.1 subscribeOn()

이름 그대로 구독이 발생한 직후 실행될 스레드를 지정하는 Operator 이다. 구독이 발생하면 원본 Publisher 가 최초로 emit 을 하기 때문에 `subscribeOn()`에 지정된 스레드는 원본 Publisher 의 동작을 수행하기 위한 스레드라고 볼 수 있다.

### 3.2 publishOn()

이름 그대로 Publisher 가 Signal 을 Downstream 으로 전송할 때 실행될 스레드를 지정하는 Operator 이다. Reactor Sequence 에서 발생하는 Signal 을 Downstream 으로 전송하는 스레드를 지정하는 것이다. 

그래서 `publishOn()` 을 기준으로 Downstream 의 실행 스레드는 변경된다.

`publishOn()` Operator 는 한 개 이상 사용할 수 있고, 실행 스레드를 목적에 맞게 적절히 분리할 수 있다.

### 3.3 parallel()

3.1 절과 3.2 절의 Operator 에서 다뤄지는 스레드 개념은 동시성을 가지는 논리적인 스레드에 해당하지만 `parallel()`은 병렬성을 가지는 물리적인 스레드에 해당한다. 여기서 말하는 물리적인 스레드는 논리적인 코어의 개수다.

## 4. publishOn()과 subscribeOn()의 동작 이해

두 Operator 를 모두 사용한다면 구독이 일어난 직후에 실행되고, 그 이후에 `publishOn()` 의 실행이 처리되기 때문에 순서가 `publishOn()` &rarr; `subscribeOn()` 으로 흘러간다.

## 5. Scheduler 의 종류

### 5.1 Scheduler.immediate()

`Scheduler.immediate()`는 별도의 스레드를 추가적으로 생성하지 않고, 현재 스레드에서 작업을 처리하기 위한 용도의 Scheduler 다.

### 5.2 Scheduler.single()

`Scheduler.single()`은 스레드 하나만 생성해서 Scheduler 가 제거되기 전까지 재사용하는 용도의 Scheduler 다.

### 5.3 Scheduler.newSingle()

`Scheduler.newSingle()`은 `Scheduler.newSingle()`이 호출될 때마다 매번 새로운 스레드 하나를 생성한다. `newSingle()` 메서드의 첫번째 파라미터로는 생성할 스레드의 이름, 두번째 파라미터로는 스레드를 데몬 스레드로 동작하게 할지 여부를 받는다.

### 5.4 Scheduler.boundedElastic()

`Scheduler.boundedElastic()`은 ExecutorService 기반의 스레드 풀을 생성한 후, 그 안에서 정해진 수만큼의 스레드를 사용해 작업을 처리하고 작업이 종료된 스레드는 반납해 재사용한다.

기본적으로 `CPU 코어 수 * 10` 만큼의 스레드를 생성하며, 풀에 있는 모든 스레드가 작업을 처리하고 있다면 이용 가능한 스레드가 생길 때까지 최대 100,000개의 작업이 큐에서 대기할 수 있다. 

Blocking I/O 작업이 수행되는데 오랜 시간 스레드가 사용되고 있을 때, 다른 Non-Blocking 처리에 영향을 주지 않도록 전용 스레드를 할당하기 때문에 Blocking I/O 를 효과적으로 처리하기 위해 필요한 방식이다.

### 5.5 Scheduler.parallel()

Non-Blocking I/O 에 최적화되어 있는 Scheduler 로 CPU 코어 수만큼의 스레드를 생성한다.

### 5.6 정리 및 추가 정보

1. **기본 스케줄러**
    - `Schedulers.parallel()`: CPU 바운드 작업에 적합
    - `Schedulers.boundedElastic()`: I/O 바운드 작업에 적합
    - `Schedulers.immediate()`: 현재 스레드에서 실행
    - `Schedulers.single()`: 단일 스레드에서 실행
2. **스케줄러 선택 가이드**
    - I/O 작업(네트워크, 파일 등): `boundedElastic()`
    - CPU 집약적 작업: `parallel()`
    - 빠른 작업: `immediate()`
    - 순차적 실행이 필요한 작업: `single()`
3. 성능 고려사항
    - `boundedElastic()`은 I/O 작업에 최적화되어 있지만, 과도한 사용은 메모리 사용량을 증가시킬 수 있다.
    - 적절한 타임아웃 설정이 중요하다.
    - 로깅은 비동기 작업의 추적에 매우 중요하므로 스케줄링에 로깅도 고려하자.