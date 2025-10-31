## 리밸런스 리스너를 가진 컨슈머 애플리케이션
리밸런스 발생을 감지하기 위해 카프카 라이브러리는 ConsumerRebalanceListener 인터페이스를 지원한다. ConsumerRebalanceListener 인터페이스로 구현된 클래스는 onPartitionAssigned() 메서드와 onPartitionRevoked() 메서드로 이루어져 있다.

- onPartitionAssigned() : 리밸런스가 끝난 뒤에 파티션이 할당 완료되면 호출되는 메서드이다.
- onPartitionRevoked() : 리밸런스가 시작되기 직전에 호출되는 메서드이다. 마지막으로 처리한 레코드를 기준으로 커밋을 하기 위해서는 리밸런스가 시작하기 직전에 커밋을 하면 되므로 onPartitionRevoked() 메서드에 커밋을 구현하여 처리할 수 있다.

## 파티션 할당 컨슈머 애플리케이션
기본적으로 subscribe를 사용해서 Topic을 구독하는 컨슈머 그룹으로 운영할 수도 있지만 직접 Topic에 대해서 Partition을 각각 할당해서 해당 Partition만 데이터를 처리할 수 있도록 진행하는 것도 가능하다. 그렇게 진행하려고 할 땐 다음과 같이 Assign 메서드를 활용하면 된다. Assign 메서드를 활용할 때 Topic Partition에 대한 정보를 한 개 이상 집어 넣어 특정 토픽에 대해 특정 Partition을 Assign, 즉, 직접 할당하도록 동작시킬 수 있다.

```java
private final static int PARTITION_NUMBER = 0;
private final static String BOOTSTRAP_SERVERS = "my-kafka:9092";

public static main(String[] args) {
    ...
    KafkaConsumer<String, String> consumer = new KafkaConsumer<>(configs);
    consumer.assign(Collections.singleton(new TopicPartition(TOPIC_NAME, PARTITION_NUMBER)));
    while (true) {
        ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(1));
        for (Consumer<String, String> record : records) {
            logger.info("record : {}", record);
        }
    }
}
```