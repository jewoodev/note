# Virtual memory 2

## 1. Diverse environment of cashing

- 캐싱 기법
  - 한정된 빠른 공간(=캐시)에 요청된 데이터를 저장해 두었다가 후속 요청시 캐시로부터 직접 서비스하는 방식
  - paging system 외에도 cache memory, buffer caching, Web caching 등 다양한 분야에서 사용
- 캐싱 기법의 시간 제약
  - 교체 알고리즘에서 삭제할 항목을 결정하는 일에 지나치게 많은 시간이 걸리는 경우 실제 시스템에서 사용할 수 없음
  - Buffer caching 이나 Web caching 의 경우
    - O(1) 에서 O(log n) 정도까지 허용
  - Paging system 인 경우
    - page fault 인 경우에만 OS가 관여함
    - 페이지가 이미 메모리에 존재하는 경우 참조 시각 등의 정보를 OS가 알 수 없음
    - O(1)인 LRU 의 list 조작조차 불가능

## 2. Paging system 에서 LRU, LFU 가능한가?

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory2/lru_lfu_is_possible_in_paging_system.png?raw=true" width="70%">

## 3. Clock Algorithm

LRU, LFU 에서 필요로 하는 것을 운영체제는 알 수 없다(page default 가 나서 I/O를 하는 그 시점만 운영체제는 알고 있고, 재사용되는 것은 알 수 없다).

따라서 실제로 사용되는 알고리즘은 두가지가 아니다. Clock Algorithm 이다. Virtual Memory 시스템에서 일반적으로 사용하는 알고리즘이 이 것이다.

- LRU 의 근사(approximation) 알고리즘
- 여러 명칭으로 불림
  - Second chance algorithm
  - NUR(Not Used Recently) 또는 NRU(Not Recently Used)
- Reference bit 을 사용해서 교체 대상 페이지 선정 (circular list)
- Reference bit 가 0인 것을 찾을 때까지 포인터를 하나씩 앞으로 이동
- 포인터가 이동하는 중에 reference bit 1은 모두 0으로 바꿈
- Reference bit 이 0인 것을 모두 찾으면 그 페이지를 교체
- 한 바퀴 되돌아와서도(=second chance) 0이면 그때에는 replace 당함
- 자주 사용되는 페이지라면 second chance 가 올 때 1

### 3.1 Clock Algorithm 의 개선

- reference bit 와 modified bit(dirty bit)을 함께 사용
- reference bit = 1 : 최근에 참조된 페이지
- modified bit = 1 : 최근에 변경된 페이지(I/O를 동반하는 페이지)

modified bit 을 각 페이지에 할당해서 무거운 I/O 작업을 줄일 수 있는 전략을 사용할 수 있다. 

modified bit이 1이면 메모리에서 쫓아내지 않고, 0이면 쫓아내면 페이지를 쫓겨내면서 디스크에 써줄 필요가 없기 때문에 보다 더 빠르게 처리할 수 있게 되는 원리이다.

## 4. Page Frame 의 Allocation

- Allocation problem: 각 process 에 얼마 만큼의 page frame 을 할당할 것인가?
- Allocation 의 필요성
  - 메모리 참조 명령어 수행 시 명령어, 데이터 등 여러 페이지 동시 참조
    - 명령어 수행을 위해 최소한 할당되어야 하는 frame 의 수가 있음
  - Loop 를 구성하는 page 들은 한꺼번에 allocate 되는 것이 유리함
    - 최소한의 allocation 이 없으면 매 loop 마다 page fault


- Allocation scheme
  - Equal allocation: 모든 프로세스에 똑같은 갯수 할당
  - Proportional allocation: 프로세스 크기에 비례하여 할당
  - Priority allocation: 프로세스의 priority 에 따라 다르게 할당

### 4.1 Global vs. Local Replacement

- Global replacement
  - Replace 시 다른 process 에 할당된 frame 을 빼앗아 올 수 있다.
  - Process 별 할당량을 조절하는 또 다른 방법임
  - FIFO, LRU, LFU 등의 알고리즘을 global replacement 로 사용 시에 할당
  - Working set, PFF 알고리즘 사용


- Local replacement
  - 자신에게 할당된 frame 내에서만 replacement
  - FIFO, LRU, LFU 등의 알고리즘을 process 별로 운영 시

### 4.2 Thrashing

- 프로세스의 원활한 수행을 위해 필요한 최소한의 page frame 의 갯수만큼을 할당받지 못한 경우 발생한다.
- Page fault rate 가 매우 높아진다.
- CPU utilization 이 낮아진다.
- OS는 MPD(Multiprogramming degree)를 높여야 한다고 판단
- 또 다른 프로세스가 시스템에 추가됨(higher MPD)
- 프로세스 당 할당된 frame 의 수가 더욱 감소
- 프로세스는 page 의 swap in / swap out 으로 매우 바쁨
- 대부분의 시간에 CPU 는 한가함
- low throughput

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory2/thrashing_diagram.png?raw=true" width="70%">

Thrashing 이 발생되지 않도록 예방하기 위해서는 degree of multiprogramming 을 높여야 하고, 그러다가 해당 degree 가 너무 높아지면 CPU utilization 이 급격히 나빠지는(시스템이 매우 비효율적이 되는) 결과로 이어진다. 이런 현상을 막기 위해서는 degree 를 조절해줘야 한다.

그런 조절을 해주는 알고리즘이 PFF Scheme 과 Working-Set Model 이다.

#### 4.2.1 Working-Set Model

- Locality of reference
  - 프로세스는 특정 시간 동안 일정 장소만을 집중적으로 참조한다.
  - 집중적으로 참조되는 해당 page 들의 집합을 locality set 이라 한다.


- Working-Set Model
  - Locality 에 기반하여 프로세스가 일정 시간 동안 원활하게 수행되기 위해 한꺼번에 메모리에 올라와 있어야 하는 page 들의 집합을 Working Set 이라 정의한다.
    - Working Set Model 에서는 process 의 Working Set 전체가 메모리에 올라와 있어야 수행되고 그렇지 않을 경우 모든 frame 을 반납한 후 swap out(suspend) 
    - Thrashing 을 방지한다.
    - Multiprogramming degree 를 결정한다.

#### 4.2.2 Working-Set Algorithm

- Working Set 의 결정
  - Working Set window 를 통해 알아낸다.
  - Window size 가 $\Delta$인 경우
    - 시각 t$_{i}$ 에서의 working set WS (t$_{i}$)
  - Time interval [t$_{i}$ -$\Delta$, t$_{i}$] 사이에 참조된 서로 다른 페이지들의 집합
    - Working set 에 속한 page 는 메모리에 유지, 속하지 않은 것은 버림(즉, 참조된후 $\Delta$시간 동안 해당 page를 메모리에 유지한 후 버림)

  <img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory2/working_set_decision.png?raw=true" width="70%">

- Working Set Algorithm
  - Process 들의 working set size 의 합이 page frame 의 수보다 큰 경우
    - 일부 process 를 swap out 시켜 남은 process 의 working set 을 우선적으로 충족시켜 준다(MPD 를 줄임).
  - Working set 을 다 할당하고도 page frame 이 남는 경우
    - Swap out 되었던 프로세스에게 working set 을 할당(MPD 를 키움)

- Window size $\Delta$
  - Working set 을 제대로 탐지하기 위해서는 window size 를 잘 결정해야 한다.
  - $\Delta$값이 너무 작으면 locality set 을 모두 수용하지 못할 우려
  - $\Delta$값이 크면 여러 규모의 locality set 을 수용
  - $\Delta$값이 $\infty$이면 전체 프로그램을 구성하는 page 를 working set 으로 간주

#### 4.2.3 PFF(Page-Fault Frequency) Scheme

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory2/pff.png?raw=true" width="70%">

- Page-fault rate 의 상한값과 하한값을 둔다.
  - Page fault rate 이 상한값을 넘으면 frame 을 더 할당한다.
  - Page fault rate 이 하한값 이하이면 할당 frame 수를 줄인다.
- 빈 frame 이 없으면 일부 프로세스를 swap out.

## 5. Page Size 의 결정

- Page size 를 감소시키면
  - 페이지 수 증가
  - 페이지 테이블 크기 증가
  - Internal fragmentation 감소
  - Disk transfer 의 효율성 감소
    - Seek/rotation vs. transfer
  - 필요한 정보만 메모리에 올라와 메모리 이용이 효율적
    - Locality 활용 측면에서는 좋지 않음

- Trend
  - Larger page size

