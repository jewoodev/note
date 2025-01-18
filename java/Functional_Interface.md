# @FunctionalInterface

특정 인터페이스를 람다식으로 사용할 용도라는 것을 명시하는 인터페이스이다.

그리고 자주 사용되는 람다식을 미리 만들어서 제공하는 것들이 있다. 

## 단순한 FunctionalInterface

-  **Consumser**: 매개변수가 있고, 리턴값이 없는 FunctionalInterface이다.
- **Supplier**: 매개변수가 없고 리턴값이 있는 FunctionalInterface이다.

### Consumer

```java
class UseFunctionInterface {
    public static void main(String[] args) {
        Consumer<String> c = s -> System.out.println(s);
    }
}
```

### Supplier

```java
class UseFunctionInterface {
    public static void main(String[] args) {
        Supplier<String> c = () -> "반환값";
    }
}
```

## 복잡한 FunctionalInterface

이제 살펴볼 FunctionalInterface은 매개변수와 리턴값 모두 있는 것들이다.

### Function

```java
class UseFunctionInterface {
    public static void main(String[] args) {
        Function<String, Integer> f = str -> Integer.parseInt(str);
    }
}
```

제네릭으로 첫번째 타입이 매개변수의 타입, 두번째 타입이 리턴값의 타입이다.

### Operator

이건 연산이 주로 이루어지는 람다식을 쓰려할 때 사용하는 용도로 만들어졌다.

```java
class UseFunctionInterface {
    public static void main(String[] args) {
        UnaryOperator<Integer> operator = // 매개변수가 하나 일 때 사용하는 Operator
                num -> num * num;
        
        BinaryOperator<Double> binaryOperator = // 매개변수가 두 개일 때 사용하는 Operator
                (num1, num2) -> num1 + num2;
    }
}
```

### Predicate

리턴값이 boolean 타입일 때 사용하는 것이다. 제네릭으로는 매개변수의 타입을 지정하면 된다.

```java
class UseFunctionInterface {
    public static void main(String[] args) {
        Predicate<String> predicate =
                str -> str.length() > 5;
    }
}
```