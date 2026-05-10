 # Type alias & as import
```kotlin
typealias StudentFilter = (Student) -> Boolean

typealias USSMap = Map<String, UltraSpecialStudent>
```
Type alias로 긴 타입을 간결하게 표현해 가독성과 개발 속도를 좋게 만들 수 있다.

```
package com.example.kotlin.j

fun act() {
    // ...
}
```

```
package com.example.kotlin.e

fun act() {
    // ...
}
```
위와 같이 다른 패키지의 같은 이름의 함수를 가져오기 위해서는 as import를 사용해야 한다.

- as import: 어떤 함수나 클래스를 불러올 때 이름을 바꿔서 가져오는 기능

# 구조 분해 & componentN
```kotlin
val student = Student(name = "jewoo", grade = 1)
var (name , age) = student
```
위의 두 번째 라인은 구조 분해 문법이다. 그럼 name에 jewoo, age에 1이 대입된다. 이게 가능한 이유는 componentN 함수 덕분인데, 이는 data class가 자동으로 생성해주는 함수 중 하나다.

`val (name, age) = student` 는 사실 아래의 코드가 합쳐진 코드다.

```kotlin
val name = student.component1()
val age = student.component2()
```

componentN()은 N번째 프로퍼티를 가져오는 메서드다. 이 두 라인이 구조 분해 문법으로 `val (name, age) = student`로 합쳐진 거고 구조분해 문법을 사용한다는 건 componentN 함수로 출력한다는 뜻이다.

data class가 아닌 클래스로 componentN() 함수를 사용하고 싶다면, 해당 클래스에 componentN() 함수를 직접 구현할 수 있다.

```kotlin
class Student(
    val name: String,
    val grade: Int
) {
    operator fun component1(): String = name
    operator fun component2(): Int = grade
}
```
다만 주의할 점은, componentN() 함수는 연산자의 속성을 띄고 있기에 연산자 오버로딩을 하는 것처럼 간주되어야 한다. 그렇게 하기 위해서는 앞에 `operator` 키워드를 붙여줘야 한다.

그리고
```kotlin
val map = mapOf("a" to 1, "b" to 2)
for ((key, value) in map) { // 이 문법도 구조 분해 문법

}
```
이다.

# Jump & Label
자바에서 코드 흐름을 제어할 때 쓰이는 키워드 세 가지는 코틀린에서 어떻게 다른지 알아보자.

- return: 기본적으로 가장 가까운 enclosing function 또는 익명함수로 값이 반환된다.
- break: 가장 가까운 loop를 제거한다.
- continue: 가장 가까운 loop를 다음 step으로 보낸다.

자바에서와 완전히 동일하다. 단 foreach 구문이 있다. 이는 함수형과 함께 마지막 끝 혹은 중간에 반복적으로 루프를 돌릴 수 있게 한다. 자바의 foreach와 유사하지만, 코틀린의 foreach는 element를 변경할 수 없다. 이는 코틀린의 immutability와 일치하기 때문이다. 그리고 continue나 break를 사용할 수 없다. break를 꼭 사용하고 싶다면 foreach 구문을 run이라는 블록으로 감싸고 `return@run`이라고 해줘야 한다. continue를 꼭 사용하고 싶다면 `return@foreach` 라고 해주면 된다.

```kotlin
loop@ for (i in 1..10) {
    for (j in 1..10) {
        if (i == 5 && j == 5) break@loop
    }
}
```
위는 label 기능을 사용한 예시다. 이 기능은 특정 expression에 `라벨이름@`를 붙여서 하나의 라벨로 간주하게 하고 break, continue, return 등을 사용할 수 있다. 예시에서 원래는 가장 가까운 루프를 대상으로 제거되겠지만 라벨 기능을 통해 다른 루프를 대상으로 제거시키는 것이다.

# TakeIf & TakeUnless
코틀린에서 메소드 체이닝을 위해 제공하는 함수들 중 하나이다.

```kotlin
fun getIfBiggerThan10(): Int? =
    if (number > 10) number else null 

fun getIfBiggerThan10(): Int? = number.takeIf { it > 10 }

fun getIfBiggerThan10(): Int? = number.takeUnless { it <= 10 }
```
위의 세 함수는 모두 같은 작업을 수행하는 함수다.