# Update
업데이트의 경우 `MongoOperation.updateFirst`를 사용하여 찾은 첫 번째 문서를 업데이트할 수 있고, `MongoOperation.updateMulti` 메서드를 사용하여 쿼리와 일치하는 것으로 찾은 모든 문서를 업데이트할 수 있으며, Fluent API에서는 `all`을 사용할 수 있다. 다음 예에서는 `$inc` 연산자를 사용하여 잔액에 일회성 $50.00 보너스를 추가하는 모든 SAVINGS 계좌를 업데이트하는 방법을 보여준다.

```java
Mono<UpdateResult> result = template.update(Account.class)
    .matching(where("accounts.accountType").is(Type.SAVINGS))
    .apply(new Update().inc("accounts.$.balance", 50.00))
    .all();
```

앞서 설명한 `Query` 외에도 `Update` 객체를 사용하여 업데이트 정의를 제공합니다. `Update` 클래스에는 MongoDB에서 사용 가능한 업데이트 수정자와 일치하는 메서드가 있습니다. 대부분의 메서드는 API에 유연한 스타일을 제공하기 위해 `Update` 객체를 반환한다.

> _Important_  
> `@Version` 속성은 업데이트에 포함되지 않으면 자동으로 증가한다. 이는 Optimistic Lock을 수행하는데 필요하다.

## Methods for Running Updates for Documents
updateFirst: 쿼리 문서 기준과 일치하는 첫 번째 문서를 업데이트된 문서로 업데이트한다.
updateMulti: 쿼리 문서 기준과 일치하는 모든 객체를 업데이트된 문서로 업데이트한다.

> _Warning_  
> `updateFirst`는 MongoDB 8.0 미만 버전에서는 정렬을 지원하지 않는다. 이전 버전을 사용하는 경우 `findAndModify`를 사용하여 정렬을 적용하자.

> _Note_   
> 업데이트 작업에 대한 인덱스 힌트는 `Query.withHint(...)`를 통해 제공될 수 있습니다.

## Methods in the Update Class
`Update` 클래스에서는 메서드들이 연쇄적으로 호출되도록 설계된 "syntax sugar"을 사용할 수 있다. 또한 `public static Update update(String key, Object value)`와 정적 임포트를 사용하여 새로운 `Update` 인스턴스 생성을 시작할 수 있다.

Update 클래스는 다음과 같은 메서드들을 포함한다:
- `Update` addToSet `(String key, Object value)` - `$addToSet` 업데이트 수정자를 사용한 업데이트
- `Update` currentDate `(String key)` - `$currentDate` 업데이트 수정자를 사용한 업데이트
- `Update` currentTimestamp `(String key)` - `$type timestamp`가 포함된 `$currentDate` 업데이트 수정자를 사용한 업데이트
- `Update` inc `(String key, Number inc)` - `$inc` 업데이트 수정자를 사용한 업데이트
- `Update` max `(String key, Object max)` - `$max` 업데이트 수정자를 사용한 업데이트
- `Update` min `(String key, Object min)` - `$min` 업데이트 수정자를 사용한 업데이트
- `Update` multiply `(String key, Number multiplier)` - `$mul` 업데이트 수정자를 사용한 업데이트
- `Update` pop `(String key, Update.Position pos)` - `$pop` 업데이트 수정자를 사용한 업데이트
- `Update` pull `(String key, Object value)` - `$pull` 업데이트 수정자를 사용한 업데이트
- `Update` pullAll `(String key, Object[] values)` - `$pullAll` 업데이트 수정자를 사용한 업데이트
- `Update` push `(String key, Object value)` - `$push` 업데이트 수정자를 사용한 업데이트
- `Update` pushAll `(String key, Object[] values)` - `$pushAll` 업데이트 수정자를 사용한 업데이트
- `Update` rename `(String oldName, String newName)` - `$rename` 업데이트 수정자를 사용한 업데이트
- `Update` set `(String key, Object value)` - `$set` 업데이트 수정자를 사용한 업데이트
- `Update` setOnInsert `(String key, Object value)` - `$setOnInsert` 업데이트 수정자를 사용한 업데이트
- `Update` unset `(String key)` - `$unset` 업데이트 수정자를 사용한 업데이트

## Aggregation Pipeline Updates
`MongoOperations` 및 `ReactiveMongoOperations`에서 제공하는 업데이트 메서드도 `AggregationUpdate`를 통해 집계 파이프라인을 사용할 수 있다. `AggregationUpdate`를 사용하면 업데이트 작업에서 [MongoDB 4.2 aggregation](https://www.mongodb.com/docs/manual/reference/method/db.collection.update/#update-with-aggregation-pipeline)를 활용할 수 있다. 업데이트에서 집계를 사용하면 단일 작업으로 여러 단계와 여러 조건을 표현하여 하나 이상의 필드를 업데이트할 수 있다.

업데이트는 다음과 같은 단계들로 구성될 수 있다:
- `AggregationUpdate.set(…​).toValue(…​)` → `$set : { …​ }`
- `AggregationUpdate.unset(…​)` → `$unset : [ …​ ]`
- `AggregationUpdate.replaceWith(…​)` → `$replaceWith : { …​ }`

```java
AggregationUpdate update = Aggregation.newUpdate()
    .set("average").toValue(ArithmeticOperators.valueOf("tests").avg())     // 1
    .set("grade").toValue(ConditionalOperators.switchCases(                 // 2
        when(valueOf("average").greaterThanEqualToValue(90)).then("A"),
        when(valueOf("average").greaterThanEqualToValue(80)).then("B"),
        when(valueOf("average").greaterThanEqualToValue(70)).then("C"),
        when(valueOf("average").greaterThanEqualToValue(60)).then("D"))
        .defaultTo("F")
    );

template.update(Student.class)                                              // 3
    .apply(update)
    .all(); // 4
```

```mongodb-json
db.students.update(                                                         
   { },
   [
     { $set: { average : { $avg: "$tests" } } },      // 1                      
     { $set: { grade: { $switch: {                    // 2                    
                           branches: [
                               { case: { $gte: [ "$average", 90 ] }, then: "A" },
                               { case: { $gte: [ "$average", 80 ] }, then: "B" },
                               { case: { $gte: [ "$average", 70 ] }, then: "C" },
                               { case: { $gte: [ "$average", 60 ] }, then: "D" }
                           ],
                           default: "F"
     } } } }
   ],
   { multi: true }                                        // 4                  
)
```

1. 	1번째 `$set` 단계에서는 테스트 필드의 평균을 기반으로 새로운 필드 평균을 계산한다. 
2. 2번째 `$set` 단계는 첫 번째 집계 단계에서 계산된 평균 필드를 기반으로 새로운 필드 등급을 계산한다.
3. 파이프라인은 학생 컬렉션에서 실행되며 집계 필드 매핑에 `Student`를 사용한다. 
4. 컬렉션 내의 모든 일치하는 문서에 업데이트를 적용한다.

# Upsert
`updateFirst` 오퍼레이션과 관련해서 `upsert` 오퍼레이션을 사용할 수도 있다. 이는 쿼리에 매치되는 document가 있을 때 insert를 수행하는 오퍼레이션이다. insert되는 document는 query document와 update document의 조합이다. 다음의 예시는 `upsert` 메소드의 사용 방법을 보여준다.

```java
Mono<UpdateResult> result = template.update(Person.class)
  .matching(query(where("ssn").is(1111).and("firstName").is("Joe").and("Fraizer").is("Update"))
  .apply(update("address", addr))
  .upsert();
```

> _Warning_  
> `upsert` does not support ordering. Please use `findAndModify` to apply `Sort`.

> _Important_  
> `@Version` 속성은 업데이트에 포함되지 않으면 자동으로 증가한다. 이는 Optimistic Lock을 수행하는데 필요하다.

## Replacing Documents in a Collection
`MongoTemplate`에서 제공하는 다양한 `replace` 메서드를 사용하면 일치하는 첫 번째 Document를 재정의할 수 있다. 일치하는 Document가 없으면 `ReplaceOptions`에 해당 구성을 제공하여 이전 섹션에서 설명한 대로 새 Document를 업서트할 수 있다.

```java
Person tom = template.insert(new Person("Motte", 21)); // 1
Query query = Query.query(Criteria.where("firstName").is(tom.getFirstName())); // 2 
tom.setFirstname("Tom"); // 3
template.replace(query, tom, ReplaceOptions.none()); //4
```

1. 새 document를 insert한다.
2. Replace할 single document를 찾는데 사용할 쿼리이다.
3. 기존 문서와 동일한 `_id`를 갖거나 `_id`가 전혀 없는 대체 문서를 설정합니다.
4. 바꾸기 작업을 실행합니다. 하나를 upsert로 바꿉니다.

```java
Person tom = new Person("id-123", "Tom", 21) 
Query query = Query.query(Criteria.where("firstName").is(tom.getFirstName()));
template.replace(query, tom, ReplaceOptions.replaceOptions().upsert());
```

1. upsert를 위해서는 `_id` 값이 반드시 필요하다. 그렇지 않으면 MongoDB가 도메인 유형과 호환되지 않는 `ObjectId`를 사용하여 새 `ObjectId`를 생성합니다. MongoDB는 도메인 유형을 인식하지 못하므로 `@Field(targetType)` 힌트는 고려되지 않으며, 생성된 `ObjectId`는 도메인 모델과 호환되지 않을 수 있습니다.
2. 매치되는 document가 없을 때 새 document를 insert하기 위해 `upsert`를 사용한다.

> _Warning_  
> 기존 문서의 `_id`는 replace 작업으로 변경할 수 없습니다. MongoDB는 `upsert` 시 항목의 새 ID를 결정하는 두 가지 방법을 사용합니다. * `_id`는 {"_id" : 1234 }처럼 쿼리 내에서 사용됩니다. * `_id`는 대체 문서에 존재합니다. 어떤 방법으로도 `_id`가 제공되지 않으면 MongoDB는 문서에 대한 새 `ObjectId`를 생성합니다. 사용된 도메인 유형 `id` 속성의 유형이 `Long`과 같은 다른 경우 매핑 및 데이터 조회 오류가 발생할 수 있습니다.

# Find and Modify
`MongoCollection`의 `findAndModify(...)` 메서드는 문서를 업데이트하고 단일 작업으로 이전 문서나 새로 업데이트된 문서를 반환할 수 있다. `MongoTemplate`은 `Query` 및 `Update` 클래스를 사용하여 `Document`를 POJO로 변환하는 네 가지 `findAndModify` 오버로드 메서드를 제공한다.

```java
<T> T findAndModify(Query query, Update update, Class<T> entityClass);

<T> T findAndModify(Query query, Update update, Class<T> entityClass, String collectionName);

<T> T findAndModify(Query query, Update update, FindAndModifyOptions options, Class<T> entityClass);

<T> T findAndModify(Query query, Update update, FindAndModifyOptions options, Class<T> entityClass, String collectionName);
```

다음의 예제는 몇 개의 `Person` 객체를 컨테이너에 insert하고 `findAndUpdate` 오퍼레이션을 수행한다.
```java
template.insert(new Person("Tom", 21));
template.insert(new Person("Dick", 22));
template.insert(new Person("Harry", 23));

Query query = new Query(Criteria.where("firstName").is("Harry"));
Update update = new Update().inc("age", 1);

Person oldValue = template.update(Person.class)
  .matching(query)
  .apply(update)
  .findAndModifyValue(); // oldValue.age == 23

Person newValue = template.query(Person.class)
  .matching(query)
  .findOneValue(); // newValye.age == 24

Person newestValue = template.update(Person.class)
  .matching(query)
  .apply(update)
  .withOptions(FindAndModifyOptions.options().returnNew(true)) // Now return the newly updated document when updating
  .findAndModifyValue(); // newestValue.age == 25
```
`FindAndModifyOptions` 메서드를 사용하면 `returnNew`, `upsert`, `remove` 옵션을 설정할 수 있다. 이전 코드를 확장한 예제는 다음과 같다:
```java
Person upserted = template.update(Person.class)
  .matching(new Query(Criteria.where("firstName").is("Mary")))
  .apply(update)
  .withOptions(FindAndModifyOptions.options().upsert(true).returnNew(true))
  .findAndModifyValue()
```

# Find and Replace
전체 `Document`를 바꾸는 가장 간단한 방법은 `save` 메서드를 사용하여 해당 문서의 `id`를 확인하는 것이다. 하지만 이 방법이 항상 가능한 것은 아니다. `findAndReplace`는 간단한 쿼리를 통해 바꿀 문서를 식별할 수 있는 대안을 제공한다.

```java
Optional<User> result = template.update(Person.class) // 1      
    .matching(query(where("firstame").is("Tom")))     // 2 
    .replaceWith(new Person("Dick"))
    .withOptions(FindAndReplaceOptions.options().upsert())  // 3
    .as(User.class)                                        // 4
    .findAndReplace();                                     // 5
```

1. 쿼리를 매핑하고 컬렉션 이름을 끌어내기 위해 주어진 도메인 유형과 함께 fluent update API를 사용하거나 `MongoOperations#findAndReplace`를 사용하자.
2. 주어진 도메인 유형에 매핑된 실제로 일치하는 쿼리이다. 쿼리를 통해 정렬, 필드 및 데이터 정렬 설정을 제공한다.
3. 기본값 외에 `upsert`와 같은 옵션을 제공하기 위한 추가 선택적 hook이다.
4. 작업 결과를 매핑하는 데 사용되는 선택적 projection 유형이다. 지정된 투영 유형이 없으면 초기 도메인 유형이 사용된다.
5. 실제 처리를 트리거한다. `Optional` 대신 `findAndReplaceValue`를 사용하여 null 허용 결과를 얻는다.

> _Important_
> 대체 문서는 자체적으로 `id`를 가져서는 안 된다. 기존 `Document`의 `id`가 저장소 자체에 의해 대체 문서로 전달되기 때문이다. 또한 `findAndReplace`는 지정된 정렬 순서에 따라 쿼리 기준과 일치하는 첫 번째 문서만 대체한다는 것에 유의하자.

# Delete
5개의 오버로드된 메서드 중 하나를 사용하여 데이터베이스에서 객체를 제거할 수 있다.

```java
template.remove(tywin, "GOT"); // 1
template.remove(query(where("lastname").is("lannister")), "GOT"); // 2
template.remove(new Query().limit(3), "GOT"); // 3
template.findAllAndRemove(query(where("lastname").is("lannister"), "GOT"); // 4
template.findAllAndRemove(new Query().limit(3), "GOT");  // 5
```

1. 연관된 컬렉션에서 `_id`로 지정된 단일 엔터티를 제거한다.
2. `GOT` 컬렉션에서 쿼리 기준과 일치하는 모든 문서를 제거한다.
3. `GOT` 컬렉션에서 처음 세 개의 문서를 제거한다. <2>와 달리, 제거할 문서는 `_id`로 식별되며, 주어진 쿼리를 실행하고 `sort`, `limit`, `skip` 옵션을 먼저 적용한 후, 별도의 단계에서 모두 한 번에 제거한다.
4. `GOT` 컬렉션에서 쿼리 조건에 맞는 모든 문서를 제거한다. <3>과 달리, 문서는 일괄적으로 삭제되지 않고 하나씩 삭제된다.
5. `GOT` 컬렉션에서 처음 세 개의 문서를 제거합니다. <3>과 달리, 문서는 일괄적으로 삭제되지 않고 하나씩 삭제됩니다.

# Optimistic Locking
`@Version` 어노테이션은 MongoDB 컨텍스트에서 JPA와 유사한 구문을 제공하며, 일치하는 버전을 가진 문서에만 업데이트가 적용되도록 한다. 따라서 version 속성의 실제 값이 업데이트 쿼리에 추가되어, 다른 작업이 문서를 변경하더라도 업데이트가 적용되지 않는다. 이 경우 `OptimisticLockingFailureException`이 발생한다. 다음 예제는 이러한 기능을 보여준다.

```java
@Document
class Person {

  @Id String id;
  String firstname;
  String lastname;
  @Version Long version;
}

Person daenerys = template.insert(new Person("Daenerys"));  // 1

Person tmp = template.findOne(query(where("id").is(daenerys.getId())), Person.class);   // 2 

daenerys.setLastname("Targaryen");
template.save(daenerys);       // 3                                                    

template.save(tmp); // throws OptimisticLockingFailureException // 4
```

1. 처음에 문서를 삽입한다. `version`은 `0`으로 설정된다.
2. 방금 삽입한 문서를 로드한다. `version`은 아직 `0`이다.
3. 문서를 `version = 0`으로 업데이트한다. `lastname`을 설정하고 `version`을 `1`로 높인다.
4. 이전에 로드한 문서 중 `version = 0`인 문서를 업데이트해보자. 현재 `version`이 `1`이므로 `OptimisticLockingFailureException` 오류가 발생하여 작업이 실패한다.

`MongoTemplate`의 특정 CRUD 작업만 버전 속성을 고려하고 변경한다. 자세한 내용은 `MongoOperations` Java 문서를 참조하자.

> _Important_
> Optimistic Locking을 사용하려면 `WriteConcern`을 `ACKNOWLEDGED`로 설정해야 한다. 그렇지 않으면 `OptimisticLockingFailureException`이 자동으로 무시될 수 있다.

> _Note_
> 버전 2.2부터 `MongoOperations`는 데이터베이스에서 엔터티를 제거할 때 `@Version` 속성도 포함한다. 버전 확인 없이 `Document`를 제거하려면 `MongoOperations#remove(Object)` 대신 `MongoOperations#remove(Query,…)`를 사용하자.

> _Note_
> 버전 2.2부터 저장소는 버전 관리된 엔터티를 제거할 때 확인된 삭제 결과를 확인한다. `CrudRepository.delete(Object)`를 통해 버전 관리된 엔터티를 삭제할 수 없는 경우 `OptimisticLockingFailureException`이 발생한다. 이 경우 버전이 변경되었거나 객체가 삭제된 것이다. `CrudRepository.deleteById(ID)`를 사용하면 낙관적 잠금 기능을 우회하고 버전과 관계없이 객체를 삭제할 수 있다.