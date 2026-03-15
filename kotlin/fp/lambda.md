# 람다 함수
```kotlin
// 만드는 방법 1
val isCoffee = fun(drink: Drink): Boolean = drink.name == "coffee"

// 만드는 방법 2
val isCoffee = { drink: Drink -> drink.name == "coffee" }

// 호출하는 두 가지 방법
fun main() {
    isCoffee(Drink("coffee")) // 1
    
    isCoffee.invoke(Drink("coffee")) // 2
}
```
설명과 코드를 함께 작성했으니 참고하자. 그리고 함수에도 별개의 타입이 있다. 위 함수를 예시로 들면

```kotlin
val isCoffee: (Drink) -> Boolean = fun(drink: Drink): Boolean = drink.name == "coffee"

val isCoffee: (Drink) -> Boolean = { drink: Drink -> drink.name == "coffee" }
```
이렇게 된다.

만약 람다 함수가 어떤 함수의 파라미터로 마지막에 위치하면 중괄호와 화살표로 만든 람다 함수를 별도로 뺄 수 있다.
```kotlin
fun main() {
    filterDrinks(drinks) { drink: Drink -> drink.name == "coffee" }
}

fun filterDrinks(drinks: List<Drink>, filter: (Drink) -> Boolean): List<Drink> {
    // ....
}
```

그리고 `filterDrinks()` 메소드의 파라미터 타입으로 람다 함수의 파라미터 타입을 추론할 수 있기에 타입을 생략할 수 있다.
```kotlin
filterDrinks(drinks) { drink -> drink.name == "coffee" } // drink 대신 어떤 명칭을 사용해도 상관 없음
```

여기에 더해 익명 함수를 만들 때 파라미터가 하나이면 it 라는 지시어로 화살표 마저 생략할 수 있다.
```kotlin
filterDrinks(drinks) { it.name == "coffee" }
```

그리고 람다 함수 로직의 마지막 라인의 결과가 리턴 값이 되어 리턴을 명시해주지 않아도 된다.

## 자바와의 중요한 차이점
자바에서 함수는 2급 시민(변수로 선언, 파라미터로 사용 불가)이지만 코틀린에서는 1급 시민이다.

# Closure
자바에선 람다 밖의 변수를 람다 안에서 사용하는 데에 제약이 있다. 그런데 코틀린에서는 아무 문제 없이 동작한다. 이게 가능한 이유가 뭘까?

코틀린에서는 람다가 시작하는 지점에 참조하고 있는 모든 변수들을 **모두 포획**하여 그 정보를 가지고 있다. 그렇게 해야만 람다가 진정한 일급 시민으로 간주될 수 있다. 이 데이터 구조를 **Closure**라고 한다.