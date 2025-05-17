우리는 빈번하게 호출되는 쿼리의 결과를 캐싱하여 병목을 줄이고 성능을 높일 수 있다.

캐시 저장소는 인메모리 데이터베이스로 신뢰성이 높은 Redis를 사용하여 설명을 이어가겠다.

```java
@EnableCaching
@Configuration
public class RedisConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration cacheConfiguration = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(10))
                .disableCachingNullValues()
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer()));

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(cacheConfiguration)
                .withCacheConfiguration("user", cacheConfiguration.entryTtl(Duration.ofMinutes(5)))
                .build();
    }
}
```

Value Serializer는 GenericJackson2JsonRedisSerializer를 사용했고 이는 기본 생성자를 필요로 한다. 추가 설명은 생략하고 넘어가겠다.

```java
@Cacheable(value = "user", key = "#id")
public User getUser(Long id) {
    return userRepository.findById(id).orElse(null);
}
```

이런 식으로 사용하면 된다. value가 캐시 이름인데, 여기에 `::` 를 붙이고 key 값을 붙여서 Redis의 키(캐시의 value와 key를 조합해서 만든)를 생성한다. 따라서 유저 객체마다 id가 1, 2 라면 user::1, user::2 이렇게 생성된다. 

보통의 경우에는 위의 예시처럼 Persistent Layer에서 캐시를 관리하는 것보다는 Business Layer에서 캐시를 관리하는 것이 좋다. Repository는 데이터 접근 계층이므로, 캐시와 같은 부가 기능은 Service 계층에서 처리하는 것이 적절하다는, 관심사의 분리 원칙에 더 잘맞는다는 관점에서 그러하다. 

캐시를 삭제하는 API를 쉽게 만들게 해주는 `@CacheEvict` 애노테이션은 인터페이스에서 사용할 수 없으므로 일관성을 가져가기에도 좋다. 

위의 예시에서 `@Cacheable` 애너테이션 파라이터 값으로 쓰인 `#id` 는 Spring Expression Language(SpEL) 표현식이다. 

이 표현식에서 사용할 수 있는 특별한 변수들은 다음과 같다.

1.`#result`: 메서드의 반환값을 참조한다.
2.`#root`: 루트 객체를 참조한다.
3.`#root.method`: 실행된 메서드를 참조한다.
4.`#root.target`: 대상 객체를 참조한다.
5.`#root.targetClass`: 대상 클래스를 참조한다.
6.`#root.args`: 메서드의 인자 배열을 참조한다.
7.`#p0`, `#p1`, ...: 메서드의 첫 번째, 두 번째, ... 인자를 참조한다.
8.`#a0`, `#a1`, ...: `#p0`, `#p1`과 동일하다.
9.`#argumentName`: 메서드 파라미터의 이름으로 참조한다.

--- 

WebFlux 애플리케이션에서 Redis 캐시를 설정할 때 사용하는 `ConnectionFactory`는 reactive 버전의 팩토리를 사용해야 할 것 같은데, 실상은 그렇지 않다.

Spring의 캐시 추상화는 기본적으로 일반 스택을 기반으로 설계되어 있다. 따라서 `@Cacheable` 등의 캐시 어노테이션은 일반 `CacheManager`와 함께 사용된다. 그리고 `CacheManager`는 reactive 버전의 팩토리를 사용하지 않고 일반 팩토리를 사용한다. 따라서 `RedisConnectionFactory`를 사용해야.
