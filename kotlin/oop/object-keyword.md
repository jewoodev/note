# 선언

## companion object

자바의 정적 영역에 대응되는 이 동반 객체는 자바와는 달리 하나의 객체로 간주된다. 그래서 이름을 붙일 수도 있고, interface로 구현할 수도 있다. 

```kotlin
companion object Factory : FactoryInterface {}
```

companion object에 유틸성 함수를 정의하고 싶을 수 있지만, 최상단 파일에 정의하는 걸 권장한다. (이 또한 static 함수처럼 간주된다.)

만약 자바에서 코틀린의 companion object 명세를 사용하려면 companion object 블록에 @JvmStatic 어노테이션을 붙여야 한다.

### static 함수와 변수

코틀린에서는 static 함수와 변수를 object로 정의할 수 있다. 클래스 내에 companion object(동반 객체) 라는 키워드로 블럭을 열어 그곳에 위치시키면 static 이 붙은 것과 동일하게 사용할수 있다.

이곳에 변수를 정의하면 Warning이 발생한다. 그 이유는 정적 변수이기에, 런타임 시에 할당하지 말고 컴파일 시점에 할당하는게 더 좋기 때문이다. 앞에 `const` 키워드를 붙이면 상수를 지정하는 행위가 되어 컴파일 시점에 할당된다. 이는 기본 타입과 String에만 붙일 수 있다.

## 싱글톤
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

# 표현식

Kotlin에서 **이름 없는 클래스를 정의하면서 객체**를 만드는 문법은 object 표현식이다.

다만 인터페이스가 추상 메서드 하나만 가진 fun interface라면, SAM 변환으로 람다를 구현체처럼 사용할 수도 있다.

```kotlin
fun interface Task {
    fun run()
}

// object 표현식
val a = object : Task {
    override fun run() = println("실행")
}

// SAM 변환
val b = Task { println("실행") }
```

두 번째도 Task 구현체로 사용할 수 있지만, 문법적으로는 익명 객체 표현식이 아니라 람다를 이용한 SAM 변환입니다.

## by 인터페이스 위임

다음 문법은 **이름 없는 클래스의 객체를 만들면서, 인터페이스 구현을 기존 객체에 위임하고 일부 메서드만 바꾸는 방법**이다.

```kotlin
val wrapper = object : SomeInterface by original {
    override fun someMethod() {
        // 이 메서드만 직접 구현한다.
    }
}
```

기존 구현을 그대로 활용하면서 특정 호출에만 로깅이나 테스트용 대기를 추가할 때 사용할 수 있다. 아래에서는 프로젝트 지식 없이 읽을 수 있는 예제로 문법을 설명한 뒤, 실제 동시성 테스트에서 사용한 이유를 살펴본다.

## 1. 일반적인 예제로 읽기

문자열을 저장하고 조회하는 인터페이스와 구현체가 있다고 하자.

```kotlin
interface TextStore {
    fun read(key: String): String?
    fun write(key: String, value: String)
}

class MemoryTextStore : TextStore {
    private val values = mutableMapOf<String, String>()

    override fun read(key: String): String? = values[key]

    override fun write(key: String, value: String) {
        values[key] = value
    }
}

fun main() {
    val original = MemoryTextStore()

    val loggingStore = object : TextStore by original {
        override fun write(key: String, value: String) {
            println("저장 요청: $key")
            original.write(key, value)
        }
    }

    loggingStore.write("greeting", "안녕하세요")
    println(loggingStore.read("greeting"))
}
```

실행 결과는 다음과 같다.

```text
저장 요청: greeting
안녕하세요
```

`loggingStore.write(...)`는 직접 작성한 메서드를 실행한다. 로그를 출력한 뒤 실제 저장은 `original.write(...)`에 맡긴다. `read(...)`는 재정의하지 않았으므로 `original.read(...)`로 전달된다. 이 예제의 메모리 저장소는 문법 설명용이며 동시 접근을 제어하지 않는다.

## 2. 문법을 부분별로 나누기

```kotlin
val loggingStore = object : TextStore by original {
    override fun write(key: String, value: String) {
        println("저장 요청: $key")
        original.write(key, value)
    }
}
```

| 부분 | 의미 |
| --- | --- |
| `val loggingStore = ...` | 표현식의 결과인 객체를 지역 변수에 담는다. |
| `object { ... }` | 클래스 이름을 따로 선언하지 않고 객체를 만든다. |
| `: TextStore` | 생성한 객체가 `TextStore` 인터페이스를 구현한다. |
| `by original` | 인터페이스 구현을 기존 `original` 객체에 위임한다. |
| `override fun write(...)` | 위임받을 메서드 중 `write`는 직접 구현한다. |

`loggingStore`는 클래스 이름이 아니다. 이름 없는 클래스의 인스턴스를 가리키는 변수 이름이다. `original`과 `loggingStore`는 서로 다른 객체이고, 위임은 기존 객체의 코드를 수정하지 않는다.

직접 재정의한 메서드에서는 원래 구현을 자동 호출하지 않는다. 예제에서 `original.write(...)`를 지우면 로그만 출력하고 저장은 하지 않는다. 위임 대상은 부모 클래스가 아니므로 여기서는 `super.write(...)` 대신 `original.write(...)`로 호출한다.

이 설명은 Kotlin의 [인터페이스 구현 위임](https://kotlinlang.org/docs/delegation.html) 문법에 해당한다. `val value by lazy { ... }` 같은 프로퍼티 위임과는 적용 대상이 다르다.

## 3. by 없이 풀어 쓰면

위 객체는 동작 관점에서 다음과 같이 풀어 쓸 수 있다. 컴파일러가 정확히 이 소스 코드를 생성한다는 뜻은 아니다.

```kotlin
val loggingStore = object : TextStore {
    override fun read(key: String): String? {
        return original.read(key)
    }

    override fun write(key: String, value: String) {
        println("저장 요청: $key")
        original.write(key, value)
    }
}
```

`by`를 사용하면 변경하지 않을 메서드를 일일이 전달하는 코드를 줄일 수 있다. 반복해서 사용할 구현이라면 이름 있는 클래스로 추출할 수도 있다.

```kotlin
class LoggingTextStore(private val original: TextStore) : TextStore by original {
    override fun write(key: String, value: String) {
        println("저장 요청: $key")
        original.write(key, value)
    }
}
```

한 가지 주의할 점이 있다. 위임 대상 `original`의 메서드가 자기 내부에서 다른 메서드를 호출할 때는 `original`의 구현을 사용한다. 그 내부 호출까지 바깥 객체의 재정의로 바뀌는 것은 아니다. [Kotlin 위임의 재정의 동작](https://kotlinlang.org/docs/delegation.html#overriding-a-member-of-an-interface-implemented-by-delegation)

## 4. 실제 테스트의 40행은 무엇을 하는가

설명의 출발점은 다음 테스트 코드다. 줄 번호는 이후 변경될 수 있다.

출처: [ReceivablesReportExecutionServiceTest.kt](../../backend/src/test/kotlin/com/icar/aicounselor/reporting/application/service/ReceivablesReportExecutionServiceTest.kt)의 `racing triggers create only one execution owner` 테스트.

```kotlin
val barrier = CyclicBarrier(2)
val racingStore = object : ReceivablesReportExecutionStore by store {
    override fun createIfAbsent(execution: ReceivablesReportExecution): Boolean {
        barrier.await(5, TimeUnit.SECONDS)
        return store.createIfAbsent(execution)
    }
}
```

이름이 긴 타입들은 다음 정도로 이해하면 충분하다.

| 이름 | 역할 |
| --- | --- |
| `ReceivablesReportExecution` | 보고서 생성 작업의 현재 상태를 담은 값 |
| `ReceivablesReportExecutionStore` | 상태 조회·최초 생성·조건부 갱신을 제공하는 저장소 인터페이스 |
| `store` | 테스트에서 사용하는 기존 메모리 저장소 객체 |
| `createIfAbsent` | 같은 작업의 기록이 없을 때만 생성하고, 성공 여부를 반환하는 메서드 |
| `racingStore` | 생성 직전에 대기를 추가한 저장소 구현 객체 |

이 테스트는 두 요청이 같은 작업을 동시에 시작하려 해도, 하나만 실행 권한을 얻는지 확인한다.

`CyclicBarrier(2)`는 두 스레드가 지정한 지점에 도착할 때까지 기다리게 하는 동기화 도구다. 첫 번째 스레드는 `await(...)`에서 대기한다. 두 번째 스레드도 도착하면 대기가 풀리고 둘 다 다음 코드로 진행할 수 있다. 여기서는 최대 5초를 기다리며, 상대가 도착하지 않으면 테스트가 실패하도록 제한을 둔다.

```text
요청 A: 작업 없음 확인 → 생성 직전 대기 ─┐
                                      ├→ 두 요청이 생성 경쟁
요청 B: 작업 없음 확인 → 생성 직전 도착 ─┘
```

정확히 같은 CPU 시각에 실행하게 만드는 것은 아니다. 두 요청이 모두 생성 직전까지 도달하도록 해, 단순히 요청을 순서대로 실행하는 테스트가 되지 않게 한다.

대기가 끝나면 실제 생성은 기존 `store.createIfAbsent(...)`가 수행한다. 테스트의 메모리 저장소는 동기화된 메서드로 존재 여부 검사와 생성을 함께 처리하므로, 하나만 성공하고 다른 하나는 이미 존재한다는 결과를 받는다. **중복 생성 방지는 barrier가 아니라 저장소가 보장한다.**

따라서 `racingStore`의 목적은 저장소 로직을 새로 만드는 것이 아니라, 기존 구현 앞에 경쟁 상황을 만드는 대기를 덧붙이는 것이다. 재정의하지 않은 `find`와 `replace`는 `by store`에 의해 기존 저장소로 위임된다.

## 5. 키워드·선언·표현식 구분

키워드는 언어가 특별한 의미로 정한 단어이고, 선언과 표현식은 문법 구조다. 같은 `object` 키워드가 다른 구조에서 쓰일 수 있다.

| 구분 | 예 | 의미 |
| --- | --- | --- |
| 키워드 | `object` | 객체 관련 문법에 사용하는 단어 |
| object 표현식 | `val x = object : TextStore { ... }` | 표현식을 평가할 때 이름 없는 클래스의 객체 생성 |
| object 선언 | `object DefaultStore { ... }` | 이름 있는 싱글턴 객체 선언 |
| 동반 객체 선언 | `companion object { ... }` | 클래스 내부의 동반 객체 선언 |

`object` 표현식은 평가될 때마다 새 객체를 만든다. 반면 이름 있는 `object` 선언은 싱글턴 객체를 정의한다. `companion object`도 선언이며, 이름을 생략하면 기본 이름은 `Companion`이다. [Kotlin 객체 선언과 표현식](https://kotlinlang.org/docs/object-declarations.html)

```kotlin
class Report {
    companion object {
        const val VERSION = 1
    }
}

// Report.VERSION 또는 Report.Companion.VERSION으로 접근한다.
```

`val x = object { ... }`에서는 오른쪽이 객체 표현식이고, 전체는 `x`의 선언이다. 함수 내부라면 지역 변수 선언, 클래스나 파일 수준이라면 프로퍼티 선언에 해당한다.

## 6. 람다로 바꿀 수 있는가

추상 메서드가 하나인 Kotlin `fun interface`는 SAM 변환으로 람다를 구현체처럼 사용할 수 있다.

```kotlin
fun interface Task {
    fun run()
}

val task = Task { println("실행") }
```

이는 `object` 표현식과 다른 문법이다. `ReceivablesReportExecutionStore`에는 추상 메서드가 세 개 있으므로 이 방식으로 대체할 수 없다. 일부 메서드만 바꾸고 나머지는 기존 구현에 맡기는 현재 테스트에는 `object : Interface by delegate`가 적합하다. [Kotlin 함수형 인터페이스와 SAM 변환](https://kotlinlang.org/docs/fun-interfaces.html)
