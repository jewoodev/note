TCP의 전송에 실패하면 재전송을 하는 특성은 네트워크가 혼잡해졌을 때 그 상태를 악화시킬 수 있기 때문에 대처가 필요하다. 그 대체 방법을 TCP Congestion Control이라고 부르며 세 가지의 주요 phases를 거치는 방법으로 행해진다.

1. Slow Start
2. Additive increase
3. Multiplicative decrease

# 1. TCP Congestion Control Method
## 1.1 Slow Start
어느 전송률에서 혼잡이 발생할지 모르기 때문에 클라이언트 측은 조심스럽게 전송률을 조정한다. '얼마나 조심스러워할 것인가'가 중요한 논점이다. 너무 천천히 증가시키면 네트워크와 수신자가 처리할 수 있는 처리율이 여유가 있을 때 비효율적이게 되고, 너무 빠르면 네트워크는 쉽게 혼잡해지기 때문이다. TCP가 채택한 것은 다음과 같다. 처음엔 1MSS(Maximum Segment Size=500byte)를 보내고 그 다음부턴 그 양을 지수적으로 증가시킨다. 그러다 threshold를 만나면 Slow Start 구간이 끝난다.

## 1.2 Additive(Linear) increase
Slow Start로 전송률을 증가시키다가 threshold에 도달하게 되면 그때부터는 1MSS씩 증가시킨다. 

## 1.3 Multiplicative decrease
Additive increase를 수행하다가 네트워크 혼잡이 확인되면 그 시점의 send buffer 크기의 절반을 threshold 값으로 초기화한다. 

## 1.4 늘릴 때는 천천히, 줄일 때는 급격히 하는 이유가 뭘까?
네트워크는 공유 자원이라 각 호스트가 천천히 줄여서는 혼잡이 해소되기 어렵다.


# 2. TCP Congestion Control: details

- sender limits transmission: $LastByteSent\ -\ LastByteAcked\ <=\ CongWin$
- 대략적인 전송률은 $rate\ =\ \cfrac{CongWin}{RTT}\ Bytes/sec$
- CongWin(혼잡 윈도우)는 동적이며 감지된 네트워크 혼잡의 함수다.
- 송신자가 혼잡을 감지하는 방법은?
  - loss event = timeout or 3 duplicate acks
  - TCP sender reduces rate(CongWin) after loss event


# 3. TCP Tahoe vs TCP Reno
위에서 살펴본 방식에서 send buffer를 1MSS로 초기화하고 Slow Start부터 동일하게 수행하는 것이 Tahoe의 방식이다. 

Reno는 send buffer를 절반으로 줄이고 거기서부터 Additive increase부터 수행하는 것이 Reno의 방식이다.


# 4. TCP Fairness
같은 네트워크 자원을 사용하는 두 호스트가 다른 시점에 통신을 시작한다면 공평하게 사용할 수 있을까? 그 경로 상의 bandwidth가 R이면 R/2 씩 나눠쓰게 되는 걸까? 직관적으로 그럴 것 같지 않지만 결과만 이야기하면 K개의 호스트가 사용한다면 공평하게 각각 R/K의 bandwidth를 사용하게 된다.

