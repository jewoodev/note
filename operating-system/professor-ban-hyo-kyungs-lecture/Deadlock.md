# Deadlock

일련의 프로세스들이 서로가 가진 자원을 기다리며 block된 상태

## Resource

- 하드웨어, 소프트웨어 등을 포함하는 개념
  - ex. I/O device, CPU cycle, memory space, semaphore 등
- 프로세스가 자원을 사용하는 절차
  - Request, Allocate, Use, Release
- Dealock example 1
  - 시스템에 2개의 tape drive가 있다.
  - 프로세스 P1과 P2 각각이 하나의 tape drive를 보유한 채 다른 하나를 기다리고 있다.
- Dealock example 2
  - Binary semaphores A and B  
    ![deadlock_example2.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Deadlock/deadlock_example2.png?raw=true)

## 1. Deadlock 발생의 네 가지 조건

- Mutual exclusion(상호 배제)
  - 매 순간 하나의 프로세스만이 자원을 사용할 수 있음
- No preemption(비선점)
  - 프로세스는 자원을 스스로 내어놓을 뿐 강제로 빼앗기지 않음
- Hold and wait(보유 대기)
  - 자원을 가진 프로세스가 다른 자원을 기다릴 때 보유 자원을 놓지 않고 계속 가지고 있음
- Circular wait(순환 대기)
  - 자원을 기다리는 프로세스 간에 사이클이 형성되어야 함
  - 프로세스 P0, P1, ... Pn이 있을 때  
    - P0은 P1이 가진 자원을 기다림
    - P1은 P2가 가진 자원을 기다림
    - Pn-1은 Pn이 가진 자원을 기다림
    - Pn은 P0이 가진 자원을 기다림

이 네 가지 조건을 모두 만족해야 Deadlock이 발생한다. 하나라도 만족하지 않으면 발생하지 않는다.

## 2. Deadlock 처리 방법

- Deadlick Preventation
  - 자원 할당 시 Deadlock의 네 가지 필요 조건 중 어느 하나가 만족되지 않도록 하는 것.
- Deadlock Avoidance
  - 자원 요청에 대한 부가적인 정보를 이용해서 deadlock의 가능성이 없는 경우에만 자원을 할당한다.
  - 시스템 state가 원래의 state로 돌아올 수 있는 경우에만 자원을 할당한다.
- Deadlock Detection and recovery
  - Deadlock 발생은 허용하되 그에 대한 detection 루틴을 두어 deadlock 발견 시 recover.
- Deadlock Ignorance
  - Deadlock을 시스템이 책임지지 않음.
  - UNIX를 포함한 대부분의 OS가 채택.

### 2.1 Deadlock Prevention

- Mutual exclusion
    - 공유해서는 안되는 자원의 경우 반드시 성립해야 함.
- Hold and Wait
    - 프로세스가 자원을 요청할 때 다른 어떤 자원도 가지고 있지 않아야 한다.
      - 방법1. 프로세스 시작 시 모든 필요한 자원을 할당받게 하는 방법
      - 방법2. 자원이 필요할 경우 보유 자원을 모두 놓고 다시 요청
- No preemption
    - 프로세스가 어떤 자원을 기다려야 하는 경우 이미 보유한 자원이 선점됨.
    - 모든 필요한 자원을 얻을 수 있을 때 그 프로세스는 다시 시작된다.
    - state를 쉽게 save하고 restore할 수 있는 자원에서 주로 사용(CPU, memory)
- Circular wait
    - 모든 자원 유형에 할당 순서를 정하여 정해진 순서대로만 자원 할당
    - 예를 들어 순서가 3인 자원 Ri를 보유 중인 프로세스가 순서가 1인 자원 Rj을 할당받기 위해서는 우선 Ri를 release 해야 한다.

&rarr; Utilization 저하, throughput 감소, starvation 문제

### 2.2 Deadlock Avoidance

자원 요청에 대한 부가정보를 이용해서 자원 할당이 deadlock으로 부터 안전(safe)한지를 동적으로 조사해서 안전한 경우에만 할당하는 것으로 데드락을 회피한다.

가장 단순하고 일반적인 모델은 프로세스들이 필요로 하는 각 자원별 최대 사용량을 미리 선언하도록 하는 방법이다.

- safe state
  - 시스템 내의 프로세스들에 대한 safe sequence가 존재하는 상태
- safe sequence
  - 프로세스의 sequence<P1, P2, ..., Pn>이 safe하려면 Pi(1<=i<=n)의 자원 요청이 "가용 자원 + 모든 Pj(j<i)의 보유 자원"에 의해 충족되어야 함
  - 조건을 만족하면 다음 방법으로 모든 프로세스의 수행을 보장
    - Pi의 자원 요청이 즉시 충족될 수 없으면 모든 Pj(j<i)가 종료될 때까지 기다린다.
    - Pi-1이 종료되면 Pi의 자원 요청을 만족시켜 수행한다.

시스템이 safe state에 있으면 데드락이 발생될 수 없고, unsafe state에 있으면 데드락이 발생할 가능성이 있다.

Deadlock Avoidance는 시스템이 unsafe state가 되지 않도록 보장하는 것이다. avoidance 알고리즘엔 두가지 경우가 있다.

1. Single instance per resource types
   - Resource Allocation Graph algorithm 사용
2. Multiple instances per resource types
   - Banker's Algorithm 사용

