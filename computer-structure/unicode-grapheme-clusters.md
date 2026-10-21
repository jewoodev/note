# 그래핌 클러스터: 사람이 한 글자로 인식하는 단위

**그래핌 클러스터(grapheme cluster)는 사람이 한 글자로 인식하는 단위에 가깝게, 하나 이상의 유니코드 코드 포인트를 묶은 것이다.** 이 문서는 특정 프로젝트의 사전 지식 없이 읽을 수 있으며, 예제는 Kotlin/JVM을 사용한다.

## 1. 화면의 한 글자가 내부적으로도 하나일까?

유니코드는 문자에 `U+0041` 같은 번호를 부여한다. 이 번호를 **코드 포인트(code point)**라고 한다. 하지만 화면에서 한 글자로 보이는 표현이 반드시 코드 포인트 하나로 구성되는 것은 아니다.

| 표현 | 내부 구성 | 코드 포인트 수 | 그래핌 클러스터 수 |
| --- | --- | ---: | ---: |
| `A` | `U+0041` | 1 | 1 |
| `😀` | `U+1F600` | 1 | 1 |
| `é` | `e` + 결합 악센트 | 2 | 1 |
| `🇰🇷` | 지역 표시 기호 K + R | 2 | 1 |
| `👨‍👩‍👧‍👦` | 사람 이모지 4개 + 연결 문자 3개 | 7 | 1 |

표의 `é`는 `U+0065`와 `U+0301`을 연결한 표현이다. 가족 이모지의 연결 문자는 ZWJ(Zero Width Joiner, `U+200D`)다.

그래핌 클러스터 경계는 유니코드의 텍스트 분할 규칙으로 정한다. 이 문서에서는 **확장 그래핌 클러스터(extended grapheme cluster)**를 기준으로 설명한다. [Unicode Text Segmentation](https://www.unicode.org/reports/tr29/)

## 2. 서로게이트 쌍과는 무엇이 다른가?

UTF-16은 16비트 코드 단위를 사용한다. 일부 코드 포인트는 두 코드 단위로 표현하는데, 이 두 단위가 **서로게이트 쌍**이다. [Unicode FAQ](https://www.unicode.org/faq/utf_bom.html)

| 개념 | 무엇을 다루는가? |
| --- | --- |
| 코드 포인트 | 유니코드에서 문자를 식별하는 번호 |
| UTF-16 코드 단위 | UTF-16 표현을 구성하는 16비트 단위 |
| 서로게이트 쌍 | 코드 단위 두 개로 코드 포인트 하나를 표현하는 방식 |
| 그래핌 클러스터 | 코드 포인트들을 한 글자로 취급할 단위로 묶는 기준 |

예를 들어 가족 이모지는 다음 세 가지 길이를 갖는다.

```text
👨‍👩‍👧‍👦

UTF-16 코드 단위:   11개  (사람 이모지 4 × 2 + ZWJ 3 × 1)
코드 포인트:         7개  (사람 이모지 4 + ZWJ 3)
그래핌 클러스터:     1개
```

서로게이트 쌍을 보존하면 코드 포인트가 깨지는 것을 막는다. 그래핌 클러스터를 보존하면 여러 코드 포인트로 구성된 결합 표현까지 함께 유지할 수 있다.

## 3. 왜 문자열 처리에 필요한가?

다음 문자열을 생각해 보자.

```kotlin
val text = "e\u0301!" // e + 결합 악센트 + 느낌표
val first = text.substring(0, 1)

check(first == "e") // 악센트가 떨어졌다.
```

Kotlin/JVM의 문자열 인덱스와 `length`는 UTF-16 코드 단위 기준이다. 위 예제는 올바른 코드 포인트 경계에서 잘랐지만, 그래핌 클러스터 중간에서 잘랐다. [Java String 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html)

그래핌 클러스터는 커서 이동, 글자 선택, 미리보기 생략, 메시지 분할 등을 구현할 때 유용하다. 다만 편집 동작의 세부 정책은 프로그램마다 다를 수 있다. [Unicode Text Segmentation](https://www.unicode.org/reports/tr29/)

## 4. Kotlin/JVM에서 그래핌 클러스터로 나누기

Java의 정규식 `\X`는 확장 그래핌 클러스터 하나를 인식한다. Kotlin 문자열에서는 역슬래시를 이스케이프하여 `"\\X"`로 적는다. 아래 예제는 JDK 25의 `Pattern` API를 기준으로 한다. [Java Pattern 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/regex/Pattern.html)

```kotlin
import java.util.regex.Pattern

fun graphemeClusters(text: String): List<String> {
    val matcher = Pattern.compile("\\X").matcher(text)
    val result = mutableListOf<String>()
    while (matcher.find()) {
        result += matcher.group()
    }
    return result
}

fun main() {
    val text = "Ae\u0301👨‍👩‍👧‍👦"
    val clusters = graphemeClusters(text)

    check(clusters == listOf("A", "e\u0301", "👨‍👩‍👧‍👦"))
    check(clusters.size == 3)
    check(text.codePointCount(0, text.length) == 10)
    check(text.length == 14)
    check(clusters.joinToString("") == text)

    val preview = clusters.take(2).joinToString("")
    check(preview == "Ae\u0301") // 악센트를 함께 유지한다.
}
```

`find()`는 다음 클러스터로 이동하고, `group()`은 매칭한 원문을 반환한다. 이 예제는 이해를 위해 모든 클러스터를 리스트에 담는다. 큰 문자열에서는 경계 위치만 기록하거나 필요한 구간까지만 순회할 수도 있다.

## 5. 길이 제한과 분할 경계는 별개다

“100자까지 허용”이라는 요구에는 어떤 단위를 세는지 명시해야 한다.

| 요구 | 확인할 값 |
| --- | --- |
| 사용자에게 보이는 글자 수에 가까운 제한 | 그래핌 클러스터 수 |
| Java 문자열의 길이 제한 | UTF-16 코드 단위 수인 `length` |
| UTF-8 전송 데이터 크기 제한 | `toByteArray(Charsets.UTF_8).size` |

예를 들어 전송 제한이 UTF-16 코드 단위 10개라면 가족 이모지 하나는 11개이므로 들어가지 않는다. 그래핌 클러스터 한 개라는 사실만으로 길이 제한을 만족하지는 않는다.

이때는 **크기는 전송 규격의 단위로 계산하고, 자르는 위치는 그래핌 클러스터 경계로 선택**할 수 있다. 클러스터 하나가 제한보다 길다면 거부하거나 제한을 조정하는 별도 정책이 필요하다.

## 6. 이해할 때 주의할 점

- **OS 전용 개념이 아니다.** 유니코드 텍스트 처리 표준을 OS·언어·편집기 등이 활용한다.
- **화면 폭이나 그려지는 모양의 개수를 뜻하지 않는다.** 폰트와 표시 환경에 따라 같은 문자열의 모양과 폭이 달라질 수 있다.
- **사람의 인식과 항상 완벽히 일치하지는 않는다.** 표준의 기본 경계 규칙이며 언어나 용도에 따른 조정이 가능하다.
- **원문을 정규화하지 않는다.** `é` 한 코드 포인트와 `e` + 악센트 두 코드 포인트는 각각 한 클러스터여도 원본 문자열은 다르다. 경계 인식과 문자열 정규화는 별도 작업이다.
- **구현이 지원하는 유니코드 버전이 중요하다.** 경계 규칙과 문자 데이터가 갱신되면 처리 결과도 달라질 수 있다.

경계 규칙과 그 적용 범위는 [Unicode Text Segmentation](https://www.unicode.org/reports/tr29/)에서, Java의 지원 사항은 [Pattern 문서](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/regex/Pattern.html)에서 확인할 수 있다.
