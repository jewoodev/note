# switch expression(java 14)
## statement와 expression
일반적인 프로그래밍 언어에서 statement란 어떠한 프로그램의 문장을 의미한다. statement의 예시로 `System.out.println("Hello World");`를 들 수 있다.

expression은 프로그래밍 문장 중에서도 어떤 결과값이 정해지는 문장을 의미한다. 덧셈 연산이 expression의 예시이며, if-else 문은 하나의 값으로 귀결되는 expression은 아니므로 이를 참고해 expression이 무엇인지 이해하는데 참고하길 바란다. 

## switch statement -> expression
과거에는 각 케이스를 만족하는 로직이 끝날 때마다 break 명령어가 반복적으로 작성되어야 했지만 expression으로 개선되면서 그런 불편함이 사라졌다.

```java
private String calculate(int number) {
    String result = "";
    switch (number) {
        case 1:
            result = "one";
            break;
        case 2:
            result = "two";
            break;
        case 3:
```

```java
private String calculate(int number) {
    return switch (number) {
        case 1:
            yield "one";
        case 2:
            yield "two";
        case 3:
            yield "three";
        default:
            yield "unknown";
    };
}
```
또, 이전에는 return 코드 뒤에 switch문이 오는 것이 불가능했는데 이것도 가능해졌다.

### 새로운 라벨
switch expression에서만 쓸 수 있는 새로운 라벨이 등장했다. 위의 라벨은 case 라벨이며, 새로운 라벨은 arrow case 라벨이다.

```java
private String calculate(int number) {
    return switch (number) {
        case 1 -> "one"; // yield 생략!
        case 2 -> "two";
        case 3 -> "three";
        default -> "unknown";
    };
}

private String calculate(int number) {
    return switch (number) {
        case 1 -> { // arrow case는 중괄호도 사용할 수 있음
            // 추가적인 로직 삽입 가능
            yield "one"; // yield 생략 불가!
        }
        case 2 -> "two";
        case 3 -> "three";
        default -> "unknown";
    };
}
```

# instanceof pattern matching (java 14 preview, 16 formal)
기존의 instanceof 활용법은
1. instanceof 로 부모 타입의 파라미터가 어떤 타입의 인스턴스인지 확인하여
2. 그 타입으로 형 변환하고
3. 그 타입이 갖고 있는 기능을 사용한다.

는 세 단계를 거쳐야 하는 불편함이 있었다. 그래서 instanceof pattern matching이 등장했다.

```java
public abstract class Animal {
    public String sound(Animal animal) {
        if (animal instanceof Dog dog) { // 1, 2번의 작업이 한 번에 처리됨
            dog.bark();
        } else if (animal instanceof Cat cat) {
            cat.meow();
        } else {
            throw new IllegalArgumentException("Unknown animal type");
        }
        return "Animal sound";
    }
}
```

instanceof pattern matching은 instanceof 결과가 true이면 왼쪽 변의 변수를 형 변환한 오른쪽 변수를 사용 가능하게 만든다.

```java
public String sound(Animal animal) {
        if (!(animal instanceof Dog dog)) {
            return "강아지가 아닙니다!";
        } 
        return dog.bark(); // dog를 사용할 수 있다?!
    }
```
만약 위 예시처럼 return이 조건 실행문에 있으면, 조건문을 지나쳐 왔을 땐 변수의 타입이 무조건 Dog이므로 조건문 밖에서도 dog 변수를 사용할 수 있게 된다.

### pattern matching
이처럼 조건을 확인하고 조건문 수행 결과가 true이면 특정 변수에 값을 할당해주는 기능을 부르는 명칭이다.

