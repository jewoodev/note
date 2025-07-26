`MappingMongoConverter`로부터 풍부한 mapping support가 제공된다. 이 converter는 domain objects를 MongoDB documents로 변환하는데 필요한 모든 기능을 제공하는 metadata model를 hold 하고 있다. Mapping metadata는 domain objects에 사용하는 애노테이션들로 채워진다. 그러나 이 인프라가 애노테이션만이 metadata 정보의 유일한 source가 되도록 제한하지 않는다. `MappingMongoConverter`는 또한 set of conventions만으로, 어떤 추가적인 metadata 없이 object를 map 할 수 있게 한다.

# Object Mapping Fundamentals
이 섹션에서는 Spring Data 객체 매핑, 객체 생성, 필드 및 속성 접근, 가변성 및 불변성의 기본 사항을 다룬다. 이 섹션은 JPA처럼 기본 데이터 저장소의 객체 매핑을 사용하지 않는 Spring Data 모듈에만 적용된다. 또한 인덱스, 열 또는 필드 이름 사용자 정의 등 저장소별 객체 매핑에 대한 내용은 저장소별 섹션을 참조하자.

Spring Data object mapping의 Core responsibility는 도메인 객체의 인스턴스를 생성하고 저장소의 네이티브한 데이터 구조에 그걸 입히는 것이다. 그리고 이건 우리가 근본적인 두 단계를 필요로 한다는 것을 의미한다.

1. Instance creation by using one of the constructors exposed.
2. Instance population to materialize all exposed properties.

## Object creation
Spring Data는 해당 유형의 객체를 구체화하는 데 사용될 영구 엔티티의 생성자를 자동으로 감지한다. Resolution 알고리즘은 다음과 같이 작동한다.
1. `@PersistenceCreator`와 함께 single static factory method가 있다면 그게 사용된다.
2. 하나의 생성자만 존재한다면, 그게 사용된다.
3. 여러 개의 생성자가 있고, 하나만 `@PersistenceCreator` 애노테이션이 적용되어 있다면 그게 사용된다.
4. 만약 타입이 자바의 `Record`이면 그것의 canonical constructor가 사용된다.
5. 만약 no-argument constructor가 있다면 그게 사용되고 나머지는 무시된다.

Value resolution은 생성자/팩토리 메서드의 argument names가 엔티티의 property names와 매칭된다는 것을 가정한다. 즉, resoltion은 mapping의 모든 customizations(다른 datastore column 혹은 필드 이름 등)을 포함하는 개념의 property가 채워지는 것처럼 수행된다. 또한, 이를 위해서는 클래스 파일에서 parameter names 정보들이 available 하거나 생성자에 `@ConstructorProperties` 애노테이션이 있어야 한다.

Value resolution은 Spring Framework의 `@Value` 값 어노테이션과 저장소별 SpEL 표현식을 사용하여 사용자 정의할 수 있다. 자세한 내용은 저장소별 매핑 섹션을 참조하자.

> ## Object creation internals
> 리플렉션 오버헤드를 피하기 위해 Spring Data object creation은 기본적으로 런타임에 생성되는 팩토리 클래스를 사용하며, 이 클래스는 도메인 클래스의 생성자를 직접 호출한다. 즉, 이 예제에서는 다음과 같이 입력한다.
> ```java
> class Person {
>   Person(String firstname, String lastname) { … }
> }
> ```
> 런타임에 이것과 의미적으로 동등한 팩토리 클래스를 생성될 것이다:
> ```java
> class PersonObjectInstantiator implements ObjectInstantiator {
>   Object newInstance(Object... args) {
>         return new Person((String) args[0], (String) args[1]);
>    }
> }
> ```
> 이렇게 하면 리플렉션보다 약 10%의 성능 향상을 얻을 수 있다. 도메인 클래스가 이러한 최적화를 적용하려면 다음과 같은 제약 조건을 준수해야 한다.
> - it must not be a private class
> - it must not be a non-static inner class
> - it must not be a CGLib proxy class
> - the constructor to be used by Spring Data must not be private  
> 
> 이 규칙들을 하나라도 만족하지 않으면 Spring Data는 엔티티 초기화를 리플렉션으로 수행하는 방식으로 fallback할 것이다.

## Property population
엔티티의 인스턴스가 생성되고 나면, Spring Data가 그 클래스의 남아있는 persistent property 들을 채운다. 엔티티의 생성자로부터 채워지지 않았다면(즉, constructor argument list를 통해 소모되지 않았다면), 순환 객체 참조의 확인을 허용하기 위해 식별자 속성이 먼저 채워진다. 그 후, 생성자에 의해 아직 채워지지 않은 모든 비일시적 속성이 엔터티 인스턴스에 설정된다. 이를 위해 우리는 다음의 알고리즘을 사용한다.

1. 속성이 변경 불가능하지만 `with…` 메서드를 노출하는 경우(아래 참조), `with…` 메서드를 사용하여 새 속성 값으로 새 엔터티 인스턴스를 생성한다.
2. Property access(즉, getter 및 setter를 통한 액세스)가 정의된 경우 setter 메서드를 호출한다.
3. 속성이 변경 가능한 경우 필드를 직접 set 한다.
4. 속성이 변경 불가능한 경우 persistence operations 에서 사용되는 생성자를 사용하여 인스턴스의 복사본을 생성합니다([Object creation](https://docs.spring.io/spring-data/mongodb/reference/mongodb/mapping/mapping.html#mapping.object-creation) 참조).
5. 기본적으로 필드 값을 직접 set 한다.

### Property Population 내부 구조
객체 생성에서의 최적화와 유사하게, 엔티티 인스턴스와 상호작용하기 위해 Spring Data 런타임 생성 접근자 클래스도 사용한다.
```java
class Person {
  private final Long id;
  private String firstname;
  private @AccessType(Type.PROPERTY) String lastname;

  Person() {
    this.id = null;
  }

  Person(Long id, String firstname, String lastname) {
    // 필드 할당
  }

  Person withId(Long id) {
    return new Person(id, this.firstname, this.lastname);
  }

  void setLastname(String lastname) {
    this.lastname = lastname;
  }
}
```

_생성된 Property Accessor_
```java
class PersonPropertyAccessor implements PersistentPropertyAccessor {
  private static final MethodHandle firstname;              // 1
  private Person person;                                    // 2

  public void setProperty(PersistentProperty property, Object value) {
    String name = property.getName();

    if ("firstname".equals(name)) {
      firstname.invoke(person, (String) value);             // 3
    } else if ("id".equals(name)) {
      this.person = person.withId((Long) value);            // 4
    } else if ("lastname".equals(name)) {
      this.person.setLastname((String) value);              // 5
    }
  }
}
```
1. PropertyAccessor는 underlying 객체의 가변 인스턴스를 보유한다. 이는 immutable properties의 변경을 가능하게 하기 위함이다. 
2. 기본적으로 Spring Data는 property values를 읽고 쓰기 위해 field-access을 사용한다. private 필드의 가시성 규칙에 따라 `MethodHandles`가 필드와 상호작용하는 데 사용된다. 
3. 클래스는 식별자를 설정하는 데 사용되는 `withId(…)` 메서드를 노출한다. 예를 들어, 인스턴스가 datastore에 삽입되고 식별자가 생성된 경우이다. `withId(…)`를 호출하면 새 `Person` 객체가 생성된다. 모든 후속 변경은 새 인스턴스에서 발생하며 이전 인스턴스는 그대로 남는다. 
4. 속성 접근을 사용하면 `MethodHandles`을 사용하지 않고 직접 메서드 호출이 가능하다.

이 방식은 리플렉션에 비해 약 25%의 성능 향상을 제공한다. 도메인 클래스가 이러한 최적화를 받을 수 있으려면 다음 제약 조건을 준수해야 한다:
- 타입은 기본 패키지나 `java` 패키지 아래에 있으면 안 된다.
- 타입과 그 생성자는 `public`이어야 한다.
- 내부 클래스의 타입은 `static`이어야 한다.
- 사용된 Java Runtime은 originating `ClassLoader`에서 클래스 선언을 허용해야 한다. Java 9 이상에서는 특정 제한이 있다.

기본적으로 Spring Data는 생성된 속성 접근자를 사용하려고 시도하고, 제한이 감지되면 리플렉션 기반 접근자로 되돌아간다.

다음 엔티티를 살펴보겠습니다:
```java
class Person {

  private final @Id Long id;                 // 1                               
  private final String firstname, lastname;      // 2                          
  private final LocalDate birthday;           
  private final int age;                      // 3                          

  private String comment;                     // 4                              
  private @AccessType(Type.PROPERTY) String remarks;  // 5                        

  static Person of(String firstname, String lastname, LocalDate birthday) { // 6 

    return new Person(null, firstname, lastname, birthday,
      Period.between(birthday, LocalDate.now()).getYears());
  }

  Person(Long id, String firstname, String lastname, LocalDate birthday, int age) {  // 6

    this.id = id;
    this.firstname = firstname;
    this.lastname = lastname;
    this.birthday = birthday;
    this.age = age;
  }

  Person withId(Long id) {                                                 // 1
    return new Person(id, this.firstname, this.lastname, this.birthday, this.age);
  }

  void setRemarks(String remarks) {                                        // 5
    this.remarks = remarks;
  }
}
```
1. **식별자 속성은 final이지만 생성자에서 `null`로 설정된다.** 클래스는 식별자를 설정하는 데 사용되는 `withId(…)` 메서드를 노출한다. 예를 들어, 인스턴스가 데이터스토어에 삽입되고 식별자가 생성된 경우이다. Original `Person` 인스턴스는 변경되지 않고 새로운 인스턴스가 생성된다. 일반적으로 동일한 패턴이 저장소에서 관리되는 다른 properties에 적용되지만 persistence operations를 위해 변경해야 할 수 있는 다른 properties 에도 적용된다. wither 메서드는 선택적이다. Persistence constructor(6번 참조)가 효과적인 copy constructor이면서 효과적인 속성 설정을 하는 것이 새 식별자 값이 적용된 fresh한 instance를 생성하는 것으로 변환되기 때문이다.
2. **`firstname` 및 `lastname` 속성은 getter를 통해 잠재적으로 노출되는 일반적인 불변 속성이다.**
3. **`age` 속성은 `birthday` 속성에서 파생된 불변이지만 계산된 속성이다.** 살펴봐온 설계에서 Spring Data가 선언된 유일한 생성자를 사용하므로 데이터베이스 값이 기본값보다 우선된다. 계산이 선호되는 것이 의도라 하더라도, 이 생성자가 age를 매개변수로 받는 것이 중요하다(잠재적으로 무시하기 위해). 그렇지 않으면 속성 채우기 단계에서 age 필드를 설정하려고 시도하다가 불변이고 `with…` 메서드가 없어서 실패하게 된다.
4. **`comment` 속성은 가변이며 필드를 직접 설정하여 채워진다.**
5. **`remarks` 속성은 가변이며 setter 메서드를 호출하여 채워진다.**
6. **클래스는 객체 생성을 위한 팩토리 메서드와 생성자를 노출한다.** 여기서 핵심 아이디어는 `@PersistenceCreator`를 통한 생성자 명확화의 필요성을 피하기 위해 추가 생성자 대신 팩토리 메서드를 사용하는 것이다. 대신 속성의 기본값 설정은 팩토리 메서드 내에서 처리됩니다. Spring Data가 객체 인스턴스화를 위해 팩토리 메서드를 사용하도록 하려면 `@PersistenceCreator`로 어노테이션을 추가하면 된다.


## General Recommendations
- _불변 객체를 고수하려고 노력하라_  — 불변 객체는 객체를 구체화하는 것이 생성자만 호출하면 되므로 생성하기가 간단하다. 또한, 이렇게 하면 클라이언트 코드가 객체 상태를 조작할 수 있도록 하는 세터 메서드가 도메인 객체에 잔뜩 쌓이는 것을 방지할 수 있다. 이러한 세터 메서드가 필요한 경우, 제한된 수의 같은 위치에 있는 타입에서만 호출할 수 있도록 패키지 보호 기능을 제공하는 것이 좋다. 생성자 전용 구체화는 속성 채우기보다 최대 30% 더 빠르다.
- _all-args constructor를 제공하라_  — 엔티티를 변경 불가능한 값으로 모델링할 수 없거나 모델링하고 싶지 않더라도 변경 가능한 속성을 포함하여 엔터티의 모든 속성을 인수로 사용하는 생성자를 제공하는 건 여전히 가치가 있다. 왜냐하면, 그렇게 하면 object mapping이 property population를 건너뛰도록 하는게 허용되기 때문이다.
- _`@PersistenceCreator`의 필요성을 피하기 위해 생성자를 오버로드하지 말고 팩토리 메서드를 사용하라_  — 최적의 성능을 위해서는 모든 인수를 갖는 생성자가 필요하기 때문에 auto-generated identifiers, 등등을 생략하는 특정 생성자를 애플리케이션에 노출할 필요가 있다. 이러한 all-args constructor의 variants를 노출하는 것 대신 static factory methods를 사용하는 것이 established pattern 이다.
- _생성된 instantiator와 property access classes가 사용될 수 있게 하는 제약을 준수하라_  — 
- _Identifiers를 생성할 때 combination안에서 여전히 final 필드로 유지하고, all-args persistence constructor가 파라미터로 갖게 하던가 `with...` 메서드를 더 선호한다면 그걸 만들어라_
- _보일러플레이트 코드를 줄이기 위해 Lombok을 사용하라_  — Persistence operations는 일반적으로 모든 인수를 취하는 생성자가 필요하므로, 해당 선언은 필드 할당에 대한 보일러플레이트 매개변수의 지루한 반복으로 이어지는데, 이는 Lombok의 @AllArgsConstructor를 사용하면 가장 잘 방지할 수 있습니다.


### Overrriding Properties
Java는 하위 클래스가 상위 클래스에 이미 동일한 이름으로 선언된 속성을 정의할 수 있도록 도메인 클래스를 유연하게 설계할 수 있도록 한다. 다음 예를 살펴보겠다.
```java
public class SuperType {

   private CharSequence field;

   public SuperType(CharSequence field) {
      this.field = field;
   }

   public CharSequence getField() {
      return this.field;
   }

   public void setField(CharSequence field) {
      this.field = field;
   }
}

public class SubType extends SuperType {

   private String field;

   public SubType(String field) {
      super(field);
      this.field = field;
   }

   @Override
   public String getField() {
      return this.field;
   }

   public void setField(String field) {
      this.field = field;

      // optional
      super.setField(field);
   }
}
```
두 클래스 모두 할당 가능한 타입을 사용하여 `field`를 정의한다. 하지만 `SubType`은 `SuperType.field`를 가린다. 클래스 설계에 따라 생성자를 사용하는 것이 `SuperType.field`를 설정하는 유일한 기본 방법일 수 있다. 또는 setter에서 `super.setField(…)`를 호출하여 `SuperType`의 `field`를 설정할 수 있다. 이러한 모든 메커니즘은 속성이 이름은 같지만 서로 다른 두 값을 나타낼 수 있기 때문에 어느 정도 충돌을 일으킨다. Spring Data는 타입을 할당할 수 없는 경우 상위 타입 속성을 건너뛴다. 즉, 오버라이드된 속성의 타입은 오버라이드로 등록되려면 상위 타입 속성 타입에 할당 가능해야 한다. 그렇지 않으면 상위 타입 속성은 일시적인 것으로 간주된다. 일반적으로 서로 다른 속성 이름을 사용하는 것이 좋다.

Spring Data 모듈은 일반적으로 서로 다른 값을 갖는 오버라이드된 속성을 지원한다. 프로그래밍 모델 관점에서는 다음과 같은 몇 가지 사항을 고려해야 한다:
1. 어떤 속성을 유지해야 할까? (선언된 모든 속성이 기본값) `@Transient` 어노테이션을 사용하여 속성을 제외할 수 있다.
2. 데이터 저장소에서 속성을 어떻게 표현해야 할까? 서로 다른 값에 동일한 필드/열 이름을 사용하면 일반적으로 데이터가 손상될 수 있으므로, 적어도 하나의 속성에는 명시적인 필드/열 이름을 사용하여 주석을 추가해야 한다.
3. `@AccessType(PROPERTY)`를 사용하면 세터 구현에 대한 추가적인 가정 없이는 일반적으로 슈퍼 속성을 설정할 수 없으므로 사용할 수 없습니다.

# Convention-based Mapping
`MappingMongoConverter`는 추가 매핑 메타데이터가 제공되지 않을 때 객체를 문서에 매핑하기 위한 몇 가지 규칙을 가지고 있다. 규칙은 다음과 같다.
- 짧은 Java 클래스 이름은 다음과 같은 방식으로 컬렉션 이름에 매핑된다. 클래스 `com.bigbank.SavingsAccount`는 컬렉션 이름 `savingsAccount`에 매핑된다.
- 모든 중첩된 객체들은 DBRefs가 아닌 문서에 중첩된 객체로 저장된다.
- Converter는 등록된 모든 Spring Converters를 사용하여 객체 속성의 기본 매핑을 문서 필드 및 값에 오버라이드한다.
- 객체의 필드는 문서의 필드와 데이터를 변환하는 데 사용된다. 공개 `JavaBean` 속성은 사용되지 않는다.
- 문서의 최상위 필드 이름과 생성자 인수 이름이 일치하는 'non-zero argument constructor'가 하나뿐인 경우 해당 생성자가 사용된다. 그렇지 않은 경우 인수가 없는 생성자가 사용된다. 'non-zero argument constructor'가 두 개 이상인 경우 예외가 발생한다.

## How the _id field is handled in the mapping layer
MongoDB는 모든 문서에 대해 `_id` 필드를 요구한다. 만약 이 필드를 제공하지 않으면 드라이버가 생성된 값을 갖는 ObjectId를 할당할 것이다. `_id` 필드는 고유해야 하며, 배열을 제외한 모든 유형이 될 수 있다. 드라이버는 기본적으로 모든 기본 유형과 날짜를 지원합니다. `MappingMongoConverter`를 사용할 때 Java 클래스의 속성이 `_id` 필드에 매핑되는 방식을 제어하는 특정 규칙이 있다.

다음은 `_id` 문서 필드에 매핑될 필드를 간략하게 설명한다:
- `@Id` 어노테이션이 지정된 필드(`org.springframework.data.annotation.Id`)는 `_id` 필드에 매핑된다.  
  또한, `@Field` 어노테이션을 통해 문서 필드의 이름을 사용자 지정할 수 있으며, 이 경우 문서에는 `_id` 필드가 포함되지 않는다.
- 주석은 없지만 이름이 `id`인 필드는 `_id` 필드에 매핑된다.

<br>

_Table 1. Examples for the translation of `_id` field definitions_

| Field definition         | Resulting Id-Fieldname in MongoDB                   |
|--------------------------|-----------------------------------------------------|
| String id                | _id                                                 |
| @Field String id         | _id                                                 |
| @Field("x") String id    | x                                                   |
| @Id String x             | _id                                                 |
| @Field("x") @Id String y | _id (@Field(name) is ignored, @Id takes precedence) |

다음은 _id 문서 필드에 매핑된 속성에 대해 어떤 유형 변환이 수행되는지에 대한 개요이다.

- Java 클래스에서 `id`라는 필드가 문자열 또는 BigInteger로 선언된 경우, 가능한 경우 ObjectId로 변환되어 저장된다. 필드 유형으로 ObjectId를 사용하는 것도 유효하다. 애플리케이션에서 `id` 값을 지정하면 MongoDB 드라이버가 ObjectId로 변환한다. 지정된 `id` 값을 ObjectId로 변환할 수 없는 경우, 해당 값은 문서의 `_id` 필드에 그대로 저장됩니다. 이는 필드에 `@Id` 주석이 있는 경우에도 적용된다.
- Java 클래스에서 필드에 `@MongoId` 어노테이션이 지정되면 해당 필드는 실제 유형을 사용하여 변환되어 저장된다. `@MongoId`가 원하는 필드 유형을 선언하지 않는 한 추가 변환은 발생하지 않는다. `id` 필드에 값을 지정하지 않으면 새로운 `ObjectId`가 생성되어 속성 유형으로 변환된다.
- Java 클래스에서 필드에 `@MongoId(FieldType.…)` 어노테이션이 지정되면 해당 값을 선언된 `FieldType`으로 변환한다. `id` 필드에 값이 지정되지 않으면 새로운 `ObjectId`가 생성되어 선언된 타입으로 변환된다.
- Java 클래스에서 `id`라는 필드가 String, BigInteger 또는 ObjectID로 선언되지 않은 경우, 애플리케이션에서 해당 필드에 값을 할당하여 문서의 `_id` 필드에 '있는 그대로' 저장되도록 해야 한다.
- Java 클래스에 `id`라는 필드가 없으면 드라이버에서 암시적 `_id` 파일이 생성되지만 Java 클래스의 속성이나 필드에 매핑되지 않는다.

쿼리하고 업데이트할 때, `MongoTemplate`는 위의 documents saving rules에 따라 `Query` 및 `Update` 객체들을 converter를 사용해서 변환하므로 쿼리에서 사용되는 필드 이름과 유형이 도메인 클래스에 있는 내용과 같을 수 있다.

# Data Mapping and Type Conversion
Spring Data MongoDB는 MongoDB의 내부 문서 형식인 BSON으로 표현 가능한 모든 타입을 지원한다. 이러한 타입 외에도 Spring Data MongoDB는 추가 타입을 매핑하는 내장 변환기 세트를 제공한다. 사용자가 직접 변환기를 제공하여 타입 변환을 조정할 수도 있다.

다음은 요청하신 텍스트를 표로 변환한 것이다:

<br>

_Table 2. Built in Type conversions: Type_


| Type                                                     | Type conversion                 | Sample                                                                                                                                                                                    |
|----------------------------------------------------------|---------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| String                                                   | native                          | {"firstname" : "Dave"}                                                                                                                                                                    |
| double, Double, float, Float                             | native                          | {"weight" : 42.5}                                                                                                                                                                         |
| int, Integer, short, Short                               | native 32-bit integer           | {"height" : 42}                                                                                                                                                                           |
| long, Long                                               | native 64-bit integer           | {"height" : 42}                                                                                                                                                                           |
| Date, Timestamp                                          | native                          | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| byte[]                                                   | native                          | {"bin" : { "binary" : "AQIDBA==", "type" : "00" }}                                                                                                                                        |
| java.util.UUID (Legacy UUID)                             | native                          | {"uuid" : { "binary" : "MEaf1CFQ6lSphaa3b9AtlA==", "type" : "03" }}                                                                                                                       |
| Date                                                     | native                          | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| ObjectId                                                 | native                          | {"_id" : ObjectId("5707a2690364aba3136ab870")}                                                                                                                                            |
| Array, List, BasicDBList                                 | native                          | {"cookies" : [ … ]}                                                                                                                                                                       |
| boolean, Boolean                                         | native                          | {"active" : true}                                                                                                                                                                         |
| null                                                     | native                          | {"value" : null}                                                                                                                                                                          |
| Document                                                 | native                          | {"value" : { … }}                                                                                                                                                                         |
| Decimal128                                               | native                          | {"value" : NumberDecimal(…)}                                                                                                                                                              |
| AtomicInteger calling get() before the actual conversion | converter 32-bit integer        | {"value" : "741" }                                                                                                                                                                        |
| AtomicLong calling get() before the actual conversion    | converter 64-bit integer        | {"value" : "741" }                                                                                                                                                                        |
| BigInteger                                               | converter NumberDecimal, String | {"value" : NumberDecimal(741) }, {"value" : "741" }                                                                                                                                       |
| BigDecimal                                               | converter NumberDecimal, String | {"value" : NumberDecimal(741.99) }, {"value" : "741.99" }                                                                                                                                 |
| URL                                                      | converter                       | {"website" : "[https://spring.io/projects/spring-data-mongodb/](https://spring.io/projects/spring-data-mongodb/)" }                                                                       |
| Locale                                                   | converter                       | {"locale : "en_US" }                                                                                                                                                                      |
| char, Character                                          | converter                       | {"char" : "a" }                                                                                                                                                                           |
| NamedMongoScript                                         | converter Code                  | {"_id" : "script name", value: (some javascript code)}                                                                                                                                    |
| java.util.Currency                                       | converter                       | {"currencyCode" : "EUR"}                                                                                                                                                                  |
| Instant (Java 8)                                         | native                          | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| Instant (Joda, JSR310-BackPort)                          | converter                       | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| LocalDate (Joda, Java 8, JSR310-BackPort)                | converter / native (Java8)[1]   | {"date" : ISODate("2019-11-12T00:00:00.000Z")}                                                                                                                                            |
| LocalDateTime, LocalTime (Joda, Java 8, JSR310-BackPort) | converter / native (Java8)[2]   | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| DateTime (Joda)                                          | converter                       | {"date" : ISODate("2019-11-12T23:00:00.809Z")}                                                                                                                                            |
| ZoneId (Java 8, JSR310-BackPort)                         | converter                       | {"zoneId" : "ECT - Europe/Paris"}                                                                                                                                                         |
| Box                                                      | converter                       | {"box" : { "first" : { "x" : 1.0 , "y" : 2.0} , "second" : { "x" : 3.0 , "y" : 4.0}}                                                                                                      |
| Polygon                                                  | converter                       | {"polygon" : { "points" : [ { "x" : 1.0 , "y" : 2.0} , { "x" : 3.0 , "y" : 4.0} , { "x" : 4.0 , "y" : 5.0}]}}                                                                             |
| Circle                                                   | converter                       | {"circle" : { "center" : { "x" : 1.0 , "y" : 2.0} , "radius" : 3.0 , "metric" : "NEUTRAL"}}                                                                                               |
| Point                                                    | converter                       | {"point" : { "x" : 1.0 , "y" : 2.0}}                                                                                                                                                      |
| GeoJsonPoint                                             | converter                       | {"point" : { "type" : "Point" , "coordinates" : [3.0 , 4.0] }}                                                                                                                            |
| GeoJsonMultiPoint                                        | converter                       | {"geoJsonLineString" : {"type":"MultiPoint", "coordinates": [ [ 0 , 0 ], [ 0 , 1 ], [ 1 , 1 ] ] }}                                                                                        |
| Sphere                                                   | converter                       | {"sphere" : { "center" : { "x" : 1.0 , "y" : 2.0} , "radius" : 3.0 , "metric" : "NEUTRAL"}}                                                                                               |
| GeoJsonPolygon                                           | converter                       | {"polygon" : { "type" : "Polygon", "coordinates" : [[ [ 0 , 0 ], [ 3 , 6 ], [ 6 , 1 ], [ 0 , 0 ] ]] }}                                                                                    |
| GeoJsonMultiPolygon                                      | converter                       | {"geoJsonMultiPolygon" : { "type" : "MultiPolygon", "coordinates" : [ [ [ [ -73.958 , 40.8003 ] , [ -73.9498 , 40.7968 ] ] ], [ [ [ -73.973 , 40.7648 ] , [ -73.9588 , 40.8003 ] ] ] ] }} |
| GeoJsonLineString                                        | converter                       | { "geoJsonLineString" : { "type" : "LineString", "coordinates" : [ [ 40 , 5 ], [ 41 , 6 ] ] }}                                                                                            |
| GeoJsonMultiLineString                                   | converter                       | {"geoJsonLineString" : { "type" : "MultiLineString", coordinates: [ [ [ -73.97162 , 40.78205 ], [ -73.96374 , 40.77715 ] ], [ [ -73.97880 , 40.77247 ], [ -73.97036 , 40.76811 ] ] ] }}   |

> _Note_  
> 
> Collection handling은 MongoDB에서 반환되는 실제 값에 따라 달라진다.
> - 문서가 컬렉션에 매핑된 필드를 포함하지 않는 경우, 매핑은 해당 속성을 업데이트하지 않는다. 즉, 값은 `null`, Java 기본값 또는 객체 생성 중에 설정된 값으로 유지된다.
> - 문서가 매핑될 필드를 포함하지만 해당 필드가 `null` 값을 가지고 있는 경우 (`{ 'list' : null }`와 같은), 속성 값은 `null`로 설정된다.
> - 문서가 컬렉션에 매핑될 필드를 포함하고 그 값이 null이 아닌 경우 ({ 'list' : [ …​ ] }와 같은), 컬렉션은 매핑된 값들로 채워진다.
>
> 일반적으로 생성자 생성을 사용하는 경우, 설정될 값을 가져올 수 있다. 속성 채우기는 쿼리 응답에서 속성 값이 제공되지 않는 경우 기본 초기화 값을 사용할 수 있다.

# Mapping Configuration
명시적으로 구성하지 않는 한, MongoTemplate을 생성할 때 기본적으로 `MappingMongoConverter`의 인스턴스가 생성된다. 물론 `MappingMongoConverter`의 자체 인스턴스를 생성할 수 있다. 이렇게 하면 classpath 에서 domain class를 찾을 위치를 지정할 수 있어서, Spring Data MongoDB가 메타데이터를 추출하고 인덱스를 구성할 수 있다. 또한 자체 인스턴스를 생성함으로써 특정 클래스를 데이터베이스에서 매핑하기 위한 Spring converters를 등록할 수 있다.

그리고 Java 기반 또는 XML 기반 메타데이터를 사용하여 `MappingMongoConverter`뿐만 아니라 `com.mongodb.client.MongoClient` 및 MongoTemplate을 구성할 수 있습니다. 다음 예제는 그 configuration을 보여준다:

```java
@Configuration
public class MongoConfig extends AbstractMongoClientConfiguration {

  @Override
  public String getDatabaseName() {
    return "database";
  }

  // the following are optional

  @Override
  public String getMappingBasePackage() { // 1
    return "com.bigbank.domain";
  }

  @Override
  void configureConverters(MongoConverterConfigurationAdapter adapter) { // 2
      
  	adapter.registerConverter(new org.springframework.data.mongodb.test.PersonReadConverter());
  	adapter.registerConverter(new org.springframework.data.mongodb.test.PersonWriteConverter());
  }

  @Bean
  public LoggingEventListener<MongoMappingEvent> mappingEventsListener() {
    return new LoggingEventListener<MongoMappingEvent>();
  }
}
```

1. 매핑 기반 패키지는 `MappingContext`를 사전 초기화하는 데 사용되는 엔티티를 스캔하는 데 사용되는 루트 경로를 정의한다. 기본적으로 구성 클래스 패키지가 사용된다.
2. 특정 도메인 유형에 대한 기본 매핑 절차를 사용자 정의 구현으로 대체하는 추가 사용자 정의 변환기를 구성한다.

`AbstractMongoClientConfiguration`은 `com.mongodb.client.MongoClient`를 정의하는 메서드와 데이터베이스 이름을 제공하는 메서드를 구현하도록 요구한다. `AbstractMongoClientConfiguration`에는 또한 `getMappingBasePackage(…)`라는 메서드가 있어서, 이를 재정의하여 컨버터에게 `@Document` 어노테이션이 붙은 클래스를 스캔할 위치를 알려줄 수 있다.

> _Tip_
> 
> _Java Time Types_
> `customConversionsConfiguration` 메서드를 재정의하여 컨버터에 추가 컨버터를 추가할 수 있다. MongoDB의 네이티브 JSR-310 지원은 `MongoConverterConfigurationAdapter.useNativeDriverJavaTimeCodecs()`를 통해 활성화할 수 있다. 앞의 예제에서 보여진 것은 `LoggingEventListener`인데, 이는 Spring의 `ApplicationContextEvent` 인프라스트럭처에 게시되는 `MongoMappingEvent` 인스턴스를 로깅한다.

> _Note_
> 
> `AbstractMongoClientConfiguration`은 `MongoTemplate` 인스턴스를 생성하고 이를 `mongoTemplate`이라는 이름으로 컨테이너에 등록한다.

`base-package` 속성은 `@org.springframework.data.mongodb.core.mapping.Document` 주석으로 주석 처리된 클래스를 스캔할 위치를 알려준다.

> _Tip_
> 
> [Spring Boot](https://spring.io/projects/spring-boot)를 사용하여 Data MongoDB를 부트스트랩하면서도 구성의 특정 측면을 재정의하고 싶다면, 해당 타입의 빈을 노출하는 것이 좋다. 예를 들어, 커스텀 변환의 경우 Boot 인프라스트럭처에서 선택될 `MongoCustomConversions` 타입의 빈을 등록하는 것을 선택할 수 있습니다. 이에 대해 더 자세히 알아보려면 [Spring Boot 참조 문서](https://docs.spring.io/spring-boot/reference/data/nosql.html#data.nosql.mongodb)를 읽어보시기 바랍니다.

# Metadata-based Mapping
Spring Data MongoDB 지원 내의 객체 매핑 기능을 최대한 활용하려면, 매핑된 객체에 `@Document` 어노테이션을 붙여야 한다. 매핑 프레임워크가 이 어노테이션을 반드시 필요로 하는 것은 아니지만(POJO는 어노테이션 없이도 올바르게 매핑된다), classpath scanner가 도메인 객체를 찾고 사전 처리하여 필요한 메타데이터를 추출할 수 있게 해준다. 이 어노테이션을 사용하지 않으면, 매핑 프레임워크가 도메인 객체의 속성과 이를 지속하는 방법에 대해 알기 위해 내부 메타데이터 모델을 구축해야 하므로, 도메인 객체를 처음 저장할 때 애플리케이션에서 약간의 성능 저하가 발생한다. 다음 예제는 도메인 객체를 보여준다:

```java
package com.mycompany.domain;

@Document
public class Person {

  @Id
  private ObjectId id;

  @Indexed
  private Integer ssn;

  private String firstName;

  @Indexed
  private String lastName;
}
```

> _Important_
> 
> The `@Id` annotation tells the mapper which property you want to use for the MongoDB `_id` property, and the `@Indexed` annotation tells the mapping framework to call `createIndex(…)` on that property of your document, making searches faster. Automatic index creation is only done for types annotated with `@Document`.

> _Warning_
> 
> Auto index creation is disabled by default and needs to be enabled through the configuration (see [Index Creation](https://docs.spring.io/spring-data/mongodb/reference/mongodb/mapping/mapping.html#mapping.index-creation)).

## Mapping Annotation Overview
MappingMongoConverter는 메타데이터를 사용하여 객체를 문서에 매핑할 수 있다. 다음과 같은 애노테이션을 사용할 수 있다.

- `@Id`: 필드 레벨에 적용되어 식별 목적으로 사용되는 필드임을 표시한다.
- `@MongoId`: 필드 레벨에 적용되어 식별 목적으로 사용되는 필드임을 표시한다. ID 변환을 커스터마이징하기 위한 선택적 `FieldType`을 허용한다.
- `@Document`: 클래스 레벨에 적용되어 이 클래스가 database mapping을 위한 후보임을 나타낸다. 데이터가 저장될 컬렉션의 이름을 지정할 수 있다.
- `@DBRef`: 필드에 적용되어 com.mongodb.DBRef를 사용하여 저장됨을 나타낸다.
- `@DocumentReference`: 필드에 적용되어 다른 문서에 대한 포인터로 저장됨을 나타낸다. 이는 단일 값(기본적으로 ID) 또는 컨버터를 통해 제공되는 Document일 수 있다.
- `@Indexed`: 필드 레벨에 적용되어 필드를 어떻게 인덱싱을 할 건지를 서술한다.
- `@CompoundIndex` (반복 가능): 타입 레벨에 적용되어 Compound Indexes 임을 선언한다.
- `@GeoSpatialIndexed`: 필드 레벨에 적용되어 필드를 어떻게 geoindex 할 건지 서술한다.
- `@TextIndexed`: 필드 레벨에 적용되어 text index에 포함될 필드임을 표시합니다.
- `@HashIndexed`: sharded cluster에서 데이터를 분할하기 위한 해시 인덱스 내에서 사용하기 위해 필드 레벨에 적용된다.
- `@Language`: text index의 language 속성을 설정하기 위해 필드 레벨에 적용된다.
- `@Transient`: 기본적으로 모든 필드는 document에 매핑된다. 이 어노테이션은 적용된 필드가 데이터베이스에 저장되지 않도록 제외한다. 컨버터가 생성자 인수에 대한 값을 구체화할 수 없게 되기 때문에 transient properties는 persistence constructor 내에서 사용할 수 없다.
- `@PersistenceConstructor`: 데이터베이스에서 객체를 인스턴스화할 때 사용할 생성자(패키지 보호 생성자도 포함)라고 표시한다. 생성자 인수는 검색된 Document의 키 값의 이름으로 매핑된다.
- `@Value`: 이 어노테이션은 Spring Framework의 일부이다. 매핑 프레임워크 내에서 생성자 인수에 적용할 수 있다. 이를 통해 도메인 객체를 구성하는 데 사용되기 전에 데이터베이스에서 검색된 키의 값을 변환하는 Spring Expression Language 문을 사용할 수 있다. 주어진 문서의 속성을 참조하려면 다음과 같은 표현식을 사용해야 한다: `@Value("#root.myProperty")` 여기서 `root`는 주어진 문서의 루트를 참조한다.
- `@Field`: 필드 레벨에 적용되어 MongoDB BSON 문서에서 표현될 때의 필드 이름과 타입을 설명할 수 있게 하므로, 클래스의 필드명 및 속성 타입과 다른 이름과 타입을 가질 수 있다.
- `@Version`: 필드 레벨에 적용되어 낙관적 잠금에 사용되며 저장 연산 시 수정 여부를 확인한다. 초기값은 0(기본 타입의 경우 1)이며 매 업데이트마다 자동으로 증가한다.

매핑 메타데이터 인프라스트럭처는 기술에 구애받지 않는 별도의 spring-data-commons 프로젝트에서 정의된다. 특정 하위 클래스들이 MongoDB 지원에서 어노테이션 기반 메타데이터를 지원하기 위해 사용된다. 원한다면 다른 전략들도 구현 가능하다.

```java
@Document
@CompoundIndex(name = "age_idx", def = "{'lastName': 1, 'age': -1}")
public class Person<T extends Address> {

  @Id
  private String id;

  @Indexed(unique = true)
  private Integer ssn;

  @Field("fName")
  private String firstName;

  @Indexed
  private String lastName;

  private Integer age;

  @Transient
  private Integer accountTotal;

  @DBRef
  private List<Account> accounts;

  private T address;

  public Person(Integer ssn) {
    this.ssn = ssn;
  }

  @PersistenceConstructor
  public Person(Integer ssn, String firstName, String lastName, Integer age, T address) {
    this.ssn = ssn;
    this.firstName = firstName;
    this.lastName = lastName;
    this.age = age;
    this.address = address;
  }

  public String getId() {
    return id;
  }

  // no setter for Id.  (getter is only exposed for some unit testing)

  public Integer getSsn() {
    return ssn;
  }

// other getters/setters omitted
}
```

> _Tip_
> 
> `@Field(targetType=…​)`는 매핑 인프라에서 추론된 MongoDB 네이티브 타입이 예상 타입과 일치하지 않을 때 유용하게 사용할 수 있다. 예를 들어, 이전 버전의 MongoDB 서버에서는 `BigDecimal`을 지원하지 않았기 때문에 `Decimal128` 대신 `String`으로 표현되는 경우와 같다.
> ```java
> public class Balance {
>
>   @Field(targetType = DECIMAL128)
>   private BigDecimal value;
>
>   // ...
> }
> ```
> 
> `@Field(targetType=…​)`을 활용한 custom annotation을 사용하는 것도 고려할 사항이다.
> ```java
> @Target(ElementType.FIELD)
> @Retention(RetentionPolicy.RUNTIME)
> @Field(targetType = FieldType.DECIMAL128)
> public @interface Decimal128 { }
> 
> // ...
> 
> public class Balance {
> 
>   @Decimal128
>   private BigDecimal value;
> 
>   // ...
> }
> ```

##