# DynamoDB의 AttributeValue 이해하기

`AttributeValue`는 **DynamoDB 속성 하나의 값과 타입을 표현하는 AWS SDK 객체**다. 문자열, 숫자, 불리언뿐 아니라 중첩된 Map과 List도 표현할 수 있다.

이 문서는 AWS SDK for Java 2.x를 Kotlin에서 사용하는 경우를 설명한다. 아래 예제는 저장할 데이터를 구성하는 코드이며, 그 자체로 AWS에 연결하거나 데이터를 저장하지 않는다.

```kotlin
import software.amazon.awssdk.services.dynamodb.model.AttributeValue
```

다른 AWS 서비스에도 같은 이름의 클래스가 있으므로 import의 `services.dynamodb`를 확인해야 한다. [DynamoDB AttributeValue SDK 문서](https://docs.aws.amazon.com/java/api/latest/software/amazon/awssdk/services/dynamodb/model/AttributeValue.html)

## 1. 테이블·항목·속성의 관계

DynamoDB는 AWS가 제공하는 NoSQL 데이터베이스다. 데이터를 담는 단위는 다음처럼 구분한다.

- **테이블(table)**: 관련 데이터를 모아 두는 공간.
- **항목(item)**: 하나의 레코드. 예를 들어 사용자 한 명의 정보.
- **속성(attribute)**: 항목을 구성하는 이름과 값. 예를 들어 `name`, `age`.

사용자 항목 하나를 개념적으로 표현하면 다음과 같다.

```text
사용자 항목
 ├─ id: "user-123"      (문자열)
 ├─ name: "민수"        (문자열)
 └─ age: 30             (숫자)
```

Java SDK의 저수준 API에서는 항목 전체를 `Map<String, AttributeValue>`로 표현한다. Map의 키는 속성 이름이고, 값은 해당 속성의 타입과 데이터를 담는 `AttributeValue`다.

```kotlin
val item: Map<String, AttributeValue> = mapOf(
    "id" to AttributeValue.fromS("user-123"),
    "name" to AttributeValue.fromS("민수"),
    "age" to AttributeValue.fromN("30"),
)
```

여기서 `"age"`라는 이름은 바깥 Map에 있다. `AttributeValue.fromN("30")` 자체에는 속성 이름이 들어 있지 않다.

## 2. 타입별 값 만들기

`fromS`, `fromN`, `fromM` 등의 팩터리 메서드는 어떤 DynamoDB 타입으로 표현할지 지정한다. 한 속성값에는 하나의 타입을 선택한다.

| 코드 | DynamoDB 타입 | 의미 |
| --- | --- | --- |
| `AttributeValue.fromS("hello")` | S — String | 문자열 |
| `AttributeValue.fromN("30")` | N — Number | 숫자 |
| `AttributeValue.fromBool(true)` | BOOL — Boolean | 참·거짓 |
| `AttributeValue.fromNul(true)` | NULL | 명시적인 null 값 |
| `AttributeValue.fromM(mapOf(...))` | M — Map | 이름과 값으로 구성된 중첩 데이터 |
| `AttributeValue.fromL(listOf(...))` | L — List | 순서가 있는 값 목록 |

이 밖에도 바이너리와 문자열·숫자·바이너리 집합 타입이 있다. 집합은 목록과 달리 중복 원소를 허용하지 않으며 순서를 보장하지 않는다. [DynamoDB 데이터 타입 문서](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html)

### 숫자인데 왜 문자열을 전달할까?

```kotlin
val number = AttributeValue.fromN("30")
val text = AttributeValue.fromS("30")
```

두 값은 다르다. 첫 번째는 숫자 30, 두 번째는 문자열 "30"이다.

DynamoDB API는 숫자 값을 문자열 형태로 전달하지만, `N`으로 지정된 값은 데이터베이스에서 숫자로 취급한다. `fromN()`의 문자열 인수는 숫자의 표현 방식이며 문자열 타입으로 저장하라는 뜻이 아니다. 따라서 임의의 문자열을 넣어도 된다는 의미도 아니다. [AttributeValue API 문서](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_AttributeValue.html)

## 3. 중첩 Map과 항목 전체의 차이

사용자 항목에 주소 정보를 추가한다고 가정하자.

```kotlin
val addressFields: Map<String, AttributeValue> = mapOf(
    "city" to AttributeValue.fromS("서울"),
    "postalCode" to AttributeValue.fromS("01234"),
)

val address: AttributeValue = AttributeValue.fromM(addressFields)

val user: Map<String, AttributeValue> = mapOf(
    "id" to AttributeValue.fromS("user-123"),
    "address" to address,
)
```

`addressFields`는 주소 속성들의 맵이다. 이를 `fromM()`으로 감싸면 사용자 항목의 `address` 속성에 넣을 수 있는 **하나의 Map 타입 속성값**이 된다.

```text
user: Map<String, AttributeValue>           ← 항목 전체
 ├─ "id" → AttributeValue(S)
 └─ "address" → AttributeValue(M)          ← 중첩 Map 속성값
                  ├─ "city" → AttributeValue(S)
                  └─ "postalCode" → AttributeValue(S)
```

따라서 `Map<String, AttributeValue>`와 Map 타입의 `AttributeValue`는 관련되어 있지만 서로 다른 타입이다. 중첩 데이터를 상위 항목의 속성값으로 넣을 때 `fromM()`이 그 경계를 연결한다.

## 4. 저장된 값 읽기

값을 꺼낼 때는 저장한 타입에 맞는 접근자를 사용한다.

```kotlin
val nameValue = AttributeValue.fromS("민수")
val ageValue = AttributeValue.fromN("30")

val name: String = nameValue.s()
val age: Int = ageValue.n().toInt()
val city: String = address.m().getValue("city").s()
```

이 예제는 위에서 만든 값의 타입을 이미 알고 있다는 가정이다. 실제 저장소에서 읽은 데이터는 속성 누락, 다른 타입, 잘못된 숫자 범위 등을 검사해야 한다. `n()`이 숫자 객체로 자동 변환해 주지는 않으며, `toInt()` 같은 변환도 실패할 수 있다.

Map·List 접근자는 값이 설정되지 않아도 빈 컬렉션을 반환할 수 있다. 따라서 `m()`의 null 여부만으로 Map 속성의 존재를 판단하지 않는다. 필요하면 `hasM()`처럼 SDK가 제공하는 존재 확인 메서드를 사용한다. SDK가 반환하는 컬렉션은 수정할 수 없으므로 변경된 값은 새로 구성한다. [SDK 접근자 문서](https://docs.aws.amazon.com/java/api/latest/software/amazon/awssdk/services/dynamodb/model/AttributeValue.html)

## 5. 속성 생략과 명시적인 null

다음 두 항목은 의미가 다르다.

```kotlin
// nickname 속성 자체가 없음
val omitted = mapOf("id" to AttributeValue.fromS("user-123"))

// nickname 속성이 있고 값의 타입이 NULL임
val explicitNull = mapOf(
    "id" to AttributeValue.fromS("user-123"),
    "nickname" to AttributeValue.fromNul(true),
)
```

Kotlin 객체의 null을 저장할 때는 속성을 생략할지, DynamoDB의 NULL 타입으로 표현할지 결정해야 한다. 이는 속성의 존재를 검사하는 조건식에도 영향을 준다.

## 6. JSON 문자열이나 데이터베이스 연결 객체는 아니다

다음 코드는 구조화된 Map을 저장하는 표현이다.

```kotlin
AttributeValue.fromM(mapOf("city" to AttributeValue.fromS("서울")))
```

반면 다음 코드는 JSON처럼 생긴 내용을 가진 문자열을 저장하는 표현이다.

```kotlin
AttributeValue.fromS("""{"city":"서울"}""")
```

후자는 DynamoDB 관점에서 문자열 한 개이므로 내부의 `city`가 중첩 속성이 되지 않는다. Map으로 다룰 것인지 JSON 문자열로 다룰 것인지를 명시적으로 선택해야 한다.

또한 `AttributeValue`는 데이터 표현 객체다. 생성했다고 저장되거나, 값을 읽는 접근자를 호출했다고 AWS 요청이 발생하지 않는다. 실제 저장·조회는 별도의 DynamoDB 클라이언트 호출이 담당한다.
