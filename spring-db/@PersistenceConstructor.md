`@PersistenceConstructor`는 **Spring Data**에서 **영속성 계층에서 엔티티를 복원할 때 사용할 생성자를 지정**하기 위한 애노테이션입니다. 이 애노테이션은 주로 **JPA가 아닌 다른 Spring Data 모듈**, 예를 들어 `Spring Data MongoDB`나 `Spring Data JDBC` 등에서 사용됩니다.

---

### 💡 주요 개념 요약

- **역할**: Spring Data가 객체를 조회하고 복원할 때 사용할 생성자를 명시함
- **대상**: 주로 MongoDB, JDBC 등 JPA 외 Spring Data 모듈에서 사용
- **사용 위치**: 생성자에 붙여 사용

---

### 📦 왜 필요할까?

Spring Data는 객체를 조회할 때, 기본적으로 **기본 생성자 + 세터 방식**이나 **모든 필드를 인자로 받는 생성자**를 사용해서 객체를 만듭니다. 그런데 여러 개의 생성자가 존재할 경우 어떤 걸 써야 할지 모호하죠. 이럴 때 `@PersistenceConstructor`를 사용하면, **Spring Data가 해당 생성자를 통해 객체를 생성하도록 지시**할 수 있습니다.

---

### 🧪 예제 (MongoDB 기준)

```java
java
복사편집
@Document
public class User {

    private final String id;
    private final String name;

    @PersistenceConstructor
    public User(String id, String name) {
        this.id = id;
        this.name = name;
    }

    public User(String name) {
        this(null, name);
    }

    // getter 생략
}

```

이 예제에서는 MongoDB에서 데이터를 조회할 때 `id`, `name`을 사용하는 생성자를 지정하기 위해 `@PersistenceConstructor`를 붙였습니다. 만약 이 애노테이션이 없다면 Spring Data는 어떤 생성자를 사용할지 결정하지 못해 예외가 발생할 수도 있습니다.

---

### ⚠️ 주의할 점

- **JPA에서는 사용하지 않습니다.** JPA는 기본 생성자가 필수이며, `@PersistenceConstructor`는 인식하지 않습니다.
- **하나의 생성자만 있는 경우엔 생략 가능**합니다. 하지만 생성자가 여러 개일 경우엔 반드시 명시해주는 것이 안전합니다.