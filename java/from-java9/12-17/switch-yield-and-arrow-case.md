# 자바의 switch와 함께 쓸 수 있는 yield 지시자는 switch 식만을 위해 사용이 가능하니? arrow case는 switch 식 & switch 문 둘 모두에 사용이 가능하고?
Java에서 `yield`와 arrow case(`->`)의 사용 범위에 대해 정확히 설명드리겠습니다.

## yield 키워드
`yield`는 **switch 식(switch expression)에서만** 사용 가능합니다. switch 문에서는 사용할 수 없습니다.

```java
// Switch 식에서 yield 사용 (가능)
int result = switch (value) {
    case 1, 2 -> {
        System.out.println("1 or 2");
        yield 10;  // OK
    }
    case 3 -> 20;  // 단일 표현식이면 yield 불필요
    default -> {
        yield 30;  // OK
    }
};

// Switch 문에서 yield 사용 (불가능)
switch (value) {
    case 1 -> {
        yield 10;  // 컴파일 에러! switch 문에서는 yield 사용 불가
    }
}
```

## Arrow case (->)
Arrow case는 switch 식과 switch 문 모두에서 사용 가능합니다.

```java
// Switch 문에서 arrow case 사용
switch (value) {
    case 1 -> System.out.println("One");
    case 2 -> System.out.println("Two");
    case 3 -> {
        System.out.println("Three");
        System.out.println("Multiple statements");
    }
}

// Switch 식에서 arrow case 사용
String result = switch (value) {
    case 1 -> "One";
    case 2 -> "Two";
    case 3 -> {
        System.out.println("Processing three");
        yield "Three";
    }
    default -> "Other";
};
```

## 정리
- **yield**: switch 식에서만 사용 가능
- **arrow case (->)**: switch 식과 switch 문 모두에서 사용 가능

Arrow case를 사용하면 `break` 문이 필요 없고 fall-through도 발생하지 않아 더 안전하고 간결한 코드를 작성할 수 있습니다.