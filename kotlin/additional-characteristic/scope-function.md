# scope function이란?
람다를 사용해 일시적인 영역을 만들고 코드를 더 간결하게 만들거나 method chaining에 활용하는 함수를 말한다. 종류로는 아래와 같은 것들이 있다.

1. let
2. run
3. also
4. apply
5. with

- with만 확장 함수가 아니고 나머지는 모두 확장 함수이다.
- let & run은 람다 실행 결과를 반환한다.
- also & apply는 (결과와 무관하게) 수신 객체 자체를 반환한다.
- let & also는 확장 함수의 수신 객체를 호출할 때 it을 사용한다.
  - it은 생략이 불가능한 대신 다른 이름을 붙일 수 있다.
  - 두 함수는 파라미터 타입이 일반 함수라 그렇다.
    - 일반 함수는 파라미터를 받아서 그걸 내부에서 호출한다.
- run & apply는 확장 함수의 수신 객체를 호출할 때 this를 사용한다.
  - this는 생략이 가능한 대신 다른 이름을 붙일 수 없다.
  - 두 함수는 파라미터 타입이 확장함수라 이렇다.
    - 확장 함수는 본인 자신을 this로 호출하거나 생략할 수 있다.


```kotlin
val student = Student("신제우", 10, "Korea")
with(student) {
    println("$name is from $country")
    println("He is $age years old.")
}
```
with(파라미터, 람다): this를 통해 접근이 가능하고, this는 생략 가능


- [Kotlin 공식 문서](https://kotlinlang.org/docs/scope-functions.html)