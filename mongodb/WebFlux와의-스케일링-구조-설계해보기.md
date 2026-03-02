# MongoDB 스케일 아웃 방법
MongoDB는 여러 스케일 아웃 전략을 제공하며, WebFlux 애플리케이션과 함께 사용할 때 고려해야 할 사항들이 있다.

## 1. MongoDB 샤딩 (Sharding)
**샤딩**은 MongoDB의 기본적인 수평 확장 방법이다.

``` javascript
// 샤딩 키 설정 예시
sh.shardCollection("myapp.users", { "userId": 1 })
sh.shardCollection("myapp.orders", { "customerId": 1, "orderDate": 1 })
```
**샤딩 구성 요소:**
- **Config Servers**: 메타데이터 저장 (최소 3개 권장)
- **Shards**: 실제 데이터를 저장하는 MongoDB 인스턴스들
- **Mongos**: 라우터 역할, 애플리케이션과 샤드 간 연결

## 2. 레플리카 셋 (Replica Sets)
각 샤드는 레플리카 셋으로 구성하여 고가용성을 확보한다.

``` javascript
// 레플리카 셋 구성 예시
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 1, arbiterOnly: true }
  ]
})
```

## 3. WebFlux와 MongoDB 연동 최적화
**Connection Pool 설정:**
``` java
@Configuration
public class MongoConfig {
    
    @Bean
    public ReactiveMongoTemplate reactiveMongoTemplate() {
        ConnectionString connectionString = new ConnectionString(
            "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/myapp?replicaSet=rs0"
        );
        
        MongoClientSettings settings = MongoClientSettings.builder()
            .applyConnectionString(connectionString)
            .applyToConnectionPoolSettings(builder -> 
                builder.maxSize(100)
                       .minSize(10)
                       .maxWaitTime(2, TimeUnit.SECONDS)
                       .maxConnectionLifeTime(30, TimeUnit.MINUTES)
            )
            .readPreference(ReadPreference.secondaryPreferred())
            .build();
            
        return new ReactiveMongoTemplate(
            MongoClients.create(settings), 
            "myapp"
        );
    }
}
```

**리액티브 쿼리 최적화:**
``` java
@Service
public class UserService {
    
    @Autowired
    private ReactiveMongoTemplate mongoTemplate;
    
    public Flux<User> findUsersByRegion(String region) {
        Query query = Query.query(Criteria.where("region").is(region));
        query.with(Sort.by(Sort.Direction.ASC, "createdAt"));
        
        return mongoTemplate.find(query, User.class)
                           .buffer(100) // 배치 처리
                           .flatMap(Flux::fromIterable);
    }
}
```

## 4. 샤딩 키 선택 전략
**좋은 샤딩 키의 특징:**
- **High Cardinality**: 많은 고유값을 가짐
- **Even Distribution**: 데이터가 균등하게 분산됨
- **Query Isolation**: 쿼리가 특정 샤드에 집중되지 않음

``` java
// 복합 샤딩 키 예시
@Document(collection = "orders")
public class Order {
    @Id
    private String id;
    
    @Indexed
    private String customerId;  // 샤딩 키 일부
    
    @Indexed
    private LocalDateTime orderDate;  // 샤딩 키 일부
    
    // 기타 필드...
}
```

## 5. 읽기 성능 최적화
**읽기 분산 설정:**
``` java
@Configuration
public class ReadPreferenceConfig {
    
    @Bean
    @Primary
    public ReactiveMongoTemplate primaryTemplate() {
        // 쓰기 작업용 - Primary 노드 사용
        return createTemplate(ReadPreference.primary());
    }
    
    @Bean
    @Qualifier("readOnlyTemplate")
    public ReactiveMongoTemplate readOnlyTemplate() {
        // 읽기 작업용 - Secondary 노드 사용
        return createTemplate(ReadPreference.secondaryPreferred());
    }
    
    private ReactiveMongoTemplate createTemplate(ReadPreference readPreference) {
        MongoClientSettings settings = MongoClientSettings.builder()
            .applyConnectionString(connectionString)
            .readPreference(readPreference)
            .build();
            
        return new ReactiveMongoTemplate(
            MongoClients.create(settings), 
            "myapp"
        );
    }
}
```

## 6. 모니터링 및 최적화
**성능 모니터링:**
``` java
@Component
public class MongoMetrics {
    
    private final MeterRegistry meterRegistry;
    
    public MongoMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }
    
    public <T> Mono<T> monitorQuery(String operation, Mono<T> query) {
        return Timer.Sample.start(meterRegistry)
                   .stop(Timer.builder("mongodb.query")
                              .tag("operation", operation)
                              .register(meterRegistry))
                   .then(query);
    }
}
```

## 7. 권장 아키텍처
``` 
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   WebFlux App   │    │   WebFlux App   │    │   WebFlux App   │
│   Instance 1    │    │   Instance 2    │    │   Instance 3    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Mongos      │
                    │   (Router)      │
                    └─────────────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
        ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
        │   Shard 1     │ │   Shard 2     │ │   Shard 3     │
        │ (Replica Set) │ │ (Replica Set) │ │ (Replica Set) │
        └───────────────┘ └───────────────┘ └───────────────┘
```
## 8. 실제 운영 고려사항
1. **점진적 스케일링**: 처음에는 레플리카 셋으로 시작하고, 필요에 따라 샤딩 도입
2. **백업 전략**: 각 샤드별로 백업 스케줄링
3. **인덱스 최적화**: 샤딩 키를 포함한 복합 인덱스 구성
4. **장애 복구**: 자동 페일오버 및 복구 프로세스 구축

이러한 방식으로 MongoDB를 스케일 아웃하면 WebFlux 애플리케이션과 함께 높은 처리량과 가용성을 달성할 수 있다.

# 스케일링 원칙
살펴본 스케일링 전략에는 **DB와 WAS를 별도의 스케일링 구조로 설계하여 서로 블랙박스화**하는 원칙이 녹아들어 있다.  
이는 마이크로서비스 아키텍처의 핵심 원칙 중 하나이다.

## 1. 분리된 스케일링의 장점
### **독립적인 확장성**
``` yaml
# WAS 스케일링 (Kubernetes 예시)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webflux-app
spec:
  replicas: 5  # WAS만 독립적으로 확장
  template:
    spec:
      containers:
      - name: app
        image: webflux-app:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

``` yaml
# DB 스케일링 (MongoDB Operator 예시)
apiVersion: mongodb.com/v1
kind: MongoDB
metadata:
  name: mongo-cluster
spec:
  members: 3  # DB만 독립적으로 확장
  type: ReplicaSet
  version: "5.0"
  opsManager:
    configMapRef:
      name: ops-manager-connection
```

## 2. 권장 아키텍처 패턴
### **Connection Pool을 통한 블랙박스화**
``` java
@Configuration
public class DatabaseConfig {
    
    @ConfigurationProperties("spring.data.mongodb")
    @Bean
    public MongoProperties mongoProperties() {
        return new MongoProperties();
    }
    
    @Bean
    public ReactiveMongoClient mongoClient(MongoProperties properties) {
        // DB 클러스터 정보는 설정으로만 관리
        ConnectionString connectionString = new ConnectionString(
            properties.getUri()  // mongodb://mongo-cluster:27017/myapp
        );
        
        MongoClientSettings settings = MongoClientSettings.builder()
            .applyConnectionString(connectionString)
            .applyToConnectionPoolSettings(builder -> 
                builder.maxSize(50)      // WAS 인스턴스당 최대 연결 수
                       .minSize(10)      // 최소 연결 수 유지
                       .maxWaitTime(5, TimeUnit.SECONDS)
                       .maxConnectionIdleTime(10, TimeUnit.MINUTES)
            )
            .build();
            
        return MongoClients.create(settings);
    }
}
```

### **Service Discovery 패턴**
``` java
@Service
public class DatabaseService {
    
    private final ReactiveMongoTemplate mongoTemplate;
    private final LoadBalancer loadBalancer;
    
    public DatabaseService(ReactiveMongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
        // DB 클러스터 정보는 완전히 숨겨짐
    }
    
    public Mono<User> findUser(String userId) {
        // WAS는 DB 내부 구조를 알 필요 없음
        return mongoTemplate.findById(userId, User.class);
    }
}
```

## 3. 실제 운영 환경 구성 예시
### **Docker Compose로 분리된 구조**
``` yaml
# docker-compose.yml
version: '3.8'
services:
  # WAS 클러스터
  webflux-app-1:
    image: webflux-app:latest
    ports:
      - "8080:8080"
    environment:
      - MONGODB_URI=mongodb://mongo-cluster:27017/myapp
      - SPRING_PROFILES_ACTIVE=prod
    depends_on:
      - mongo-cluster
      
  webflux-app-2:
    image: webflux-app:latest
    ports:
      - "8081:8080"
    environment:
      - MONGODB_URI=mongodb://mongo-cluster:27017/myapp
      - SPRING_PROFILES_ACTIVE=prod
    depends_on:
      - mongo-cluster
  
  # Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - webflux-app-1
      - webflux-app-2
      
  # MongoDB 클러스터 (별도 관리)
  mongo-cluster:
    image: mongo:5.0
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=password
    volumes:
      - mongo-data:/data/db
```

### **Kubernetes 환경에서의 분리**
``` yaml
# webflux-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webflux-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webflux-app
  template:
    metadata:
      labels:
        app: webflux-app
    spec:
      containers:
      - name: app
        image: webflux-app:latest
        env:
        - name: MONGODB_URI
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: mongodb-uri
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: webflux-service
spec:
  type: LoadBalancer
  selector:
    app: webflux-app
  ports:
  - port: 80
    targetPort: 8080
```

``` yaml
# mongodb-cluster.yaml (별도 관리)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb-service
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: mongodb-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

## 4. 모니터링과 운영의 분리
### **각각 독립적인 모니터링**
``` java
// WAS 모니터링
@Component
public class WebFluxMetrics {
    
    private final MeterRegistry meterRegistry;
    
    @EventListener
    public void handleRequest(RequestEvent event) {
        Counter.builder("webflux.requests")
               .tag("endpoint", event.getEndpoint())
               .register(meterRegistry)
               .increment();
    }
}

// DB 모니터링 (별도 시스템)
@Component
public class DatabaseMetrics {
    
    @Scheduled(fixedRate = 30000)
    public void collectDatabaseMetrics() {
        // DB 클러스터 상태 모니터링
        // Connection pool 상태 확인
        // 쿼리 성능 측정
    }
}
```

## 5. 장애 격리 및 복구
### **Circuit Breaker 패턴**
``` java
@Service
public class UserService {
    
    private final ReactiveMongoTemplate mongoTemplate;
    private final CircuitBreaker circuitBreaker;
    
    public UserService(ReactiveMongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
        this.circuitBreaker = CircuitBreaker.ofDefaults("database");
    }
    
    public Mono<User> findUser(String userId) {
        return circuitBreaker.executeSupplier(() -> 
            mongoTemplate.findById(userId, User.class))
            .onErrorResume(throwable -> {
                // DB 장애 시 캐시나 대체 로직
                return getCachedUser(userId);
            });
    }
}
```

## 6. 운영상의 이점
### **독립적인 배포 및 관리**
- **WAS 배포**: 애플리케이션 로직 변경 시에만
- **DB 스케일링**: 데이터 증가나 성능 이슈 시에만
- **각각 다른 팀**이 관리 가능
- **장애 영향 최소화**

### **비용 최적화**
``` yaml
# 각각 다른 리소스 요구사항
webflux-app:
  resources:
    - CPU 집약적
    - 메모리 중간
    - 네트워크 집약적
    
mongodb:
  resources:
    - CPU 중간
    - 메모리 집약적  
    - 디스크 I/O 집약적
```
이렇게 **블랙박스화된 구조**는 각 컴포넌트의 **독립성을 보장**하고, **운영 복잡도를 줄이며**, **확장성과 유지보수성**을 크게 향상시킵니다.
