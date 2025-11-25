# CPU Scheduler & Dispatcher

- CPU Scheduler
  - Ready 상태의 프로세스 중에서 이번에 CPU를 줄 프로세스를 고른다.
- Dispatcher
  - CPU의 제어권을 CPU scheduler에 의해 선택된 프로세스에게 넘긴다.
    - 이 과정을 context switch 라고 한다.

CPU 스케줄링이 필요한 경우는 프로세스에게 다음과 같은 상태 변화가 있는 경우이다.

1. Running &rarr; Blocked (ex. I/O 요청하는 시스템 콜)
2. Running &rarr; Ready (ex. 할당시간 만료로 timer interrupt)
3. Blocked &rarr; Ready (ex. I/O 완료 후 인터럽트)
4. Terminate

1, 4 에서의 스케줄링은 nonpreemptive(강제로 빼앗지 않고 자진 반납)

나머지는 preemptive(강제로 뻬앗음)