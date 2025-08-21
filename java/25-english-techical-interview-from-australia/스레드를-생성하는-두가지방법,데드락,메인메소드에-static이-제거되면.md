# `extends Thread`
자바의 기본 패키지의 Thread 클래스를 상속받아 클래스를 구현하는 방법이다.

# `implements Runnable`
Runnable 인터페이스를 구현하고 `run()`메소드를 오바라이드한 다음 그 객체를 스레드의 생성자에 넣는 방법이다.

# 데드락
멀티 스레드 환경에서 발생하는 것으로 스레드의 교착 상태라고도 한다. 

```java
class Example {
    public static void main(String[] args) throws Exception {
        final Object lock1 = new Object();
        final Object lock2 = new Object();
        Thread t1 = new Thread() {
            @Override
            public void run() {
                synchronized (lock1) {
                    System.out.println("Thread 1 holds lock 1");
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                    }
                    synchronized (lock2) {
                        System.out.println("Thread 1 holds lock 2");
                    }
                }
            }
        };

        Thread t2 = new Thread() {
            @Override
            public void run() {
                synchronized (lock2) {
                    System.out.println("Thread 2 holds lock 2");
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                    }
                    synchronized (lock1) {
                        System.out.println("Thread 2 holds lock 1");
                    }
                }
            }
        };
    }
}
```
위와 같이 각각의 스레드가 lock1, lock2를 선점하고 1초 동안 sleep를 하고나면 서로 필요한 다음 락이 대치가 된 상태라 프로그램이 진행되지 않는다.

이런 경우의 데드락은 락을 선점하는 순서를 똑같이 해주면 방지할 수 있다.

```java
class Example {
    public static void main(String[] args) throws Exception {
        final Object lock1 = new Object();
        final Object lock2 = new Object();
        Thread t1 = new Thread() {
            @Override
            public void run() {
                synchronized (lock1) {
                    System.out.println("Thread 1 holds lock 1");
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                    }
                    synchronized (lock2) {
                        System.out.println("Thread 1 holds lock 2");
                    }
                }
            }
        };

        Thread t2 = new Thread() {
            @Override
            public void run() {
                synchronized (lock1) {
                    System.out.println("Thread 2 holds lock 1");
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                    }
                    synchronized (lock2) {
                        System.out.println("Thread 2 holds lock 2");
                    }
                }
            }
        };
    }
}
```

## 데드락 정리
데드락은 멀티스레드가 서로의 락을 기다리며 영원히 block되어 프로그램이 더 이상 진행되지 않는 상황을 의미한다. 이를 방지하는 방법은 다음과 같다.

- 가장 쉬운 방법으로, 하나 이상의 멀티풀 락을 선점하지 않는 방법
- synchronized block 내에 또 다른 synchronized block을 포함하는 nested lock을 가능하면 피하는 방법
- nested lock가 필요한 경우, 멀티 스레드가 lock을 얻는 순서를 동일하게 하는 방법
- 퍼포먼스가 중요하지 않다면 싱글 스레드를 이용하는 방법

# 메인 메소드에 static 제어자가 제거되면 어떻게 될까?
만약 그렇게 되면 메인 메소드는 실행할 수 없게 된다. 

왜냐하면 프로그램이 실행되고 나서 곧바로 메인 메소드를 실행하려고 하는데, static 제어자가 없는 메소드는 객체를 생성하고 나서야 실행을 시킬 수 있기 때문이다. 객체가 생성되고 나서야 메모리에 메인 메소드가 올라오게 되는데, static 제어자가 있는 메소드라면 자바 프로그램이 실행되자 마자 메모리에 올라간다.