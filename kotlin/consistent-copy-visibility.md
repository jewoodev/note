# Kotlin의 @ConsistentCopyVisibility: data class의 생성 경로 제어하기

`@ConsistentCopyVisibility`는 `data class`가 자동 생성하는 `copy()` 함수의 접근 수준을 **주 생성자와 같게 만드는 애노테이션**이다.
생성자가 `private`이면 `copy()`도 `private`, 생성자가 `internal`이면 `copy()`도 `internal`이 된다.
값을 검사하거나 정규화하는 생성 함수를 제공하면서, 외부 코드가 `copy()`로 별도의 생성 경로를 사용하지 못하게 할 때 활용한다.
[공식 API 설명](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-consistent-copy-visibility/)

이 글은 Kotlin의 클래스·함수·`val`을 읽을 수 있는 독자를 대상으로 한다. 특정 서비스나 프레임워크에 대한 지식은 필요하지 않다.
예제는 상품 코드처럼 정해진 형식을 가진 값을 객체로 표현하는 상황을 사용한다.

## 1. data class의 copy()는 무엇인가

Kotlin의 `data class`는 주 생성자에 선언한 프로퍼티를 바탕으로 `equals()`, `hashCode()`, `toString()`, `componentN()`, `copy()` 등을 자동 생성한다.
`copy()`는 일부 값을 바꾼 새 객체를 만드는 함수다. 원래 객체의 프로퍼티를 수정하지 않는다.
[Data classes 문서](https://kotlinlang.org/docs/data-classes.html)

```kotlin
data class DeliveryLabel(val recipient: String, val city: String)

fun main() {
    val original = DeliveryLabel("민수", "서울")
    val changed = original.copy(city = "수원")

    check(original.city == "서울")
    check(changed.city == "수원")
    check(changed.recipient == "민수")
}
```

위 클래스의 `copy()`는 개념적으로 다음과 같은 동작을 한다. 설명용 코드이며 클래스에 직접 추가하는 구현은 아니다.

```kotlin
fun copy(
    recipient: String = this.recipient,
    city: String = this.city,
): DeliveryLabel = DeliveryLabel(recipient, city)
```

생성자를 호출해 새 객체를 만들기 때문에 새 객체의 `init` 블록도 실행된다.
Kotlin의 객체 초기화 과정은 [Classes 문서](https://kotlinlang.org/docs/classes.html)에 설명돼 있다.

## 2. 생성자를 숨겨도 copy()가 공개되던 문제

외부 입력을 일관된 형식으로 바꾸고 싶을 때 다음과 같은 구조를 사용할 수 있다.

- 생성자는 `private`으로 둔다.
- `of()` 같은 공개 함수를 통해 객체를 만든다. 이런 함수를 팩터리 함수라고 한다.
- 팩터리 함수에서 공백 제거·대소문자 통일 등의 정규화를 수행한다.
- `init`에서는 객체가 지켜야 할 조건을 검사한다.

그런데 과거 Kotlin에서는 생성자가 비공개여도 `data class`의 `copy()`는 공개되는 동작이 있었다.
따라서 생성자를 직접 호출하지 못하는 외부 코드도 기존 객체에서 `copy()`를 호출해 새 객체를 만들 수 있었다.
Kotlin 2.0.20부터 이 동작을 변경하는 단계적 전환과 관련 애노테이션이 도입됐다.
[Kotlin 2.0.20 변경 사항](https://kotlinlang.org/docs/whatsnew2020.html#data-class-copy-function-to-have-the-same-visibility-as-constructor)

여기서 우회되는 것은 **팩터리 함수**다. `copy()`가 생성자와 `init`까지 생략하는 것은 아니다.
검증을 팩터리에만 두면 공개 `copy()`가 그 검증을 건너뛸 수 있지만, `init`의 검증은 새 객체를 만들 때 실행된다.

## 3. 클래스에 적용하는 방법

다음 예제에서는 상품 코드를 `ABC-123` 형식으로 저장한다.
앞 세 글자는 영문 대문자, 뒤 세 글자는 숫자라는 예제용 규칙이다.

```kotlin
@ConsistentCopyVisibility
data class ProductCode private constructor(val value: String) {
    init {
        require(value.matches(Regex("[A-Z]{3}-[0-9]{3}"))) {
            "Product code must have the form ABC-123"
        }
    }

    companion object {
        fun of(raw: String): ProductCode =
            ProductCode(raw.trim().uppercase())
    }
}

fun main() {
    val first = ProductCode.of(" abc-123 ")
    val second = ProductCode.of("ABC-123")

    check(first.value == "ABC-123")
    check(first == second)
    check(first.hashCode() == second.hashCode())
    check(runCatching { ProductCode.of("invalid") }.isFailure)
}
```

`ConsistentCopyVisibility`는 Kotlin 표준 라이브러리의 `kotlin` 패키지에 있으므로 이 예제에는 별도 라이브러리나 명시적인 import가 필요하지 않다.

다음은 위 클래스와 함께 컴파일하면 실패해야 하는 **외부 호출 예제**다. 두 줄을 각각 확인할 수 있다.

```kotlin
fun forbiddenCalls(code: ProductCode) {
    ProductCode("ABC-123")         // 컴파일 오류: 생성자가 private
    code.copy(value = "XYZ-001")   // 컴파일 오류: copy()도 private
}
```

`XYZ-001` 자체는 올바른 상품 코드지만, 외부에서 `copy()`를 호출하는 경로가 허용되지 않으므로 컴파일되지 않는다.
새 값이 필요하면 `ProductCode.of("XYZ-001")`을 사용한다.

반면 `first.value`를 읽거나 두 객체를 `==`로 비교하는 것은 가능하다.
생성자의 접근 수준과 프로퍼티의 접근 수준은 별개이며, 이 애노테이션의 대상은 생성되는 `copy()`의 가시성이다.
[Visibility modifiers 문서](https://kotlinlang.org/docs/visibility-modifiers.html)

## 4. 각 장치가 맡는 역할

| 장치 | 예제에서의 역할 |
| --- | --- |
| `private constructor` | 외부 코드의 직접 생성자 호출을 제한 |
| `ProductCode.of()` | 입력 공백을 제거하고 대문자로 정규화 |
| `init` | 저장되는 값이 `ABC-123` 형식을 지키는지 검사 |
| `@ConsistentCopyVisibility` | 자동 생성된 `copy()`도 생성자와 같은 접근 수준으로 제한 |
| `val value` | 생성 후 프로퍼티에 다른 값을 재할당하지 못하게 함 |

이 설계에서 외부 호출자는 입력 형식의 차이를 `of()`에 맡긴다.
클래스 내부에서는 `init`이 정규화된 상태를 확인한다. 생성 경로와 값의 조건을 각각 코드로 표현할 수 있다.

`data class`의 값 비교·문자열 표현은 유용하지만 외부의 임의 복제는 허용하고 싶지 않을 때 이 조합을 고려할 수 있다.
예를 들어 정규화된 식별자, 단위가 고정된 수량, 허용된 범위의 설정값 같은 객체에 적용할 수 있다.
여러 상태 전이와 부수 효과를 관리하는 객체라면 일반 `class`에 목적이 드러나는 메서드를 두는 설계도 검토할 수 있다.

## 5. 모듈 전체에 적용하는 방법

클래스마다 애노테이션을 붙이는 대신 `-Xconsistent-data-class-copy-visibility` 컴파일러 옵션을 사용할 수 있다.
공식 설명상 같은 모듈의 모든 `data class`에 애노테이션을 적용하는 것과 같은 효과다.
[옵션 설명](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-consistent-copy-visibility/)

Kotlin JVM Gradle 플러그인이 적용된 `build.gradle.kts`에서는 다음처럼 설정할 수 있다.

```kotlin
kotlin {
    compilerOptions {
        freeCompilerArgs.add("-Xconsistent-data-class-copy-visibility")
    }
}
```

클래스 단위 적용은 변경 영향을 해당 타입에서 확인하기 쉽다.
모듈 단위 적용은 같은 정책을 일괄 적용할 때 적합하다. 이때는 비공개 생성자가 있는 기존 타입의 외부 `copy()` 호출을 함께 점검한다.

| 주 생성자의 접근 수준 | 일관된 가시성 적용 후 copy() | 일반적인 Kotlin 호출 범위 |
| --- | --- | --- |
| `public` | `public` | 타입에 접근할 수 있는 외부 코드 |
| `internal` | `internal` | 같은 모듈 내부 |
| `private` | `private` | 해당 클래스 내부와 companion object |

모듈은 단순히 같은 패키지에 속한 코드라는 뜻이 아니다. Kotlin에서 함께 컴파일되는 코드의 단위이며 Gradle 소스 세트 등이 그 예다.
테스트 컴파일의 내부 접근 허용 같은 빌드 설정은 별도로 고려한다.
[접근 수준과 모듈 정의](https://kotlinlang.org/docs/visibility-modifiers.html)

## 6. Kotlin 버전과 기존 코드의 호환성

관련 애노테이션과 전환 안내는 Kotlin 2.0.20에서 도입됐다.
전환은 경고, 오류 강화, 기본 동작 변경의 단계로 설명되지만 공식 API 문서의 버전 일정에는 예상 표기가 포함돼 있다.
특정 버전부터 애노테이션이 무조건 필요 없다고 단정하기보다, 사용 중인 컴파일러·언어 버전·옵션과 실제 진단을 함께 확인한다.
[전환 안내](https://kotlinlang.org/docs/whatsnew2020.html#data-class-copy-function-to-have-the-same-visibility-as-constructor),
[변경 추적 이슈 KT-11914](https://youtrack.jetbrains.com/issue/KT-11914)

기본 동작이 이미 생성자의 가시성을 따르는 환경에서는 이 애노테이션이나 옵션이 필요하지 않을 수 있다.
이 경우에도 의도한 외부 호출이 실제로 차단되는지 확인한 뒤 정리한다.

배포된 라이브러리를 변경할 때는 이미 컴파일된 사용자가 공개 `copy()`를 호출하고 있을 수 있다.
이런 바이너리 호환성 전환을 위한 애노테이션이 `@ExposedCopyVisibility`다.
공개 바이너리 가시성을 유지하는 용도이며, Kotlin 소스에서 접근할 수 없게 되는 호출을 계속 허용해 주는 일반적인 해결책은 아니다.
신규 코드의 생성 경로를 제한하려는 목적이라면 `@ConsistentCopyVisibility` 또는 모듈 옵션을 우선 검토한다.
[ExposedCopyVisibility 공식 설명](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-exposed-copy-visibility/)

## 7. 자주 혼동하는 점

**모든 data class에 붙일 필요는 없다.** 공개 생성자와 공개 `copy()`가 자연스러운 단순 데이터 전달 객체에는 가시성 제한의 이점이 크지 않다.

**객체 전체를 불변으로 만들지는 않는다.** `var` 프로퍼티나 변경 가능한 컬렉션이 있으면 그 값은 별도의 경로로 바뀔 수 있다.

**깊은 복사를 제공하지 않는다.** `copy()`는 얕은 복사이며 참조한 객체를 재귀적으로 복제하지 않는다. 가시성 애노테이션은 복사 방식을 바꾸지 않는다.
[copy()의 복사 방식](https://kotlinlang.org/docs/data-classes.html#copying)

**copy()를 직접 재정의하는 방식은 사용할 수 없다.** Kotlin의 `data class`는 명시적인 `copy()` 구현을 허용하지 않는다.
필요하면 `withCode()`처럼 다른 이름의 함수를 만들거나 일반 `class`를 사용한다.
[자동 생성 함수의 제약](https://kotlinlang.org/docs/data-classes.html)

**입력 검증·권한 검사 기능은 아니다.** 애노테이션은 Kotlin 코드의 접근 범위를 정한다.
사용자가 입력한 값의 유효성은 검증 로직으로, API 호출 권한은 인증·인가 로직으로 판단해야 한다.

## 8. 적용 후 확인할 사항

정상 생성과 잘못된 값 처리는 실행 테스트로 확인하고, 외부 `copy()` 접근 제한은 컴파일 결과로 확인한다.

| 확인 항목 | 기대 결과 |
| --- | --- |
| `ProductCode.of(" abc-123 ")` | `ABC-123`으로 정규화 |
| 같은 상품 코드 두 개를 비교 | 값 기준으로 같음 |
| `ProductCode.of("invalid")` | 생성 시 검증 실패 |
| 외부에서 생성자 직접 호출 | 컴파일 오류 |
| 외부에서 `copy()` 호출 | 컴파일 오류 |

컴파일 실패 확인용 코드는 일반 테스트 소스에 그대로 넣으면 전체 테스트 컴파일이 실패한다.
별도 샘플 디렉터리나 컴파일 검증 도구에서 실행하고, 실패 원인이 의도한 비공개 멤버 접근인지 확인한다.

예제 검증일: 2026-10-19. Kotlin/JVM 컴파일러 2.4.21, JVM 타깃 17에서 두 실행 예제의 컴파일·실행,
외부 생성자·`copy()` 호출의 컴파일 실패, 모듈 옵션에 의한 동일한 접근 제한을 확인했다.
이 결과는 해당 환경에서의 예제 검증이며 모든 Kotlin 버전의 기본 동작이 같다는 의미는 아니다.
