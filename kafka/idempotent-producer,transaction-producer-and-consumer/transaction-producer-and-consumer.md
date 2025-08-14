# 트랜잭션 프로듀서, 컨슈머

## 트랜잭션 프로듀서의 동작
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240506184302053.png?raw=true" alt="image-20240506184302053" style="zoom:50%;" />

카프카에서 트랜잭션은 다수의 파티션에 데이털르 저장할 경우 모든 데이터에 대해 동일한 원자성(atomic)을 만족시키기 위해 사용된다. 원자성을 만족시킨다는 의미는 다수의 데이터를 동일 트랜잭션으로 묶음으로써 전체 데이터를 처리하거나 전체 데이터를 처리하지 않도록 하는 것을 의미한다.

트랜잭션 프로듀서는 사용자가 보낸 데이터를 레코드로 파티션에 저장할 뿐만 아니라 트랜잭션의 시작과 끝을 표현하기 위해 트랜잭션 레코드를 한 개 더 보낸다.

## 트랜잭션 컨슈머의 동작
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240506184548630.png?raw=true" alt="image-20240506184548630" style="zoom:50%;" />

트랜잭션 컨슈머는 파티션에 저장된 트랜잭션 레코드를 보고 트랜잭션이 완료(commit)되었음을 확인하고 데이터를 가져간다. 트랜잭션 레코드는 실질적인 데이터는 가지고 있지 않으며 트랜잭션이 끝난 상태를 표시하는 정보만 가지고 있다.

## 트랜잭션 프로듀서 설정
트랜잭션 프로듀서로 동작하기 위해 transactional.id를 설정해야 한다. 프로듀서별로 고유한 ID 값을 사용해야 하며 init, begin, commit 순서대로 수행되어야 한다.

```java
configs.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, UUID.randomUUID());

Producer<String, String> producer = new KafkaProducer<>(configs);

producer.initTransactions();

producer.beginTransaction();
producer.send(new ProducerRecord<>(TOPIC, "전달하는 메세지 값"));
producer.commitTransaction();

producer.close();
```

## 트랜잭션 컨슈머 설정
트랜잭션 컨슈머는 커밋이 완료된 레코드들만 읽기 위해 isolation.level 옵션을 read_committed로 설정해야 한다. 기본 값은 read_uncommitted로써 트랜잭션 프로듀서가 레코드를 보낸 후 커밋 여부와 상관없이 모두 읽는다. read_committed로 설정한 컨슈머는 커밋이 완료된 레코드들만 읽어 처리한다.

```java
configs.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
KafkaConsumer<String, String> consumer = new KafkaConsumer<>(configs);
```

여기서 주의할 점은 반드시 트랜잭션 컨슈머나 프로듀서는 물론 우리가 카프카에서 기본적으로 다 프로토콜들이 명시가 되어 있긴 하지만 이런 완벽한 동작을 위해서는 Java 공식 라이브러리를 사용해야 같은 방식으로 동작이 된다는 것이다. 여타 서드파티 라이브러리들, 고랭이라던가 파이썬이라든가 다른 언어들에서 제공하는 라이브러리는 이 트랜잭션 프로듀서나 컨슈머를 지원할 수도 있고, 하지 않을 수도 있다. 따라서 자바가 아닌 다른 언어로 사용하는 경우에는 해당 언어로도 기능이 지원되는지 확인이 필요하다.

