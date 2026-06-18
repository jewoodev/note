# static 함수와 변수
코틀린에서는 static 함수와 변수를 object로 정의할 수 있다. 클래스 내에 companion object(동행 객체) 라는 키워드로 블럭을 열어 그곳에 위치시키면 static 이 붙은 것과 동일하게 사용할수 있다. 

이곳에 변수를 정의하면 Warning이 발생한다. 그 이유는 정적 변수이기에, 런타임 시에 할당하지 말고 컴파일 시점에 할당하는게 더 좋기 때문이다. 앞에 `const` 키워드를 붙이면 상수를 지정하는 행위가 되어 컴파일 시점에 할당된다. 이는 기본 타입과 String에만 붙일 수 있다. 

## companion object
자바의 정적 영역에 대응되는 이 동반 객체는 자바와는 달리 하나의 객체로 간주된다. 그래서 이름을 붙일 수도 있고, interface로 구현할 수도 있다. 

```kotlin
companion object Factory : FactoryInterface {}
```

companion object에 유틸성 함수를 정의하고 싶을 수 있지만, 최상단 파일에 정의하는 걸 권장한다. (이 또한 static 함수처럼 간주된다.)

만약 자바에서 코틀린의 companion object 명세를 사용하려면 companion object 블록에 @JvmStatic 어노테이션을 붙여야 한다.

# 싱글톤
자바에서 싱글톤을 만드는 방법은 아래와 같다.

1. 정적 영역에 인스턴스라는 걸 만들어서 필요로 할 때 그걸 가져가게 하기
2. 동시다발적으로 getInstance()를 호출하는 걸 대비하기
3. 싱글톤이 어떤 클래스가 상속받을 필요가 없다면 Enum Class로 만들기

코틀린에서는 `object` 라는 키워드만 사용하면 끝난다. 그리고 자바에서와 달리 인스턴스를 가져오지 않고 `.변수` 혹은 `.함수()`로 접근한다.

# 익명 클래스 
```kotlin
fun main() {
    learnSomething(object : Learnable { // 코틀린에서는 이렇게 익명 클래스를 정의
        override fun learn() { println("I am learning") }
        override fun train() { println("I am training") }
    })
}

private fun learnSomething(learnable: Learnable) {
    learnable.learn()
    learnable.train()
}
```