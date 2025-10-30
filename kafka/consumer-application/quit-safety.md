# 컨슈머의 안전한 종료

컨슈머 애플리케이션은 안전하게 종료되어야 한다. 정상적으로 종료되지 않은 컨슈머는 세션 타임아웃이 발생할 때까지 컨슈머 그룹에 남게 된다. 컨슈머를 안전하게 종료하기 위해 KafkaConsumer 클래스는 wakeup() 메서드를 지원한다. wakeup() 메서드를 실행하여 KafkaConsumer 인스턴스를 안전하게 종료할 수 있다. wakeup() 메서드가 실행된 이후 poll() 메서드가 호출되면 WakeupException 예외가 발생한다. Wakeup Exception 예외를 받은 뒤에는 데이터 처리를 위해 사용한 자원들을 해제하면 된다.

```java
static class ShutdownThread extends Thread {
    public void run() {
        logger.info("Shutdown hook");
        consumer.wakeup();
    }
}

public static void main(String[] args) {
    Runtime.getRuntime().addShutdownHook(new ShutdownThread());
    ...
    consumer = new KafkaConsumer<>(configs);
    consumer.subscribe(Arrays.asList(TOPIC_NAME));
    
    try {
        while (true) {
            ConsumberRecords<String, String> records = consumer.poll(Duration.ofSecond(1));
            for (ConsumerRecord<String, String> record : records) {
                logger.info("{}", record);
            }
        }
    } catch (WakeupException e) {
        logger.warn("Wakeup consumer");
    } finally {
        consumer.close();
    }
}
```