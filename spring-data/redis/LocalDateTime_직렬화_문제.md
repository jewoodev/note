Redis에는 따로 전용 DB Serializer가 없기 때문에 Jackson을 사용하게 되는데, LocalDateTime을 직렬화하는데서 문제가 발생한다.

```
com.fasterxml.jackson.databind.exc.InvalidDefinitionException: Java 8 date/time type `java.time.LocalDateTime` not supported by default: add Module "com.fasterxml.jackson.datatype:jackson-datatype-jsr310" to enable handling (through reference chain: com.heri2go.chat.domain.user.User["createdAt"])
```

에러가 알려주는 의존성은 스프링 부트 2.0 버전(확인 필요)에서 부터 기본적으로 가져오기 때문에 따로 추가해줄 필요는 없다. 그게 문제가 아니라 Jackson의 jsr310 모듈도 Redis 로의 LocalDateTime 타입의 직렬화는 제공하지 않는 것 같다. 

오브젝트 매퍼에 올바르게 설정을 해도 같은 에러가 발생한다. 캐싱 데이터에 자바의 LocalDateTime을 저장할 필요 자체가 떨어지기 때문에 관련해서 직접 기능을 만들 필요는 없을 거라 생각된다.