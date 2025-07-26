# Custom Conversions
다음은 `String` 타입을 custom `Email` 값의 object로 변환하는 Spring Converter 구현의 예시이다.

```java
@ReadingConverter
public class EmailReadConverter implements Converter<String, Email> {

  public Email convert(String source) {
    return Email.valueOf(source);
  }
}
```

소스와 대상 타입이 네이티브 타입인 `Converter`를 작성하는 경우, 이를 읽기 전용 변환기로 간주해야 할지 쓰기 전용 변환기로 간주해야 할지 스프링은 판단할 수 없다. 변환기 인스턴스를 읽기 전용 변환기와 쓰기 전용 변환기의 역할을 모두 수행하도록 등록하면 원치 않는 결과가 발생할 수 있다. 예를 들어, `Converter<String, Long>`은 모호하지만(등록이 되긴 한다), 쓰기 작업 시 모든 `String` 인스턴스를 `Long` 인스턴스로 변환하는 것은 말이 되지 않을 수 있다. 인프라스트럭처가 변환기를 하나의 방법으로만 등록하도록 강제하는 방법을 제공하기 위해, 우리는 변환기 구현에 사용할 수 있는 `@ReadingConverter` 및 `@WritingConverter` 어노테이션을 제공합니다.

컨버터들은 분명하게 register가 되어야 하는 인스턴스이다. Registration 같은 것으로부터 생겨나는 사이드 이펙트와 conversion service와 함께 unwanted registration이 수행되는 것을 피하기 위해서 그렇다. 컨버터들은 소스 및 대상 유형에 따라 등록된 변환기에 대한 등록 및 쿼리를 허용하는 중앙 시설인 `CustomConversions`에 등록된다.

## Converter Disambiguation
일반적으로 우리는 source와 target 타입 간의 변환을 수행하는 `Converter`의 구현체들을 점검한다. 그것들 중 하나가 기본 data access API가 natively하게 처리할 수 있는 type인지 여부에 따라 컨버터 인스턴스를 읽기 또는 쓰기 컨버터로 등록한다.

```java
// Write converter as only the target type is one that can be handled natively
class MyConverter implements Converter<Person, String> { … }

// Read converter as only the source type is one that can be handled natively
class MyConverter implements Converter<String, Person> { … }
```

## Type based Converter
매핑 결과에 영향을 주기 위한 방법으로 가장 사소한 것은 `@Field` 애노테이션으로 native MongoDB target type을 원하는 것으로 저장하는 것이다. 이것은 도메인 모델의 프로퍼티가 `BigDecimal`처럼 MongoDB types 가 아닌 경우에도 native인 `org.bson.types.Decimal128` 포맷으로 영속화하는 것으로 비틀어서 작업을 허용한다.

```java
public class Payment {

  @Id String id; // 1

  @Field(targetType = FieldType.DECIMAL128) // 2 
  BigDecimal value;

  Date date; // 3
}
```
```mongodb-json
{
  "_id"   : ObjectId("5ca4a34fa264a01503b36af8"), // 1 
  "value" : NumberDecimal(2.099),                 // 2
  "date"  : ISODate("2019-04-03T12:11:01.870Z")   // 3
}
```

1. 유효한 `ObjectId`로 표현될 String id 는 자동으로 변환된다.
2. 명확하게 desired target type이 명시되었다. 그렇지 않으면 `BigDecimal`은 `String`으로 변환된다.
3. `Date` 값은 MongoDB driver 자체에 의해 다뤄져서 `ISODate`로 저장된다.

간단한 타입 힌트를 제공하는 위의 정보는 유용하다. 매핑 과정을 더 부드럽게 하려면, you can register Spring converters를 `MappingMongoConverter`처럼 `MongoConverter` 구현체와 함께 등록해라.

`MappingMongoConverter`는 객체 자체를 매핑하기 전에 특정 클래스를 처리할 수 있는 Spring 변환기가 있는지 확인한다. 성능 향상이나 기타 사용자 지정 매핑 요구 사항 등을 위해 `MappingMongoConverter`의 일반적인 매핑 전략을 '차단'하려면 먼저 Spring `Converter` 인터페이스 구현체를 생성한 다음, 그걸 `MappingConverter`와 함께 등록해야 한다.

> _Note_
> 
> Spring type conversion service에 대한 더 자세한 정보는 [reference docs](https://docs.spring.io/spring-framework/reference/core.html#validation) 에서 확인하자.

