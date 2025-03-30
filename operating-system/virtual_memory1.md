# Virtual memory 1

## Demand paging

- 실제로 필요할 때 page를 메모리에 올리는 것
  - I/O 양의 감소
  - Memory 사용량의 감소
  - 빠른 응답 시간
  - 더 많은 사용자 수용
- Valid / Invalid bit의 사용
  - Invalid 의 의미
    - 사용되지 않는 주소 영역인 경우
    - 페이지가 물리적 메모리에 없는 경우
  - 처음에는 모든 page entry가 invalid로 초기화
  - address translation 시에 invalid bit이 set 되어 있으면 "page fault"
    - cpu는 자동적으로 운영체제에게 control이 넘어가고(trap 발생) 디스크에서 I/O를 수행하게 된다.

## Page fault

- invalid page를 접근하면 MMU가 trap을 발생시킴(page fault trap)
- Kernel mode로 들어가서 page fault handler가 invoke됨
- 다음과 같은 순서로 page fault를 처리함
  1. Invalid reference? (ex. bad address, protection violation) &rarr; abort
  2. Get an empty page frame. (없으면 뺏어옴:replace)
  3. 해당 페이지를 disk에서 memory로 읽어옴
     1. disk I/O가 끝나기까지 이 프로세스는 CPU를 prompt 당함 (block)
     2. disk read가 끝나면 page tables entry에 기록, valid/invalid bit &rarr; "valid"
     3. ready queue에 process를 insert &rarr; dispatch later
  4. 이 프로세스가 CPU를 잡고 다시 running
  5. 아까 중단되었던 instruction을 재개

## Free frame이 없는 경우

- Page replacement
  - 어떤 frame을 빼앗아올지 결정해야 함
  - 곧바로 사용되지 않을 page를 쫓아내는 것이 좋음
  - 동일한 페이지가 여러 번 메모리에서 쫓겨났다가 다시 들어올 수 있음
- Replacement Algorithm
  - page-fault rate를 최소화하는 것이 목표
  - 알고리즘의 평가
    - 주어진 page reference string에 대해 page fault를 얼마나 내는지 조사
  - reference string의 예
    - 1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5.

## Optimal Algorithm of Replacement 

page fault가 가장 적게 일어나도록 하는 알고리즘

- MIN(OPT): 가장 먼 미래에 참조되는 page를 replace 
- 4 frames example
  - ![oaor_4frames_example.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/oaor_4frames_example.png?raw=true)
- 미래의 참조를 어떻게 아는가?
  - Offline algorithm
- 다른 알고리즘의 성능에 대한 upper bound 제공
  - Belady's optimal algorithm, MIN, OPT 등으로 불림

## FIFO Algorithm

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/fifo_algorithm.png?raw=true" width="70%">

- FIFO Anomaly(Belady's Anomaly)
  - more frames !=> less page faults

## LRU(Least Recently Used) Algorithm

- LRU: 가장 오래 전에 참조된 것을 지움

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/lru_algorithm.png?raw=true" width="60%">

## LFU(Least Frequently Used) Algorithm

- LFU: 참조 횟수가 가장 적은 페이지를 지움
  - 최저 참조 함수인 page가 여럿 있는 경우
    - LFU 알고리즘 자체에서는 여러 page 중 임의로 선정한다.
    - 성능 향상을 위해 가장 오래 전에 참조된 page를 지우게 구현할 수도 있다.
  - 장단점
    - LRU처럼 직전 참조 시점만 보는 것이 아니라 장기적인 시간 규모를 보기 때문에 page의 인기도를 좀 더 명확히 반영할 수 있음
    - 참조 시점의 최근성을 반영하지 못함
    - LRU보다 구현이 복잡함

## LRU와 LFU 알고리즘 예제

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/example_of_lru_lfu.png?raw=true" width="60%">

## LRU와 LFU 알고리즘의 구현

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/impl_of_lru_lfu1.png?raw=true" width="70%">

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory1/impl_of_lru_lfu2.png?raw=true" width="70%">

