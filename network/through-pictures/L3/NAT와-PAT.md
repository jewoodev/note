# NAT
- Private IP 주소를 Public IP 주소로 변환하는 역할
- NAT을 세분화하면 4가지
  - Static NAT
  - Dynamic NAT
  - Static PAT
  - Dynamic PAT

## Static NAT
- 관리자가 라우터에 **직접** `{Private IP 주소: Public IP 주소}`를 매핑하는 방식
- Private IP 주소와 Public IP 주소가 1대1 매핑됨
  - 1대1 매핑 -> 주소 공간을 절약할 수 없음
- 아운바운딩 패킷(다른 네트워크로 **나가는**)과 인바운딩 패킷(다른 네트워크에서 LAN으로 **들어오는**) 모두 사용 가능
- 주로 보안 목적으로 쓰임

## Dynamic NAT
- 관리자가 여러 개의 Public IP를 준비해두고, 요청한 호스트에게 여분의 Public IP를 **빌려주는** 방식
- 여분의 Public IP가 모두 사용 중일 땐 외부 네트워크로의 통신이 실패함
  - 사용 중인 IP를 반납하기 전까지는 외부와 절대 통신 불가
  - 이 단점으로 요즘은 거의 사용되지 않음

## Static PAT
- IP 뿐 아니라 transport 계층의 **포트까지 이용**해 매핑 테이블을 작성하는 방법
  - 포트마다 IP가 할당되는 '그 포트'를 말하는 것일까?
    - transport에서 말하는 포트는 다른 개념의 포트
    - PC 내의 실행 중인 애플리케이션을 구분하는 숫자(고유 식별자)
- 하나의 Public IP 주소에 '같은 네트워크에 존재하는 여러 개의 Private IP 주소'를 할당 가능

## Dynamic PAT
- 가장 많이 이용됨
- 여러 개의 Private IP 주소를 하나의 Public IP 주소로 매핑시키는 기술
- Static PAT과 비슷하지만, 포트를 자동으로 할당해주기 때문에 굉장히 편리
- Public IP 주소와 함께 저장되는 포트는 '중복되지 않는 임의의 숫자' 이어야 함
- Binding Life Time 컬럼이 있고, 설정된 시간만큼 유지된 후 자동 삭제됨


- 단점
  - 단방향(Outbound Only)으로만 통신을 시작할 수 있음
    - 수신받기 전에 먼저 송신함으로써 NAT 테이블에 Learning 하지 않으면
    - 수신받는 라우터의 NAT 테이블에 목적지 IP와 PORT 정보가 기록되어있지 않기 때문
    - 이런 경우 Static PAT을 이용해야 함
