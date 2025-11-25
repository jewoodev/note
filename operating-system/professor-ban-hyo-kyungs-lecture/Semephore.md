# Semaphore

소프트웨어 개발자가 프로세스 동기화에 대한 로직을 매번 반복적으로 구현하는 것을 추상화하여 간편하게 사용할 수 있게 하는 추상 자료형이다.

보통 integer 변수를 담고, 아래의 두 가지 atomic 연산에 의해서만 접근 가능하다.

```
P(S) :            while (S<=0) do no-op;
                  S--;
```
>                   If positive, decrement-&-enter.
>                   Otherwise, wait until positive(busy-wait)

```
V(S) :            
                  S++;
```

P 연산이 lock을 획득하는 것에 해당하고, S 연산이 lock을 놓는 것에 해당한다.

그런데 busy-wait는 효율적이지 않다.

따라서 Block & Wakeup 방식의 구현을 사용한다(= sleep lock).

## Block / Wakeup Implementation

```
typedef struct
{   int value; /* semaphore */
    struct process *L; /* process wait queue */
} semaphore;
```

block과 wakeup을 다음과 같이 가정한다.

- block : 커널은 block을 호출한 프로세스를 suspend시킴  
  이 프로세스의 PCB를 semaphore에 대한 wait queue에 넣음
- wakeup(P) : block된 프로세스 P를 wakeup 시킴  
  이 프로세스의 PCB를 ready queue로 옮김

## Two types of Semaphore

- Counting semaphore
    - 도메인이 0 이상인 임의의 정수값
    - 주로 resource counting에 사용
- Binary semaphore(= mutex)
    - 0 또는 1 값만 가질 수 있는 semaphore
    - 주로 mutual exclusion(lock/unlock)에 사용

## Bounded-Buffer Problem

Producer-Consumer Problem 이라고도 불린다.

- Shared data
    - buffer 자체 및 buffer 조작 변수(empty/full buffer의 시작 위치)
- Synchronization variables
    - mutual exclusion &rarr; Need binary semaphore (shared data의 mutual exclusion을 위해)
- resource count &rarr; Need integer semaphore (남은 full/empty buffer의 수)

## Semephore의 문제점

- 코딩하기 힘들다.
- 정확성(correctness)의 입증이 어렵다.
- 자발적 협력(voluntary cooperation)이 필요하다.
- 한 번의 실수가 모든 시스템에 치명적인 영향을 미친다.

예시:

![semaphore_problem.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Process_Synchronization/semaphore_problem.png?raw=true)

