스트림즈DSL로 구성된 애플리케이션을 코드로 구현하기 전에 먼저 살펴봐야할 개념이 있다. 레코드의 흐름을 추상화한 3가지 개념 KStream, KTable, GlobalTable이 바로 그 것이다.

이 3가지 개념은 컨슈머, 프로듀서, 프로세서 API에서는 사용되지 않고 스트림즈DSL에서만 사용되는 개념이다.

## KStream
KStream은 레코드의 흐름을 추상화한 것으로 메세지 키와 메세지 값으로 구성되어 있다. KStream으로 데이터를 조회하면 토픽에 존재하는(또는 Kstream에 존재하는) 모든 레코드가 출력된다. KStream은 컨슈머로 토픽을 구독하는 것과 동일한 선상에서 사용하는 것이라고 볼 수 있다.

![kstream.png](https://github.com/jewoodev/blog-img/blob/main/kafka/streamsdsl/kstream.png?raw=true)

## KTable
KTable은 KStream와 다르게 메세지 키를 기준으로 묶어서 사용한다. **KStream**은 토픽의 **모든 레코드**를 조회할 수 있지만 **KTable**은 **유니크**한 메세지 키를 기준으로 **가장 최신** 레코드만을 저장한다. 그래서 KTable로 데이터를 조회하면 메세지 키 기준 가장 최신에 추가된 레코드의 데이터가 출력된다. 새로 데이터를 적재할 때 동일한 메세지 키가 있으면 데이터가 업데이트 된다.

![ktable.png](https://github.com/jewoodev/blog-img/blob/main/kafka/streamsdsl/ktable.png?raw=true)

## 코파티셔닝
![co-partitioning.png](https://github.com/jewoodev/blog-img/blob/main/kafka/streamsdsl/co-partitioning.png?raw=true)

KStream과 KTable 데이터를 조인하기 위해서는 반드시 각 데이터가 코파티셔닝(co-partitioning)되어 있어야 한다. 

코파티셔닝이란 조인을 하는 2개 데이터의 '파티션 개수'와 '파티셔닝 전략'을 동일하게 맞추는 작업이다. 파티션 개수가 동일하고 파티셔닝 전략이 같은 경우에는 동일한 메세지 키를 가진 데이터가 동일한 태스크에 들어가는 것을 보장한다. 이를 통해 각 태스크는 KStream의 레코드와 KTable의 메세지 키가 동일할 경우 조인을 수행할 수 있다.



