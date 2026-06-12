# abstract class

```kotlin
abstract class Student(
    protected val name: String,
    protected val sex: Sex,
    protected open val role: Role
) {
    abstract fun act()
}

enum class Sex {
    MALE, FEMALE
}

enum class Role {
    NORMAL, CLASS_PRESIDENT, COUNCIL, PRESIDENT
}

class Jewoo(
    var grade: Grade,
    var age: Int
) : Student("Jewoo", MALE, Role.NORMAL) {
    override fun act() {
        println("저는 ${this.age}살 ${super.name}이고 ${this.grade.description}학년입니다.")
    }

    override val role: Role
        get() = if (grade == Grade.THIRD)
            CLASS_PRESIDENT
        else
            COUNCIL
}

enum class Grade(description: String) {
    FIRST("1학년"), SECOND("2학년"), THIRD("3학년");

    val description: String
        get() = description
}
```

- 상속 명시에 대한 관습
  - 타입을 쓸 땐 띄워쓰지 않고 `:`
  - 상속을 명시할 땐 띄어 써서 ` :`
- 어떤 클래스를 상속받을 때 무조건 상위 클래스의 생성자를 바로 호출해줘야 한다.
- 추상이 아닌 프로퍼티를 override하려면 상위 클래스에서 open 키워드를 사용해야 한다.
  - 코틀린의 class와 프로퍼티, 그리고 멤버 함수는 기본적으로 final 이기 때문이다.

# interface
- default method
  - JDK 8부터 넣을 수 있게 된 기본 메서드
  - 인터페이스에서 구현이 가능함
  - 코틀린에서는 default 키워드를 생략할 수 있음

```java
public final class Jewoo extends Student implements RollOut, Doze {
    @Override
    public void introduce() {
        Rollout.super.act();
        Doze.super.act();
    }
}
```
위 자바 코드를 코틀린 코드로 옮기면 아래와 같다.
```kotlin
class Jewoo(
    var grade: Grade,
    var age: Int
) : Student("Jewoo", MALE, Role.NORMAL), RollOut, Doze {
    override fun act() {
        super<Rollout>.act() // 중복되는 인터페이스를 특정할 때 super<타입>.함수()
        super<Doze>.act()
    }
}

interface RollOut {
    fun act() {
        println("저 발표하겠습니다!")
    }
}

interface Doze {
    fun act() {
        println("아... 정신이 혼미해진다...")
    }
}
```

- 코틀린에서는 backing field가 없는 프로퍼티를 Interface에 만들 수 있다.

```kotlin
interface Doze {
    val desireScore: Int
}
```
위의 `desireScore`라는 프로퍼티는 인터페이스 안에 있는 필드가 아니라 구현체에서 getter를 구현해주길 기대하는 명세가 된다. 그리고 해당 프로퍼티는 인터페이스 내에서 구현해줄 거라 믿고 default method 안에서 사용할 수 있다.

```kotlin
class Jewoo(
    var grade: Grade,
    var age: Int
) : Student("Jewoo", MALE, Role.NORMAL), RollOut, Doze {
    override fun act() {
        super<Rollout>.act() // 중복되는 인터페이스를 특정할 때 super<타입>.함수()
        super<Doze>.act()
    }
    override val desireScore: Int
        get() = 100
}

interface Doze {
    val desireScore: Int
      get() = 3 // 인터페이스 안에서도 구현할 수 있다. 이게 default 값이 되는 것이다.
    
    fun act() {
        println(desireScore)
    }
}
```
이는 인터페이스에 만드는 프로퍼티는 getter 메소드를 default method로 만들거나 추상 메서드로 만드는 것이라 backing field없는 프로퍼티가 된다.

# 상속 사용 시 유의사항
상위 클래스의 생성자나 init 블럭 안에서 하위 클래스의 프로퍼티에 접근하지 말아야 한다. 하위 클래스가 상위 클래스의 프로퍼티를 오버라이드 하는 구조라면 상위 클래스의 프로퍼티에도, 하위 플래스의 프로퍼티에도 접근하지 못하고 해당 타입의 초기 기초값이 되기 때문이다. 다시 말해, 초기화가 이루어지지 않게 된다.

따라서 첫 문장은 "상위 클래스의 생성자나 init 블럭 안에서 final이 아닌 프로퍼티에 접근하지 않아야 한다." 혹은 "상위 클래스를 설계할 때 생성자 또는 초기화 블록에서 사용되는 프로퍼티에는 open을 피해야 한다." 라는 표현이 될 수 있다.

