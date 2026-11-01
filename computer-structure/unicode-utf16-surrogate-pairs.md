# 서로게이트 쌍: 한 문자가 두 개의 Char로 표현되는 이유

서로게이트 쌍(surrogate pair)은 **UTF-16에서 하나의 코드 포인트를 두 개의 16비트 코드 단위로 표현하는 방식**이다. 예를 들어 `😀`는 하나의 코드 포인트이지만 Java와 Kotlin/JVM에서는 두 개의 `char` 또는 `Char`로 표현된다.

이 문서는 특정 프로젝트에 대한 사전 지식 없이 읽을 수 있다. 예제는 Kotlin/JVM을 기준으로 하며, `Character`는 Java 표준 라이브러리의 `java.lang.Character`를 뜻한다.

## 1. 코드 포인트와 코드 단위

유니코드의 **코드 포인트(code point)**는 문자를 식별하는 번호다. `U+` 뒤의 숫자는 16진수다. 예를 들어 `A`는 `U+0041`, `가`는 `U+AC00`, `😀`는 `U+1F600`이다.

**인코딩**은 이런 번호를 실제 데이터로 표현하는 규칙이고, **코드 단위(code unit)**는 그 인코딩에서 사용하는 기본 단위다. UTF-8은 8비트, UTF-16은 16비트 단위를 사용한다. 같은 코드 포인트라도 인코딩에 따라 필요한 단위 수가 달라진다. [Unicode FAQ](https://www.unicode.org/faq/utf_bom.html)

| 예시 | 코드 포인트 | UTF-16 코드 단위 수 | UTF-8 바이트 수 |
| --- | --- | --- | --- |
| `A` | `U+0041` | 1 | 1 |
| `가` | `U+AC00` | 1 | 3 |
| `😀` | `U+1F600` | 2 | 4 |

따라서 “문자열 길이”를 이야기할 때는 코드 포인트 수, UTF-16 코드 단위 수, 인코딩한 바이트 수 중 무엇을 세는지 구분해야 한다.

## 2. 왜 두 개가 필요한가?

16비트 하나는 `0x0000`부터 `0xFFFF`까지 표현할 수 있다. 유니코드 코드 포인트의 범위는 `U+0000`부터 `U+10FFFF`까지이므로, 모든 코드 포인트를 16비트 하나에 담을 수는 없다.

UTF-16은 `U+10000`부터 `U+10FFFF`까지의 **보충 코드 포인트(supplementary code point)**를 두 코드 단위로 표현한다. 이 두 단위가 서로게이트 쌍이다. `U+0000`부터 `U+FFFF`까지는 기본 다국어 평면(BMP)이며, 그 안의 서로게이트 전용 범위는 독립적인 문자 표현으로 사용하지 않는다. [Unicode FAQ](https://www.unicode.org/faq/utf_bom.html)

## 3. High와 Low가 한 쌍을 이룬다

| 역할 | 코드 단위 값의 범위 | 위치 |
| --- | --- | --- |
| High surrogate | `0xD800` ~ `0xDBFF` | 첫 번째 |
| Low surrogate | `0xDC00` ~ `0xDFFF` | 두 번째 |

유효한 쌍은 반드시 **High 다음에 Low**가 오는 순서다. [Java Character 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Character.html)

`😀`의 UTF-16 표현을 펼치면 다음과 같다.

```text
코드 포인트: U+1F600 (😀)

UTF-16:      0xD83D       0xDE00
             └ High ┘    └ Low ┘
             └──── 하나의 코드 포인트 ────┘
```

각각은 이모지의 왼쪽 그림과 오른쪽 그림을 의미하지 않는다. 두 숫자를 함께 해석해야 `U+1F600`이라는 번호가 나온다.

## 4. Java와 Kotlin/JVM에서 확인하기

Java의 `char`와 Kotlin/JVM의 `Char` 하나는 UTF-16 코드 단위 하나를 나타낸다. 문자열의 인덱스도 이 단위를 기준으로 한다. 따라서 `Char` 하나가 항상 완전한 문자 하나인 것은 아니다. [Java String 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html)

```kotlin
val text = "😀"

println(text.length)                         // 2
println(text[0].code.toString(16))            // d83d
println(text[1].code.toString(16))            // de00
println(text.codePointAt(0).toString(16))     // 1f600
println(text.codePointCount(0, text.length)) // 1

println(text == "\uD83D\uDE00")              // true
println(text.toByteArray(Charsets.UTF_8).size) // 4
```

`"\uD83D\uDE00"`는 소스 코드에서 두 코드 단위를 이스케이프 표기로 적은 것이다. 실행 시에는 `"😀"`와 같은 문자열이다.

여기서 `length == 2`는 코드 단위 수에 관한 설명이다. JVM 내부에서 문자열 객체가 실제로 차지하는 메모리 크기를 계산한 결과는 아니다.

## 5. isHighSurrogate는 무엇을 검사하는가?

정확한 Java 메서드 이름은 `Character.isHighSurrogate(char ch)`다. `isHigherSurrogate`가 아니다.

이 메서드는 전달받은 값이 High surrogate 범위에 속하는지만 검사한다. 다음 값이 Low인지까지 확인하지는 않는다. 두 값을 함께 검사하려면 `isSurrogatePair(high, low)`를 사용할 수 있다. [Java Character 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Character.html#isHighSurrogate(char))

```kotlin
val high = '\uD83D'
val low = '\uDE00'

println(Character.isHighSurrogate(high))        // true
println(Character.isLowSurrogate(low))          // true
println(Character.isSurrogatePair(high, low))   // true
println(Character.isSurrogatePair(low, high))   // false
println(Character.isHighSurrogate('A'))         // false
```

문자열 전체의 UTF-16 형식이 올바른지 검사하려면 일반 코드 단위는 그대로 통과시키되, High가 나올 때 바로 다음 Low까지 확인해야 한다. 짝 없이 등장한 Low도 거부한다.

```kotlin
fun isWellFormedUtf16(text: String): Boolean {
    var index = 0
    while (index < text.length) {
        val current = text[index]
        when {
            Character.isHighSurrogate(current) -> {
                if (index + 1 >= text.length ||
                    !Character.isLowSurrogate(text[index + 1])) {
                    return false
                }
                index += 2
            }
            Character.isLowSurrogate(current) -> return false
            else -> index++
        }
    }
    return true
}

check(isWellFormedUtf16("A가😀"))
check(isWellFormedUtf16(""))
check(!isWellFormedUtf16("\uD83D"))       // High만 있음
check(!isWellFormedUtf16("\uDE00"))       // Low만 있음
check(!isWellFormedUtf16("\uD83DA"))      // High 다음이 일반 문자
check(!isWellFormedUtf16("\uDE00\uD83D")) // 순서가 반대
```

이 함수는 UTF-16 구조만 검사한다. 빈 문자열 허용 여부나 제어 문자 금지 같은 업무 규칙은 별도로 판단해야 한다.

## 6. 문자열을 중간에서 자르면 생기는 문제

다음 코드는 `😀`를 온전히 가져오지 못한다.

```kotlin
val text = "😀A"
val broken = text.substring(0, 1)

check(broken.length == 1)
check(!isWellFormedUtf16(broken)) // High만 남아 있음
```

`substring`의 인덱스는 UTF-16 코드 단위 기준이기 때문이다. Java 문자열에는 이런 짝 없는 서로게이트가 들어갈 수 있으므로, 문자열 객체를 만들었다는 사실만으로 올바른 UTF-16이라는 보장은 없다. 표시하거나 인코딩할 때의 결과는 처리 방식에 따라 달라질 수 있다.

올바른 UTF-16 입력에서 코드 포인트 한 개를 가져오려면 코드 포인트 기준으로 끝 인덱스를 구할 수 있다. [Java String 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#offsetByCodePoints(int,int))

```kotlin
val text = "😀A"
val endIndex = text.offsetByCodePoints(0, 1)
val firstCodePoint = text.substring(0, endIndex)

check(endIndex == 2)
check(firstCodePoint == "😀")
```

`codePointCount`나 `offsetByCodePoints`는 UTF-16 유효성 검사 함수가 아니다. 짝 없는 서로게이트도 한 단위로 취급하므로, 잘못된 입력을 거부해야 한다면 별도 검증이 필요하다. [Java String 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html#codePointCount(int,int))

## 7. 서로게이트 쌍을 보존해도 화면의 한 글자가 나뉠 수 있다

사람이 한 글자로 인식하는 모양은 여러 코드 포인트로 구성될 수 있다. 예를 들어 `e` 뒤에 결합 악센트 `U+0301`을 붙인 `é`는 두 코드 포인트다. 가족 이모지처럼 여러 이모지를 연결한 표현도 있다.

이런 경계를 다루는 개념이 **그래핌 클러스터(grapheme cluster)**다. 사용자에게 보이는 글자 단위로 자르려면 서로게이트 쌍뿐 아니라 그래핌 클러스터 경계도 고려해야 한다. [Unicode Text Segmentation](https://www.unicode.org/reports/tr29/)

| 처리 목적 | 고려할 기준 |
| --- | --- |
| UTF-16 형식이 올바른지 검사 | High와 Low의 짝과 순서 |
| 코드 포인트 단위로 순회하거나 자르기 | 서로게이트 쌍을 함께 처리 |
| 사용자에게 보이는 글자 단위로 자르기 | 그래핌 클러스터 경계 |
| 전송 데이터의 바이트 제한 확인 | 실제 사용할 인코딩의 바이트 수 |

## 8. UTF-8에도 서로게이트 쌍이 있는가?

서로게이트 쌍은 UTF-16의 표현 방식이다. UTF-8에서는 `😀`라는 코드 포인트를 네 바이트로 직접 인코딩한다. High와 Low 각각을 별도의 문자로 UTF-8 인코딩하는 것이 아니다. [Unicode FAQ](https://www.unicode.org/faq/utf_bom.html)

따라서 Kotlin/JVM 문자열의 `length`, 코드 포인트 수, UTF-8 전송 바이트 수는 서로 다른 값일 수 있다. 문자열 길이를 제한하거나 분할하는 코드를 작성할 때는 먼저 어느 단위를 기준으로 하는지 정해야 한다.
