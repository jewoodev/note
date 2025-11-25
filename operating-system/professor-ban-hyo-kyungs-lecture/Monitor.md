# Monitor

동시 수행중인 프로세스 사이에서 abstract data type의 안전한 공유를 보장하기 위한 high-levl synchronzation construct를 말한다.

![monitor_layout.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Monitor/monitor_layout.png?raw=true)

공유 자원에 대한 접근을 모니터의 프로시저를 통해서만 할 수 있게 제한하고, 프로세스가 들어가고자 할 때 다른 프로세스가 모니터 내부에 있다면 입장 큐에서 기다리게 함으로써 락 없이 프로세스 동기화를 구현할 수 있게한다.

- 모니터 내에서는 한 번에 하나의 프로세스만이 활동 가능하다.
- 프로그래머가 동기화 제약 조건을 명시적으로 코딩할 필요가 없다.
- 프로세스가 모니터 안에서 기다릴 수 있도록 하기 위해 _condition variable_ 을 사용한다. `condition x, y;`
- Condition variable은 *wait*와 _signal_ 연산에 의해서만 접근 가능하다.  
                    `x.wait();`  
    x.wait()을 invoke한 프로세스는 다른 프로세스가    
    x.signal()을 invoke하기 전까지 suspend된다.  
                    `x.signal();`
    x.signal()은 정확하게 하나의 suspend된 프로세스를 resume한다.  
    Suspend된 프로세스가 없으면 아무 일도 일어나지 않는다.

## Bounded-Buffer Problem

![monitor_bounded_buffer_problem.png](https://github.com/jewoodev/blog_img/blob/main/operating-system/Monitor/monitor_bounded_buffer_problem.png?raw=true)

## Dining Philosophers Example

```
monitor dining_philosopher {
    enum {thinking, hungry, eating} state[5];
    condition self[5];
    void pickup(int i) {
        state[i] = hungry;
        test(i);
        if (state[i] != eating)
            self[i].wait(); /* wait here */
    }
    
    void putdown(int i) {
        state[i] = thinking;
        /* test left and right neighbors */
        test((i+4) % 5); /* if L is waiting */
        test((i+1) % 5);
    }
    
    void test(int i) {
        if ((state[(i+4) % 5] != eating) && (state[i] == hungry) && (state[(i+1) %5] != eating)) {
            state[i] = eating;
            self[i].signal();  /* wake up Pi */
        }
    }
    
    void init() {
        for (int i = 0; i < 5; i++)
            state[i] = thinking;
    }
}

Each Philosopher: // Enter monitor
{   pickup(i);
    eat();
    putdonw(i);
    think();
} while(1);            
```

