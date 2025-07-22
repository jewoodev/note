# MAC addresses and ARP
- 32-bit IP address:
  - 인터페이스의 네트워크 계층 주소
  - 3계층(네트워크 계층) 전달에 사용됨
- MAC (or LAN or physical or Ethernet) address:
  - 기능: 한 인터페이스에서 물리적으로 연결된 다른 인터페이스(IP 주소 지정 측면에서 동일 네트워크)로 프레임을 가져오는 데 '로컬'로 사용된다.
  - NIC ROM에 구운 48비트 MAC 주소(대부분의 LAN용), 때로는 소프트웨어 설정 가능 / 앞의 24비트는 제조 회사, 뒤 24비트는 그 인터페이스의 고유 넘버
  - e.g.: 1A-2F-BB-76-09-AD('-'으로 나뉜 각각의 숫자 혹은 문자열은 16진법 표기법이다. 각각의 숫자는 4비트이다.)

사람의 정보를 호스트의 정보와 매칭을 시켰을 때 주민번호에 해당하는게 MAC address다. 이름이나 거주지는 바꿀 수 있지만, 주민번호는 바꿀 수 없다는 점에서 그렇다.

이제 프레임의 src MAC address 를 자신의 네트워크 인터페이스의 MAC address로 기입하면, dest MAC address를 어떤 주소로 기입해야 하는지 생각해보자. 자신이 속한 AS의 게이트웨이 라우터의 MAC address 여야 할 것이다. 내 호스트는 그럼 그걸 알고 있을까? IP 주소는 알고 있는 걸까? 알고 있다면 어떻게 알고 있는걸까? 

우리의 호스트는 DHCP를 통해 게이트웨이 라우터의 IP 주소를 알고 있을 것이다. 그럼 이제 이 IP 주소를 통해 그 라우터의 MAC address를 알아내는 과정이 필요해진다. 각각 호스트는 내부에 **ARP**(Address Resolution Protocol) table이 있다. 이 테이블에는 IP addr 와 MAC addr 가 매핑된 것이 쭈욱 나열되어있다. 이 테이블을 참조해서 알아낸다. 근데 처음에는 게이트웨이 라우터의 엔트리가 없었을 것이다. 이걸 통신하려는 호스트가 채워넣어야 하는데 그걸 채워넣게 만드는 프로토콜이 바로 ARP 프로토콜이다. 그리고 ARP table(cache다)의 엔트리는 TTL 값도 가져서 시간이 지나면 삭제된다. 

이제 A 호스트가 게이트웨이 라우터의 MAC address를 알아내는 ARP 프로토콜의 수행과정을 살펴봐보자. A 호스트는 ARP request를 만들어서 Sender Hardware Address(SHA, 발신자의 MAC 주소)와 Sender Protocol Address(SPA, 발신자 IP 주소), Target Protocol Address(TPA, 목적지 IP 주소)를 헤더에 설정하여 브로드캐스트한다. 그럼 TPA를 보고 게이트웨이 라우터만 request를 받아들여 자신의 MAC 주소를 알려줄 수 있다. 

이제 그 MAC 주소를 통해 Google 사이트를 들어가기까지의 Link layer에서의 여정을 살펴보자. A 호스트가 Gateway 라우터로 MAC protocol 통신으로 프레임을 송신하고, 그 라우터가 자신이 가지고 있는 포워딩 테이블을 참고해서 다음 홉의 라우터 중 어떤 라우터로 포워딩해야 할지 참조하고, 포워딩할 라우터의 IP 주소 값에 매칭되는 MAC 주소를 그 라우터의 ARP table을 참조하여 알아내서 프레임의 dst address 헤더 값에 세팅한다. 
