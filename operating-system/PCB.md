# PCB

프로세스가 생성될 때 커널 영역에 생성되는, 해당 프로세스의 문맥 정보를 저장하는 자료구조이다.

## 구성 요소

1. OS가 관리상 사용하는 정보
    - Process state, Process ID
    - Scheduling information, priority
2. CPU 수행 관련 하드웨어 값
    - Program counter, registers
3. 메모리 관련
    - Code, Stack, Data 의 위치 정보
4. 파일 관련
    - Open file descriptors...