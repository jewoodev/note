# Address

- Symbolic Address
  - 프로그래머가 사용하는 변수 이름
- Logical Address(= virtual address)
  - 프로세스마다 독립적으로 가지는 주소 공간
  - 각 프로세스마다 0번지부터 시작
  - CPU가 보는 주소는 logical address 이다.
- Physical Address
  - 메모리에 실제로 올라가는 위치

* 주소 바인딩: 주소를 결정하는 것  
  Symbolic Address &rarr; Logical Address &rarr; Physical Address

## Address Binding

- Compile time binding
  - 물리적 메모리 주소(physical address)가 컴파일 시 알려진다.
  - 시작 위치 변경시 다시 재컴파일한다.
  - 컴파일러는 절대 코드(absolute code)를 생성한다.
- Load time binding
  - Loader의 책임 하에 물리적 메모리 주소가 부여된다.
  - 컴파일러가 재배치가능코드(relocatable code)를 생성한 경우 가능하다.
- Execution time binding(= Runtime binding)
  - 수행이 시작된 이후에도 프로세스의 메모리 상 위치를 옮길 수 있다.
  - CPU가 주소를 참조할 때마다 binding을 점검(address mapping table)
  - 하드웨어적인 지원이 필요  
    (ex. base and limit registers, MMU)

## Dynamic Loading

프로세스 전체를 메모리에 미리 다 올리는 것이 아니라 해당 루틴이 불려질 때 메모리에 load하는 전략을 일컫는다. 이는 memory utilization을 높인다.

가끔씩 사용되는 코드의 양이 많으면 많을수록 유욯하다.(ex. 오류 처리 루틴)

운영체제의 특별한 지원 없이 프로그램 자체에서 구현이 가능하다(OS는 라이브러리를 통해 지원 가능).

## Overlays

메모리에 프로세스의 부분 중 실제 필요한 정보만을 올린다. 프로세스의 크기가 메모리보다 클 때 유용하다.

운영체제의 지원없이 사용자에 의해 구현이 되고, 작은 공간의 메모리를 사용하던 초창기 시스템에서 수작업으로 프로그래머가 구현한다.

### Dynamic Loading과의 차이점

Dynamic Loading은 라이브러리를 통해 보다 적은 비용으로 구현이 가능하지만, Overlays는 라이브러리없이 구현하기에 비용이 비싸다.

## Swapping

프로세스를 일시적으로 메모리에서 backing store로 쫓아내는 걸 일컫는다.

- Backing store(= swap area)
  - 디스크
    - 많은 사용자의 프로세스 이미지를 담을 만큼 충분히 빠르고 큰 저장 공간
- Swap in / Swap out
  - 일반적으로 중기 스케줄러(swapper)에 의해 swap out 시킬 프로세스 선정한다.
  - priority-based CPU scheduling algorithm
    - priority가 낮은 프로세스를 swapped out 시킨다.
    - priority가 높은 프로세스를 메모리에 올려 놓는다.
  - Compile time 혹은 load time binding에서는 원래 메모리 위치로 swap in 해야 한다.
  - Execution time binding에서는 추후 빈 메모리 영역 아무 곳에서나 올릴 수 있다.
  - swap time은 대부분 transfer time(swap 되는 양에 비례하는 시간)이다.

## Dynamic Linking

Linking을 실행 시간(execution time)까지 미루는 기법이다.

- Static linking
  - 라이브러리가 프로그램의 실행 파일 코드에 포함된다.
  - 실행 파일의 크기가 커진다.
  - 동일한 라이브러리를 각각의 프로세스가 메모리에 올리므로 메모리가 낭비된다(ex. printf 함수의 라이브러리 코드).
- Dynamic linking
  - 라이브러리가 실행 시 연결(link)된다.
  - 라이브러리 호출 부분에 라이브러리 루틴의 위치를 찾기 위한 stub이라는 작은 코드를 둔다.
  - 라이브러리가 이미 메모리에 있으면 그 루틴의 주소로 가고 없으면 디스크에서 읽어온다.
  - 운영체제의 도움이 필요하다.

> Linking 이라는 건, 컴파일 된 하나의 파일에서 다른 파일(외부 라이브러리나 기타 코드 파일)의 내용들을 묶어서 하나의 실행 파일을 만드는 과정을 말한다.

## Allocation of Physical Memory

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

### Contiguous Allocation

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
 