WebFlux는 근본적으로 WebMVC와 아키텍처 구성이 달라 로직마다 스레드를 어떻게 할당할 것인지 지정하는게 일반적이다. WebMVC 애플리케이션에선 어떻게 그러한 스레드 관리를 할 수 있을까?

## WebMVC 스레드 관리 특성

### 1. **Thread-per-Request 모델**
``` java
// WebMVC - 각 요청마다 하나의 스레드가 할당
@RestController
public class WebMvcController {
    
    @GetMapping("/blocking-operation")
    public ResponseEntity<String> blockingOperation() {
        // 이 메서드는 하나의 스레드에서 시작부터 끝까지 실행됨
        String result = someBlockingDatabaseCall(); // 스레드 블로킹
        return ResponseEntity.ok(result);
    }
}
```
### 2. **병렬 처리가 필요한 경우 개발자가 직접 관리**
``` java
@Service
public class WebMvcService {
    
    @Async("taskExecutor") // 개발자가 명시적으로 비동기 처리 지정
    public CompletableFuture<String> asyncOperation() {
        return CompletableFuture.completedFuture("result");
    }
    
    public List<String> parallelProcessing() {
        // 개발자가 직접 병렬 스트림 사용
        return list.parallelStream()
                  .map(this::processItem)
                  .collect(Collectors.toList());
    }
}
```
## WebFlux의 스레드 관리와 차이점
### WebFlux의 스케줄러 전략
``` java
@Service
public class ChatRoomService {
    
    public Mono<ChatRoomResponse> save(ChatRoomCreateRequest request) {
        return chatRoomRepository.save(chatRoom)
                .subscribeOn(Schedulers.boundedElastic()) // I/O 작업용 스케줄러
                .map(this::convertToResponse)
                .subscribeOn(Schedulers.parallel()); // CPU 집약적 작업용 스케줄러
    }
}
```
## WebMVC에서 병렬 처리 최적화 방법
### 1. **@Async 어노테이션 활용**
``` java
@Configuration
@EnableAsync
public class AsyncConfig implements AsyncConfigurer {
    
    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(10);
        executor.setMaxPoolSize(20);
        executor.setQueueCapacity(500);
        executor.initialize();
        return executor;
    }
}
```
### 2. **CompletableFuture 활용**
``` java
@Service
public class OptimizedWebMvcService {
    
    public CompletableFuture<List<String>> processMultipleItems(List<String> items) {
        List<CompletableFuture<String>> futures = items.stream()
                .map(item -> CompletableFuture.supplyAsync(() -> processItem(item)))
                .collect(Collectors.toList());
        
        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
                .thenApply(v -> futures.stream()
                        .map(CompletableFuture::join)
                        .collect(Collectors.toList()));
    }
}
```
## 결론
- **WebMVC**: 프레임워크가 자동으로 스레드 전략을 변경하지 **않음**
- **개발자가 명시적으로** `@Async`, , `parallelStream()` 등을 사용해야 함 `CompletableFuture`
- **WebFlux**: 리액티브 체인에서 `subscribeOn()`, `publishOn()` 등으로 스케줄러를 동적으로 변경 가능

WebMVC는 전통적인 블로킹 I/O 모델이므로, 병렬 처리가 필요한 경우 개발자가 의도적으로 구현해야 한다. 반면 WebFlux는 논블로킹 특성상 런타임에 더 유연한 스레드 관리가 가능하다.


