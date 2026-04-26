# 코틀린 파일에서의 접근 제어
# protected

| Java                      | Kotlin                         |
|---------------------------|--------------------------------|
| 같은 패키지 또는 하위 패키지에서만 접근 가능 | **선언된 클래스** 또는 하위 클래스에서만 접근 가능 |

코틀린에서는 패키지를 namespace를 관리하기 위한 용도로만 사용한다. 가시성 제어에는 사용하지 않는다. 그로 인해 위와 같은 차이가 있다고 보면 된다.

# default to internal

| Modifier | Java              | Kotlin         |
|----------|-------------------|----------------|
| default  | 같은 패키지 내에서만 접근 가능 |                |
| internal |                   | 같은 모듈에서만 접근 가능 |

패키지를 가시성 제어하는 데에 쓰지 않다 보니 default가 사라지고 새로운 가시성 제어 지시자가 생겨났다.

여기서 말하는 모듈은 다음과 같다.

- IDEA Module
- Maven Project
- Gradle Source Set
- Ant Task <kotlinc>의 호출로 컴파일 파일의 집합

# private

| Java              | Kotlin           |
|-------------------|------------------|
| 같은 클래스 내에서만 접근 가능 | 같은 파일 내에서만 접근 가능 |

마지막으로 Java의 기본 접근 지시어는 `default`, Kotlin은 `public`

# 코틀린 파일의 접근 제어
코틀린은 .kt 파일 내에 변수, 함수, 클래스 여러 개를 바로 만들 수 있다. 

protected 지시어는 파일(최상단)에는 사용할 수 없다. (kotlin에서) 이 지시어는 kotlin에서 선언된 클래스와 그 하위 클래스에 작동하는 것이기 때문이다.

# 다양한 구성 요소의 접근 제어
## 클래스 안의 멤버, 생성자
코틀린 파일에서와 동일하다. 단 생성자는 생성자에 사용하려면 constructor 키워드를 직접 작성해야 한다.

## 유틸리티 클래스
```java
public abstract class StringUtils {
    private StringUtils() { }
    
    public static boolean isDirectoryPath(String path) {
        return path.endsWith("/");
    }
}
```

자바에서는 유틸성 코드를 만들 때 위와 같이 추상 클래스를 만들고 private 생성자를 만들어서 인스턴스화와 상속이 불가능하도록 만들었었다. 코틀린에서도 이처럼 작성하는게 가능하다. 하지만 파일 최상단에 바로 유틸 함수를 작성해주는게 훨씬 간편하다.

## 프로퍼티
var/val 앞에 지시어를 둬 getter와 setter의 가시성을 한번에 제어할 수 있고, 프로퍼티 아래에 `private set`과 같이 작성을 해서 setter에만 추가로 가시성을 부여할 수 있다.

# Java와 함께 사용할 때 유의할 점
Internal은 바이트 코드로 컴파일되면 public이 된다. 그래서 Java에서 Kotlin 모듈의 internal 코드를 가져올 수 있다.

Java의 protected는 같은 패키지 내에서 접근이 가능하게 한다. 그래서 자바에서는 같은 패키지 내에서 protected Kotlin class를 가져올 수 있다.