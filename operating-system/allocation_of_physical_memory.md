# Allocation of Physical Memory

메모리는 일반적으로 두 영역으로 나뉘어 사용된다.

1. OS 상주 영역
   - interrupt vector와 함께 낮은 주소 영역 사용
2. 사용자 프로세스 영역
   - 높은 주소 영역 사용

- 사용자 프로세스 영역의 할당 방법
  - Contiguous allocation: 각각의 프로세스가 메모리의 연속적인 공간에 적재되도록 하는 방법   
    - Fixed partition allocation
    - Variable partition allocation
  - Noncontiguous allocation : 하나의 프로레스가 메모리의 여러 영역에 분산되어 올라가도록 하는 방법
    - Paging
    - Segmentation
    - Paged Segmentation

## Dynamic Relocation

운영체제는 여러 프로세스를 동시에 메모리에 올리고 내리는 역할을 수행하는데, 동적으로 메모리를 할당하는 과정에서 **MMU**를 이용한다.

이때 메모리 주소는 논리 주소와 물리 주소, 두가지 개념으로 나뉜다. CPU는 logical address를 이용하고, MMU는 CPU가 logical address를 넘겨주면   
MMU가 relocation register(해당 프로세스의 physical address의 시작 주소)를 가지고 physical address에 매핑한다. 

MMU는 limit register(해당 프로세스가 할당받는 메모리 공간의 크기)값을 갖고, logical address가 이 크기를 벗어나면 잘못된 요청임을 감지하고 명령을 수행하지 않는다.

![dynamic_relocation.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/allocation_of_physical_memory/dynamic_relocation.png?raw=true)

이렇게 relocation이 일어날 수 있는 것은 하나의 프로세스가 통째로 올라가는 contiguous allocation이 일어났을 때의 일이고, 프로세스가 각기 다른 메모리 위치에 나뉘어 할당되면 위의 예시처럼 하나의 MMU로 relocation을 할 수 없다. 

## Contiguous allocation

- 고정 분할(Fixed partition) 방식
  - 물리적 메모리를 몇 개의 영구적 분할(partition)로 나눈다.
  - 분할의 크기가 모두 동일한 방식과 서로 다른 방식이 존재한다.
  - 분할 당 하나의 프로그램이 적재된다.
  - 융통성이 없다.
    - 동시에 메모리에 load되는 프로그램 수가 고정된다.
    - 최대 수행 가능 프로그램의 크기가 제한된다.
  - Internal fragmentation(external fragmentation도 발생)

  
- 가변 분할(Variable partition) 방식
  - 프로그램의 크기를 고려해서 할당한다.
  - 분할의 크기, 갯수가 동적으로 변한다.
  - 기술적 관리 기법이 필요하다.
  - External fragmentation이 발생한다.


- External fragmentation(외부 조각)
  - 프로그램 크기보다 분할의 크기가 작은 경우
  - 아무 프로그램에도 배정되지 않은 빈 곳인데도 프로그램이 올라갈 수 없는 작은 분할
- Internal fragmentation(내부 조각)
  - 프로그램 크기보다 분할의 크기가 큰 경우
  - 하나의 분할 내부에서 발생하는 사용되지 않는 메모리 조각
  - 특정 프로그램에 배정되었지만 사용되지 않는 공간

- Hole
  - 가용 메모리 공간을 부르는 말이다.
  - 다양한 크기의 hole들이 메모리 여러 곳에 흩어져 있다.
  - 프로세스가 도착하면 수용가능한 hole에 할당한다.
  - 운영체제는 다음의 정보를 유지한다.
    - 할당 공간
    - 가용 공간(hole)

## NonContiguous allocation

[paging](../../../Users/admin/Downloads/note/operating-system/paging.md)

[segment](../../../Users/admin/Downloads/note/operating-system/segmentation.md)

