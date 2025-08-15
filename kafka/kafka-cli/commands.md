# kafka-topics.sh
파티션 개수를 늘리기 위해서 --alter 옵션을 사용하면 된다.

```shell
$ bin/kafka-topics.sh --create --bootstrap-server my-kafka:9092 --topic test
Created topic test
$ bin/kafka-topics.sh --bootstrap-server my-kafka:9092 --topic test --describe
Topic: test PartitionCount: 3 ReplicationFactor: 1 Configs: segment.bytes=1073741824
...
$ bin/kafka-topics.sh --bootstrap-server my-kafka:9092 --topic test \
--alter --partitions 4
$ bin/kafka-topics.sh --bootstrap-server my-kafka:9092 --topic test --describe
Topic: test PartiontionCount: 4 ReplicationFactor: 1 Configs: segment.bytes=1073741824
```

my-kafka는 편의성을 위해 /etc/hosts 에 my-kafka 프로퍼티를 추가해서 사용했다. 동일하게 하고 싶다면 `sudo vim /etc/hosts` 로 hosts 파일을 연 후에 `127.0.0.1 my-kafka` 를 추가해주자.

# kafka-configs.sh
토픽의 일부 옵션을 설정하기 위해서는 kafka-configs.sh 명령어를 사용해야 한다. --alter 와 --add-config 옵션을 사용해서 min.insync.replicas 옵션을 토픽별로 설정할 수 있다. min.insync.replicas 옵션은 우리가 프로듀서로 데이터를 보낼 때 그리고 컨슈머가 데이터를 읽을 때 워터마크 용도로도 사용되고 얼마나 안전하게 데이터를 보내야 되는지에 대해서도 명확하게 설정할 때 많이 활용된다.

이 옵션을 설정하기 위해서 그리고 수정하기 위해서는 kafka-configs라는 shell 스크립트를 사용해야 한다.

```shell
$ bin/kafka-configs.sh --bootstrap-server my-kafka:9092 \
  --alter \
  --add-config min.insync.replicas=2 \
  --topic test
Completed updating config for topic test.

$ bin/kafka-topics.sh --bootstrap-server my-kafka:9092 --topic test --describe
Topic: test PartitionCount: 3 ReplicationFactor: 1 Configs: min.insync.replicas=2, segment.bytes=1073741824
  Topic: test Partition: 0Leader: 0 Replicas: 0 Isr: 0
  Topic: test Partition: 1Leader: 0 Replicas: 0 Isr: 0
  Topic: test Partition: 2Leader: 0 Replicas: 0 Isr: 0
```

브로커에 설정된 각종 기본값은 --broker, --all, --describe 옵션을 사용하여 조회할 수 있다.

```shell
$ bin/kafka-configs.sh --bootstrap-server my-kafka:9092 \
 --broker 0 \
 --all \
 --describe
All configs for broker 0 are:
 . . .
```

# kafka-console-producer.sh
메세지 키를 가지는 레코드를 전송하기 위해서는 몇가지 추가 옵션을 작성해야 한다. key.separator를 선언하지 않으면 기본 설정은 Tab delimeter(\t)이므로 key.separator를 선언하지 않고 메세지를 보내려면 메세지 키를 작성하고 탭키를 누른 뒤 메세지 값을 작성하고 엔터를 누른다. 여기서는 명시적으로 확인하기 위해 콜론(:)을 구분자로 선언했다.

```shell
$ bin/kafka-console-producer.sh --bootstrap-server my-kafka:9092 \
  --topic hello.kafka \
  --property "parse.key=true" \
  --property "key.separator=:"
```

## Point!
만약 레코드에 키와 값을 포함하여 파티션에 전송하면 같은 키를 가진 레코드는 같은 파티션에 저장된다. 메세지 키가 null인 경우는 레코드 배치 단위(레코드 전송 묶음)로 라운드 로빈으로 전송된다. 메세지 키가 존재하는 경우에는 키의 해시값을 작성해 존재하는 파티션 중 한 개에 할당된다.

그래서 특정 데이터에 대해서 순서를 지켜서 데이터를 처리하고 싶을 때에는 메세지 키를 넣어서 데이터를 보내야 한다.

# kafka-console-consumer.sh
토픽으로 전송한 데이터는 kafka-console-consumer.sh 명령어로 확인할 수 있다. 이때 필수 옵션으로 --bootstrap-server에 카프카 클러스터 정보, --topic에 토픽 이름이 필요하다. 추가로 --from-beginning 옵션을 주면 토픽에 저장된 가장 처음 데이터부터 출력한다.

만약 레코드의 메세지 키와 값을 함께 확인하고 싶다면 --property 옵션을 사용하면 된다.

```shell
$ bin/kafka-console-consumer.sh --bootstrap-server my-kafka:9092 \ 
  --topic hello.kafka \
  --property print.key=true \
  --property key.separator="-" \
  --from-beginning
```

- --max-message 옵션을 사용하면 최대 컨슘 메세지 개수를 설정할 수 있다.
- --partition 옵션을 사용하면 특정 파티션만 컨슘할 수 있다.

--group 옵션을 사용하면 컨슈머 그룹을 기반으로 kafka-console-consumer가 동작한다. 컨슈머 그룹이란 특정 목적을 가진 컨슈머들을 묶음으로 사용하는 것을 뜻한다. 컨슈머 그룹으로 토픽의 레코드를 가져갈 경우 어느 레코드까지 읽었는지에 대한 데이터가 카프카 브로커에 저장된다. 즉, 이 옵션을 사용하지 않으면 커밋이 일어나지 않는다.

# kafka-consumer-groups.sh
컨슈머 그룹은 따로 생성하는 명령을 날리지 않고 컨슈머를 동작시킬 때 그룹 이름을 지정하면 새로 생생된다. 생성된 컨슈머 그룹의 리스트는 kafka-consumber-groups.sh 명령어로 확인할 수 있다.

```shell
$ bin/kafka-consumer-groups.sh \
  --bootstrap-server my-kafka:9092 \
  --list
hello-group

$ bin/kafka-consumer-groups.sh --bootstrap-server my-kafka:9092 \
  --group hello-group --describe
...
```

--describe 옵션을 사용하면 해당 컨슈머 그룹이 어떤 토픽을 대상으로 레코드를 가져갔는지 상태를 확인할 수 있다. 파티션 번호, 현재까지 가져간 레코드의 오프셋, 파티션 마지막 레코드의 오프셋, 컨슈머 랙, 컨슈머 ID, 호스트를 알 수 있기 때문에 컨슈머의 상태를 조회할 때 유용하다.

```shell
$ bin/kafka-consumer-groups.sh \
  --bootstrap-server my-kafka:9092 \
  --group hello-group --describe
```

> ***컨슈머 랙이란?***
> 컨슈머 랙은 현재까지 가져간 레코드의 오프셋 번호와 파티션의 마지막 레코드의 오프셋 번호와의 차이이다. 즉, producer가 보내는 레코드를 consumer에서 읽어내는 동안 생겨나는 지연의 정도가 바로 컨슈머 랙이다.
>
> 컨슈머 랙은 매우 중요한 지표이다. 이 지표를 보고 프로듀서에 비해 컨슈머의 처리량이 낮거나 높은지 확인을 할 수 있기 때문에, 파티션와 컨슈머를 더 늘려서 처리할 필요가 있는지 판단하는 척도가 된다.

## 오프셋 리셋

```shell
$ bin/kafka-consumer-groups.sh \
  --bootstrap-server my-kafka:9092 \
  --group hello-group \
  --topic hello.kafka \
  --reset-offsets --to-earliest --execute

...

$ bin/kafka-consumer-groups.sh \
  --bootstrap-server my-kafka:9092 \
  --group hello-group \
  --topic hello.kafka
1
2
3
```

이미 컨슈머 그룹이 파티션의 특정 지점까지 읽고 있을 때 다시 어떤 토픽에 대해서 이 파티션의 데이터를 재처리하고 싶다면 reset-offset을 활용하면 된다.  이런 환경은 kafka-consumer-groups offset reset 종류에 따라서 다 다르게 진행된다.

아래에 리셋 종류를 나열하겠다.

- --to-earliest : 가장 처음 오프셋(작은 번호)으로 리셋
- --to-latest : 가장 마지막 오프셋(큰 번호)으로 리셋
- --to-current : 현 시점 기준 오프셋으로 리셋
- --to-datetime {YYYY-MM--DDTHH:mmSS.sss} : 특정 일시로 오프셋 리셋(레코드 타임스탬프 기준)
- --to-offset {long} : 특정 오프셋으로 리셋
- --shift-by {+/- long} : 현재 컨슈머 오프셋에서 앞뒤로 옮겨 리셋

# 그 외 커맨드 라인 툴
Kafka-producer-perf-test.sh는 카프카 프로듀서로 퍼포먼스를 측정할 때 사용된다.

```shell
$ bin/kafka-producer-perf-test.sh \
  --producer-props bootstrap.servers=my-kafka:9092 \
  --topic hello.kafka \
  --num-records 10 \
  --throughput 1 \
  --record-size 100 \
  --print-metric
```

---

Kafka-consumer-perf-test.sh는 카프카 컨슈머로 퍼포먼스를 측정할 때 사용된다. 카프카 브로커와 컨슈머(여기서는 해당 스크립트를 돌리는 호스트)간의 네트워크를 체크할 때 사용할 수 있다.

```shell
$ bin/kafka-consumer-perf-test.sh \
  --bootstrap-server my-kafka:9092 \
  --topic hello.kafka \
  --messages 10 \
  --show-detailed-stats
```

---

kafka-reassign-partitions.sh를 사용하면 리더 파티션과 팔로워 파티션이 위치를 변경할 수 있다. 카프카 브로커에는 auto.leader.rebalance.enable 옵션이 있는데 이 옵션의 기본값은 true로써 클러스터 단위에엇 리더 파티션을 자동 리밸런싱하도록 도와준다. 브로커의 백그라운드 스레드가 일정한 간격으로 리더의 위치를 파악하고 필요시 리더 리밸런싱을 통해 리더의 위치가 알맞게 배분된다.

```shell
$ bin/kafka-reassign-partitions.sh --zookeeper my-kafka:2181 \
  --reassignment-json-file partitions.json --execute
```

---

kafka-delete-record.sh는 특정 토픽의 특정 파티션의 0번부터 특정 오프셋까지를 삭제할 때 사용할 수 있다.

```shell
$ cat delete.json
{
  "partitions": [
    {
      "topic": "hello.kafka", "partition": 0, "offset": 5
    }
  ], "version": 1
}

$ bin/kafka-delete-records.sh --bootstrap-server my-kafka:9092 \
  --offset-json-file delete.json
Excuting records delete operation
Records delete operation completed:
partition: hello.kafka-0 low_watermark: 5
```

---

kafka-dump-log.sh는 카프카가 메세지를 잘 발행하고 이를 잘 기록하고 있는지 로그 내용을 확인할 때 사용할 수 있다.

```shell
$ ls data-hello.kafka-0

$ bin/kafka-dump-log.sh \
  --files data/hello.kafka-0/000000000000000.log
  --deep-iteration
  
```

# 카프카 브로커와 로컬 커맨드 라인 툴 버전을 맞춰야 하는 이유

카프카 브로커로 커맨드 라인 툴 명령을 내릴 때 브로커의 버전과 커맨드 라인 툴 버전을 반드시 맞춰서 사용하는 것을 권장한다. 브로커의 버전이 업그레이드 됨에 따라 커맨드 라인 툴의 상세 옵션이 달라지기 때문에 버전 차이로 인해 명령이 정상적으로 실행되지 않을 수도 있다. 