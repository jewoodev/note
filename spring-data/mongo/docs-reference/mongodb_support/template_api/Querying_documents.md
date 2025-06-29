`Query` 및 `Criteria` 클래스를 사용하여 쿼리를 표현할 수 있다. 이 클래스의 메서드 이름은 `lt`, `lte`, `is` 등 MongoDB 네이티브 연산자 이름과 같다. `Query` 및 `Criteria` 클래스들은 fluent API 스타일을 따르므로 여러 메서드 기준과 쿼리를 연결하여 이해하기 쉬운 코드를 작성할 수 있다. 가독성을 높이기 위해 정적 가져오기를 사용하면 `Query` 및 `Criteria` 인스턴스를 생성할 때 'new' 키워드를 사용하지 않아도 된다. 다음 예제와 같이 `BasicQuery`를 사용하여 일반 JSON 문자열로 `Query` 인스턴스를 생성할 수도 있다.

```java
BasicQuery query = new BasicQuery("{ age : { $lt : 50 }, accounts.balance : { $gt : 1000.00 }}");
List<Person> result = mongoTemplate.find(query, Person.class);
```

# Querying Documents in a Collection
이전 문서들에서 `MongoTemplate`의 `findOne` 및 `findById` 메서드를 사용하여 단일 문서를 검색하는 방법을 살펴보았다. 이 메서드들은 단일 도메인 객체를 바로 반환하거나, 반응형 API인 `Mono`를 사용하여 단일 요소를 반환한다. 또한, 도메인 객체의 list로 반환될 문서 컬렉션을 쿼리할 수도 있다. 이름과 나이를 가진 여러 개의 `Person` 객체가 컬렉션에 문서로 저장되어 있고, 각 개인에게 잔액이 포함된 내장 계좌 문서가 있다고 가정하면, 다음 코드를 사용하여 쿼리를 실행할 수 있다.

```java
// ...

Flux<Person> result = template.query(Person.class)
  .matching(query(where("age").lt(50).and("accounts.balance").gt(1000.00d)))
  .all();
```

모든 find 메서드는 `Query` 객체를 매개변수로 받는다. 이 객체는 쿼리 수행에 사용되는 기준과 옵션을 정의한다. 기준은 `where`라는 이름의 정적 팩토리 메서드를 갖는 `Criteria` 객체를 사용하여 지정하며, 이 객체를 통해 새 `Criteria` 객체를 인스턴스화한다. 쿼리의 가독성을 높이려면 `org.springframework.data.mongodb.core.query.Criteria.where` 및 `Query.query`에 정적 import를 사용하는 것이 좋다.

쿼리는 지정된 기준을 충족하는 `Person` 객체의 `List` 또는 `Flux`를 반환해야 한다. 이 섹션의 나머지 부분에서는 MongoDB에서 제공하는 연산자에 해당하는 `Criteria` 및 `Query` 클래스의 메서드를 나열한다. 대부분의 메서드는 API에 유연한 스타일을 제공하기 위해 `Criteria` 객체를 반환한다.

`Criteria` Class의 메서드들과 `Query` Class의 메서드들은 [공식 문서](https://docs.spring.io/spring-data/mongodb/reference/mongodb/template-query-operations.html)에서 직접 확인하자.


# Selecting fields
MongoDB는 [projecting fields](https://www.mongodb.com/docs/manual/tutorial/project-fields-from-query-results/)를 쿼리가 반환하게 하는 것을 지원한다. Projection은 필드를 그것들의 이름을 기반으로 해서 제외할 수도 포함할 수도 있다. `_id` 필드는 명시적으로 제외하지 않으면 항상 포함된다.

```java
public class Person {

    @Id String id;
    String firstname;

    @Field("last_name")
    String lastname;

    Address address;
}

query.fields().include("lastname");              // 1

query.fields().exclude("id").include("lastname")  // 2

query.fields().include("address")                // 3

query.fields().include("address.city")            // 4
```
1. 결과에는 `{ "last_name" : 1 }`을 통해 `_id`와 `last_name`이 모두 포함된다.
2. 결과에는 `{ "_id" : 0, "last_name" : 1 }`를 통해 `last_name`만 포함된다.
3. 결과에는 `_id`와 `{ "address" : 1 }`를 통해 전체 주소 객체가 포함된다.
4. 결과에는 `{ "address.city" : 1 }`를 통해 `city` 필드만 포함하는 `_id` 및 `address` 객체가 포함된다.

MongoDB 4.4부터 아래와 같이 필드 프로젝션에 집계 표현식을 사용할 수 있다.

```java
query.fields()
  .project(MongoExpression.create("'$toUpper' : '$last_name'"))         // 1
  .as("last_name");                                                     // 2

query.fields()
  .project(StringOperators.valueOf("lastname").toUpper())               // 3
  .as("last_name");

query.fields()
  .project(AggregationSpELExpression.expressionOf("toUpper(lastname)")) // 4
  .as("last_name");
```

1. 네이티브 표현식을 사용할 수 있다. 이때 사용된 필드 이름은 데이터베이스 문서 내의 필드 이름을 참조해야 한다.
2. 표현식 결과가 투영될 필드 이름을 지정한다. 결과 필드 이름은 도메인 모델에 매핑되지 않는다.
3. `AggregationExpression`을 사용할 수 있다. 기본 `MongoExpression` 외에 필드 이름은 도메인 모델에 사용된 이름에 매핑된다.
4. `AggregationExpression`과 함께 SpEL을 사용하여 표현식 함수를 호출한다. 필드 이름은 도메인 모델에서 사용되는 필드 이름과 매핑된다.

`@Query(fields="…")` allows usage of expression field projections at `Repository` level as described in [MongoDB JSON-based Query Methods and Field Restriction](https://docs.spring.io/spring-data/mongodb/reference/mongodb/repositories/repositories.html#mongodb.repositories.queries.json-based).


# Additional Query Options
MongoDB는 주석이나 배치 크기와 같은 메타 정보를 쿼리에 적용하는 다양한 방법을 제공합니다. `Query` API를 직접 사용하면 이러한 옵션에 대한 여러 가지 방법을 사용할 수 있습니다.

## Hints
인덱스 힌트는 인덱스 이름이나 필드 정의를 사용하여 두 가지 방법으로 적용할 수 있다.
```java
template.query(Person.class)
    .matching(query("...").withHint("index-to-use"));

template.query(Person.class)
    .matching(query("...").withHint("{ firstname : 1 }"));
```

## Cursor Batch Size
커서 배치 크기는 각 응답 배치에서 반환할 문서 수를 정의한다.
```java
Query query = query(where("firstname").is("luke"))
    .cursorBatchSize(100)
```

## Collations
컬렉션 작업에서 데이터 정렬을 사용하려면 다음 두 가지 예에서 보듯이 쿼리나 작업 옵션에서 `Collation` 인스턴스를 지정하면 된다.
```java
Collation collation = Collation.of("de");

Query query = new Query(Criteria.where("firstName").is("Amél"))
    .collation(collation);

List<Person> results = template.find(query, Person.class);
```

## Read Preference
사용할 `ReadPreference`는 아래에 설명된 대로 실행할 `Query` 객체에 직접 설정할 수 있다.
```java
template.find(Person.class)
    .matching(query(where(...)).withReadPreference(ReadPreference.secondary()))
    .all();
```

> _Note_
> `Query` 인스턴스에 설정된 기본 설정은 `MongoTemplate`의 기본 `ReadPreference`를 대체하게 된다.

## Comments
쿼리에 주석을 추가하면 서버 로그에서 더 쉽게 찾을 수 있다.
```java
template.find(Person.class)
    .matching(query(where(...)).comment("Use the force luke!"))
    .all();
```


# Query Distinct Values
Collection의 distinct values를 `MongoDBTemplate`을 통해 조회할 수 있다. 추가적인 내용은 [공식 문서]((https://docs.spring.io/spring-data/mongodb/reference/mongodb/template-query-operations.html))를 확인하자.

# About Geo 1, 2, ...
지리 데이터에 관한 내용은 공식 문서를 확인하자.

# Full-text Search 
`$text` 오퍼레이터에 관한 내용들이다. 이것도 공식 문서를 참고하자.

# Query by Example
Query by Example는 템플릿 API 수준에서 Example 쿼리를 실행하는데 사용될 수 있다.

```java
Person probe = new Person();
probe.lastname = "stark";

Example example = Example.of(probe);

Query query = new Query(new Criteria().alike(example));
List<Person> result = template.find(query, Person.class);
```

기본 `Query` 객체는 `_class` 키의 값으로 쿼리의 결과를 엄격하게 제한한다. 만약 이를 원하지 않는다면, `UntypedExampleMatcher`를 사용하자. 이걸 사용하면 기본 동작을 우회하여 타입 제한을 없앨 수 있다.
```java
class JustAnArbitraryClassWithMatchingFieldName {
  @Field("lastname") String value;
}

JustAnArbitraryClassWithMatchingFieldNames probe = new JustAnArbitraryClassWithMatchingFieldNames();
probe.value = "stark";

Example example = Example.of(probe, UntypedExampleMatcher.matching());

Query query = new Query(new Criteria().alike(example));
List<Person> result = template.find(query, Person.class);
```