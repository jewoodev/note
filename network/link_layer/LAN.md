# LAN structure
실제 (오늘날의) LAN 환경은 bus 구조가 아니라 중앙에 "스위치"가 있는 star 구조를 갖는다.


# Ethernet frame structure
전송 어댑터는 IP 데이터그램(또는 다른 네트워크 계층 프로토콜 패킷)을 이더넷 프레임의 데이터 영역에 캡슐화하여 삽입한다.

![Ethernet_frame_structure.png](https://github.com/jewoodev/blog_img/blob/main/network/link_layer/LAN/Ethernet_frame_structure.png?raw=true)

첫번째 "preamable" 헤더는 그렇게 중요한 정보를 담고 있진 않다. 두 번째, 세 번째 헤더는 각각 말 그대로 MAC 주소값이고 type은 network layer의 어떤 프로토콜의 패킷인지에 대한 정보가 담긴다. 따라서 거의 `IP` 가 담기게 되겠다.

# TCP의 Timeout 혹은 Duplicated ACK로의 전송 실패 감지, 재전송 / 기타 
일단 TCP의 신뢰적인 전송과 CSMA/CD를 비교해보자.
- TCP는 end-to-end라 훨씬 오래걸리고, MAC protocol에서 CSMA/CD로 collision을 detect하는 것은 하나의 홉을 단위로 하기 때문에 훨씬 빠르다.
- TCP가 신뢰적인 전송을 위해 고려하는 호스트가 end-to-end 만으로 설정될 수 있는 것은 그 사이 각 홉들에서 CSMA/CD로 collision을 detect하고 있기 때문이다.

하지만 이더넷에서 collision이 발생했을때 MAC layer에서 감지되지 않을 수 있다. 왜냐면 CSMA/CD는 MAC layer의 ACKS를 사용하지 않기 때문이다.

그러니까 최악의 경우 다음과 같은 상황이 발생할 수 있다.
A,B,C,D,E가 일렬로 위치해있는데 A가 E로 먼저 프레임을 전송하기 시작한다. 그리고 A의 프레임이 E에 막 도착하기 직전에 E가 프레임을 전송하려 한다고 해보자. 그럼 E는 아직 자신이 listen 할 수 있는 프레임이 없으니까 전송에는 성공하지만 collision이 발생하고, 프레임을 전부 전송하는데 성공하기 전에 A의 프레임이 자신에게 도착해 collision을 감지하고 전송을 중단한다. 근데 이때 A에게 E의 프레임(일부)이 도착하기 전에 전송을 완료한다면, A는 collision을 감지하지 못한다. 

이 문제를 어떻게 해결할 수 있을까? propagation delay는 빛의 속도로 우리가 기술적으로 제어할 수 있는 영역이 아니기 때문에 A가 프레임을 전송하는 시간을 좀 더 늘리는 방법으로 귀결된다. 그래서 ethernet은 최소한 호스트가 더 이상 전송할 데이터가 없어도 "전송 중" 상태를 유지하기 위한 프레임의 최소 크기를 설정한다. 그걸 Minimum Frame Size라고 부르고 64 byte 이다. 만약 호스트가 보내려는 데이터가 64 byter가 안 된다면 padding을 해서 64 byte 크기로 만들게 된다.