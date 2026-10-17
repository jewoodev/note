# 멤버 참조

## 함수 참조

코틀린에서는 함수 타입이 필요한 곳에 함수를 바로 넘길 수 없지만, 그 대신 함수에 대한 참조는 넘길 수 있다. 

그리고 어떤 객체를 유일한 파라미터로 받는 최상위 수준 함수가 있으면 그 함수를 참조로 전달할 수 있다. 

```kotlin
fun translate(engMsg: Message) = 
    !engMsg.toKorean() &&
            engMsg.sender in setOf("Customer")
```

## 확장 함수 참조

확장 함수에 대한 참조를 만드려면 참조 앞에 확장 대상 타입 이름을 붙이면 된다.

```kotlin
fun Int.times998() = times(998)

fun goInt(n: Int, r: (Int) -> Int) = r(n)

fun main() {
    goInt(12 , Int::times998)
}
```
