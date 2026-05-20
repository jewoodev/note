# 클래스와 프로퍼티
- 기본으로 설정되는 접근제어자가 public이다. 이는 함수와 동일하다.
- 자바와 다르게 프로퍼티를 자동으로 생성해준다.
  - 여기서 말하는 프로퍼티는 필드 + getter/setter 를 말한다.

# 생성자와 init
- 코틀린은 바디가 아니라 클래스 이름의 바로 옆에 constructor 이름으로 괄호를 열어 생성자를 정의한다.
  - constructor는 생략 가능하다.
  - 생성자를 선언할 때 프로퍼티를 함께 선언할 수 있다.
- `.필드`로 getter/setter를 호출한다.
  - 자바 클래스를 코틀린에서 가져다 쓰더라도 이는 동일하게 사용 가능하다.
- 자바의 생성자 안에 작성할 수 있는 검증 로직은 코틀린에서는 `init` 블록 안에 작성하면 된다.
- 주 생성자(primary constructor) 외에 추가로 생성자(부 생성자, secondary constructor)를 정의하려면 바디에 `constructor` 키워드를 사용해 선언한다.
  - 주 생성자는 반드시 존재해야 한다. 
    - 필드가 하나도 존재하지 않는 클래스는 굳이 정의해주지 않아도 자동으로 생성된다.
  - 부 생성자는 있어도 되고 없어도 된다.
  - 부 생성자는 최종적으로 주 생성자를 호출해야 한다.
  - 부 생성자는 바디를 가질 수 있다.
  - converting이 필요할 땐 부 생성자를 사용할 수도 있지만, 그보단 정적 팩토리 메서드가 권장된다.

# 커스텀 getter/setter
- 코틀린에서는 클래스의 필드로의 연산을 하나의 프로퍼티가 있는 것처럼 만드는 커스텀 getter/setter를 정의할 수 있다.

```kotlin
// 예시
class StudyCafe(
  val maxCapacity: Int,
  var curUserCount: Int
) {
    val isFull: Boolean
        get() = curUserCount == maxCapacity 
}
```

- 커스텀 getter/setter vs 함수
  - 객체의 속성이라면 전자, 아니면 후자를 사용하는게 권장된다.

# backing field

```kotlin
class ArrogantStudyCafe(
  maxCapacity: Int, // getter/setter 를 자동으로 만들지 않게 하려면, var/val을 제거하자.
  var curUserCount: Int
) {
    val maxCapacity = maxCapacity // 생성자로 넘어온 인수가 대입됨
        get() = maxCapacity * 10
    
    val isFull: Boolean
        get() = curUserCount == maxCapacity 
}
```
이렇게 작성하면 무한루프에 빠지게 된다. 왜냐면 내부이건 외부이건 field를 호출하면 내부적으로 getter를 호출하기 때문이다. 즉, 외부에서 maxCapacity를 호출하면 내부적으로 getter를 호출하게 되는데, 이 getter는 maxCapacity를 호출하기 때문에 무한루프에 빠지게 된다.

```kotlin
class ArrogantStudyCafe(
  maxCapacity: Int,
  var curUserCount: Int
) {
  val maxCapacity = maxCapacity 
    get() = field * 10 // backing field

  val isFull: Boolean
    get() = curUserCount == maxCapacity
}
```
위의 `field`는 그런 무한루프를 막기 위한 '필드 자기 자신을 가리키는 예약어'이다. 이를 "자기 자신을 가리키는 보이지 않는 필드다." 라고 해서 backing field라고 부른다.

# 커스텀 setter
```kotlin
class ArrogantStudyCafe(
  maxCapacity: Int, 
  var curUserCount: Int
) {
    val maxCapacity = maxCapacity 
        set(value) = value * 10
    
    val isFull: Boolean
        get() = curUserCount == maxCapacity 
}
```
