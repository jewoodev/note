# 전달 신뢰성
멱등성이란 여러 번 연산을 수행하더라도 동일한 결과를 나타내는 것을 뜻한다. 이러한 의미에서 멱등성 프로듀서는 동일한 데이터를 여러 번 전송하더라도 카프카 클러스터에 단 한 번만 저장됨을 의미한다. 기본 프로듀서의 동작 방식은 적어도 한 번 전달(at least once delivery)을 지원한다. 적어도 한 번 전달이란 프로듀서가 클러스터에 데이터를 전송하여 저장할 때 적어도 한 번 이상 데이터를 적재할 수 있고 데이터가 유실되지 않음을 뜻한다. 다만, 두 번 이상 적재할 가능성이 있으므로 데이터의 중복이 발생할 수 있다.

- At least once : 적어도 한 번 이상 전달
- At most once : 최대 한 번 전달
- Exactly once : 정확히 한 번 전달


# 멱등성 프로듀서
프로듀서가 보내는 데이터의 중복 적재를 막기 위해 0.11.0 이후 버전부터는 프로듀서에서 enable.idempotence 옵션을 사용하여 정확히 한 번 전달(exactly once delivery)을 지원한다. enable.idempotence 옵션의 기본값은 false이며 정확히 한 번 전달을 위해서는 true로 옵션값을 설정해서 멱등성 프로듀서로 동작하도록 만들면 된다.

카프카 3.0.0 부터는 enable.idempotence 옵션값의 기본값은 true(acks=all)로 변경되므로 신규 버전에서 프로듀서의 동작에 유의하여 사용하도록 한다.

```java
Properties configs = new Properties();
configs.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
configs.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
configs.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
configs.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);

KafkaProducer<String, String> producer = new KafkaProducer<>(configs);
```

## 멱등성 프로듀서의 동작
멱등성 프로듀서는 기본 프로듀서와 달리 데이터를 브로커로 전달할 때 프로듀서 PID(Producer unique ID)와 파티션별 시퀀스 넘버(sequence number)를 함께 전달한다. 그러면 브로커는 프로듀서의 PID와 시퀀스 넘버를 확인하여 동일한 메세지의 적재 요청이 오더라도 단 한 번만 데이터를 적재함으로써 프로듀서의 데이터는 정확히 한 번 브로커에 적재되도록 동작한다.

- PID(Producer unique ID) : 프로듀서의 고유한 ID
- SID(Sequence ID) : 레코드의 전달 번호 ID

## 멱등성 프로듀서가 아닌 경우
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240506180125573.png?raw=true" alt="image-20240506180125573" style="zoom:50%;" />

멱등성 프로듀서가 아닌 경우에 레코드를 send() 하는데는 성공하더라도 acks 응답을 할 때 네트워크 이슈가 발생했을 경우 혹은 다른 이슈가 발생했을 경우에는 위와 같이 프로듀서가 브로커가 적재에 실패했다고 판단하고 재차 send() 하게 된다. 중복 적재되는 것이다. 흔히 일어나는 상황은 절대 아니니까 두려워하지 않아도 괜찮고 이런 일이 일어날 가능성이 있다고 알아두면 좋다.

## 멱등성 프로듀서인 경우
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240506182908405.png?raw=true" alt="image-20240506182908405" style="zoom:50%;" />

멱등성 프로듀서는 send() 를 할 때 sequence id와 PID를 같이 보내는 것을 위에서 확인할 수 있다. ID 값을 이용해 중복 적재하지 않고 적재되었던 값을 기준으로 응답값을 보내는 것이 기본 동작이다.

## 멱등성 프로듀서의 한계
그럼 멱등성 프로듀서로 모두 설정하는게 좋을 것 같은데 굳이 아닌 경우를 남겨놓은 이유가 뭘까? 멱등성 프로듀서는 동일한 세션에서만 정확히 한 번 전달을 보장한다. 여기서 말하는 동일한 세션이란 PID의 생명주기를 뜻한다. 만약 멱등성 프로듀서로 동작하는 프로듀서 애플리케이션에 이슈가 발생하여 종료되고 애플리케이션을 재시작하면 PID가 달라진다. 동일한 데이터를 보내더라도 PID가 달라지만 브로커 입장에서 다른 프로듀서 애플리케이션이 다른 데이터를 보냈다고 판단하기 때문에 멱등성 프로두서는 장애가 발생하지 않을 경우에만 정확히 한 번 적재하는 것을 보장한다는 점을 고려해야 한다.

## 멱등성 프로듀서로 설정할 경우 옵션
멱등성 프로듀서를 사용하기 위해 enable.idempotence를 true로 설정하면 정확히 한 번 적재하는 로직이 성립되기 위해 프로듀서의 일부 옵션들이 강제로 설정된다. 프로듀서의 데이터 재전송 횟수를 정하는 retries는 기본값으로 Integer.MAX_VALUE로 설정되고 acks옵션은 all로 설정된다. 이렇게 설정되는 이유는 프로듀서가 적어도 한 번 이상 브로커에 데이터를 보냄으로써 브로커에 단 한 번만 데이터가 적재되는 것을 보장하기 위해서다. 멱등성 프로듀서는 정확히 한 번 브로커에 데이터를 적재하기 위해 정말로 한 번 전송하는 것이 아니다. 상황에 따라 프로듀서가 여러 번 전송하되 브로커가 여러 번 전송된 데이터를 확인하고 중복된 데이터는 적재하지 않는 것이다.

## 멱등성 프로듀서 사용 시 오류 확인
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240506183814880.png?raw=true" alt="image-20240506183814880" style="zoom:50%;" />

멱등성 프로듀서의 시퀀스 넘버는 0부터 시작하여 숫자를 1씩 더한 값이 전달된다. 브로커에서 멱등성 프로듀서가 전송한 데이터의 PID와 시퀀스 넘버를 확인하는 과정에서 시퀀스 넘버가 일정하지 않은 경우에는 OutOfOrderSequenceException이 발생할 수 있다. 이 오류는 브로커가 예상한 시퀀스 넘버와 다른 번호의 데이터의 적재 요청이 왔을 때 발생한다. OutOfOrderSequenceException 이 발생했을 경우에는 시퀀스 넘버의 역전현상이 발생할 수 있기 때문에 순서가 중요한 데이터를 전송하는 프로듀서는 해당 Exception이 발생했을 경우 대응하는 방안을 고려해야 한다.