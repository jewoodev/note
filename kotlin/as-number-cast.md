# Kotlin의 `as Number` 이해하기

## 한 문장으로 이해하기

```kotlin
val value = (rawValue as Number).toLong()
```

이 코드는 `rawValue`의 실제 객체가 숫자 타입이라고 런타임에 검증한 다음, 그 숫자를 `Long` 값으로 변환한다.

`as Number`는 숫자 변환이 아니라 타입 캐스팅이고, 실제 숫자 변환은 뒤의 `toLong()`이 수행한다.

## `as`는 명시적 타입 캐스팅이다

Kotlin의 `as`는 어떤 값의 런타임 타입이 지정한 타입과 호환된다고 단언하는 문법이다.

```kotlin
val rawValue: Any = 1L
val number = rawValue as Number
```

`rawValue`의 컴파일 타임 타입은 `Any`지만 실제 객체는 `Long`이다. `Long`은 `Number`의 하위 타입이므로 캐스팅이 성공한다.

반대로 실제 객체가 숫자가 아니면 캐스팅이 실패한다.

```kotlin
val rawValue: Any = "1"
val number = rawValue as Number // ClassCastException
```

`as Number`는 문자열을 숫자로 파싱하지 않는다. 문자열을 숫자로 바꾸려면 `toLong()`과 같은 문자열 변환 함수를 사용해야 한다.

```kotlin
val value = "1".toLong()
```

## `Number`를 사용하는 이유

`Number`는 여러 숫자 타입의 공통 상위 타입이다.

```text
Number
├── Byte
├── Short
├── Int
├── Long
├── Float
└── Double
```

JVM에서는 `BigInteger`, `BigDecimal` 같은 Java 숫자 타입도 `Number`로 다룰 수 있다.

외부 라이브러리나 JDBC가 반환한 값의 정적인 타입이 `Any`이고, 구체적인 숫자 타입까지 고정할 수 없을 때 `Number`로 먼저 캐스팅하면 여러 숫자 표현을 수용할 수 있다.

```kotlin
fun toLong(rawValue: Any): Long = (rawValue as Number).toLong()

toLong(1)  // Int를 받아 1L 반환
toLong(1L) // Long을 받아 1L 반환
```

## 캐스팅과 변환은 서로 다르다

다음 표현에는 두 단계가 있다.

```kotlin
val version = (rawValue as Number).toLong()
```

1. `rawValue as Number`: 객체가 `Number`인지 검사하고 그 타입으로 취급한다.
2. `.toLong()`: 숫자의 값을 `Long` 표현으로 변환한다.

캐스팅은 객체의 실제 숫자 타입을 바꾸지 않는다.

```kotlin
val rawValue: Any = 1
val number = rawValue as Number

println(number::class) // class kotlin.Int
val converted = number.toLong()
println(converted::class) // class kotlin.Long
```

## `as Long`과의 차이

`as Long`은 실제 객체가 정확히 `Long`과 호환될 때만 성공한다.

```kotlin
val rawValue: Any = 1

rawValue as Long             // 실패: 실제 객체는 Int
(rawValue as Number).toLong() // 성공: Int도 Number이며 Long으로 변환 가능
```

따라서 JDBC처럼 데이터베이스 컬럼과 드라이버에 따라 `Int`, `Long`, `BigDecimal` 등 서로 다른 숫자 타입이 반환될 수 있는 경계에서는 `as Number`가 구체 타입 캐스팅보다 유연하다.

## JDBC 테스트 예제

Spring의 `JdbcTemplate.queryForMap()`은 각 컬럼 값을 범용적인 값 타입으로 반환한다.

```kotlin
val row = jdbcTemplate.queryForMap(
    "SELECT version FROM finance_contracts WHERE id = ?",
    contractId,
)
```

`row.getValue("version")`의 정적인 타입만으로는 구체적인 숫자 타입을 알 수 없다. 다음 코드는 값이 숫자라는 스키마 계약을 확인하고 비교 타입을 `Long`으로 통일한다.

```kotlin
assertEquals(
    1L,
    (row.getValue("version") as Number).toLong(),
)
```

이 표현은 다음 두 가지 계약을 함께 검증한다.

- `version`이라는 컬럼이 결과에 존재한다.
- 해당 컬럼의 값이 숫자다.

`getValue("version")`은 키가 없으면 예외를 발생시키고, `as Number`는 값이 숫자가 아니면 예외를 발생시킨다. 따라서 데이터베이스 스키마와 조회 결과가 예상과 다르면 테스트가 즉시 실패한다.

## 안전한 캐스팅 `as?`

값이 숫자가 아닐 가능성을 정상적인 입력으로 처리해야 한다면 `as?`를 사용할 수 있다.

```kotlin
val number = rawValue as? Number
```

`as?`는 캐스팅할 수 없을 때 예외를 발생시키지 않고 `null`을 반환한다.

```kotlin
val value = (rawValue as? Number)?.toLong()
```

필수 숫자 값이라면 명시적인 오류를 붙일 수도 있다.

```kotlin
val value = (rawValue as? Number)?.toLong()
    ?: error("Expected a numeric value: $rawValue")
```

테스트에서 스키마 위반을 즉시 실패시키려는 경우에는 강제 캐스팅인 `as Number`가 적절하다. 사용자 입력이나 선택적인 외부 데이터처럼 타입 불일치가 예상 가능한 경우에는 `as? Number`가 더 적합하다.

## `is Number`와 스마트 캐스트

조건에 따라 분기해야 한다면 `is`로 타입을 확인할 수 있다.

```kotlin
if (rawValue is Number) {
    val value = rawValue.toLong()
}
```

`is Number` 검사에 성공한 블록 안에서는 Kotlin이 `rawValue`를 자동으로 `Number`로 취급한다. 이를 스마트 캐스트라고 한다.

용도는 다음처럼 구분할 수 있다.

```text
as Number   숫자가 아니면 프로그램 계약 위반이므로 즉시 실패
as? Number  숫자가 아닐 가능성을 null로 처리
is Number   숫자인 경우와 아닌 경우를 분기
```

## 숫자 변환 시 주의할 점

`Number.toLong()`은 모든 숫자를 손실 없이 변환한다는 뜻이 아니다.

```kotlin
val value = (BigDecimal("1.9") as Number).toLong()
println(value) // 1
```

소수부가 있는 값은 잘릴 수 있고, 표현 가능한 범위를 벗어난 숫자도 주의해야 한다. 정확한 정수 변환이 중요한 경우에는 입력의 구체 타입과 범위를 별도로 검증해야 한다. 예를 들어 `BigDecimal`이라면 `longValueExact()`를 사용해 소수부나 범위 손실을 오류로 처리할 수 있다.

버전 번호나 식별자처럼 데이터베이스에서 이미 정수형으로 제한된 값을 테스트에서 읽는 경우에는 `(value as Number).toLong()`이 간결하고 실용적이다.

## 대안: 처음부터 반환 타입을 지정하기

컬럼 하나만 조회한다면 범용 Map을 사용하지 않고 반환 타입을 직접 지정할 수 있다.

```kotlin
val version = jdbcTemplate.queryForObject(
    "SELECT version FROM finance_contracts WHERE id = ?",
    Long::class.java,
    contractId,
)
```

이 방식은 `as Number` 캐스팅이 필요 없고 기대 타입이 코드에 더 직접적으로 드러난다.

여러 컬럼을 한 번에 검증하기 위해 `queryForMap()`을 사용한다면 다음 표현이 적절하다.

```kotlin
val version = (row.getValue("version") as Number).toLong()
```

즉, `as Number`는 범용 타입으로 반환된 숫자 값을 다룰 때 사용하는 런타임 타입 검증이며, 구체적인 숫자 값으로 바꾸는 작업은 그 뒤의 변환 함수가 담당한다.
