자프링에서는 보통 엔티티의 필드를 정의할 때 private로 외부로의 필드의 노출을 
막고, 롬복 어노테이션을 통해 getter나 setter를 제공하여 해당 메서드를 통해 접근할 수 있도록 하여 객체지향적인 특성을
 만족시켜 주었다.

![image.png](../../blog-img/kotlin/JPA-캡슐화-유지하는-방법/image.png)

https://github.com/spring-guides/tut-spring-boot-kotlin#persistence-with-jpa

그러나 Spring 공식문서를 살펴보면, 코프링의 Entity를 설계할 때는 private와 같은 접근제어자를 사용하지 않는다.

따라서 왜 private 접근제어자를 사용하지 않는지, 그렇다면 어떻게 객체지향적인 특성을 만족하면서 설계할 수 있는지에 대해 알아보고자 한다.

---

# 🔸Kotlin은 Field의 개념이 아닌 Property의 개념

![image.png](temp/image%201.png)

프로그래밍에서 필드(Field)와 프로퍼티(property)는 비슷해 보이지만 중요한 차이점이 있다.

## 1️⃣ Field

```java
public class Car {
    private final String name;
    private final Integer distance;
    public Car(String name, Integer distance){
        this.name = name;
        this.distance = distance;
    }
}
```

우선 우리가 흔히 사용하는 java에서는 위의 코드에서 name과 distance의 변수들은 field의 개념으로 접근한다.

즉, 위에서 다루는 클래스의 상태를 나타내는 **field는 값 그 자체**이다.

따라서 해당 field를 private로 접근제어자를 설정하여 Entity의 상태를 외부로 노출시키지 않고, getter나 setter를 통해 접근하는 것이 객체지향적인 특성 중 캡슐화를 지키며 설계할 수 있다.

---

## 2️⃣ Property

```kotlin
class Car(
    val name: String, // 불변 변수
    var distance: Int
)
```

반면, kotlin에서는 field의 개념이 아닌 property의 개념이다.

![image.png](temp/image%202.png)

> https://kotlinlang.org/docs/properties.html#getters-and-setters
> 

코틀린의 공식문서를 살펴보면 field라는 용어 대신 Property라는 용어를 사용하는 것을 볼 수 있다.

그렇다면 Field와 Property의 차이점은 무엇일까?

## 🔹 Property란?

> 프로퍼티(Property)는 객체의 속성(값)을 다룰 때 사용하는 개념으로,
>
> **필드(Field)를 감싸고 Getter(읽기)와 Setter(쓰기)를 통해 제어할 수 있도록 만든다.**
 

위의 예시로 다시 돌아와 만약 위의 코드를 자바로 디컴파일 하면 어떻게 될까?

```kotlin
public class Car {
    private final String name; // final 필드 (Setter 없음)
    private int distance;
    
    public Car(String name, int distance) {
        this.name = name;
        this.distance = distance;
		}
		
    public String getName() { // Getter만 존재
        return name;
    }

    public int getDistance() {
        return distance;
    }

    public void setDistance(int distance) { // distance만 Setter 있음
        this.distance = distance;
    }
}
```

위의 디컴파일 된 코드를 살펴보면 다음과 같은 결론을 내릴 수 있다.

- Kotlin에서 **var**을 사용하면 Java에서는 **final** 필드 + **getter**/**setter**가 자동 생성됨.
- Kotlin에서 **val**을 사용하면 Java에서 **getter**만 생성되고 setter는 없음.
- Kotlin의 **생성자는** Java에서도 일반적인 **public 생성자**로 변환됨.

> 💡 코틀린은 기본적으로 모든 클래스, 메서드, 프로퍼티가 final이다.
>

Kotlin에서는 프로퍼티 개념을 사용하여 불필요한 코드 작성을 줄이고, Getter와 Setter를 통해 필드를 간접적으로 조작하는 기능을 제공한다. 이러한 방식 덕분에 **Java로 디컴파일된 코드에서도 Entity는 우리가 원하는 캡슐화 상태를 유지**할 수 있어, 별도의 접근 제어자를 설정하지 않아도 객체를 안전하게 보호할 수 있다.

***그런데도 여전히 찝찝한 부분이 남는다.***

비록 필드 자체는 외부에 직접 노출되지 않지만, **프로퍼티를 통해 Entity의 상태가 그대로 외부에 공개**되므로 언제든지 쉽게 접근하고 변경할 수 있기 때문이다.

그렇다면 **더 세밀한 제어를 위해서는 어떻게 해야 할까?**

---

# 🔸Kotlin Entity를 객체지향적으로 설계해 보자

## 1️⃣ 접근 제어자 private로 선언하기

외부로 값을 노출시키지 않기 위해 가장 첫 번째로 떠오르는 방법이다.

```kotlin
@Entity
@Table(name = "user")
class User(
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0L,

    @Column(name = "email", nullable = false, unique = true)
    var email: String,

    @Column(name = "password", nullable = false)
    var pw: String,

    @Column(name = "name", nullable = false)
    var name: String,
)
```

위와 같은 User의 엔티티가 있다고 가정해 보자.

현재 위의 엔티티에서는 email, pw, name과 같은 컬럼들이 외부에 노출되어 쉽게 접근하고 변경될 수 있는 값들이다.

```kotlin
@Entity
@Table(name = "user")
class User(
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private var id: Long = 0L,

    @Column(name = "email", nullable = false, unique = true)
    private var email: String,

    @Column(name = "password", nullable = false)
    private var pw: String,

    @Column(name = "name", nullable = false)
    private var name: String,
)
```

**위와 같이 private로 접근제어자를 설정하면 어떻게 될까?**

이렇게 설정하면 이제 Entity 외부에서 접근을 할 수 없게 되고 값을 변경할 수도 없게 된다

```kotlin
fun getEmail =
        email;
```

따라서, 위와 같은 메서드를 정의함으로써 접근이나 변경이 필요한 변수에 대해서는 getter나 setter를 별도로 제공해줘야 한다.

***여기서 모순이 발생한다.***

### 1. Lombok을 지원하는 자바와 달리, Kotlin은 직접적으로 프로퍼티를 관리해야 한다

일단 첫 번째로, 코틀린은 **불필요한 코드 생성을 줄이는 것을 철학으로 하는 언어**이다. 하지만 이렇게 접근하거나 변경해야 하는 변수마다 일일이 getter나 setter를 지정하게 되면 코드가 너무 장황해진다.

자프링에서는 이러한 getter나 setter로 인해 코드가 길어지는 것을 방지하고자 롬복 어노테이션을 제공하지만, 코프링에서는 프로퍼티의 개념이기 때문에 **롬복 어노테이션이 제공되지 않는다**. 그래서 결과적으로 코드가 길어진다.

### 2. Kotlin의 프로퍼티는 컴파일 과정에서 Java 바이트코드로 변환된다

위에서도 다뤘듯이 코틀린은 프로퍼티의 개념이다. 그리코 코틀린은 컴파일 과정에서 자바 바이트 코드로 변환되어 실행되는데, 이때 **자바 디컴파일 과정에서 자동으로 getter와 setter가 생성**이 된다.

```kotlin
class User{
	...
    
    private Long getId() {
        return id;
    }

    private String getEmail() {
        return email;
    }

    private String getPw() {
        return pw;
    }
    
    ...
```

Kotlin에서 private으로 선언한 프로퍼티는 **private 한 getter와 setter**로 변환되었지만, 우리는 이를 다시 public으로 열어야 한다.

즉, 원래 Kotlin에서 의도적으로 private var로 선언하여 외부에서 접근을 막았음에도 불구하고, getter와 setter를 명시적으로 다시 만들어 public으로 열어야 하는 **불필요한 과정**이 발생한다. 이 과정은 Kotlin의 불필요한 코드를 줄이려는 철학과 맞지 않는다.

결국, Kotlin에서 객체의 캡슐화를 유지하면서도 **세밀한 제어를 가능하게 하려면, setter를 막고 getter만 제공하거나, 아예 객체의 상태를 불변(immutable)하도록 설계하는 방법을 고려해야 한다.**

---

## 2️⃣ val로만 변수를 지정?

```kotlin
@Entity
@Table(name = "user")
class User(
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0L,

    @Column(name = "email", nullable = false, unique = true)
    val email: String,

    @Column(name = "password", nullable = false)
    val pw: String,

    @Column(name = "name", nullable = false)
    val name: String,
)
```

다음으로 생각할 수 있는 부분은 var이 아닌 불변을 나타내는 var로 변수를 선언하는 것이다.

왜냐하면 우리가 고려하는 부분이 의도치 않게 setter가 외부로 노출되어 개발자들의
 실수로 인해 entity의 상태 값의 변화가 생기는 것이기 때문이다. 따라서 var이 아닌 val로 변수를 선언하게 되면 자바로
 디컴파일되는 과정에서 getter만 생성될 것이고 외부로부터의 엔티티가 의도치 않게 변경될 수도 있다는 문제점은 해결될 것이다.

그러면 변경할 값만 var로 두고, 변경되지 않을 고유의 값들은 val로 설정하면 문제가 금방 해결될 것처럼 보인다.

하지만 **이러한 접근방식은 JPA와 Hibernate 문서는 엔티티가 지켜야 하는 조건 3가지에 위배된다.**

우선 val로 정의하는 경우 자바에서 디컴파일 되었을 때를 다시 한번 살펴보자.

```kotlin
val email: String
```

위와 같은 변수를 자바로 디컴파일하면

```kotlin
private final String email;

public void getEmail(){
	return email;
}
```

**private final**로 선언된 필드가 생기게 된다.

### 🚨JPA & Hibernate 공식 문서 권장 사항

이때, **final 키워드가 문제가 되는 것**인데 다시 본론으로 돌아와 JPA와 Hibernate 문서가 요구하는 것을 살펴보자.

![image.png](temp/image%203.png)

> https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html#_requirements_for_entity_classes

JPA 공식문서에는 Entity를 설계할 때 위와 같은 조건을 제시하고 있다.

- Class는 final로 선언되어서는 안된다.
- Method를 final로 선언하면 안된다.
- Persistent Instance Variable(field)을 final로 선언하면 안된다.

즉, field값에 대해서 final로 선언하지 않는 것을 원칙으로 하고 있다.

![image.png](temp/image%204.png)

> https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#entity-pojo

그리고 Hibernate의 공식문서에도 비슷한 내용을 확인할 수 있다.

- Hibernate의 Lazy-Loading(지연 로딩) 기능은 엔티티를 프록시(proxy) 객체로 감싸서 필요할 때 데이터를 불러오도록 동작한다.
- 하지만 final 클래스를 사용하면 Hibernate가 프록시를 생성할 수 없기 때문에 Lazy-Loading을 사용할 수 없다.

**따라서 Hibernate에서는 final 클래스를 피하는 것이 좋다.**

- getter와 setter를 final로 선언하는 것도 지양해야 한다.

**Hibernate는 getter를 오버라이딩하여 프록시 객체를 만들고 lazy-loading을 수행하는데, final이면 이를 막아버리기 때문.**

- 성능 최적화(performance tuning)를 고려한다면 final 키워드를 피하는 것이 Hibernate와 더 잘 맞는다.

Hibernate는 Java 기반의 ORM(Object-Relational Mapping) 프레임워크로, 객체와 데이터베이스 사이의 매핑을 자동으로 수행하여 SQL을 직접 작성하지 않고도 데이터베이스를 조작할 수 있도록 도와주는 역할을 한다.


### 🔹지연로딩(Lazy-Loading)?

```kotlin
@Entity
class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY) // Lazy Loading 적용
    private List<Order> orders;
}
```

이때, 성능 최적화를 위해 엔티티를 프록시 객체로 감싸서 지연 로딩이라는 기능을 지원하는데, 이는 객체를 즉시 가져오지 않고 해당 데이터가 **실제로 필요할 때 로드하는 방식**이다. 즉 Lazy Loading은 **불필요한 데이터 로드를 방지하여 성능을 최적화**하는 데 기여한다.

[hibernate-orm/hibernate-core/src/main/java/org/hibernate/proxy/AbstractLazyInitializer.java at 8b021ac01f3a5d015d1db0ddd34fd687c
Hibernate's core Object/Relational Mapping functionality - hibernate/hibernate-orm
github.com](https://github.com/hibernate/hibernate-orm/blob/8b021ac01f3a5d015d1db0ddd34fd687c1cc7928/hibernate-core/src/main/java/org/hibernate/proxy/AbstractLazyInitializer.java#L31)

hibernate-orm의 **AbstractLazyInitializer.java**의 코드의 동작과정을 조금 더 상세하게 살펴보고자 한다.

Hibernate는 **지연 로딩(Lazy Loading)**을 구현하기 위해 엔티티를 직접 로드하지 않고 EntityManager.find 호출 시 데이터를 조회하지 않고 엔티티 클래스를 상속한 프록시 객체를 생성한다.

AbstractLazyInitializer는
 프록시 객체가 실제 엔티티에 대한 참조를 유지하고, 초기화되지 않은 상태에서 메서드 호출( (getter와 setter와 같은 
영속성 필드에 접근하는 메서드)이 발생하면 데이터베이스에서 해당 엔티티를 로드하여 참조를 갱신한다. **이후 프록시 객체는 모든 메소드 호출을 원본 엔티티에게 위임한다.**

따라서, Hibernate의 지연 로딩은 프록시 객체를 통해 실제 데이터 로드를 지연시키고, 필요한 시점에만 데이터베이스 접근을 수행하여 성능을 최적화하는 방식으로 동작하는 것을 살펴볼 수 있다.

### 🧐 val을 사용하면 지연로딩 중 문제가 될까?

사실 val로 Entity의 프로퍼티를 정의해도 JPA, Hibernate의 지연 로딩이 제대로 동작하는 것을 확인할 수 있다.

이유는 다음과 같이 세 가지이다.

### 1. jpa를 사용하기 위해 all-open 플러그인을 사용하기 때문에 var, val에 상관없이 open으로 동작한다.

Kotlin은 기본적으로 모든 클래스와 메서드가 final이므로, **JPA에서 프록시 객체를 생성할 수 있도록 Kotlin 엔티티 클래스를 open으로 만들어야 한다.**

이를 자동으로 처리해주는 것이 바로 **all-open 플러그인**이다.

위에서 지연로딩의 과정을 살펴보면 JPA에서는 엔티티 클래스를 상속하여 프록시 객체를 생성한다. 이때 엔티티 클래스가 open이어야 상속이 가능하다.

Kotlin에서는 기본적으로 모든 클래스가 final이므로, JPA를 사용할 경우 프록시 객체를 만들 수 없다.

이를 해결하기 위해 all-open 플러그인은 특정 어노테이션(@Entity, @MappedSuperclass, @Embeddable)이 붙은 클래스를 자동으로 open으로 변경한다.

### 2. 지연로딩은 원본 엔티티 생성 자체를 뒤로 미루는 방식이다.

```kotlin
User user = entityManager.find(User.class, 1L)
```

이 코드가 실행될 때, Hibernate는 **즉시 User 엔티티를 생성하는 것이 아니라, 프록시 객체를 생성**한다.

```kotlin
User userProxy = new HibernateProxy()  // 프록시 객체 생성
```

이 프록시 객체는 **실제 데이터에 접근하기 전까지는 값이 비어 있다.**

이후 getter 메서드인 user.getOrders()를 호출하면 Hibernate가 DB에서 데이터를 조회하여 원본 엔티티를 생성하고 참조를 업데이트한다.

**즉, val을 사용해도 Hibernate의 프록시는 원본 엔티티를 변경하는 것이 아니라, "실제 엔티티를 로딩하는 시점을 늦추는 방식"으로 동작하므로 불변성이 깨지지 않는다.**

### 3. Field Access vs Property Access

실제 엔티티를 로딩하는 시점에서 JPA의 접근방식에 따라 나뉘게 된다.

JPA에서 영속성 엔티티에 접근할 때 2가지 방식이 있다.

1. **Field Access**
    
    ![image.png](temp/image%205.png)
    
2. **Property Access**
    
    ![image.png](temp/image%206.png)
    

> https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#access


Hibernate의 공식문서에 따르면, **기본적으로 @Id 어노테이션이 붙는 위치에 따라 접근 방식이 달라진다**.

- **Field Access** : @Id 어노테이션이 **field**에 붙은 경우
- **Property Access** : @Id 어노테이션이 **getter**에 붙은 경우

![image.png](temp/image%207.png)

> https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html#_persistent_fields_and_properties_in_entity_classes


JPA 공식문서에서는 프로퍼티의 접근 방식일 경우 JavaBeans 컨벤션을 따라야 한다고 설명하고 있으며, private필드와 public 한 getter와 setter의 조합으로 프로퍼티를 표현해야 한다고 말하고 있다.

즉 프로퍼티에 접근하기 위해서는 반드시 setter가 있어야 하는데

*그러면 val은 setter가 생성되지 않으니 문제가 되는 거 아닌가?*

결론부터 말하자면 val을 사용해도 문제가 없다.

**코틀린은 프로퍼티의 개념을 사용하고 있지만 @Id 어노테이션으로 프로퍼티 변수에 접근할 때는 필드 접근 방식**이다.

```kotlin
@Entity
class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0L,  // 필드 접근 방식

    @Column(nullable = false)
    var name: String
)
```

위의 코드를 자바로 디컴파일 하게 되면 다음과 같은 결과를 얻는다.

```kotlin
@Entity
public class User {
    @Id  // 필드에 적용됨 (Field Access 방식)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    public Long getId() {
        return this.id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return this.name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

위와 같이 **@Id 어노테이션이 getter가 아닌 필드에 붙는 것**을 확인할 수 있다.

만약, 프로퍼티 접근 방식으로 설정하고 싶으면

```kotlin
@Entity
class User(
    @get:Id  // Getter에 @Id 적용 (Property Access 방식)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0L,

    @Column(nullable = false)
    var name: String
)
```

**@get:Id** 어노테이션을 활용하면 프로퍼티 접근 방식으로 접근이 가능하다.

(이때는 val을 사용해서는 안된다.)

**따라서 val을 사용해도 JPA는 필드 접근 방식이기 때문에 val을 사용해도 문제가 없다는 점**이다.

---

### 🧐그렇다면 val은 문제가 없는 거 아닐까?

**결론부터 말하자면 Hibernate 구현체에서"는" 문제가 없다.**

val을 다시 정리해 보자면,

val프로퍼티는 자바로 디컴파일 하면 field에 final이 붙고, setter가 생성되지 않는다는 점을 지니고 있다

이때, setter가 생성되지 않는 점은 필드 접근 방식이면 괜찮다고 언급했다.

하지만 final 필드의 경우에는 괜찮은 근거를 더 찾아봐야 한다.

![image.png](temp/image%208.png)

> https://github.com/hibernate/hibernate-orm/blob/b7038b2294eecd124e51e25dc6f48b0ad6c66d36/hibernate-core/src/main/java/org/hibernate/property/access/spi/SetterFieldImpl.java#L57
> 

우선 hibernate의 경우에는 내부적으로 **자바 리플렉션의 field.set**을 사용하기 때문에 final 필드의 값을 변경할 수 있다.

따라서 final 필드에 대해서는 문제가 없어 보이지만,

![image.png](temp/image%209.png)

> https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/lang/reflect/Field.html#set%28java.lang.Object,java.lang.Object%29
> 

javadoc 문서에 따르면 **final field**가 field.set에 들어가는 경우 final 필드가 있는 **클래스의 인스턴스를 역직렬화하거나 재구성**하는 동안에만 의미가 있으며 다른 컨텍스트에서 사용하면 프로그램의 다른 부분에서 이 필드의 원래 값을 계속 사용하는 경우를 포함하여 **예측할 수 없는 효과**가 발생할 수 있다고 설명하고 있다.

즉, **Hibernate가 final 필드를 리플렉션으로 강제 변경하면, 프로그램이 의도한 대로 동작하지 않을 위험**이 있다

또한 Hibernate와 같은 JPA 구현체 중 하나인 **Apache OpenJPA는 final이 붙으면 transient 필드로 취급해 DB에 저장하지 않는다.**

**이러한 부분들을 이루어 보았을 때, 아직까지는 Entity에서 val을 통한 선언은 리스크가 있어 보인다.**

---

## 3️⃣ var + private set

그렇다면 우리는 jpa entity를 정의할 때 최대한 val를 피하는 것이 좋다는 결론을 내렸으므로, **var을 이용하되 어떻게 프로퍼티의 노출을 막을 수 있을지**에 대한 생각을 해봐야 한다.

Kotlin에서는 프로퍼티를 var로 선언하여 Hibernate가 값을 변경할 수 있도록 허용하면서도, 외부에서는 Setter를 막는 방법을 제공한다.

즉, Java로 디컴파일될 때 Getter는 public으로 유지하되, Setter는 private으로 제한하는 방식이다.

```kotlin
@Entity
class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0L,  
        private set  // 외부에서 Setter 호출을 막음

    @Column(nullable = false)
    var name: String,
        private set 
)
```

위와 같이 private set을 별도로 설정해 준다면 자바로 디컴파일 했을 때의 결과는 다음과 같다.

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    public Long getId() {  // Getter는 public
        return this.id;
    }

    private void setId(Long id) {  // Setter는 private
        this.id = id;
    }

    public String getName() {  // Getter는 public
        return this.name;
    }

    private void setName(String name) {  // Setter는 private
        this.name = name;
    }
}
```

위의 코드처럼 getter는 public으로 설정되는 반면 setter에 대해서는 private로 설정이 된다.

### 🚨문제점

하지만 위의 코드처럼 실행하면 에러가 뜨는 것을 확인할 수 있다.

> Error: Private setters are not allowed for open properties
> 

이는 위에서 다루었던 Hibernate의 lazy loading의 동작 방식과 관련이 있다.

지연 로딩을 실행할 때 원본객체를 상속받는 프록시 객체를 생성하는데, 이때의 핵심은 **상속**이다.

그러나 코틀린의 경우 자바와 반대로 open을 붙여주지 않는 이상 기본적으로 
final class, final method가 되는데, 이러한 형태는 상속이 불가능하기 때문에 JPA에서 allopen 
플러그인을 제공하고, property에 자동으로 open이 붙게 된다.

따라서 **open이 붙은 프로퍼티에는 private set을 하면 컴파일 에러가 뜨는 것**이다.

*(kotlin 1.9.x에서 직접 실행해 보니까 컴파일 에러가 안 뜨던데 이 부분에 대한 패치가 진행되었는지 확인이 필요할 것 같다..)*

---

## 4️⃣ var + protected set
private set은 open class에서 사용이 불가능하므로 조금 더 완화된 조건인, protected set을 떠올릴 수 있다.

Kotlin에서는 var + protected set을 사용하면, 같은 패키지나 외부 클래스에서는 Setter를 사용할 수 없지만, 서브클래스에서는 Setter를 사용할 수 있도록 제한할 수 있다.

즉, Setter의 접근 범위를 protected로 설정하여, 외부에서는 값을 변경하지 못하지만, 상속받은 클래스에서는 변경할 수 있도록 하는 방법이다**.**

lazy loading 시에 상속받는 프록시 객체를 사용하므로 protected로 선언된 setter도 문제없이 상속받을 수 있을 것이다.

```kotlin
@Entity
open class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long = 0L, 
        protected set  // 외부에서 직접 Setter 호출을 막고, 서브클래스에서는 허용

    @Column(nullable = false)
    var name: String,
        protected set 
)
```

위와 같이 protected set을 정의해 주면 자바로 디컴파일 했을 때 코드는 다음과 같다.

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    public Long getId() {  // Getter는 public
        return this.id;
    }

    protected void setId(Long id) {  // Setter는 protected
        this.id = id;
    }

    public String getName() {  // Getter는 public
        return this.name;
    }

    protected void setName(String name) {  // Setter는 protected
        this.name = name;
    }
}
```

위와 같이 setter에 대해서는 protected의 접근자가 붙은 것을 확인할 수 있다.

그렇다면 서브 클래스에서는 변경이 가능하지만 외부에서는 변경이 불가능한 상태로 만들어 최대한의 캡슐화를 지킬 수 있는 코드라고 볼 수 있다.

따라서 var+protected set 방법이 가장 최선의 방법이라고 할 수 있을 것 같다.

### 🚨문제점
모든 방식에는 trade-off가 있듯이 var+protected set의 방식에도 문제점이 있다.

1. **코틀린은 불필요한 코드를 줄이고자 설계된 언어인데, 캡슐화를 지키기 위해 컬럼들에 protect set을 정의하면 코드가 너무 장황해진다.**

2. **프로퍼티를 생성자 매개변수를 통해 초기화하려 할 때 불편함이 생긴다.**

```kotlin
@Entity
@Table(name = "`user`")
class User(
    name: String,
) {
    @Column(nullable = false)
    var name: String = name
        protected set
}
```

위의 코드처럼 생성자 매개변수에 정의를 하고 아래에서 또 정의를 해줘야 한다는 점이다.

(생성자 매개변수에서는 protected set 설정이 불가능하기 때문)

---

# [📢 마무리](https://jhzlo.tistory.com/73#%F0%9F%93%A2%20%EB%A7%88%EB%AC%B4%EB%A6%AC-1)

- 코틀린은 자바와 달리 필드의 개념이 아닌 프로퍼티의 개념이다.
    - var은 자바로 디컴파일 되는 과정에서 field + getter + setter 가 생성된다.
    - val은 자바로 디컴파일 되는 과정에서 final field + getter 가 생성된다.
- 코틀린은 디컴파일 과정에서 class와 method에 final이 붙는다 하지만 JPA의 allopen 플러그인에 따라 open으로 바뀐다 => Hibernate의 lazy loading이 가능케 하도록
- 프로퍼티가 외부로 노출되는 것을 방지하기 위한 방법으로는 뭐가 있을까?
    - private 접근 제어자 설정 -> 모순 발생
    - val로 변수 지정 -> 권장사항 x
    - var + private set -> 컴파일 에러
    - var + protected set -> 그나마 최선의 방법

💡각각의 방법들에는 모두 trade-off가 따른다. 사실 개발자들의 실수로 인해 객체의 값이 의도치 않게 변경되는 것만 아니면 문제가 없는 부분이다. 그렇기에 암묵적으로 개발자들 사이에서 이러한 과정만 잘 지켜진다면 var만 써서 코드를 간결하게 유지하는 것도 좋아 보인다.

---

# 📙 출처

[https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html#_requirements_for_entity_classes](https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html#_requirements_for_entity_classes)

[Introduction to Jakarta Persistence :: Jakarta EE Tutorial :: Jakarta EE Documentation
The persistence provider can be
 configured to automatically create the database tables, load data into 
the tables, and remove the tables during application deployment using 
standard properties in the application’s deployment descriptor. These 
tasks are t
jakarta.ee](https://jakarta.ee/learn/docs/jakartaee-tutorial/current/persist/persistence-intro/persistence-intro.html#_requirements_for_entity_classes)

[https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#entity-pojo](https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#entity-pojo)

[Hibernate ORM User Guide
Starting in 6.0, Hibernate 
allows to configure the default semantics of List without @OrderColumn 
via the hibernate.mapping.default_list_semantics setting. To switch to 
the more natural LIST semantics with an implicit order-column, set the 
setting to LIST.
docs.jboss.org](https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#entity-pojo)

[https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#access](https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#access)

[Hibernate ORM User Guide
Starting in 6.0, Hibernate 
allows to configure the default semantics of List without @OrderColumn 
via the hibernate.mapping.default_list_semantics setting. To switch to 
the more natural LIST semantics with an implicit order-column, set the 
setting to LIST.
docs.jboss.org](https://docs.jboss.org/hibernate/orm/6.5/userguide/html_single/Hibernate_User_Guide.html#access)
