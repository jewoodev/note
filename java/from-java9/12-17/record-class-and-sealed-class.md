# Record Class
java 14에서 미리보기로 등장했으며 16에서 정식 기능으로 포함되었다. 이 클래스는 데이터 전달을 위한 클래스이다. 이 클래스의 특징은 다음과 같다..

- class에 final이 선언되어 있어 다른 클래스에서 상속할 수 없다.
- private final 필드만 선언되어 있다.
- 모든 private final 필드에 대해 생성자가 존재한다.
- 클래스가 갖고 있는 모든 필드에 대해 접근할 수 있는 메서드가 있고, 그 메서드의 이름은 필드 이름과 같다.
- 다른 클래스를 상속받을 수 없다.
  - enum이 Enum.class를 상속하고 있듯이 Record.class를 상속하고 있어서 그렇다.
- 인터페이스는 구현 가능하다.
- static 필드, static 함수, 인스턴스 함수를 만들 수 있다.
- 인스턴스 필드는 만들 수 없다(컴포넌트에만 선언 가능). 
- 자동 생성되는 메서드들을 재정의하는게 가능하다.

```java
public record Person(
        String name, int age // 이 괄호 안에 들어가는 하나 하나의 요소들이 '컴포넌트'라는 명칭으로 불림
) {
}
```

## compact constructor
만약 생성자에 관련해 단순히 값을 검증하려는 목적이 있다면 생성자 대신 compact constructor를 사용할 수 있다. compact constructor는 Java 문법을 최소화하면서 생성자 안의 로직을 추가적으로 집어넣는 기능이다.  

```java
public record Person(
        String name, int age // 이 괄호 안이 '컴포넌트'라는 명칭으로 불림
) {
    public Person {
        if (age < 0) {
            throw new IllegalArgumentException("age must be positive");
        }
    }
}
```
이 기능은 매개변수를 전혀 받지 않아 문법적으로 매우 간결하다. 그런데 필드에 값을 할당할 때 this를 사용할 수 없다.

## Record Class와 Annotation
레코드 클래스의 컴포넌트는 '클래스 안의 필드'이자 '생성자의 매개변수'이기도 하며 '필드에 접근하는 메서드'이기도 하다. 그래서 컴포넌트에 애노테이션을 붙이면 세 가지 모두에 애노테이션이 붙은 것으로 간주한다. 

만약 생성자의 매개변수에만 애노테이션을 붙이고 싶다거나 생성자의 매개변수에만 붙이고 싶다면 `@Target`이라는 meta annotation을 써서 타입을 지정함으로써 특정 언어요소를 지정하면 된다. 

## Record Class와 스프링 부트
이러한 레코드 클래스는 Jackson 2.12.0 부터 사용 가능하다.



# Sealed Class
자바 15 미리보기 -> 자바 17 정식 기능에 포함된 것이다. Sealed의 사전적 의미는 '봉인을 한'과 같은 뜻인데 어떤 클래스를 말하는 걸까? 또 다른 질문을 통해 Sealed Class를 알아보자.

Animal 클래스의 하위 클래스를 Dog와 Cat만 두고 싶을 때, 즉 하위 클래스를 제한하고 싶을 때 어떻게 해야될까? Sealed Class는 그런 제한을 하고 싶을 때 사용하는 기능을 갖고 있다.

```java
public sealed abstract class Animal permits Dog, Cat { // abstract 사용은 선택적
    
}

public final class Dog extends Animal { // 자식 클래스는 일반 클래스는 될 수 없고, final 이거나 sealed 이거나 non-sealed 가 되어야 한다.
    
}

public final class Cat extends Animal {}
```
자식 클래스가 취할 수 있는 타입 종류 중 final은 익히 알려진 대로 재상속을 불가능하게 만드는 키워드이다. 그래서 이를 사용하게 되면 "sealed class를 상속받은 final 하위 클래스는 다른 누군가가 다시 한 번 상속할 수 없다." 라는 뜻이 된다.

자식 클래스가 취할 수 있는 타입 종류 중 non-sealed는 final과 다르게 다른 클래스가 상속할 수는 있는 키워드이다. 근데 non-sealed class의 부모인 sealed class가 non-sealed class의 자식 클래스 타입은 추적할 수 없다는 특징이 있다.

## 자식 클래스의 위치 제한
- 만약 module.info.java를 사용하는 'named 모듈' 에 부모가 위치한다면 자식은 부모와 같은 모듈에 위치해야 한다. 다른 모듈에 있으면 부모를 상속받을 수 없다. 
- 만약 module.info.java를 사용하지 않는 'unnamed 모듈' 에 부모 클래스가 있다면 그땐 같은 패키지에 있어야 sealed 클래스를 부모로 상속받을 수 있다. 
- 한 파일 내에 부모와 자식이 모두 있다면 permits 키워드를 생략할 수 있다. 생략해도 sealed class의 상위 타입과 하위 타입 관계를 갖게 된다. 

## 장점
- 상위 클래스를 설계할 때 호환성 걱정을 덜 수 있다.
- enum class처럼 sealed class를 사용할 수 있다.

### enum class처럼 쓸 수 있다는 건 무슨 말일까?
enum class은 컴파일 타임에 어떤 하위 타입들이 있는지 모두 알기 때문에 switch expression을 쓸 때 enum 타입이 모든 케이스에 존재하면 default 케이스를 적지 않아도 괜찮아서 깔끔한 코딩이 가능한 장점이 있다.

sealed class 역시 switch pattern matching을 쓰면 enum class처럼 sealed class를 switch expression에서 동일하게 사용할 수 있다.

## Sealed Interface
sealed class와 개념적으로 동일하다. sealed interface를 구현할 특정 구현체들을 `permits` 키워드와 함께 제안할 수 있다. 

record class같은 경우는 인터페이스를 구현할 수 있기 때문에 sealed interface와 record class를 함께 사용하면 같은 부모를 갖는 여러 DTO 객체들을 한 번에 만들어서 관리할 수 있게 된다.