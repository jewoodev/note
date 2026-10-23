# Kotlin의 `by`: 인터페이스 구현을 다른 객체에 위임하기

Kotlin에서 `object : SomeInterface by existingObject { ... }`는 **익명 객체를 만들면서, 인터페이스의 기본 동작을 기존 객체에 맡기고 필요한 동작만 재정의하는 문법**이다. 이 문서는 특정 프로젝트나 프레임워크 없이 이해할 수 있도록 메모 저장소를 예로 사용한다.

## 1. 먼저 알아둘 두 가지

인터페이스는 객체가 제공해야 할 기능을 정의하는 계약이다. 다음 저장소는 문자열을 저장하고 조회하는 두 기능을 제공한다.

```kotlin
interface NoteStore {
    fun save(id: String, text: String)
    fun find(id: String): String?
}

class InMemoryNoteStore : NoteStore {
    private val notes = mutableMapOf<String, String>()

    override fun save(id: String, text: String) {
        notes[id] = text
    }

    override fun find(id: String): String? = notes[id]
}
```

`String?`는 조회 결과가 문자열이거나 `null`일 수 있다는 뜻이다. 여기서는 없는 메모를 조회하면 `null`을 반환한다.

익명 객체는 별도의 클래스 이름을 붙이지 않고 `object { ... }` 표현식으로 만드는 객체다. `object : NoteStore { ... }`라면 `NoteStore`를 구현하는 익명 객체가 된다. `val store = object ...`에서 `store`는 객체를 참조하는 변수 이름이며 클래스 이름이 아니다. 이 표현식은 이름 있는 싱글턴을 정의하는 `object Store { ... }` 선언과 구분한다. [Kotlin 공식 문서: Object expressions](https://kotlinlang.org/docs/object-declarations.html#object-expressions)

## 2. `by`가 필요한 상황

기존 저장소의 조회 기능은 그대로 쓰고, 저장할 때만 추가 동작을 수행하고 싶다고 하자. 직접 구현하면 조회 함수에도 전달 코드를 작성해야 한다.

```kotlin
val original: NoteStore = InMemoryNoteStore()

val wrapper = object : NoteStore {
    override fun save(id: String, text: String) {
        println("저장 요청")
        original.save(id, text)
    }

    override fun find(id: String): String? = original.find(id)
}
```

인터페이스 위임을 사용하면 다음처럼 쓸 수 있다. 앞의 코드와 비교하기 위한 별도 코드 조각이다.

```kotlin
val original: NoteStore = InMemoryNoteStore()

val wrapper = object : NoteStore by original {
    override fun save(id: String, text: String) {
        println("저장 요청")
        original.save(id, text)
    }
}
```

`by original`을 지정하면 직접 재정의하지 않은 인터페이스 멤버의 호출을 `original`로 전달하는 구현을 컴파일러가 생성한다. 따라서 여기서는 `find`를 반복해서 작성하지 않아도 된다. 직접 작성한 `override save`가 우선하므로, 원래 저장도 수행하려면 그 안에서 `original.save(...)`를 명시적으로 호출해야 한다. [Kotlin 공식 문서: Delegation](https://kotlinlang.org/docs/delegation.html)

## 3. 한 줄을 나누어 읽기

```kotlin
val wrapper = object : NoteStore by original {
    // 필요한 멤버만 override
}
```

| 부분 | 의미 |
| --- | --- |
| `val wrapper =` | 생성한 객체의 참조를 변수에 저장한다. |
| `object` | 익명 객체를 만드는 표현식을 시작한다. |
| `: NoteStore` | 이 객체가 `NoteStore` 인터페이스를 구현한다. |
| `by original` | 직접 구현하지 않은 인터페이스 멤버를 `original`에 위임한다. |
| `{ ... }` | 새 객체에 필요한 멤버와 재정의를 작성한다. |

`original`은 해당 인터페이스를 구현하는 객체여야 한다. 새 객체는 `original`의 복제본이 아니며, 원래 클래스의 구현을 상속하는 것도 아니다. 위임 대상에 대한 참조를 사용해 호출을 전달한다. 이름 있는 클래스에서도 `class NoteStoreWrapper(delegate: NoteStore) : NoteStore by delegate`처럼 쓸 수 있다. [Kotlin 언어 명세: Inheritance delegation](https://kotlinlang.org/spec/declarations.html#inheritance-delegation)

## 4. 저장은 성공했지만 호출자는 오류를 받은 상황 만들기

다음 예제는 첫 번째 절의 `NoteStore`와 `InMemoryNoteStore` 선언과 함께 실행할 수 있다.

```kotlin
class StorageAcknowledgementLostException :
    RuntimeException("저장 결과를 확인하지 못했습니다")

fun main() {
    val original: NoteStore = InMemoryNoteStore()

    val lossy = object : NoteStore by original {
        override fun save(id: String, text: String) {
            original.save(id, text)
            throw StorageAcknowledgementLostException()
        }
    }

    try {
        lossy.save("note-1", "회의 기록")
    } catch (_: StorageAcknowledgementLostException) {
        println("호출자는 오류를 받았습니다")
    }

    println(original.find("note-1"))
    println(lossy.find("note-1"))
}
```

예상 출력:

```text
호출자는 오류를 받았습니다
회의 기록
회의 기록
```

`lossy.save(...)`는 먼저 실제 저장소에 값을 쓴 뒤 예외를 던진다. 호출자는 오류를 받지만 저장된 값은 남는다. 예외를 던지는 것만으로 메모리 변경이 취소되지는 않는다.

`lossy.find(...)`는 재정의하지 않았으므로 `original.find(...)`로 전달된다. 두 조회는 같은 저장소의 값을 읽는다.

이 패턴은 “서버에서는 쓰기가 성공했지만 응답이 유실됐다”는 상황에 대한 호출자 동작을 테스트할 때 유용하다. 다만 위 예제는 메모리 저장과 예외 주입으로 상황을 모사하며 실제 네트워크 장애를 발생시키지는 않는다. 저장 전에 예외를 던지는 구현과도 구분해야 한다. 그 경우에는 저장 자체가 수행되지 않는다.

## 5. 호출 경로에서 주의할 점

```text
lossy.save(...) → 익명 객체의 override → original.save(...) → 예외
lossy.find(...) → 컴파일러가 생성한 전달 코드 → original.find(...)
```

위임 대상 내부의 호출까지 새 객체의 `override`를 거치는 것은 아니다. 예를 들어 `original`의 어떤 함수가 내부에서 자신의 `save()`를 호출한다면, 그 호출은 `original`의 구현을 사용한다. 새 객체가 원래 객체의 모든 호출을 가로채는 구조로 이해하면 안 된다. [Kotlin 공식 문서: 위임한 멤버의 재정의](https://kotlinlang.org/docs/delegation.html#overriding-a-member-of-an-interface-implemented-by-delegation)

또한 위임은 동기화·재시도·트랜잭션을 자동으로 추가하지 않는다. 그러한 동작이 필요하면 위임 대상이나 재정의한 함수에서 별도로 구현해야 한다.

## 6. `by lazy`와의 차이

두 문법 모두 `by`를 쓰지만 위임하는 대상이 다르다.

| 문법 | 위임하는 것 |
| --- | --- |
| `object : NoteStore by original` | 인터페이스 멤버의 구현 |
| `val message by lazy { "hello" }` | 프로퍼티 값을 얻는 동작. `lazy`는 최초 접근 때 계산하고 결과를 보관한다. |

인터페이스 뒤의 `by`를 프로퍼티의 지연 초기화 문법으로 해석하지 않도록, `by`가 쓰인 위치를 함께 읽는다. [Kotlin 공식 문서: Delegated properties](https://kotlinlang.org/docs/delegated-properties.html)
