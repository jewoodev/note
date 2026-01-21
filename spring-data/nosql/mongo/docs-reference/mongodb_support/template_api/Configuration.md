### Default Read Preference
쿼리를 통해 다른 기본 preference가 정의되지 않은 경우 기본 read preference가 읽기 작업에 적용된다.

### WriteResultChecking Policy
개발 중에는 MongoDB 작업에서 반환된 com.mongodb.WriteResult에 오류가 포함된 경우 예외를 기록하거나 throw하는 것이 편리하다. 개발 중에 이 작업을 잊어버려 실제로는 데이터베이스가 예상대로 수정되지 않았음에도 불구하고 애플리케이션이 정상적으로 실행되는 것처럼 보이는 경우가 흔하다. MongoTemplate의 WriteResultChecking 속성을 EXCEPTION 또는 NONE 중 하나로 설정하면 각각 예외를 throw하거나 아무것도 하지 않는다. 기본적으로 WriteResultChecking 값은 NONE이다.

### Default WriteConcern
상위 레벨(예: `com.mongodb.client.MongoClient`)의 드라이버를 통해 아직 지정되지 않은 경우, `MongoTemplate`이 쓰기 작업에 사용하는 `com.mongodb.WriteConcern` 속성을 설정할 수 있다. `WriteConcern` 속성이 설정되지 않으면 MongoDB 드라이버의 DB 또는 Collection 설정에 설정된 속성이 기본값으로 사용된다.

### WriteConcernResolver
operation basis(for remove, update, insert, and save)마다 다른 `WriteConcern`을 set 하고 싶은 more advanced cases 에서는, `WriteConcernResolver` 라는 strategy interface가 `MongoTemplate`에 설정될 수 있다. `MongoTemplate`가 POJO들을 영구화하는데 사용되므로, `WriteConcernResolver`는 특정 POJO class를 `WriteConcern` 값으로 map할 수 있는 policy를 당신이 만들게 할 것이다. `WriteConcernResolver` 인터페이스를 봐보자.

```java
public interface WriteConcernResolver {
  WriteConcern resolve(MongoAction action);
}
```

`MongoAction` 인수는 `WriteConcern` 값을 결정하거나 템블릿의 값을 default로 사용하도록 하는데 쓰인다. `MongoAction`은 write가 행해질 collection의 이름과 operation 컨텍스트와 관련된 정보의 몇 개를 포함한다. 

```java
public class MyAppWriteConcernResolver implements WriteConcernResolver {

  @Override
  public WriteConcern resolve(MongoAction action) {
    if (action.getEntityType().getSimpleName().contains("Audit")) {
      return WriteConcern.ACKNOWLEDGED;
    } else if (action.getEntityType().getSimpleName().contains("Metadata")) {
      return WriteConcern.JOURNALED;
    }
    return action.getDefaultWriteConcern();
  }
}
```