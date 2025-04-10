# Segmentation

- 프로그램은 의미 단위인 여러 개의 segment로 구성된다.
  - 작게는 프로그램을 구성하는 함수 하나하나를 세그먼트로 정의
  - 크게는 프로그램 전체를 하나의 세그먼트로 정의 가능
  - 일반적으로는 code, data, stack 부분이 하나 씩의 세그먼트로 정의됨
- Segment는 다음과 같은 logical unit들이다.
  - main()
  - function
  - global variables
  - stack
  - symbol table, arrays

## Segmentation Architecture

- Logical address는 다음의 두 가지로 구성
  1. segment-number
  2. offset
- Segment table
  - each table entry has:
    - base: starting physical address of the segment
    - limit: length of the segment
- Segment-table base register(STBR)
  - 물리적 메모리에서의 segment table의 위치
- Segment-table length register(STLR)
  - 프로그램이 사용하는 segment의 수  
    segment number s is legal if s < STLR.

## Segmentation Hardware

<img src="https://github.com/jewoodev/blog_img/blob/main/operating-system/segmentation/segmentation_hardware.png?raw=true" width="60%">

## Segmentation Architecture (Cont.)

- Protection
  - 각 세그먼트 별로 protection bit가 있음
  - Each entry:
    - Valid bit = 0 &rarr; illegal segment
    - Read/Write/Execution 권한 bit
- Sharing
  - shared segment
  - same segment number
  - segment는 의미 단위이기 때문에 공유와 보안에 있어 paging보다 훨씬 효과적이다.
- Allocation
  - first fit / best fit
  - external fragmentation 발생
  - segment의 길이가 동일하지 않으므로 가변 분할 방식에서와 동일한 문제점들이 발생한다.