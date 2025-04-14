#  프로세스 동기화

## 데이터의 접근

![access_of_data.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Process_Synchronization/access_of_data.png?raw=true)

| E-box     | S-box         |
|-----------|---------------|
| (1) CPU   | Memory        |
| (2) 컴퓨터내부 | 디스크           |
| (3) 프로세스  | 그 프로세스의 주소 공간 |

## Race Condition

![race_condition.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Process_Synchronization/race_condition.png?raw=true)

S-box(Memory Address Space)를 공유하는 E-box(CPU Process)가 여럿 있는 경우 Race Condition의 가능성이 있음

> Multiprocessor system  
> 공유메모리를 사용하는 프로세스들  
> 커널 내부 데이터를 접근하는 루틴들 간(ex. 커널모드 수행 중 인터럽트로 커널모드 다른 루틴 수행 시)

### OS에서 race condition은 언제 발생하는가?

1. kernel 수행 중 인터럽트 발생 시
2. Process가 system call을 하여 kernel mode로 수행 중인데 context switch가 일어나는 경우
3. Multiprocessor에서 shared memory 내의 kernel data

Kernel 영역에서 변수값을 업데이트하는 instruction이 수행 중에 있는데, 인터럽트가 발생하면 race condition이 발생한다. OS는 이 경우의 race condition을 막고자 interrupt 플래그를 disable 시켜 해당 instruction이 완료될 때까지 interrupt를 승인받지 않는다.

따라서 Kernel 모드에서 수행 중일 때는 할당 시간이 끝나든, 어떤 트리거에 의해서든 CPU를 preempt 하지 않고 커널 모드에서 유저 모드로 돌아갈 때 preempt한다.

1, 2번의 경우는 이 방법으로 해결이 된다. 하지만 3번의 경우는 앞에서 설명한 어떤 방법으로도 해결이 되지 않는다.

3번의 경우의 해결 방법 두가지를 알아보자.

1. 커널 영역 안에 한번에 하나의 CPU만이 커널에 들어갈 수 있게 하는 방법(= 커널 영역 전체에 lock을 거는 것과 같다.)
2. 커널 내부에 있는 각 공유 데이터에 접근할 때마다 그 데이터에 대한 lock/unlock을 하는 방법

## 프로그램 해결법의 충족 조건

- Mutual Exclusion(상호 배제)
  - 프로세스 1가 critical section 부분을 수행 중이면 다른 모든 프로세스들은 그들의 critical section에 들어가면 안된다.
- Progress(진행)
  - 아무도 critical section에 있지 않은 상태에서 critical section에 들어가고자 하는 프로세스가 있으면 critical section에 들어가게 해주어야 한다.
- Bounded Waiting(유한 대기)
  - 프로세스가 critical section에 들어가려고 요청한 후부터 그 요청이 허용될 때까지 다른 프로세스들이 critical section에 들어가는 횟수에 한계가 있어야 한다.

### 가정

- 모든 프로세스의 수행 속도는 0보다 크다.
- 프로세스들 간의 상대적인 수행 속도는 가정하지 않는다.

### 모두 충족하는 Algorithm(Peterson's Algorithm)

- Combined synchronization variables of algorithms 1 and 2.
- Process Pi

```
do {
    flag[i] = true; /* My intention is to enter .... */
    turn = j; /* Set to his turn */
    while(flag[j] && turn == j); /* wait only if ... */
    critical section
    flag[i] = false;
    remainder section
} while(1);
```

- Meets all three requirements; solves the critical section problem for two processes.
- Busy Waiting(= spin lock)! (계속 CPU와 memory를 쓰면서 wait)

### Synchronization Hardware

하드웨어적으로 `Test & Modify(Set)`를 atomic하게 수행할 수 있도록 지원하는 경우 앞의 문제는 간단히 해결된다.

`Test & Modify(Set)`를 atomic하게 수행한다는 건 변수를 읽고 값을 수정하는게 원자적으로 이루어지게 끔 한다는 것이다.

boolean 값을 `Test & Modify(Set)` 에 넣어서 이미 사용 중이면 while문에 머물도록 하면 된다.