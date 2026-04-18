자바에서 `if-else`는 **Statement**이지만 코틀린에서는 **Expression**이다.

- Statement: 하나의 문장, 하나의 값으로 도출되지 않음
- Expression: 하나의 값으로 도출되는 문장

따라서 삼항 연산자가 불필요해져서 코틀린에선 삭제되었다.

# 범위 조건
자바에서는 `if (0 <= num && num <= 100)`으로 표현해야 했던 걸 코틀린에서는 `if (num in 0..100)`으로 표현할 수 있다. 전자의 방식도 코틀린에서 사용 가능하다.

# switch와 when
코틀린에서는 `when`을 사용하여 `switch`와 유사한 기능을 제공한다. `switch`는 코틀린에서 제공하지 않는다.

```kotlin
when (num) {
    1 -> println("one")
    2 -> println("two")
    else -> println("other")
}

// 응용 사용 예시
when (num) {
    in 1..10 -> println("1~10")
    in 10..20 -> println("10~20")
}

when (num) {
    is Int -> println("Int")
    else -> println("Not Int")
}

when (num) {
    1, 0, -1 -> println("어디서 많이 본 숫자일세")
    else -> println("처음보는 숫자일세")
}

when {
    number == 0 -> println("주어진 숫자는 0 입니다")
    number % 2 == 1 -> println("주어진 숫자는 짝수입니다")
    else -> println("주어진 숫자는 홀수입니다")
}
```
이 또한 Expression이다.

