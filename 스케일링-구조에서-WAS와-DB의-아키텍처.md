## Me
스케일-아웃되는 구조로 설계한 WebFlux 애플리케이션에서 데이터베이스는 MongoDB를 채택했는데 이건 어떻게 스케일 아웃하는게 가장 좋을까?

## AI Assistant
MongoDB를 스케일 아웃하는 방법에 대해 설명드리겠습니다. MongoDB는 여러 스케일 아웃 전략을 제공하며, WebFlux 애플리케이션과 함께 사용할 때 고려해야 할 사항들이 있습니다.
## 1. MongoDB 샤딩 (Sharding)
**샤딩**은 MongoDB의 기본적인 수평 확장 방법입니다:
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
각 샤드는 레플리카 셋으로 구성하여 고가용성을 확보합니다:
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

이러한 방식으로 MongoDB를 스케일 아웃하면 WebFlux 애플리케이션과 함께 높은 처리량과 가용성을 달성할 수 있습니다.


## Me
DB는 WAS 랑 별도의 스케일링 구조를 설계해서 서로 블랙박스화 하는게 더 좋구나?

## AI Assistant
네, 맞습니다! **DB와 WAS를 별도의 스케일링 구조로 설계하여 서로 블랙박스화**하는 것이 훨씬 좋은 아키텍처입니다. 이는 마이크로서비스 아키텍처의 핵심 원칙 중 하나입니다.
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

## Me
근데 보통 MSA에서는 WAS랑 DB를 나눠서 스케일링하기보다는 도메인 별로 테이블을 나누고 특정 도메인의 테이블의 작업은 모두 그 마이크로서비스를 통해서 이루어지게끔하지 않아?

## AI Assistant
맞습니다! 제가 설명한 것은 **모놀리식 아키텍처에서 WAS와 DB를 분리하는 방식**이었는데, **MSA에서는 완전히 다른 접근법**을 사용합니다.
## MSA의 실제 구조
### **도메인별 서비스 분리 (Database-per-Service)**
``` 
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│   User Service      │  │   Order Service     │  │  Product Service    │
│  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │
│  │   User API    │  │  │  │   Order API   │  │  │  │  Product API  │  │
│  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │
│          │          │  │          │          │  │          │          │
│  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │
│  │   User DB     │  │  │  │   Order DB    │  │  │  │  Product DB   │  │
│  │ (users table) │  │  │  │(orders table) │  │  │  │(products table)│  │
│  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```
## 1. 도메인별 서비스 구현
### **User Service**
``` java
// User Service의 독립적인 DB 구성
@Configuration
public class UserDatabaseConfig {
    
    @Bean
    @Primary
    public DataSource userDataSource() {
        return DataSourceBuilder.create()
                .url("jdbc:mysql://user-db:3306/user_service")
                .username("user_service")
                .password("password")
                .build();
    }
    
    @Bean
    public DatabaseClient userDatabaseClient(DataSource userDataSource) {
        return DatabaseClient.create(userDataSource);
    }
}

@RestController
@RequestMapping("/users")
public class UserController {
    
    private final UserService userService;
    
    @GetMapping("/{userId}")
    public Mono<User> getUser(@PathVariable String userId) {
        return userService.findById(userId);
    }
    
    @PostMapping
    public Mono<User> createUser(@RequestBody User user) {
        return userService.create(user);
    }
}

@Service
public class UserService {
    
    private final DatabaseClient databaseClient;
    
    // 오직 User 테이블만 접근
    public Mono<User> findById(String userId) {
        return databaseClient.sql("SELECT * FROM users WHERE id = ?")
                            .bind(0, userId)
                            .map(this::mapRowToUser)
                            .first();
    }
    
    public Mono<User> create(User user) {
        return databaseClient.sql("INSERT INTO users (id, name, email) VALUES (?, ?, ?)")
                            .bind(0, user.getId())
                            .bind(1, user.getName())
                            .bind(2, user.getEmail())
                            .fetch()
                            .rowsUpdated()
                            .map(count -> user);
    }
}
```
### **Order Service**
``` java
@Configuration
public class OrderDatabaseConfig {
    
    @Bean
    @Primary
    public DataSource orderDataSource() {
        return DataSourceBuilder.create()
                .url("jdbc:mysql://order-db:3306/order_service")
                .username("order_service")
                .password("password")
                .build();
    }
}

@RestController
@RequestMapping("/orders")
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    public Mono<Order> createOrder(@RequestBody CreateOrderRequest request) {
        return orderService.createOrder(request);
    }
    
    @GetMapping("/user/{userId}")
    public Flux<Order> getOrdersByUser(@PathVariable String userId) {
        return orderService.findByUserId(userId);
    }
}

@Service
public class OrderService {
    
    private final DatabaseClient databaseClient;
    private final UserServiceClient userServiceClient;  // 다른 서비스 호출
    
    public Mono<Order> createOrder(CreateOrderRequest request) {
        // 1. 사용자 존재 확인 (다른 서비스 호출)
        return userServiceClient.getUser(request.getUserId())
                .flatMap(user -> {
                    // 2. 주문 생성 (자신의 DB만 접근)
                    return databaseClient.sql("INSERT INTO orders (id, user_id, total_amount) VALUES (?, ?, ?)")
                                        .bind(0, UUID.randomUUID().toString())
                                        .bind(1, request.getUserId())
                                        .bind(2, request.getTotalAmount())
                                        .fetch()
                                        .rowsUpdated()
                                        .map(count -> Order.builder()
                                                          .userId(request.getUserId())
                                                          .totalAmount(request.getTotalAmount())
                                                          .build());
                });
    }
}
```
## 2. 서비스 간 통신
### **WebClient를 통한 서비스 호출**
``` java
@Component
public class UserServiceClient {
    
    private final WebClient webClient;
    
    public UserServiceClient(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .baseUrl("http://user-service")  // 서비스 디스커버리
                .build();
    }
    
    public Mono<User> getUser(String userId) {
        return webClient.get()
                       .uri("/users/{userId}", userId)
                       .retrieve()
                       .bodyToMono(User.class);
    }
}

@Component
public class ProductServiceClient {
    
    private final WebClient webClient;
    
    public ProductServiceClient(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .baseUrl("http://product-service")
                .build();
    }
    
    public Mono<Product> getProduct(String productId) {
        return webClient.get()
                       .uri("/products/{productId}", productId)
                       .retrieve()
                       .bodyToMono(Product.class);
    }
}
```
## 3. Docker Compose로 MSA 구성
``` yaml
# docker-compose.yml
version: '3.8'
services:
  # User Service
  user-service:
    build: ./user-service
    ports:
      - "8081:8080"
    environment:
      - DB_URL=jdbc:mysql://user-db:3306/user_service
    depends_on:
      - user-db
      
  user-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=user_service
      - MYSQL_USER=user_service
      - MYSQL_PASSWORD=password
    volumes:
      - user-db-data:/var/lib/mysql
      
  # Order Service
  order-service:
    build: ./order-service
    ports:
      - "8082:8080"
    environment:
      - DB_URL=jdbc:mysql://order-db:3306/order_service
      - USER_SERVICE_URL=http://user-service:8080
    depends_on:
      - order-db
      - user-service
      
  order-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=order_service
      - MYSQL_USER=order_service
      - MYSQL_PASSWORD=password
    volumes:
      - order-db-data:/var/lib/mysql
      
  # Product Service
  product-service:
    build: ./product-service
    ports:
      - "8083:8080"
    environment:
      - DB_URL=jdbc:mysql://product-db:3306/product_service
    depends_on:
      - product-db
      
  product-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=product_service
      - MYSQL_USER=product_service
      - MYSQL_PASSWORD=password
    volumes:
      - product-db-data:/var/lib/mysql
      
  # API Gateway
  api-gateway:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - user-service
      - order-service
      - product-service

volumes:
  user-db-data:
  order-db-data:
  product-db-data:
```
## 4. 각 서비스의 독립적인 스케일링
### **Kubernetes에서 독립적인 스케일링**
``` yaml
# user-service 스케일링
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3  # User Service만 3개 인스턴스
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:latest
        env:
        - name: DB_URL
          value: "jdbc:mysql://user-db:3306/user_service"
---
# order-service 스케일링
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 5  # Order Service는 5개 인스턴스 (주문이 많아서)
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: order-service:latest
        env:
        - name: DB_URL
          value: "jdbc:mysql://order-db:3306/order_service"
        - name: USER_SERVICE_URL
          value: "http://user-service:8080"
```
## 5. 데이터 일관성 처리
### **Saga 패턴으로 분산 트랜잭션**
``` java
@Service
public class OrderSagaService {
    
    private final OrderService orderService;
    private final PaymentServiceClient paymentServiceClient;
    private final InventoryServiceClient inventoryServiceClient;
    
    public Mono<OrderResult> createOrder(CreateOrderRequest request) {
        return Mono.fromCallable(() -> SagaTransaction.begin())
                   .flatMap(saga -> {
                       // 1. 재고 확인 및 예약
                       return inventoryServiceClient.reserveItems(request.getItems())
                               .flatMap(reservation -> {
                                   saga.addCompensation(() -> 
                                       inventoryServiceClient.cancelReservation(reservation.getId()));
                                   
                                   // 2. 결제 처리
                                   return paymentServiceClient.processPayment(request.getPayment())
                                           .flatMap(payment -> {
                                               saga.addCompensation(() -> 
                                                   paymentServiceClient.refundPayment(payment.getId()));
                                               
                                               // 3. 주문 생성
                                               return orderService.createOrder(request)
                                                       .map(order -> OrderResult.success(order))
                                                       .onErrorResume(error -> {
                                                           // 실패 시 보상 트랜잭션 실행
                                                           return saga.compensate()
                                                                     .then(Mono.just(OrderResult.failed(error)));
                                                       });
                                           });
                               });
                   });
    }
}
```
## 6. MSA의 핵심 원칙
### **Database-per-Service 원칙**
- 각 서비스가 **자신의 데이터베이스만 소유**
- 다른 서비스의 DB에 **직접 접근 금지**
- 모든 데이터 접근은 **API를 통해서만**

### **독립적인 배포와 스케일링**
- 각 서비스는 **독립적으로 배포**
- **필요에 따라 개별 서비스만 스케일링**
- **기술 스택을 서비스별로 다르게** 선택 가능

이렇게 MSA에서는 **도메인별로 서비스와 데이터베이스를 완전히 분리**하여, 각 서비스가 자신의 데이터에 대한 완전한 소유권을 가지도록 설계합니다.


## Me
그럼 하나의 마이크로서비스 안에서 DB 를 스케일 아웃할 땐 WAS랑 별도로 샤딩 등 DB 벤더에 알맞은 분산 세팅을 하는거지?

## AI Assistant
네, 정확합니다! **하나의 마이크로서비스 내에서 DB를 스케일 아웃할 때는 WAS와 별도로 DB 벤더에 맞는 분산 세팅**을 하는 것이 맞습니다.
## 1. 마이크로서비스 내 DB 스케일링 구조
``` 
┌─────────────────────────────────────────────────────────────┐
│                  Order Service                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │  Order WAS    │  │  Order WAS    │  │  Order WAS    │  │
│  │  Instance 1   │  │  Instance 2   │  │  Instance 3   │  │
│  └───────────────┘  └───────────────┘  └───────────────┘  │
│           │                   │                   │        │
│           └───────────────────┼───────────────────┘        │
│                               │                            │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Order DB Cluster                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │  │
│  │  │   Shard 1   │  │   Shard 2   │  │   Shard 3   │    │  │
│  │  │(orders_2024)│  │(orders_2023)│  │(orders_2022)│    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```
## 2. MySQL 샤딩 구현 예시
### **Order Service의 샤딩 구성**
``` java
@Configuration
public class OrderDatabaseConfig {
    
    @Bean
    @Primary
    public DataSource shard1DataSource() {
        return DataSourceBuilder.create()
                .url("jdbc:mysql://order-db-shard1:3306/orders_2024")
                .username("order_service")
                .password("password")
                .type(HikariDataSource.class)
                .build();
    }
    
    @Bean
    public DataSource shard2DataSource() {
        return DataSourceBuilder.create()
                .url("jdbc:mysql://order-db-shard2:3306/orders_2023")
                .username("order_service")
                .password("password")
                .type(HikariDataSource.class)
                .build();
    }
    
    @Bean
    public DataSource shard3DataSource() {
        return DataSourceBuilder.create()
                .url("jdbc:mysql://order-db-shard3:3306/orders_2022")
                .username("order_service")
                .password("password")
                .type(HikariDataSource.class)
                .build();
    }
    
    @Bean
    public ShardingDataSource shardingDataSource() {
        Map<String, DataSource> dataSources = new HashMap<>();
        dataSources.put("shard1", shard1DataSource());
        dataSources.put("shard2", shard2DataSource());
        dataSources.put("shard3", shard3DataSource());
        
        return ShardingDataSourceFactory.createDataSource(dataSources, 
                                                          shardingRuleConfig());
    }
    
    private ShardingRuleConfiguration shardingRuleConfig() {
        ShardingRuleConfiguration config = new ShardingRuleConfiguration();
        
        // 주문 테이블 샤딩 규칙
        TableRuleConfiguration orderTableRule = new TableRuleConfiguration("orders", 
                "shard${1..3}.orders");
        
        // 날짜 기반 샤딩 전략
        orderTableRule.setDatabaseShardingStrategyConfig(
            new StandardShardingStrategyConfiguration("order_date", 
                                                     new DateBasedShardingAlgorithm()));
        
        config.getTableRuleConfigs().add(orderTableRule);
        return config;
    }
}
```
### **커스텀 샤딩 알고리즘**
``` java
public class DateBasedShardingAlgorithm implements PreciseShardingAlgorithm<Date> {
    
    @Override
    public String doSharding(Collection<String> availableTargetNames, 
                           PreciseShardingValue<Date> shardingValue) {
        
        Date orderDate = shardingValue.getValue();
        LocalDate localDate = orderDate.toInstant()
                                      .atZone(ZoneId.systemDefault())
                                      .toLocalDate();
        
        int year = localDate.getYear();
        
        // 년도 기반 샤딩
        if (year >= 2024) {
            return "shard1";
        } else if (year >= 2023) {
            return "shard2";
        } else {
            return "shard3";
        }
    }
}
```
## 3. MongoDB 샤딩 구현 예시
### **User Service의 MongoDB 샤딩**
``` java
@Configuration
public class UserDatabaseConfig {
    
    @Bean
    public MongoClient mongoClient() {
        // MongoDB 샤딩 클러스터 연결
        ConnectionString connectionString = new ConnectionString(
            "mongodb://mongos1:27017,mongos2:27017/user_service"
        );
        
        MongoClientSettings settings = MongoClientSettings.builder()
            .applyConnectionString(connectionString)
            .applyToConnectionPoolSettings(builder -> 
                builder.maxSize(50)
                       .minSize(10)
                       .maxWaitTime(5, TimeUnit.SECONDS)
            )
            .build();
            
        return MongoClients.create(settings);
    }
    
    @Bean
    public ReactiveMongoTemplate reactiveMongoTemplate() {
        return new ReactiveMongoTemplate(mongoClient(), "user_service");
    }
}
```
### **Docker Compose로 MongoDB 샤딩 구성**
``` yaml
# user-service/docker-compose.yml
version: '3.8'
services:
  # User Service WAS
  user-service:
    build: .
    ports:
      - "8081:8080"
    environment:
      - MONGODB_URI=mongodb://mongos1:27017,mongos2:27017/user_service
    depends_on:
      - mongos1
      - mongos2
      
  # MongoDB Sharding 구성
  # Config Servers
  configsvr1:
    image: mongo:5.0
    command: mongod --configsvr --replSet configrs --port 27017
    
  configsvr2:
    image: mongo:5.0
    command: mongod --configsvr --replSet configrs --port 27017
    
  configsvr3:
    image: mongo:5.0
    command: mongod --configsvr --replSet configrs --port 27017
    
  # Shard 1
  shard1svr1:
    image: mongo:5.0
    command: mongod --shardsvr --replSet shard1rs --port 27017
    
  shard1svr2:
    image: mongo:5.0
    command: mongod --shardsvr --replSet shard1rs --port 27017
    
  # Shard 2
  shard2svr1:
    image: mongo:5.0
    command: mongod --shardsvr --replSet shard2rs --port 27017
    
  shard2svr2:
    image: mongo:5.0
    command: mongod --shardsvr --replSet shard2rs --port 27017
    
  # Mongos (Router)
  mongos1:
    image: mongo:5.0
    command: mongos --configdb configrs/configsvr1:27017,configsvr2:27017,configsvr3:27017 --port 27017
    depends_on:
      - configsvr1
      - configsvr2
      - configsvr3
      
  mongos2:
    image: mongo:5.0
    command: mongos --configdb configrs/configsvr1:27017,configsvr2:27017,configsvr3:27017 --port 27017
    depends_on:
      - configsvr1
      - configsvr2
      - configsvr3
```
## 4. 마이크로서비스 레벨에서의 추상화
### **Repository 패턴으로 샤딩 숨기기**
``` java
@Repository
public class OrderRepository {
    
    private final DatabaseClient databaseClient;
    
    public OrderRepository(DatabaseClient databaseClient) {
        this.databaseClient = databaseClient; // 샤딩된 데이터소스
    }
    
    public Mono<Order> findById(String orderId) {
        // 샤딩 로직은 하위 레이어에서 처리
        return databaseClient.sql("SELECT * FROM orders WHERE id = ?")
                            .bind(0, orderId)
                            .map(this::mapRowToOrder)
                            .first();
    }
    
    public Mono<Order> save(Order order) {
        // 샤딩 키(order_date)를 포함한 쿼리
        return databaseClient.sql("""
            INSERT INTO orders (id, user_id, order_date, total_amount) 
            VALUES (?, ?, ?, ?)
            """)
            .bind(0, order.getId())
            .bind(1, order.getUserId())
            .bind(2, order.getOrderDate())
            .bind(3, order.getTotalAmount())
            .fetch()
            .rowsUpdated()
            .map(count -> order);
    }
    
    public Flux<Order> findByUserId(String userId) {
        // 크로스 샤드 쿼리 (성능 주의)
        return databaseClient.sql("SELECT * FROM orders WHERE user_id = ?")
                            .bind(0, userId)
                            .map(this::mapRowToOrder)
                            .all();
    }
}
```
## 5. 서비스별 독립적인 DB 스케일링
### **각 마이크로서비스가 다른 DB 기술 사용**
``` yaml
# 전체 MSA 구성
version: '3.8'
services:
  # User Service - MongoDB 샤딩
  user-service:
    build: ./user-service
    environment:
      - MONGODB_URI=mongodb://user-mongos:27017/user_service
    depends_on:
      - user-mongos
      
  # Order Service - MySQL 샤딩
  order-service:
    build: ./order-service
    environment:
      - DB_SHARD1_URL=jdbc:mysql://order-db-shard1:3306/orders_2024
      - DB_SHARD2_URL=jdbc:mysql://order-db-shard2:3306/orders_2023
      - DB_SHARD3_URL=jdbc:mysql://order-db-shard3:3306/orders_2022
    depends_on:
      - order-db-shard1
      - order-db-shard2
      - order-db-shard3
      
  # Product Service - PostgreSQL 단일 DB (아직 스케일링 불필요)
  product-service:
    build: ./product-service
    environment:
      - DB_URL=jdbc:postgresql://product-db:5432/product_service
    depends_on:
      - product-db
      
  # Payment Service - Redis Cluster (인메모리 DB)
  payment-service:
    build: ./payment-service
    environment:
      - REDIS_CLUSTER_NODES=redis-node1:6379,redis-node2:6379,redis-node3:6379
    depends_on:
      - redis-node1
      - redis-node2
      - redis-node3
```
## 6. 운영상의 이점
### **서비스별 독립적인 DB 최적화**
``` java
// Order Service - 날짜 기반 샤딩으로 시계열 데이터 최적화
@Service
public class OrderService {
    
    public Flux<OrderSummary> getMonthlyOrderSummary(int year, int month) {
        // 특정 샤드에서만 조회 (성능 최적화)
        return orderRepository.findByYearAndMonth(year, month)
                             .groupBy(Order::getOrderDate)
                             .flatMap(this::summarizeOrders);
    }
}

// User Service - 사용자 ID 기반 샤딩으로 사용자 데이터 분산
@Service
public class UserService {
    
    public Mono<User> findById(String userId) {
        // 사용자 ID 해시값으로 샤드 결정
        return userRepository.findById(userId); // 단일 샤드 접근
    }
}
```
### **각 서비스의 독립적인 모니터링**
``` java
@Component
public class OrderDatabaseMetrics {
    
    private final MeterRegistry meterRegistry;
    
    @Scheduled(fixedRate = 30000)
    public void collectShardMetrics() {
        // Order Service DB 클러스터만 모니터링
        collectShardConnectionMetrics();
        collectShardQueryMetrics();
        collectShardReplicationLag();
    }
}
```
이렇게 **각 마이크로서비스 내에서 DB를 스케일 아웃할 때는 WAS와 완전히 분리된 DB 클러스터를 구성**하고, 마이크로서비스는 **단일 데이터소스처럼 추상화된 인터페이스**를 통해 접근하게 됩니다. 이는 **Database-per-Service 원칙을 유지하면서도 각 서비스가 독립적으로 DB를 확장**할 수 있게 해줍니다.

