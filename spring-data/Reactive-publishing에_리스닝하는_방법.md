## R2DBC의 이벤트 루프 기반 Publishing 리스닝 메커니즘
### 1. 이벤트 루프의 기본 구조
R2DBC는 **Netty의 이벤트 루프**를 기반으로 동작합니다. 각 이벤트 루프는 하나의 스레드에서 실행되며, 여러 연결을 관리합니다.
```java
// 이벤트 루프의 기본 구조 (의사코드)
while (eventLoop.isRunning()) {
    // 1. I/O 이벤트 감지 (논블로킹)
    List<IoEvent> events = selector.selectNow(); 
    
    // 2. 각 이벤트 처리
    for (IoEvent event : events) {
        if (event.isReadable()) {
            handleDatabaseResponse(event);
        }
        if (event.isWritable()) {
            sendPendingRequests(event);
        }
    }
    
    // 3. 콜백 실행
    executeScheduledCallbacks();
}
```

### 2. Publishing 리스닝의 실제 구현
```java
// R2DBC Connection의 실제 동작 방식
public class R2dbcConnection {
    private final Channel channel; // Netty Channel
    private final EventLoop eventLoop;
    private final Map<Integer, CompletableFuture<Result>> pendingRequests;
    
    public Flux<Result> execute(String sql) {
        return Flux.create(sink -> {
            int requestId = generateRequestId();
            
            // 1. 요청을 큐에 등록
            CompletableFuture<Result> future = new CompletableFuture<>();
            pendingRequests.put(requestId, future);
            
            // 2. 데이터베이스에 비동기 요청 전송
            ByteBuf message = createSqlMessage(requestId, sql);
            channel.writeAndFlush(message);
            
            // 3. 응답 리스너 등록
            future.whenComplete((result, throwable) -> {
                if (throwable != null) {
                    sink.error(throwable);
                } else {
                    // 스트리밍으로 결과 전송
                    streamResults(result, sink);
                }
            });
        });
    }
    
    // 이벤트 루프에서 호출되는 응답 처리기
    public void handleIncomingData(ByteBuf data) {
        // 이벤트 루프 스레드에서 실행됨
        eventLoop.execute(() -> {
            ResponseMessage response = parseResponse(data);
            int requestId = response.getRequestId();
            
            CompletableFuture<Result> future = pendingRequests.get(requestId);
            if (future != null) {
                if (response.isComplete()) {
                    // 요청 완료
                    future.complete(response.getResult());
                    pendingRequests.remove(requestId);
                } else {
                    // 스트리밍 데이터 중간 결과
                    notifySubscribers(response.getPartialResult());
                }
            }
        });
    }
}
```
### 3. Reactive Streams와의 통합
```java
// Publisher 구현 예시
public class DatabaseResultPublisher implements Publisher<Row> {
    private final EventLoop eventLoop;
    private final List<Subscriber<? super Row>> subscribers = new ArrayList<>();
    
    @Override
    public void subscribe(Subscriber<? super Row> subscriber) {
        // 이벤트 루프에서 구독 처리
        eventLoop.execute(() -> {
            subscribers.add(subscriber);
            subscriber.onSubscribe(new DatabaseSubscription());
        });
    }
    
    // 데이터베이스에서 데이터가 도착했을 때 호출
    public void onDataReceived(List<Row> rows) {
        // 이벤트 루프 스레드에서 실행
        eventLoop.execute(() -> {
            for (Subscriber<? super Row> subscriber : subscribers) {
                for (Row row : rows) {
                    subscriber.onNext(row); // 구독자에게 데이터 전송
                }
            }
        });
    }
}
```
### 4. 실제 동작 흐름
```java
// 실제 사용 예시와 내부 동작
@Service
public class UserService {
    public Flux<User> getAllUsers() {
        return repository.findAll() // 1. Flux 생성
            .doOnSubscribe(subscription -> {
                // 2. 구독 시점에 이벤트 루프에 리스너 등록
                log.info("구독 시작 - 이벤트 루프에 리스너 등록");
            })
            .doOnNext(user -> {
                // 3. 각 데이터 수신 시 호출 (이벤트 루프 스레드에서)
                log.info("사용자 데이터 수신: {}", user.getName());
            });
    }
}

// 내부적으로 일어나는 일
/*
1. 클라이언트가 구독 시작
2. 이벤트 루프에 I/O 이벤트 리스너 등록
3. 데이터베이스에 SQL 쿼리 전송 (논블로킹)
4. 이벤트 루프가 소켓에서 데이터 도착 감지
5. 수신된 데이터를 파싱하여 Row 객체 생성
6. 구독자들에게 onNext() 호출하여 데이터 전달
7. 모든 데이터 수신 완료 시 onComplete() 호출
*/
```
### 5. Backpressure와 함께 동작하는 방식
```java
public class BackpressureAwarePublisher {
    private final EventLoop eventLoop;
    private volatile long demand = 0; // 구독자가 요청한 데이터 수
    
    public void onDemandReceived(long n) {
        eventLoop.execute(() -> {
            demand += n;
            // 요청된 만큼만 데이터베이스에서 읽어옴
            requestDataFromDatabase(Math.min(demand, BATCH_SIZE));
        });
    }
    
    public void onDataReceived(List<Row> rows) {
        eventLoop.execute(() -> {
            int toSend = Math.min(rows.size(), (int) demand);
            
            for (int i = 0; i < toSend; i++) {
                subscriber.onNext(rows.get(i));
                demand--;
            }
            
            // 더 많은 데이터가 있고 요청이 남아있으면 계속 요청
            if (demand > 0 && hasMoreData()) {
                requestDataFromDatabase(Math.min(demand, BATCH_SIZE));
            }
        });
    }
}
```
## 핵심 포인트
1. **단일 이벤트 루프 스레드**: 하나의 스레드가 여러 연결의 I/O 이벤트를 처리
2. **I/O 멀티플렉싱**: `Selector`(Linux의 epoll, Windows의 IOCP)를 사용하여 여러 소켓을 동시에 모니터링
3. **콜백 기반**: 데이터 도착 시 등록된 콜백 함수가 호출됨
4. **논블로킹 I/O**: 소켓 읽기/쓰기가 즉시 반환되며, 데이터가 없으면 나중에 다시 시도
5. **이벤트 큐**: 수신된 데이터는 이벤트 큐에 쌓이고, 이벤트 루프가 순차적으로 처리

이런 방식으로 R2DBC는 적은 수의 스레드로도 수천 개의 데이터베이스 연결을 효율적으로 관리하면서 reactive publishing을 구현할 수 있습니다.
