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
    - O(1)인 LRU의 list 조작조차 불가능

## 2. Paging system에서 LRU, LFU 가능한가?

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/virtual_memory2/lru_lfu_is_possible_in_paging_system.png?raw=true" width="70%">

## 3. Clock Algorithm

LRU, LFU에서 필요로 하는 것을 운영체제는 알 수 없다(page default가 나서 I/O를 하는 그 시점만 운영체제는 알고 있고, 재사용되는 것은 알 수 없다).

따라서 실제로 사용되는 알고리즘은 두가지가 아니다. Clock Algorithm이다. Vitual Memory 시스템에서 일반적으로 사용하는 알고리즘이 이 것이다.

- LRU의 근사(approximation) 알고리즘
- 여러 명칭으로 불림
  - Second chance algorithm
  - NUR(Not Used Recently) 또는 NRU(Not Recently Used)
- Reference bit을 사용해서 교체 대상 페이지 선정 (circular list)
- Reference bit가 0인 것을 찾을 때까지 포인터를 하나씩 앞으로 이동
- 포인터가 이동하는 중에 reference bit 1은 모두 0으로 바꿈
- Reference bit이 0인 것을 모두 찾으면 그 페이지를 교체
- 한 바퀴 되돌아와서도(=second chance) 0이면 그때에는 replace 당함
- 자주 사용되는 페이지라면 second chance가 올 때 1

### 3.1 Clock Algorithm의 개선

- reference bit와 modified bit(dirty bit)을 함께 사용
- reference bit = 1 : 최근에 참조된 페이지
- modified bit = 1 : 최근에 변경된 페이지(I/O를 동반하는 페이지)

