# 프로세스 간 협력

## 독립적 프로세스(Independent process)

프로세스는 각자의 주소 공간을 가지고 수행되므로 원칙적으로 하나의 프로세스는 다른 프로세스의 수행에 영향을 미치지 못한다.

## 협력 프로세스(Cooperating process)

프로세스 협력 메커니즘을 통해 하나의 프로세스가 다른 프로세스의 수행에 영향을 미칠 수 있다.

## 프로세스 간 협력 메커니즘(IPC: Interprocess Communication)

- 메세지를 전달하는 방법
  - message passing: 커널을 통해 메세지 전달
- 주소 공간을 공유하는 방법
  - shared memory: 서로 다른 프로세스 간에도 일부 주소 공간을 공유하게 하는 shared memory 메커니즘이 잇음

### Message Passing

- Message system
  - 프로세스 사이에 공유 변수(shared variable)를 일체 사용하지 않고 통신하는 시스템

메세지를 통한 협력에는 두가지 방법(인터페이스)이 있다.

- Direct Communication
  - 통신하려는 프로세스의 이름을 명시적으로 표시
- Indirect Communication
  - mailbox(또는 port)를 통해 메세지를 간접 전달