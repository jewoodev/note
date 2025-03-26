# CPU 스케줄링 알고리즘

모든 프로세스는 실행하는데에 CPU를 필요로 하기 때문에 운영체제는 CPU가 효율적으로 사용되도록 잘 할당해줘야 한다.

이렇듯 운영체제가 프로세스들에게 공정하고 합리적으로 CPU 자원을 배분하는 걸 CPU 스케줄링이라고 한다. CPU 스케줄링은 컴퓨터 성능과도 직결되는 대단히 중요한 문제다.

CPU 스케줄링이 잘 이루어지지 않으면 반드시 실행되어야 할 프로세스들이 실행되지 못하거나, 당장 급하지 않은 프로세스들만 주로 실행되는 무질서한 상태가 될 수 있다.

운영체제는 그래서 CPU 스케줄링을 하는데에 여러 전략을 사용하는데, 그 결과로 특정 논리와 목적을 갖는 알고리즘을 선택한다.

CPU 스케줄링 알고리즘은 크게 두가지로 분류할 수 있다. preemptive(강제로 빼앗지 않고 자진 반납) 알고리즘과 nonpreemptive(강제로 뻬앗음) 알고리즘이다.

## Scheduling Criteria

Performance Index(= Performance Measure, 성능 척도)라는 명칭으로도 불리는 이것은 아래와 같은 것들이 있다.

- CPU utilization(이용률)
  - keep the CPU as busy as possible
- Throughput(처리량)
  - `# of processes` that `complete` their execution per time unit
- Turnaround time(소요시간, 반환시간)
  - amount of time to execute a particular process
- Waiting time(대기 시간)
  - amount of time a process has benn waiting in the ready queue
- Response time(응답 시간)
  - amount of time it takes from when a request was submitted until the first response is produced, not output (for time-sharing environment)

이 척도들은 프로세스가 태어나서 죽을 때까지의 시간과 양이 아니라, Ready queue에서 1회 CPU를 점유한 동안의 시간과 양을 의미한다.

## 1. FCFS(First-Come First-Served)

이름대로 준비 큐에 삽입된 순서대로 프로세스를 처리하는 nonpreemptive 방식이다.

이 알고리즘은 때때로 프로세스들이 기다리는 시간이 매우 길어질 수 있다는 단점이 있다. 

만약 CPU를 이용하는 시간이 17ms 인 프로세스, 5ms 인 프로세스, 2ms 인 프로세스 순으로 준비 큐에 삽입된다면 마지막 프로세스는 고작 2ms동안 CPU를 사용하기 위해 22ms를 기다려야 한다.

이런 현상을 호위 효과(convoy effect)라고 한다. 

## 2. SJF(Shortest-Job-First)

호위 효과를 방지하기 위해 준비 큐에 삽입된 프로세스들 중 CPU의 이용 시간이 가장 짧은 프로세스부터 실행하는 방식이다.

이 스케줄링은 기본적으로 nonpreemptive 스케줄링 알고리즘으로 분류되지만, preemptive으로 구현될 수도 있다.

- Preemptive
  - 현재 수행 중인 프로세스의 남은 burst time보다 더 짧은 CPU burst time을 가지는 새로운 프로세스가 도착하면 CPU를 빼앗김
  - 이 방법을 Shortest-Remaining-Time-First(SRTF)라고도 부름

그럼 이제 SJF만 쓰면 스케줄링 문제는 해결되겠구나, 생각이 드는데 이것도 심각한 단점이 있다.

### 2.1 SJF의 단점

1. **Starvation**: SJF가 극단적으로 짧은 Job만을 선호하기 때문에 이용 시간이 긴 Job은 영원히 CPU를 할당받지 못할 수 있다.
   - **Aging**: 오래 대기한 Job은 Aging을 적용해 일정 시간 이상 대기하게 되면 CPU를 할당하는 방식으로 해결할 수 있다.
2. **다음 CPU Burst Time의 예측**: Job은 if 문으로 branch가 일어나기도 하고 실시간으로 동적인 크기의 input을 받기도 하기 때문에, 스케줄링을 시행하는 시점에 Job의 Burst Time은 예측하기 어렵다.
   - 추정(estimate)만 가능하다.
   - 과거의 CPU Burst Time을 이용해서 추정한다(exponential averaging).

## 3. Round Robin(RR)

FCFS에 타임 슬라이스라는 개념이 더해진 방식이다. 타임 슬라이스란 각 프로세스가 CPU를 사용할 수 있는 정해진 시간을 의미한다. 이 개념을 적용해 정해진 타임 슬라이스만큼의 시간 동안 돌아가면서 CPU를 preemptive으로 사용한다. 

만약 CPU 사용 시간이 11ms, 3ms, 7ms 인 프로세스를 타임 슬라이스가 4ms 인 라운드 로빈 스케줄링을 하면 11ms동안 다 쓰지 못하고 3ms 동안 쓰는 프로세스에게 넘기며 스케줄링이 수행된다.

이 방식에선 타임 슬라이스의 크기가 매우 중요하다. 타임 슬라이스가 너무 크면 선입 선처리 스케줄링과 다를 바 없이 후위 효과가 생기고, 너무 작으면 문맥 교환에 발생하는 비용이 커서 CPU가 프로세스를 처리하는 것보다 프로세스를 전환하는데에 온 힘을 다 쓸 수도 있기 때문이다. 

그리고 Job의 CPU 이용 시간이 짧고 긴 것들이 마구 뒤섞여 있을 때는 효율적이지만 모두 동일한 것이 들어올 때는 비효율적이다.  
그런 비효율적인 결과의 예시로, 100 milli seconds 가 소요되는 Job 4개가 큐에 들어왔을 때가 있다. 이때 Round Robin 알고리즘이 사용되면 400 milli seconds가 흐른 후에 4개의 Job이 동시에 완료되는, 어느 것 하나 먼저 완료되지 못하는 형태로 실행된다. 

하지만 결과적으로 프로세스가 본인이 CPU를 사용하려는 시간에 비례하여 대기 시간이 늘어나고 줄어드므로 공정한 스케줄링 전략이라고 할 수 있다.

## 4. 최소 잔여 시간 우선 스케줄링

이건 SJF와 라운드 로빈 스케줄링을 합친 방식이다. 최소 잔여 시간 우선 스케줄링에서 프로세스들은 정해진 타임 슬라이스동안 CPU를 사용하되, CPU를 사용할 다음 프로세스는 남아있는 작업시간이 가장 적은 프로세스를 선택한다. 

## 5. Priority Scheduling

프로세스들에 우선순위를 부여하고, 가장 높은 우선순위를 가진 것부터 실행하는 알고리즘이다. 

최단 작업 우선 스케줄링과 최소 잔여 시간 우선 스케줄링은 넓은 의미에서 우선순위 스케줄링의 일종이라고 볼 수 있다. 

이 알고리즘도 nonpreemptive와 preemptive 알고리즘으로 각각 구현할 수 있다.

우선순위 스케줄링은 근본적인 문제를 내포하고 있는데 우선순위가 낮은 프로세스는 우선순위가 높은 프로세스들에 순서가 밀려 실행이 계속해서 연기될 수 있다는 점이다. 이를 **기아**(starvation) 현상이라고 한다. 

이를 방지하기 위한 기법들 중 대표적인 것으로 **에이징**이 있는데, 이는 오랫동안 대기한 프로세스의 우선순위를 점차 높이는 방식이다.

## 6. Multilevel Queue

우선순위 스케줄링의 발전된 형태로 Ready queue를 여러 개로 분할해 interactive 한 프로세스들과 그렇지 않은 프로세스들에 알맞은 알고리즘을 사용한다.

interactive 한 프로세스들은 foreground queue에 집어넣고, 사람과 상호작용하지 않는 배치잡은 background queue에 집어넣는다.

foreground에는 RR를 쓰고, background는 FCFS를 쓴다. 

이렇게 여러 개의 Ready queue를 사용하기 때문에 큐에 대한 스케줄링이 필요한데, 두 가지 스케줄링 방법이 있다.

- Fixed priority scheduling
  - served all from foreground then from background.
  - Possibility of starvation
- Time slice scheduling
  - 각 큐에 CPU time을 적절한 비율로 할당
  - ex. 80% to foreground in RR, 20% to background in FCFS

## 7. Multilevel Feedback Queue

다단계 큐 스케줄링은 우선 순위에 따라 비공정한 스케줄링을 하는 방식이다. 이 방식처럼 영원히 타고난 계급을 벗어날 수 없는 불합리함은 옳지 않다는 관점에서 발전시킨 알고리즘이 Multilevel Feedback Queue 이다.

불합리하기만 한 게 아니라 다단계 큐 방식의 단점때문에 기아 현상이 발생할 수 있다. 큐 사이를 이동할 수 없어 우선순위가 낮은 프로세스가 계속 연기될 수 있기 때문이다.

다단계 피드백 큐 알고리즘에서는 우선순위가 높을 수록 할당 시간을 짧게 두고, 낮을 수록 길게 둔다.

아래의 예시를 확인하며 어떻게 알고리즘이 스케줄링하는지 살펴보자.

- Three queues:
  - Q0 - time quantum 8 milliseconds
  - Q1 - time quantum 16 milliseconds
  - Q2 - FCFS
- Scheduling
  - new job이 queue Q0로 들어감
  - CPU를 잡아서 할당 시간 8 milliseconds 동안 수행됨
  - 8 milliseconds 동안 다 끝내지 못했으면 queue Q1으로 내려감
  - Q1에 줄 서서 기다렸다가 CPU를 잡아서 16ms 동안 수행됨
  - 16ms 안에 끝내지 못한 경우 queue Q2로 쫓겨남

이 알고리즘을 채택하면 CPU가 여러 개일 수록 스케줄링은 더욱 복잡해진다.

- Homogenous processor인 경우
  - Queue에 한 줄로 세워서 각 프로세서가 알아서 꺼내가게 할 수 있다.
  - 반드시 특정 프로세서에서 수행되어야 하는 프로세스가 있는 경우에는 문제가 더 복잡해진다.
- Load sharing
  - 일부 프로세서에 job이 몰리지 않도록 부하를 적절히 공유하는 메커니즘이 필요하다.
  - 별 개의 큐를 두는 방법 vs 공동 큐를 사용하는 방법
- Symmetric Multiprocessor(SMP)
  - 각 프로세서가 각자 알아서 스케줄링 결정
- Asymmetric multiprocessing
  - 하나의 프로세서가 시스템 데이터의 접근과 공유를 책임지고 나머지 프로세서는 거기에 따름.


## 8. Real-Time Scheduling

- Hard real-time systems
  - Hard real-time task는 정해진 시간 안에 반드시 끝내도록 스케줄링해야 함
- Soft real-time computing
  - Soft real-time task는 일반 프로세스에 비해 높은 priority를 갖도록 해야 함

## 9. Thread Scheduling

- Local Scheduling
  - User level thread의 경우 사용자 수준의 thread library에 의해 어떤 thread를 스케줄할지 결정
  - OS가 하는 게 아니라 그 프로세스가 직접, 다음으로 CPU를 넘겨줄 프로세스를 스케줄링하는 것
- Global scheduling
  - Kernel level thread의 경우 일반 프로세스와 마찬가지로 커널의 단기 스케줄러가 어떤 thread를 스케줄할지 결정

## 10. Algorithm Evaluation

- Queueing models
  - 확률 분포로 주어지는 arrival rate와 service rate 등을 통해 각종 performance index값을 계산
- Implementation(구현) & Measurement(성능 측정)
  - 실제 시스템에 알고리즘을 구현하여 실제 작업(workload)에 대해서 성능을 측정 비교
- Simulation(모의 실험)
  - 알고리즘을 모의 프로그램으로 작성 후 trace를 입력으로 하여 결과 비교

