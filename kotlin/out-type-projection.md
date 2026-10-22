# Kotlin의 `out`: 제네릭 타입 프로젝션 이해하기

다음 선언에서 `out`은 어떤 역할을 할까?

```kotlin
authentication: Supplier<out Authentication?>
```

이 선언은 **인증 객체 또는 null을 제공하는 공급자를 받으며, 특정 인증 구현체를 제공하는 공급자도 허용한다**는 뜻이다. `out`은 제네릭 타입의 호환 관계를, `?`는 null 허용 여부를 표현한다.

이 문서는 Kotlin의 기본 함수·클래스 문법을 아는 독자를 대상으로 한다. 특정 프로젝트나 Spring Security에 대한 지식은 필요하지 않다.

## 1. 제네릭은 무엇인가?

제네릭은 클래스나 함수가 다루는 타입을 매개변수로 받는 방법이다. 아래 `Box<T>`에서 `T`는 실제 사용할 때 정하는 타입이다.

```kotlin
class Box<T>(var value: T)

val textBox: Box<String> = Box("hello")
val numberBox: Box<Int> = Box(10)
```

`Box<String>`의 `value`는 문자열이고, `Box<Int>`의 `value`는 정수다. 같은 클래스를 여러 타입에 사용하면서 컴파일러가 타입을 확인할 수 있다.

## 2. 하위 타입 관계가 제네릭에 그대로 적용되지는 않는다

고양이와 개를 동물의 하위 타입으로 정의해 보자. 아래 코드는 앞에서 정의한 `Box`를 사용한다.

```kotlin
open class Animal
class Cat : Animal()
class Dog : Animal()

val animal: Animal = Cat() // 가능: 고양이는 동물이다.
val catBox: Box<Cat> = Box(Cat())

// 컴파일 오류: Box<Cat>은 Box<Animal>의 하위 타입이 아니다.
// val animalBox: Box<Animal> = catBox
```

마지막 대입을 허용하면 `animalBox.value = Dog()`로 고양이 상자에 개를 넣을 수 있게 된다. 그러면 원래 `catBox.value`가 `Cat`이라는 약속이 깨진다.

이처럼 기본적인 `Box<T>`는 `T`의 상속 관계만으로 다른 `Box` 타입과 호환되지 않는다. 이런 성질을 **불변성(invariance)**이라고 한다. 여기서 불변성은 타입 간 관계를 뜻하며, 객체의 값이 바뀌지 않는다는 뜻은 아니다.

## 3. `out`은 값을 꺼내는 관점으로 타입을 제한한다

`Box<out Animal>`은 구체적으로 어떤 동물의 상자인지는 몰라도, 꺼낸 값을 `Animal`로 다룰 수 있게 한다.

```kotlin
fun readAnimal(box: Box<out Animal>): Animal {
    val animal: Animal = box.value

    // 컴파일 오류: 실제 상자가 Cat 전용인지 Dog 전용인지 모른다.
    // box.value = Dog()

    return animal
}

val result: Animal = readAnimal(catBox)
```

`Box<Cat>`도 이 함수에 전달할 수 있다. 대신 함수 안에서는 `value`에 임의의 동물을 넣을 수 없다. 값을 읽는 데 필요한 타입 정보는 유지하고, 위험한 쓰기는 막는 것이다.

`Box<out Animal>`처럼 **타입을 사용하는 지점**에 `out`을 붙이는 문법을 **타입 프로젝션(type projection)** 또는 **사용 지점 변성(use-site variance)**이라고 한다. [Kotlin 공식 문서: 타입 프로젝션](https://kotlinlang.org/docs/generics.html#use-site-variance-type-projections)

이 제한은 해당 참조를 통해 할 수 있는 연산에 적용된다. 원본 상자를 복사하거나 변경 불가능한 객체로 만드는 것은 아니다. 원래 `Box<Cat>` 참조를 가진 코드는 계속 다른 `Cat`을 넣을 수 있다. [Kotlin 언어 명세: 변성](https://kotlinlang.org/spec/type-system.html#mixed-site-variance)

## 4. `Supplier<out T>`에 적용하기

Java 표준 라이브러리의 `Supplier<T>`는 `get()`으로 결과를 제공하는 인터페이스다. Kotlin에서는 람다로 구현할 수 있다. 호출할 때마다 새 객체를 만들거나 같은 객체를 반환해야 한다는 보장은 없다. [Java 공식 문서: Supplier](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/function/Supplier.html)

```kotlin
import java.util.function.Supplier

val catSupplier: Supplier<Cat> = Supplier { Cat() }
val cat: Cat = catSupplier.get()

fun obtainAnimal(source: Supplier<out Animal>): Animal = source.get()

val suppliedAnimal: Animal = obtainAnimal(catSupplier)
```

이 예제의 `Animal`과 `Cat`은 앞에서 정의한 클래스다. `Supplier<Cat>`이 주는 값은 항상 `Animal`로 다룰 수 있으므로 `obtainAnimal`에 전달해도 안전하다.

Java의 `Supplier<T>`는 타입 매개변수에 선언부 공변성이 없으므로, `Supplier<Cat>`을 `Supplier<Animal>`로 직접 대입할 수는 없다. `Supplier<out Animal>`로 받으면 하위 타입 공급자를 허용하면서 결과를 `Animal`로 읽을 수 있다. 이런 방향의 타입 호환을 **공변성(covariance)**이라고 한다. Java의 `? extends T`에 해당하는 Kotlin 표현이 사용 지점의 `out T`다. [Kotlin 공식 문서: 변성과 Java 와일드카드](https://kotlinlang.org/docs/generics.html#variance-and-wildcards-in-java)

## 5. `Supplier<out Authentication?>` 읽어 보기

`Authentication`은 인증 정보를 나타내는 타입이라고 가정하자. 비밀번호 인증이나 다른 인증 방식은 이 타입의 구현체가 될 수 있다.

| 문법 요소 | 의미 |
| --- | --- |
| `Supplier<...>` | `get()`으로 값을 제공하는 객체 |
| `Authentication` | 인증 정보의 공통 타입 |
| `Authentication?` | 인증 정보 또는 null |
| `out Authentication?` | 구체적인 하위 타입의 공급자도 허용하고, 결과를 `Authentication?`로 다룸 |

다음은 외부 라이브러리 없이 실행할 수 있는 독립적인 예제다. `Authentication`과 구현체를 학습용으로 직접 정의했다.

```kotlin
import java.util.function.Supplier

interface Authentication {
    val isAuthenticated: Boolean
}

data class PasswordAuthentication(
    override val isAuthenticated: Boolean,
) : Authentication

fun isAuthenticated(source: Supplier<out Authentication?>): Boolean {
    val current: Authentication = source.get() ?: return false
    return current.isAuthenticated
}

fun main() {
    val specific: Supplier<PasswordAuthentication> =
        Supplier { PasswordAuthentication(isAuthenticated = true) }

    val unauthenticated: Supplier<Authentication?> =
        Supplier { PasswordAuthentication(isAuthenticated = false) }

    val absent: Supplier<Authentication?> = Supplier { null }

    println(isAuthenticated(specific))        // true
    println(isAuthenticated(unauthenticated)) // false
    println(isAuthenticated(absent))          // false
}
```

함수는 구체적인 `PasswordAuthentication` 공급자와 nullable 공통 타입 공급자를 모두 받는다. 이 예제는 인증 여부만 확인하며, 업무별 접근 권한 판단은 별개의 문제다.

## 6. `out`과 `?`는 서로 다른 역할이다

| 선언 | 하위 타입 공급자 허용 | Kotlin에 표현한 결과의 null 허용 |
| --- | --- | --- |
| `Supplier<Authentication>` | 불변성에 따라 제한 | 허용하지 않음 |
| `Supplier<Authentication?>` | 불변성에 따라 제한 | 허용 |
| `Supplier<out Authentication>` | 허용 | 허용하지 않음 |
| `Supplier<out Authentication?>` | 허용 | 허용 |

이 표는 타입 인자를 명시한 참조 사이의 호환 관계를 비교한다. 람다를 전달할 때는 기대 타입을 바탕으로 공급자의 타입을 추론할 수 있으므로, 람다 전달이 성공했다는 사실만으로 불변성을 판단하지 않는다.

`Supplier<out Authentication?>`에서는 공급자 객체 자체는 null이 아니지만 공급 결과는 null일 수 있다. 공급자 자체도 null일 수 있게 하려면 바깥에 `?`를 붙인 `Supplier<out Authentication?>?`가 된다. [Kotlin 공식 문서: nullable 타입](https://kotlinlang.org/docs/null-safety.html#nullable-types-and-non-nullable-types)

null 허용 여부는 Kotlin에 표현한 계약이다. Java 코드와 함께 사용할 때는 플랫폼 타입과 nullability 어노테이션도 확인해야 한다. 특히 Java 와일드카드만으로는 Kotlin의 `?`까지 표현되지 않는다. [Kotlin 공식 문서: Java와 null 안전성](https://kotlinlang.org/docs/java-interop.html#null-safety-and-platform-types)

## 7. 선언부에 붙이는 `out`과의 차이

직접 인터페이스를 설계한다면 타입 매개변수를 선언할 때 `out`을 지정할 수도 있다.

```kotlin
interface Source<out T> {
    fun get(): T
}

fun readSource(source: Source<Animal>): Animal = source.get()

fun demonstrate(source: Source<Cat>) {
    readSource(source) // 선언 자체가 공변적이므로 사용 지점의 out이 필요 없다.
}
```

`Source<out T>`는 **선언 지점 변성(declaration-site variance)**이다. 타입 설계자가 공변성을 선언한다. `Supplier<out Animal>`은 기존 타입을 사용하는 코드가 프로젝션을 적용한 것이다. `Source` 예제의 `Animal`과 `Cat`은 앞에서 정의한 클래스다. [Kotlin 공식 문서: 선언 지점 변성](https://kotlinlang.org/docs/generics.html#declaration-site-variance)

함수 선언의 매개변수 안에 `Supplier<out T>`가 있다고 해서 선언 지점 변성이 되는 것은 아니다. `out`이 클래스·인터페이스의 타입 매개변수 선언에 붙었는지, 기존 제네릭 타입의 사용에 붙었는지로 구분한다.

반대 방향으로 값을 받는 역할에는 `in`을 사용한다. `Consumer<in Cat>`처럼 쓰면 `Cat`을 처리할 수 있는 `Consumer<Animal>`도 받을 수 있다. 이런 호환 관계를 반공변성(contravariance)이라고 한다. 타입별로 어느 방향의 관계를 허용할지는 값을 제공하는지, 받는지에 따라 결정한다. [Kotlin 언어 명세: 변성](https://kotlinlang.org/spec/type-system.html#mixed-site-variance)

## 8. Java 문법과 비교하기

제네릭의 하위 타입 허용 관계만 비교하면 다음과 대응한다.

```kotlin
// Kotlin
Supplier<out Authentication>
```

```java
// Java
Supplier<? extends Authentication>
```

Kotlin의 `Authentication?`까지 Java 코드로 표현하려면 Java 라이브러리의 nullability 어노테이션 계약을 별도로 봐야 한다. 위 대응은 와일드카드와 프로젝션의 관계를 보여준다. [Kotlin 공식 문서: Java 제네릭](https://kotlinlang.org/docs/java-interop.html#java-generics-in-kotlin)

## 코드를 읽을 때 확인할 질문

- `out`이 타입 선언에 있는가, 사용 지점에 있는가?
- 공급자가 제공할 수 있는 구체적인 하위 타입은 무엇인가?
- 결과의 null 가능성은 어디의 `?`로 표현되어 있는가?
- 호출하는 쪽은 결과를 공통 타입으로만 다루고 있는가?
- 재정의하는 Java API가 있다면 와일드카드와 nullability 계약을 함께 확인했는가?
