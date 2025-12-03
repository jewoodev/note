라우팅 프로토콜은 라우팅 알고리즘을 실제 프로토콜에 구현한 것을 말한다.
Intra-AS routing 은 목적이 '최단경로'로 라우팅하는 것으로 분명하고 간단하다. 근데 Inter-AS routing은 그렇지 않고 불분명하다. 예를 들어 우리나라가 중국으로 트래픽을 보낼 때 북한을 거쳐가는게 최단경로인데, 우리나라는 북한에 우리의 패킷이 거치길 원하지 않으므로 최단경로라고 해도 그곳을 우회한다. 그런 경제적, 정치적인 논리가 혼합된게 BGP 라는 라우팅 프로토콜이다.

# Autonomous Systems (ASes)
모든 AS는 자기만의 고유한 번호를 갖게 된다.

# Implementing Inter-Network Relationships with BGP
BGP는 인터넷의 수천 개의 ISP들을 연결하는 프로토콜이기 때문에 가장 중요하다고 볼 수 있다(유일한 경쟁자는 IP 프로토콜일 것이다). 그리고 거리 벡터 라우팅과 같은 줄기에서 나왔다고 볼 수 있는 분산형 비동기식 프로토콜이다.

## BGP-4
- **BGP** = **B**order **G**ateway **P**rotocol
- Is a **Policy-Based** routing protocol
- Is the **de facto EGP**(exterior gateway protocol) of the today's global Internet
- Relatively simple protocol, but configuration is complex and the entire world can see, and be impacted by, your mistakes.

BGP에는 갑을 관계가 있는데 어떠한 속성의 관계냐 하면, 어떤 AS가 외부와 네트워킹하기위해 누군가에게 돈을 지불해야 한다면 돈을 지불하고 그 AS에게 통신 허가를 받는 것이다. 역으로 그 AS는 돈을 지불하는 AS에게 통신할 필요가 없을 수도 있다. 이러한 갑을 관계는 다음의 세가지 관계로 형성될 수 있다.

1. Provider link
2. Customer link
3. Peer link

Peer link가 아니라면 일방적으로만 통신이 가능하다. 따라서 BGP가 수행될 땐 자신에게 가장 돈이 많이 되는 경로를 찾는게 일이 된다. 

다시 정리하면,   
Intra-AS routing protocol 에서는 OSPF(open shortest path first, 개방형 최단 경로 우선) protocol이며  
Inter-AS routing protocol은 policy base protocol이다.

## BGP 경로 정보 알리기
특정 AS가 자신의 게이트웨이 라우터로의 도달 가능 정보를 다른 라우터들에게 알리는 과정을 생각해보자. 자신의 사용할 수 있는 라우팅 경로 방향으로 고유한 AS Number를 보내면 '그 정보를 받은 라우터'는 자신의 고유한 AS Number를 그 앞에 붙인 다음 '그 다음에 정보를 받을 라우터'에게 넘기는 것을 반복한다.
 
![ASPATH_Attribute_broadcast.png](https://github.com/jewoodev/blog_img/blob/main/network/network_layer/Routing_protocol/ASPATH_Attribute_broadcast.png?raw=true)

