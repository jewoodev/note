MongoTemplate과 org.springframework.data.mongodb.core 패키지에 있는 반응형 클래스는 Spring의 MongoDB 지원의 핵심 클래스이며, 데이터베이스와의 상호 작용을 위한 풍부한 기능 세트를 제공한다. 이 템플릿은 MongoDB 문서를 생성, 업데이트, 삭제 및 쿼리하는 편리한 작업을 제공하며, 도메인 객체와 MongoDB 문서 간의 매핑을 제공한다.

> 한 번 설정되고 나면, `MongoTemplate`는 thread-safe 하며 여러 인스턴스에서 재사용할 수 있다.

## Convenience Methods
`MongoTemplate` 클래스는 `MongoOperations` 인터페이스를 구현한다. `MongoOperations`의 메서드는 MongoDB 드라이버 `Collection` 객체에서 사용 가능한 메서드의 이름을 최대한 따서 명명했다. 이는 드라이버 API에 익숙한 기존 MongoDB 개발자에게 API가 친숙하게 느껴지도록 하기 위함이다.

MongoDB driver와 달리 `MongoOperations`는 Document 대신 도메인 객체를 전달할 수 있다. 또한 `MongoOperations`는 Document를 채워 해당 작업의 매개변수를 지정하는 대신, 쿼리, 기준 및 업데이트 작업을 위한 유연한 API를 제공한다.

> MongoTemplate 인스턴스의 작업을 참조하는 가장 좋은 방법은 MongoOperations 인터페이스를 사용하는 것이다.

## Execute Callbacks
MongoTemplate은 일반적인 작업을 쉽게 수행할 수 있도록 다양한 편의 메서드를 제공한다. 하지만 MongoDB 드라이버 API를 직접적으로 사용하고 싶다면, 여러 Execute 콜백 메서드 중 하나를 사용할 수 있다. Execute 콜백은 MongoCollection 또는 MongoDatabase 객체에 대한 reference를 제공한다.

- `<T> T execute (Class<?> entityClass, CollectionCallback<T> action)`: 지정된 클래스의 엔터티 컬렉션에 대해 주어진 CollectionCallback을 실행한다.
- `<T> T execute (String collectionName, CollectionCallback<T> action)`: 지정된 이름의 컬렉션에서 지정된 CollectionCallback을 실행한다.
- `<T> T execute (DbCallback<T> action)`: DbCallback을 실행하여 필요에 따라 예외를 변환한다. Spring Data MongoDB는 MongoDB 2.2 버전에 도입된 Aggregation Framework를 지원한다.
- `<T> T execute (String collectionName, DbCallback<T> action)`: 지정된 이름의 컬렉션에서 DbCallback을 실행하여 필요에 따라 예외를 변환한다.
- `<T> T executeInSession (DbCallback<T> action)`: 쓰기 작업이 많은 환경에서 데이터를 읽을 수 있는 경우에도 일관성을 보장하기 위해 동일한 데이터베이스 연결 내에서 지정된 DbCallback을 실행한다.

아래 예시에서 CollectionCallback을 사용하여 인덱스에 대한 정보를 반환한다.

```java
Mono<Boolean> hasIndex = template.execute("geolocation", collection ->
    Flux.from(collection.listIndexes(org.bson.Document.class))
        .map(document -> document.get("name"))
        .filterWhen(name -> Mono.just("location_2d".equals(name)))
        .map(it -> Boolean.TRUE)
        .single(Boolean.FALSE)
    ).next();
```

## Fluent API
MongoDB와의 저수준 상호작용에서 핵심 구성 요소인 MongoTemplate은 컬렉션 생성, 인덱스 생성, CRUD 작업부터 Map-Reduce 및 집계와 같은 고급 기능까지 다양한 요구 사항을 충족하는 광범위한 메서드를 제공한다. 각 메서드에는 여러 overload 구현이 있으며, 대부분은 optional 또는 nullable 부분들을 커버한다.

FluentMongoOperations는 MongoOperations의 일반적인 메서드에 대해 더 좁은 인터페이스를 제공하고, 더 읽기 쉽고 유창한 API를 제공한다. 그리고 진입점(insert(…), find(…), update(…) 등)은 실행할 작업에 따라 자연스러운 명명 체계를 따른다. 진입점에서 더 나아가, API는 MongoOperations의 실제 대응 메서드(다음 예제의 경우 all 메서드)를 호출하는 종료 메서드로 이어지는 컨텍스트 종속 메서드만 제공하도록 설계되었다.

```java
List<Jedi> all = template.query(SWCharacter.class)
                .inCollection("star-wars")
                .as(Jedi.class)
                .matching(query(where("jedi").is(true)))
                .all();
```

1. The type used to map fields used in the query to.
2. The collection name to use if not defined on the domain type.
3. Result type if not using the original domain type.
4. The lookup query.

> 프로젝션을 사용하면 MongoTemplate이 프로젝션 대상 유형에 필요한 필드로 실제 응답을 제한하여 결과 매핑을 최적화할 수 있다. 이는 쿼리 자체에 필드 제한이 없고 대상 유형이 폐쇄형 인터페이스 또는 DTO 프로젝션인 경우에 적용된다.

> DBRef에 프로젝션을 적용할 수 없다.

종료 메서드인 first(), one(), all() 또는 stream()을 통해 단일 엔터티를 검색하거나 여러 엔터티를 목록이나 스트림으로 검색하는 것 사이를 전환할 수 있다.

## Exception Translation
Spring 프레임워크는 다양한 데이터베이스 및 매핑 기술에 대한 예외 변환 기능을 제공한다. 이는 전통적으로 JDBC와 JPA를 위한 것이었다. Spring의 MongoDB 지원은 `org.springframework.dao.support.PersistenceExceptionTranslator` 인터페이스 구현을 제공하여 이 기능을 MongoDB 데이터베이스로 확장합니다.

Spring의 [일관된 데이터 액세스 예외 계층 구조](https://docs.spring.io/spring-framework/reference/data-access.html#dao-exceptions)에 매핑하는 이유는 MongoDB 오류 코드에 의존하지 않고도 이식 가능하고 서술적인 예외 처리 코드를 작성할 수 있기 때문이다. Spring의 모든 데이터 액세스 예외는 루트 `DataAccessException` 클래스에서 상속되므로 단일 try-catch 블록 내에서 모든 데이터베이스 관련 예외를 확실하게 처리할 수 있다. MongoDB 드라이버에서 발생하는 모든 예외가 `MongoException` 클래스에서 상속되는 것은 아니다. inner exception과 메시지는 정보 손실을 방지하기 위해 보존된다.

`MongoExceptionTranslator가` 수행하는 매핑 중 일부는 `com.mongodb.Network`를 `DataAccessResourceFailureException`으로 매핑하고, `MongoException` 오류 코드 1003, 12001, 12010, 12011, 12012를 `InvalidDataAccessApiUsageException`으로 매핑하는 것이다.

예외 변환은 `MongoDatabaseFactory` 또는 그것의 reative variant에 사용자 지정 `MongoExceptionTranslator`를 설정하여 구성할 수 있습니다. 해당 `MongoClientFactoryBean`에 예외 변환기를 설정할 수도 있습니다. 해당 `MongoClientFactoryBean`에 예외 변환기를 설정할 수도 있다.

`MongoExceptionTranslator`를 구성하는 예시 코드는 다음과 같다.
```java
ConnectionString uri = new ConnectionString("mongodb://username:password@localhost/database");
SimpleMongoClientDatabaseFactory mongoDbFactory = new SimpleMongoClientDatabaseFactory(uri);
mongoDbFactory.setExceptionTranslator(myCustomExceptionTranslator);
```

예외를 커스터마이징하는 이유는 write 충돌같은 몇몇 일시적인 실패와 재시도했을 때 성공으로 이어지는 operation이 존재하는 트랜잭션 동안의 MongoDB의 행동에 있을 수 있다. 이런 경우, 특정 MongoDB label로 예외를 래핑하고 다른 예외 변환 전략을 적용할 수 있다.

## Domain Type Mapping
MongoDB 문서와 도메인 클래스 간의 매핑은 `MongoConverter` 인터페이스 구현에 위임하여 수행된다. Spring은 `MappingMongoConverter`를 제공하지만, 사용자가 직접 변환기를 작성할 수도 있다. `MappingMongoConverter`는 추가 메타데이터를 사용하여 객체와 문서 간의 매핑을 지정할 수 있지만, ID와 컬렉션 이름 매핑에 대한 몇 가지 규칙을 사용하여 추가 메타데이터가 없는 객체를 변환할 수도 있습니다. 
