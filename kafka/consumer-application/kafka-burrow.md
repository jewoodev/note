버로우는 링크드인에서 개발하여 오픈소스로 공개한 **컨슈머 랙 체크 툴**로써 REST API를 통해 컨슈머 그룹 별로 컨슈머 랙을 확인할 수 있다. 

데이터 독, 컴포넌트 컨트롤 센터같은 외부 모니터링 툴을 사용하면 클러스터의 다양한 정보들도 함께 모니터링할 수 있지만 그런 것들은 컨슈머렉과 조금은 먼 지표들이라고 할 수 있다. 

버로우는 한 번의 설정으로 다수의 카프카 클러스터의 컨슈머 렉을 확인할 수 있다는 장점이 있어 많은 기업들에서 사용 중이다.

## REST API
버로우를 카프카 클러스터와 연동해서 REST API로 컨슈머 그룹별 컨슈머 랙을 조회할 수 있다.

![consumer-lag-through-rest-api.png](https://github.com/jewoodev/blog-img/blob/main/kafka/consumer-application/kafka-burrow/consumer-lag-through-rest-api.png?raw=true)

## 컨슈머 랙 이슈 판별
![consumer-lag-issue-distinction.png](https://github.com/jewoodev/blog-img/blob/main/kafka/consumer-application/kafka-burrow/consumer-lag-issue-distinction.png?raw=true)

버로우의 기능 중 가장 돋보이는 건 컨슈머와 파티션의 상태를 단순히 컨슈머 랙의 임계치(threshold)로 나타내지 않았다는 점이다. 

컨슈머 랙 이슈를 빠르게 전달받고 대처하기 위해 임계치에 다달았을 때 알람 처리를 하거나 작동할 코드를 작성해둘 수 있는데, 임계치에 다달았다가 금새 임계치 아래의 수치로 떨어지는 걸 반복하는 파티션의 경우엔 임계치 도달을 이슈 트리거로 설정하는게 적합하지 않게 되버린다.

(그래서) 버로우는 임계치가 아닌 슬라이딩 윈도우를 사용해서 문제가 생긴 파티션과 컨슈머의 상태를 표현한다. 이렇게 버로우에서 컨슈머 랙의 상태를 표현하는 것을 컨슈머 랙 평가(evaluation)라고 한다.   
이 방법에서는 컨슈머 랙과 파티션의 오프셋을 슬라이딩 윈도우로 계산하여 상태를 정한다. 결과적으로 파티션 상태는 OK, STALLED, STOPPED로 표현하고 컨슈머의 상태는 OK, WARNING, ERROR로 표현된다.

## 컨슈머 랙 모니터링 아키텍처
버로우로 컨슈머 랙을 모니터링할 땐 별개의 저장소와 대시보드를 사용하는 것이 권장된다. 다양한 저장소와 대시보드 선택지 중에 빠르고 무료로 설치할 수 있는 아키텍처는 다음과 같다.
- 버로우: github.com/linkedin/Burrow
- 텔레그래프: github.com/influxdata/telegraf
- 엘라스틱서치: www.elastic.co.kr
- Grafana: github.com/grafana/grafana
- 설치 방법: blog.voidmainvoid.net/279
