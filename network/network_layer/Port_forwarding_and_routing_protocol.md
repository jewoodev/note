라우터는 접속된 통신 링크들 중 하나로 도착하는 패킷을 받아서 접속된 통신 링크 중 다른 링크로 그 패킷을 전달한다. 라우터가 어떤 링크로 패킷을 전달하는지는 IP 주소를 통해 결정된다. 패킷이 네트워크에서 라우터에 도착할 때마다 목적지 IP 주소의 일부를 확인하고 그 정보를 기반으로 어떤 링크로 전달할지 결정하는 것을 도착지에 도달할 때까지 반복한다(그리고 패킷에 오류가 없는지 체크섬 필드 값을 이용해 확인한다). 이 때 라우터가 목적지 주소(혹은 주소의 일부) 정보로 출력 링크를 매핑하는 데에 **포워딩 테이블**을 사용한다. 포워딩 테이블의 키값은 보통 주소의 일부를 사용하는데 각각의 고유한 주소마다 테이블에 기록하면 테이블의 데이터 양이 너무 커지기 때문에 주소를 특정 범위 단위로 묶어서 저장한다.

라우터마다 주소의 일부를 확인하고 다음 링크를 선택하는 통신 과정은 지도를 이용하는 대신 방향을 물어보는 걸 좋아하는 자동차 운전자의 운전 방식과 닮아있다.

그러니까 라우터가 하는 **포워딩**은 라우팅 테이블을 참조해서 해당 패킷의 헤더에 있는 목적지 주소에 대한 값에 해당하는 output link를 확인하고 보내는 것이다. 만약 패킷의 목적지 주소 값에 매칭되는 테이블의 Address range가 여러개 이면 그 중 가장 구체적인 range를 택하는 방식으로 처리한다(Longest prefix matching).

포워딩 테이블은 **라우팅 프로토콜**을 통해 자동으로 설정된다. 라우팅 프로토콜은 각 라우터로부터 각 목적지까지의 최단 경로를 결정하고 포워딩 테이블을 설정하는데 그 최단 경로 결과를 이용한다.