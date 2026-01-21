MongoDB나 Redis에 Java 객체를 JSON 형식의 String으로 변환할 때, 클래스 정보(예: @class 또는 class 필드)가 함께 저장되는 경우가 있다.

이 현상은 **특정 라이브러리의 기본 설정**에 따라 다르다.

### 왜 클래스 정보가 매핑되는가?

- **역직렬화(Deserialization) 시 타입 보존**:
    - Java의 직렬화/역직렬화 라이브러리(예: Jackson, Gson, Spring Data Redis, MongoDB Java Driver 등)는 다형성(Polymorphism)을 지원하기 위해 클래스 정보를 JSON에 포함시킬 수 있다.
    - 예를 들어, 부모 타입으로 저장했다가 자식 타입으로 복원해야 할 때 필요하다.
- **Spring Data Redis/MongoDB**
    - Spring Data Redis의 경우, 기본적으로 `JdkSerializationRedisSerializer` 또는 `GenericJackson2JsonRedisSerializer를` 사용하면 `@class` 필드가 추가되어 저장된다.
    - Spring Data MongoDB도 마찬가지로, 다형성 객체를 저장할 때 `_class` 필드가 추가된다.

### 꼭 필요한가?

- **필수는 아님**
    - 단일 타입만 저장/복원한다면 클래스 정보가 없어도 무방하다.
    - 여러 타입(상속 구조 등)을 저장/복원해야 한다면 클래스 정보가 필요할 수 있다.

### 설정으로 끌 수 있는가?

- **설정으로 끌 수 있다.**
    - Spring Data MongoDB:
        - `MappingMongoConverter`에서 `_class` 필드 저장을 비활성화할 수 있다.
    - Spring Data Redis:
        - `Jackson2JsonRedisSerializer`를 직접 설정하고, `ObjectMapper`의 `enableDefaultTyping`을 끄면 클래스 정보가 저장되지 않는다.

```java
@Configuration
public class RedisConfig {

    @Bean
    public ReactiveRedisTemplate<String, Object> reactiveRedisTemplate(ReactiveRedisConnectionFactory connectionFactory) {
        // objectMapper.enableDefaultTyping() 설정을 하지 않음으로써 클래스 정보 저장 비활성화
        ObjectMapper objectMapper = new ObjectMapper();

        Jackson2JsonRedisSerializer<Object> serializer = new Jackson2JsonRedisSerializer<>(objectMapper, Object.class);

        RedisSerializationContext.RedisSerializationContextBuilder<String, Object> builder =
                RedisSerializationContext.newSerializationContext(new StringRedisSerializer());

        RedisSerializationContext<String, Object> context = builder
                .value(serializer)
                .hashValue(serializer)
                .build();

        return new ReactiveRedisTemplate<>(connectionFactory, context);
    }
}

@Configuration
public class MongoConfig {

    @Bean
    public ReactiveMongoTemplate reactiveMongoTemplate(ReactiveMongoDatabaseFactory mongoDatabaseFactory) {
        ReactiveMongoTemplate template = new ReactiveMongoTemplate(mongoDatabaseFactory);

        // _class 필드 저장 비활성화
        ((MappingMongoConverter) template.getConverter())
                .setTypeMapper(new DefaultMongoTypeMapper(null));

        return template;
    }
}
```