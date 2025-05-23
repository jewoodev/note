## 1. 서버와 네트워크 인프라로의 공격

DoS(denial of service) 공격은 네트워크, 호스트 혹은 다른 인프라스트럭처의 요소들을 정상적인 사용자가 사용할 수 없게 하는 것이다. 웹 서버, 전자메일 서버, DNS 서버, 기관 네트워크는 DoS 공격을 받을 가능성이 있다. 대부분의 DoS 공격은 다음 세 가지 범주 중 하나에 속한다.

1. 취약성 공격(vulnerability attack): 목표 호스트에서 수행되는 애플리케이션들 중 공격받기 쉬운 것, 혹은 운영체제에 교묘한 메세지를 보내는 것을 포함한다. 만약 특정 조건을 만족하는 패킷을 공격받기 쉬운 애플리케이션이나 운영체제에 보내면 그 서비스는 중단되거나 최악의 경우엔 호스트가 동작을 멈출 수 있다.
2. 대역폭 플러딩(bandwidth flooding): 목표 호스트에 너무 많은 패킷을 보내 목표 호스트의 접속 링크가 동작하지 못하도록 해서 정상적인 패킷들이 서버에 도달하지 못하게 하는 걸 말한다.
3. 연결 플러딩(connection flooding): 목표 호스트에 반열림(half-open)이나 전열림(fully-open)된 TCP 연결을 설정해 호스트가 가짜 연결ㅇ르 처리하느라 바빠서 정상적인 연결을 받아들이지 못하게 하는 걸 말한다.

## 2. 패킷 탐지

악성 유저는 무선 전송장치의 근처에 수동적인 수신자를 위치시켜 전송되고 있는 모든 패킷의 사본을 얻을 수 있다. 이 패킷에는 민감한 정보들이 담겨있을 수 있다. 이렇듯 지나가는 모든 패킷의 사본을 기록하는 수동적인 수신자를 **패킷 스니퍼**(sniffer)라고 한다.

스니퍼는 유선 환경에서도 배치될 수 있다. 케이블 접속 기술은 브로드캐스트할 수 있기 때문에 스니핑이 가능하다. 인터넷에 연결되는 기관의 접속 라우터나 접속 링크로의 접속 권한을 얻은 악성 유저는 그 조직으로 들어가고 나오는 모든 패킷을 복사하는 패킷을 설치할 수 있다.

패킷 스니핑 소프트웨어는 여러 웹사이트에서 무료 혹은 유료로 얻을 수 있다. 

패킷 스니퍼는 수동적이기 때문에(채널에 패킷을 삽입하지 않기 때문에) 탐지하기가 어렵다. 그래서 무선 채널로 패킷을 보낼 때, 악성 유저가 우리가 보내는 패킷의 사본을 기록하고 있을 수 있다는 가능성을 받아들여야 한다. 

패킷 스니핑을 방지하기 위한 가장 좋은 방어는 암호화이다. 

## 3. 종단 위장

악성 유저는 본인이 원하는 목적을 위해 자신의 주소를 다른 사람의 주소로 위장할 수 있다. 가짜 출발지 주소를 가진 패킷을 진짜 출발지 주소로부터 온 패킷인 것처럼 인터넷으로 보내는 능력을 **IP 스푸핑**(spoofing)이라고 한다. 

이 문제를 해결하기 위해서는 **종단 인증**, 메세지가 실제로 와야할 곳으로부터 온 것인지를 확신할 수 있는 방법이 필요하다. 
