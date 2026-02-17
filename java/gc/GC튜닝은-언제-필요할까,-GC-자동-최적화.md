> - 이 문서에서 Java Heap보다 JVM Heap이라는 용어를 사용합니다.
> - 이 문서에서 JVM은 hospot VM을 지칭합니다.
> - 기본적으로 serial GC를 기준으로 서술합니다.

Java가 세상에 나오기 전, C++ 까지의 언어는 개발자가 직접 메모리를 할당받고 반납하는 작업을 해야 했다. 그런 작업은 코드 양이 늘어날수록 찾기 힘든 실수가 생기기 쉬워지는 문제를 갖고 있었다. 그걸 언어 차원에서 대신해주는 GC로 인해 개발자는 그런 작업의 관리 비용을 제거할 수 있게 되었고, 메모리 영역을 직접 관리했을 때 생길 수 있는 여러 종류의 문제들도 제거할 수 있었다.

하지만 GC로 인한 오버헤드(어떤 오브젝트가 가비지인지 검사하는 작업의)가 발생할 수 있다는 점도 고려해야 하는 부분이다.

# GC 핵심 내용
## GC의 역할
- GC는 OS로부터 메모리 영역을 확보하고, 안쓰는 일부는 다시 OS에 반납하는 역할.
- 애플리케이션에서는 객체 생성 등 메모리가 필요할 때 마다 GC가 확보한 메모리 영역을 사용.
- GC는 OS로부터 할당받은 메모리 영역 중에 애플리케이션이 실제로 사용하고 있는 영역과 그렇지 않은 영역을 파악.
- 사용되지 않는 영역은 회수해서 애플리케이션이 다시 재사용할 수 있도록 준비.
  - 파편화된 메모리 영역을 차지 중인 오브젝트들을 compact하게 연속된 공간으로 몰아넣는 것처럼 수행.
    - 실제로 메모리 주소를 옮기진 않음.

## GC의 주요 테크닉
- **세대별 청소**(generational scavenging)와 **aging** 기법을 사용해서 JVM heap 내에서도 회수할 만한 객체(메모리)가 많이 있을 법한 영역에 집중한다.
- 살아있는 객체들은 한 곳에 모아서 최대한 연속된 free 영역을 확보하려고 노력한다.
  - 개념적으로는 이렇지만 실제 동작은 조금 다름.
- GC가 동작할 때 여러 스레드를 사용해서 최대한 **병렬**로 동작할 수 있도록 하고, 오래 걸리는 GC 작업은 백그라운드에서 애플리케이션 코드와 동시에 실행될 수 있도록 한다.

## 언제 GC 선택과 튜닝이 중요한가?
- 기본적으로 자바실행환경(Java SE)이 알아서 애플리케이션이 실행되는 컴퓨터의 시스템 특성을 보고 어떤 GC로 동작할지 선택한다.
- GC가 어느 정도의 빈도와 길이의 중단(pause)을 가지더라도 애플리케이션의 성능이 잘 나온다면 별도의 GC 선택과 튜닝은 필요 없다.
- 하지만 이 기본 선택이 최선이 아닐 수도 있다. 가령 스케일이 큰 애플리케이션, 특히 데이터를 많이 쓰고, 스레드도 많이 쓰고, 높은 처리량을 요구하는 애플리케이션의 성능을 위해 별도의 GC 선택과 튜닝이 필요할 수도 있다.

## 왜 GC 선택과 튜닝이 중요한가?
- Amdahl's law: 어떤 문제에서 병렬을 통한 성능 향상은 해당 문제의 순차적인 부분에 의해 제한된다.
- 소규모 시스템에서는 별 문제가 안될 GC로 인한 성능 이슈가 대규모 시스템으로 확장될 때는 주요 병목 지점이 될 수 있다.
- 대규모 시스템에서는 GC 오버헤드를 조금만 낮춰도 성능 향상 이점이 크기 때문에 적절한 garbage collector를 선택하고, 필요하다면 튜닝을 하는 것이 중요하고 가치 있다.
- (oracle JDK 25 기준) 자바는 네 가지의 garbage collector를 제공하는데, 그 중에 serial GC를 제외하고는 모두 성능 향상을 위해 **병렬**로 동작한다.

## 언제 serial GC가 적절한가?
- 소규모 애플리케이션, 사이즈가 작은 애플리케이션에 적절.
  - 특히 약 100MB 이하의 Heap size를 필요로 하는 애플리케이션에 적절.
  - 다른 garbage collector들은 추가적인 오버헤드와 복잡도가 있음.
- 사이즈가 큰 메모리와 멀티 프로세서(멀티 코어)를 갖춘 시스템에서 스케일이 크고 스레드를 헤비하게 쓰는 애플리케이션은 serial GC가 1옵션이 될 수 없다.
- 서버-클래스로 분류될 수 있는 머신에서 애플리케이션이 실행된다면 **G1 GC를 디폴트**로 사용.

---

# Ergonomics
- Ergonomics: JVM이 주어진 환경에서 GC와 메모리 관련 설정을 스스로 최적화 하는 것. 즉, 자동 최적화.
  - default selection: collector, heap size, GC threads 수, JIT compiler
  - 실행 중에 동적 조정(behavior-based tuning)
    - 아래 두 가지 목표를 맞추기 위해 사용자가 설정한 목표를 모니터링해서 실행 중에 동적으로 조정
    - Maximum Pause-Time goal(-XX:MaxGCPauseMillis=nnn)
    - Throughput goal(-XX:GCTimeRatio=nnn)
  - 위 두 가지 목표가 모두 충족되는 동안 maximum footprint를 추구하며 동작

## JVM의 주요 default 설정
- garbage collector
  - 서버용(server-class) 머신에서는 G1 GC(Garbage-First GC)를 사용. 그 외에는 serial GC 사용.
    - 서버용 머신 판단 기준: 두 개 이상의 프로세서를 가지며 RAM(physical memory) >= 1792 MB 인 경우.

- initial heap size: 1/64 of physical memory.
- maximum heap size: 1/4 of physical memory.
- minimum heap size: 디폴트 값이 약간 복잡하게 설정됨.
  - 이 세 가지 힙 사이즈는 서버 애플리케이션의 경우 동일하게 맞춤


- 최대 GC 스레드 수는 heap size와 이용 가능한 CPU resources에 의해 결정됨.
- JIT compiler: C1과 C2 모두 사용하는 tired compiler 사용.

---

# 힙 사이즈 조정
## Maximum Pause-Time goal
- pause time: GC로 인해 애플리케이션이 아예 멈추는 시간. 즉, stop-the-world 시간.
- pause time이 아무리 길어도 maximum pause-time goal보다는 적어야 한다는 것
- maximum pause-time goal은 `-XX:MaxGCPauseMillis=nnn` 로 지정. 여기서 `nnn`의 단위는 millisecond.
- GC는 pause time에 대한 가중 평균(weighted average)과 분산을 이용해서 이 둘의 합을 maximum pause-time goal과 비교.
- garbage collector는 heap size나 GC 관련 여러 파라미터들을 조정해서 pause time을 nnn millisecond 이하로 유지하려고 시도.
- maximum pause-time goal의 디폴트 값은 collector마다 다름.

## Throughput goal
- Throughput goal: GC(garbage collection) time과 application time을 비교해서 특정 비율을 맞추도록 하는 것.
  - GC time: 지금까지 GC에 의해 pause된 시간의 총합을 의미. 즉, stop-the-world가 된 시간의 총합.
  - application time: GC time 외의 시간의 총합.
    - 일부 GC 스레드가 애플리케이션과 병렬로 실행됐다면, 이 시간도 application time에 포함.
- throughput goal은 `-XX:GCTimeRatio=nnn`으로 지정.
  - `GC time ratio = 1 / (1+nnn)` 로 목표를 설정하는 것.
- throughput goal이 충족되지 않으면 GC는 여러가지 방법으로 이를 충족시키려고 함.
  - 그 방법 중 하나가 'heap size 늘리기' 

## Minimum Footprint
- Footprint: 프로세스가 현재 사용 중인 메모리의 크기. heap 크기가 전체 메모리 크기에 가장 영향력이 클 것임.
- throughput goal과 maximum pause-time goal이 모두 충족되면 garbage collector는 heap size를 조금씩 줄임.
  - 불필요하게 점유하는 메모리를 줄여서 다른 프로세스들도 메모리를 사용할 수 있도록 하게 위함.
  - 두 goal 중 하나라도 만족하지 못할 때까지 줄여나감.
    - 예외 없이 throughput goal이 먼저 깨짐
- minimum과 maximum heap size는 각각 `-Xms=nnn`와 `-Xmx=mmm` 옵션으로 지정할 수 있음.
  - `-Xms=nnn`으로 minimum heap size를 지정하면 initial heap size도 함께 지정됨.
    - 따라서 백엔드 서버 애플리케이션이라면 `-Xms=nnn`와 `-Xmx=mmm`을 동일하게 지정하는 것이 좋음.
      - 그래서 백엔드 서버 애플리케이션을 튜닝할 때는 throughput goal과 maximum pause-time goal을 통해서 얻을 수 있는 효과가 매우 적다.
      - 최소 & 최대 힙 사이즈를 동일하게 지정하여 힙 사이즈 조정 작업 자체를 없애기 때문.

