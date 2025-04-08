# Paging

- Process의 virtual memory를 동일한 사이즈의 page 단위로 나눈다.
- Virtual memory의 내용이 page 단위로 noncontiguous하게 저장된다.
- 일부는 backing storage에, 일부는 physical memory에 저장한다.

## Basic Method

- physical memory를 동일한 크기의 frame으로 나눈다.
- logical memory를 동일 크기의 page로 나눈다(frame과 같은 크기).
- 모든 가용 frame들을 관리한다.
- page table을 사용해 logical address를 physical address로 변환한다.
- external fragmentation이 발생하지 않는다.
- internal fragmentation이 발생할 가능성이 있다.

## Address Translation Architecture

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/address_translation_architecture.png?raw=true" width="50%">

p가 f로 바뀌는게 page table을 통해 physical address의 page 번호로 변환되고, d(오프셋)은 logical address의 것과 physical address의 것이 동일하다.

## Implementation of Page Table

- Page table은 main memory에 상주한다.
- Page-table base register(PTBR)가 page table을 가리킨다.
- 모든 메모리 접근 연산에는 2번의 memory access가 필요하다.
- page table 접근 1번, 실제 data/instruction 접근 1번
- 속도 향상을 위해 associative register 혹은 translation look-aside buffer(TLB)라 불리는 고속의 lookup hardware cache를 사용한다.

## Paging Hardware with TLB

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/paging_hardware_with_tlb.png?raw=true" width="50%">

## Associative Register

- Associative rigister(TLB): parallel search가 가능
    - TLB에는 page table 중 일부만 존재
- Address translation
    - page table 중 일부가 associative register에 보관되어 있다.
    - 만약 해당 page #가 associative register에 있는 경우 곧바로 frame #을 얻는다.
    - 그렇지 않으면 main memory에 있는 page table로부터 frame #을 얻는다.
    - TLB는 contect switch 때 flush(remove old entries)한다.

## Effective Access Time

- Associative register lookup time = ${\varepsilon}$
- memory cycle time = 1
- Hit ratio = ${\alpha}$
    - associative register에서 찾아지는 비율
- Effective Access Time(EAT)  
  <img src="effective_access_time.png" width="50%">

## 1. Two-Level Page table

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/two_level_page_table.png?raw=true" width="50%">

- 현대의 컴퓨터는 address space가 매우 큰 프로그램 지원
  - 32 bit address 사용시: ${2^{32}}$B(4GB) 주소 공간
    - page size가 4K시 1M 개의 page table entry 필요
    - 각 page entry가 4B시 프로세스 당 4M의 page table 필요
    - 그러나, 대부분의 프로그램은 4G의 주소 공간 중 지극히 일부분만 사용하므로 page table 공간이 심하게 낭비됨

inner-page table은 페이지 크기로 생성된다. 위의 예시에서 page size가 4K이고 page entry가 4B면 1K개 만큼의 entry를 inner-page table 하나당 저장할 수 있다. 

inner-page table은 페이지 단위로써 필요할 때마다 생성되어 메모리의 page 하나에 저장된다.

> &rarr; page table 자체를 page로 구성
> 
> &rarr; 사용되지 않는 주소 공간에 대한 outer page table의 엔트리 값은 NULL(대응하는 inner page table이 없음)

### 1.1 Address-Translation Scheme

Two-Level Paging에서 Address-translation scheme

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/address_translation_scheme.png?raw=true" width="60%">

### 1.2 Two-Level Paging Example

- logical address(on 32-bit machine with 4K page size)의 구성
  - 20 bit의 page number
  - 12 bit의 page offset
- page table 자체가 page로 구성되기 때문에 page number는 다음과 같이 나뉜다(각 page table entry가 4B).
  - 10-bit의 page number
  - 10-bit의 page offset
- 따라서, logical address는 다음과 같다.

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/logical_address_example_of_two_level_paging.png?raw=true" width="50%">

- p1은 outer page table의 index이고
- p2sms outer page table의 page에서의 변위(displacement)

## Memory Protection

Page table의 각 enrty마다 아래의 bit를 둔다.

- Protection bit
  - page에 대한 접근 권한(read/write/read-only)
- Valid-invalid bit
  - "valid"는 해당 주소의 frame에 그 프로세스를 구성하는 유효한 내용이 있음을 뜻함(접근 허용)
  - "invalid"는 해당 주소의 frame에 유효한 내용이 없음을 뜻함(접근 불허)
    1. 프로세스가 그 주소 부분을 사용하지 않는 경우
    2. 해당 페이지가 메모리에 올라와 있지 않고 swap area에 있는 경우

## 2. Inverted Page Table

- Page table이 매우 큰 이유
  - 모든 process 별 logical address에 대응하는 모든 page에 대해 page table entry가 존재
  - 대응하는 page가 메모리에 있든 아니든 간에 page table에는 entry로 존재
- Inverted page table
  - Page frame 하나 당 page table에 하나의 entry를 둔 것 (system-wide)
  - 각 page table entry는 각각의 물리적 메모리의 page frame이 담고 있는 내용 표시(process-id, process의 logical address)
  - 단점
    - 테이블 전체를 탐색해야 함
  - 조치
    - associative register 사용(expensive)

### 2.1 Inverted Page Table Architecture

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/inverted_page_table_architecture.png?raw=true" width="50%">

## 3. Shared Page

- Shared code
  - Re-entrant Code(=Pure code)
  - read-only로 하여 프로세스 간에 하나의 code만 메모리에 올림(ex. text editors, compilers, window systems)
  - Shared code는 모든 프로세스의 logical address space에서 동일한 위치에 있어야 함
- Private code and data
  - 각 프로세스들은 독자적으로 메모리에 올림
  - Private data는 logical address space의 아무 곳에 와도 무방

### 3.1 Shared Pages Example

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/paging/shared_pages_example.png?raw=true" width="50%">
