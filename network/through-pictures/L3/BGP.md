# BGP
> Border Gateway Protocol

AS 내에서가 아닌 서로 다른 AS를 연결하기 위한 Path Vector 방식의 라우팅 프로토콜이다. BGP를 알아보기 전에, 왜 굳이 AS를 나눠서 다른 프로토콜을 사용할까? 그것부터 알아보자.

## AS 개별 관리의 이점
어떤 그룹에 AS를 부여하고 나눠서 관리하면 여러가지 이점이 있다. 

1. 정책적인 이점
   - 서로 경쟁중인 통신사가 있다면 이해관계에 따라 자신들의 데이터를 타 통신사로 전달할지 하지 않을지 컨트롤하는 게 가능하다.
2. 라우터 집단을 구분 -> 트래픽이 줄어듬
   - 구분하지 않았다면 하나의 AS의 하나의 라우터에 변화가 생길 때마다 다른 모든 단체의 모든 라우터로 전파가 될 것이다.

## 동작 방식
각 AS에서 외부 AS와 연결되는 라우터를 Autonomous System Boundary Router, 줄여서 ASBR이라고 부른다. 여기서 ASBR은 서로 경로 속성을 공유한다. 경로 속성은 연결된 모든 ASBR과 양방향으로 교환한다. 그렇게 AS 간의 경로 속성이 정리되면 그것을 활용해 AS 간의 라우팅이 이루어진다. 

AS 외부로의 라우팅을 대상으로 한 프로토콜, ERP(Exterior Routing Protocol)에 BGP가 속하며 RIP와 OSPF는 IRP(Interior Routing Protocol)에 속한다. AS 내부에서는 IRP가 쓰이고 AS 끼리는 ERP가 사용되는 것이다.