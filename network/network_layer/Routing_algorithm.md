포워딩이 longest prefix matching 되는 것으로 포워딩 테이블을 룩업하기만 하면 되는 것이 가능한 이유는 **라우팅 알고리즘**이 포워딩 테이블을 만들어줬기 때문이다. 

# Routing algorithm classification
## Q: global or decentralized information?
- **global**:
  - all routers have complete topology, link cost info
  - "link state" algorithms
- **decentralized**:
  - router knows physically-connected neighbors, link costs to neighbors
  - iterative process of computation, exchange of info with neighbors
  - "distance vector" algorithms

## Q: static or dynamic?
- **static**:
  - routes change slowly over time
- **dynamic**:
  - routes change more quickly
  - periodic update
  - in response to link cost changes

# A Link-State Routing Algorithm
## 1. Dijkstra's algorithm
해당 방식에서는 각 라우터에서 라운드를 돌면서 그 라운드마다 가장 적은 코스트의 경로를 뽑는다. 메인 서버에서 다 계산해서 브로드캐스트하는게 아니라 각 라우터에서 수행한다.   
그렇게 각 라우터가 계산한 경로 정보로 만든 포워딩 테이블을 모든 라우터에 글로벌하게 브로드캐스트하는건 아니고 각 관할별로 나눠 수행된다.

## 2. Dijkstra's algorithm, discussion
- **algorithm complexity**: n nodes
  - each iteration: need to check all nodes, w, not in N
  - n(n + 1)/2 comparisons: $O(n^{2})$
  - more efficient implementations possible: $O(n\log{n})$
- **oscillations possible**:
  - e.g., support link cost equals amount of carried traffic



# Distance vector algorithm
## Bellman-Ford equation (dynamic programming)
이 방식도 전세계의 모든 라우터에 브로드캐스트하는게 아니고 각 관할별(N회사 네트워크, C회사 네트워크의 포워딩 테이블은 각각 따로)로 나눠 수행된다.

let $d_{x}(y)$ = cost of least-cost path from x to y  
then $d_{x}(y)$ = $min({c(x,v)\ + d_{v}(y)})$

- min: min taken over all neighbors v of x
- c(x,v): cost to neighbor v
- $d_{v}(y)$: cost from neighbor v to destination y

![distance_vector_calculate_procedure.png](https://github.com/jewoodev/blog_img/blob/main/network/network_layer/Routing_algorithm/distance_vector_calculate_procedure.png?raw=true)

iterative,
  asynchronous: each local iteration caused by:
  - local link cost change
  - DV update message from neighbor
distributed:
  - each node notifies neighobrs only when its DV changes
    - neighbors then notify their neighbors if necessary

![distance_vector_calculate-expensive_case.png](https://github.com/jewoodev/blog_img/blob/main/network/network_layer/Routing_algorithm/distance_vector_calculate-expensive_case.png?raw=true)

$d_{A}(C)$값이 A 에서 C 로의 방향 그대로 나아가서 나온 값이 아니라 되돌아와서 나온 값이면 $c(A,B)$ 값이 90과 같이 급격히 커졌을 때, $d_{A}(C)$ 의 계산에서 A는 C를 통해 B로 가는 비용($d_{B}(C)$이 13이라고 잘못 알고 있기 때문에 $d_{A}(C)$ 값이 70이 넘을 때까지 13에 5를 더하는 것을 반복하는 작업이 생긴다. 이런 이유로 네트워크 비용이 비싸졌을 때(싸질 때는 이런 반복없이 하나의 라운드만에 끝난다) distance vector 계산이 오래걸리는 한계점이 있다. 

![solution_when_dvc_is_expensive.png](https://github.com/jewoodev/blog_img/blob/main/network/network_layer/Routing_algorithm/solution_when_dvc_is_expensive.png?raw=true)

그래서 (그에 대한 해결책은) distance vector가 지나쳐온 엣지를 되돌아가서 계산된 경우, 예를 들어 $d_{A}(C)$가 방금 살펴본 예시처럼 되돌아가서 13이 나왔다면 $c(A,C)$ 값을 $\infty$ 값으로 (포워딩 테이블에) 업데이트하여 반복 작업을 하지 않게 만든다.

그렇게 비싸졌을 때 그 cost에 수렴할 때까지 계속해서 왔다갔다 하며 distance vector 값을 계산하는 것을 "**count to infinity**" 문제라고 부른다. 

그리고 "count to infinity" 문제의 원인이 되는 reverse path를 막기 위해 해당 distance vector 값을 $\infty$로 업데이트하는 것은 **poison reverse** 기법이라고 한다. 그런데 이 기법을 사용할 때 모든 노드에게 자신의 distance vector 값을 무한대로 넘겨주는게 아니라, 무한대로 넘겨주지 않으면 "count to infinity" 문제가 발생하게 되는 그 노드에게만 무한대로 넘겨준다. 위 예시에서는 A 노드가 그 노드다. 

# Hierarching routing
라우팅을 전체적으로 바라보면 굉장히 복잡하고도 넓다(?). 이걸 덩어리 채 관리하면 문제가 생기기 쉽기 때문에 계층화를 적용한다. 서울대 안의 라우터, 서울대에게 소유권이 있는 라우터들은 서울대 자치권 안의 네트워크이고 성균관대 네트워크는 성균관대 자치권 내에 있다. 그 안에서도 세부적인 계층화는 나뉠 수 있으며, 하나의 계층마다 같은 라우팅 알고리즘을 사용하는 방식이다. 모든 네트워크는 자신이 속하는 자치권이 있으며 이를 "aggregate routers into regions, **autonomous systems**(AS)" 라고 부른다. 그렇게 AS 내부의 라우팅 알고리즘을 Intra-AS routing 이라고 하며, 외부의 알고리즘을 Inter-AS routing 이라고 한다.

## Routing protocol
라우팅 프로토콜은 라우팅 알고리즘을 실제 프로토콜에 구현한 것을 말한다.
Intra-AS routing 은 목적이 '최단경로'로 라우팅하는 것으로 분명하고 간단하다. 근데 Inter-AS routing은 그렇지 않고 불분명하다. 예를 들어 우리나라가 중국으로 트래픽을 보낼 때 북한을 거쳐가는게 최단경로인데, 우리나라는 북한에 우리의 패킷이 거치길 원하지 않으므로 최단경로라고 해도 그곳을 우회한다. 그런 경제적, 정치적인 논리가 혼합된게 BGP 라는 라우팅 프로토콜이다.
