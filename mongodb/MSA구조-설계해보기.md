# MSA의 실제 구조
## 도메인별 서비스 분리 (Database-per-Service)
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
## 도메인별 서비스 구현
### User Service
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

### Order Service
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
### WebClient를 통한 서비스 호출
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
### Database-per-Service 원칙
- 각 서비스가 **자신의 데이터베이스만 소유**
- 다른 서비스의 DB에 **직접 접근 금지**
- 모든 데이터 접근은 **API를 통해서만**

### 독립적인 배포와 스케일링
- 각 서비스는 **독립적으로 배포**
- **필요에 따라 개별 서비스만 스케일링**
- **기술 스택을 서비스별로 다르게** 선택 가능

이렇게 MSA에서는 **도메인별로 서비스와 데이터베이스를 완전히 분리**하여, 각 서비스가 자신의 데이터에 대한 완전한 소유권을 가지도록 설계해야 한다.


# Database-per-Service
각 WAS 당 독립된 DB를 갖도록 하는 방법도 있지만 서버 종류마다 하나의 클러스터를 운용하는 방법도 있다.

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
### Order Service의 샤딩 구성
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

### 커스텀 샤딩 알고리즘
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
### User Service의 MongoDB 샤딩
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

### Docker Compose로 MongoDB 샤딩 구성
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
### Repository 패턴으로 샤딩 숨기기
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
### 각 마이크로서비스가 다른 DB 기술 사용
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
### 서비스별 독립적인 DB 최적화
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
이렇게 **각 마이크로서비스 내에서 DB를 스케일 아웃할 때는 WAS와 완전히 분리된 DB 클러스터를 구성**하고, 마이크로서비스는 **단일 데이터소스처럼 추상화된 인터페이스**를 통해 접근하게 된다. 이는 **Database-per-Service 원칙을 유지하면서도 각 서비스가 독립적으로 DB를 확장**할 수 있게 해준다.
