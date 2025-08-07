# 람다식
## 1.1 람다식이란?
람다식은 간단히 말해서 메서드를 하나의 '식(expression)'으로 표현한 것이다. 람디식은 함수를 간략하면서도 명확한 식으로 표현할 수 있게 해준다.

메서드를 람다식으로 표현하면 메서드의 이름과 반환값이 없어지므로, 람다식으로 '익명 함수'이라고도 한다.

람다식은 메서드의 매개변수로 전달되어지는 것이 가능하고, 메서드의 결과로 반환될 수도 있다. 람다식으로 인해 메서드를 변수처럼 다루는 것이 가능해진 것이다.

## 1.3 함수형 인터페이스
### 람다식의 타입과 형변환
함수형 인터페이스로 람다식을 참조할수 있는 것일 뿐, 람다식의 타입이 함수형 인터페이스의 타입과 일치하는 것은 아니다. 람다식은 익명 객체이고 익명 객체에는 타입이 없다.  
정확히는 타입은 있지만 컴파일러가 임의로 이름을 정하기 때문에 알 수 없다. 그래서 대입 연산자의 양변의 타입을 일치시키기 위해 아래와 같이 형변환이 필요하다.

```java
MyFunction f = (MyFunction) (() -> {}); // 양변의 타입이 다르므로 형변환이 필요
```

람다식은 MyFunction 인터페이스를 직접 구현하진 않았지만, 이 인터페이스를 구현한 클래스의 객체와 완전히 동일하기 때문에 위와 같은 형변환을 허용한다. 그리고 이 형변환은 생략가능하다.

람다식은 이름이 없을 뿐 분명히 객체인데도, 아래와 같이 Object 타입으로 형변환 할 수 없다. 람다식은 오직 함수형 인터페이스로만 형변환이 가능하다.
```java
Object obj = (Object) (() -> {}); // 에러. 함수형 인터페이스로만 형변환 가능
```

굳이 Object 타입으로 형변환하려면 함수형 인터페이스로 먼저 변환한 후에 변환해야 한다.

## 1.4 java.util.function 패키지
자주 쓰이는 함수형 인터페이스의 양상은 일관적인 부분이 있다. 그래서 그렇게 자주 쓰이는 형태의 함수형 인터페이스를 java는 java.util.function 패키지에 정의해두었다.

매번 새로운 함수형 인터페이스를 정의하기보다 이 패키지의 인터페이스를 활용하자. 그래야 메서드 이름도 통일되고, 재사용성이나 유지보수 측면에서도 좋다. 

### 조건식 표현에 사용되는 Predicate
Predicate는 Function의 변형으로, 반환타입이 boolean이라는 것만 다르다. Predicate는 조건식을 람다식으로 표현하는데 사용된다.

### 매개변수가 두 개인 함수형 인터페이스
매개변수가 2개인 함수형 인터페이스는 이름 앞에 접두사 "Bi"가 붙는다. 

2개 이상의 매개변수를 갖는 함수형 인터페이스는 직접 만들어서 써야 한다.

### UnaryOperator와 BinaryOperator
Function의 변형으로 매개변수의 타입과 반환 타입이 모두 일치한다는 점만 다르다.

- UnaryOperator: 매개변수 타입 T -> 반환 타입 T
- BinaryOperator: 매개변수 타입 T, T -> 반환 타입 T

### 기본형을 사용하는 함수형 인터페이스
함수형 인터페이스는 매개변수와 반환값이 모두 지네릭 타입이여야만 할까? 그렇지 않다. 당연히 기본형보다 래퍼 클래스를 사용하는 게 비효율적이며, 그래서 더 효율적으로 처리할 수 있도록 기본형을 사용하는 함수형 인터페이스들도 제공된다.


## 1.5 Function의 합성과 Predicate의 결합
java.util.function 패키지의 함수형 인터페이스에는 추상메서드 외에도 디폴트 메서드와 static 메서드가 정의되어 있다. 그 중 Function과 Predicate의 것들만 살펴보자. 이것과 대부분 흡사하다.

### Function의 합성
수학에서 두 함수를 합성해서 하나의 새로운 함수를 만들어낼 수 있는 것처럼 두 람다식을 합성해서 새로운 람다식을 만들 수 있다.  

두 함수의 합성은 어느 함수를 먼저 적용하느냐에 따라 다른 결과로 이어진다. 함수 f, g가 있을 때 f.andThen(g)는 함수 f를 먼저 적용하고, 그 다음에 함수 g를 적용한다. 그리고 f.compose(g)는 반대로 g를 먼저 적용하고 f를 적용한다.


## 1.6 메서드 참조
'하나의 메서드만 호출하는 람다식'은 '클래스이름::메서드이름' 또는 '참조변수::메서드이름'으로 바꿀 수 있다.

### 생성자의 메서드 참조
생성자를 호출하는 람다식도 메서드 참조로 변환할 수 있다.
```java
Supplier<Example> s = () -> new Example();
Supplier<Example> s = Example::new;
```

매개변수가 있는 생성자라면 그 개수에 맞는 함수형 인터페이스를 사용하면 된다.
```java
Function<Integer, Example> f1 = (i) -> new Example(i);
Function<Integer, Example> f2 = Example::new;

BiFunction<Integer, String, Example> bf1 = (i, s) -> new Example(i, s);
BiFunction<Integer, String, Example> bf2 = Example::new;
```

그리고 배열을 생성할 땐 아래와 같이 하면 된다.
```java
Function<Integer, int[]> f1 = x -> new int[x];
Function<Integer, int[]> f2 = int[]::new;
```

메서드 참조는 람다식을 마치 static 변수처럼 다룰 수 있게 해준다. 메서드 참조는 코드를 간략히 하는데 유용해서 많이 사용된다. 




# 2. 스트림
## 2.1 스트림이란?
컬렉션이나 배열에 데이터를 담기 위해 for문이나 Iterator를 사용하면 코드가 너무 길어지고 가독성이 떨어지며 재사용성도 떨어진다. 게다가 데이터 소스마다 다른 방식으로 다뤄야 한다. Collection이나 Iterator 같은 인터페이스를 이용해서 컬렉션을 다루는 방식을 표준화하기는 했지만 각 컬렉션 클래스에는 같은 기능의 메서드들이 중복해서 정의되어 있다. 예를 들어 List의 정렬은 `Collections.sort()`를 써야 하고 배열은 `Arrays.sort()`를 써야 한다.

이런 문제점을 해결하기 위해 만든 게 **스트림**이다. 스트림은 데이터 소스를 추상화하고, 데이터를 다루는데 자주 사용되는 메서드들을 정의해 놓았다. 데이터 소스를 추상화했다는 건 데이터 소스가 무엇이든 간에 같은 방식으로 다룰 수 있게 되었다는 것과 코드의 재사용성이 높아진다는 걸 의미한다.

스트림을 이용하면, 배열이나 컬렉션뿐만 아니라 파일에 저장된 데이터도 모두 같은 방식으로 다룰 수 있다. 예를 들어 문자열 배열과 같은 내용의 문자열을 저장하는 List가 있을 때,
```java
String[] strArr = {"aaa", "bbb", "ccc"};
List<String> strList = Arrays.asList(strArr);
```

위 두 데이터 소스를 기반으로 스트림을 생성하고, 그 스트림으로 데이터 소스의 데이터를 읽어서 정렬하고 화면에 출력하는 방법은 다음과 같다. 여기서 데이터 소스가 정렬되는 건 아니라는 점에 유의하자.
```java
strList.stream().sorted().forEach(System.out::println);
Arrays.stream(strArr).sorted().forEach(System.out::println);
```

두 스트림의 데이터 소스는 서로 다르지만, 정렬하고 출력하는 방법이 완전히 동일하다. 스트림을 사용하지 않는다면 아래와 같이 코드를 작성해야 했을 것이다.
```java
Arrays.sort(strArr);
Collections.sort();

for (String str: strArr)
    System.out.println(str);

for (String str: strList)
        System.out.println(str);
```

### 스트림의 연산
중간 연산은 map()과 flatMap(), 최종 연산은 reduce()와 collect()가 핵심이다.

### 지연된 연산
스트림 연산에서 한 가지 중요한 점은 최종 연산이 수행되기 전까진 **중간 연산이 수행되지 않는다**는 점이다. 스트림에 대해 distinct()나 sort()같은 중간 연산을 호출해도 즉각적인 연산이 수행되는 것이 아니라는 말이다. 중간 연산을 호출하는 것은 단지 어떤 작업이 수행되어야 하는지를 지정해주는 것일 뿐이다. 최종 연산이 수행되어야 비로소 스트림의 요소들이 중간 연산을 거쳐 최종 연산에서 소모된다.

### Steam<Integer>와 IntStream
요소의 타입이 T인 스트림은 기본적으로 Stream<T>이지만, 오토박싱&언박싱에서의 오버헤드를 줄이기 위해 데이터 소스의 요소를 기본형으로 다루는 스트림, IntStream, LongStream, DoubleStream이 제공된다. 

### 병렬 스트림
스트림으로의 데이터 처리가 갖는 장점 중 하나가 **병렬 처리가 쉽다**는 것이다. 병렬 스트림은 내부적으로 fork&join 프레임웍으로 자동적으로 연산을 병렬로 수행한다. 개발자는 그저 스트림에 parallel()이라는 메서드를 호출해서 병렬로 연산을 수행하라고 지시하면 된다. 반대로 병렬로 처리되지 않게 하려면 sequential()을 호출하면 된다. 다만 모든 스트림은 기본적으로 병렬 스트림이 아니므로 parallel()을 호출한 걸 취소할 때가 아니면 sequantial()을 호출할 필요가 없다.


## 2.2 스트림 만들기
### 컬렉션
컬렉션의 최고 조상인 Collection에 stream()이 정의되어 있다. 그래서 컬렉션 클래스들은 이 메서드로 스트림을 생성할 수 있다.

### 배열
배열을 소스로 스트림을 생성하는 메서드는 Stream과 Arrays에 static 메서드로 정의되어 있다.
```java
Stream<T> Stream.of(T... values)
Stream<T> Stream.of(T[])
Stream<T> Arrays.stream(T[])
Stream<T> Arrays.stream(T[] arrays, int startInclusive, int endExclusive)
```

그리고 int, long, double과 같은 기본형 배열을 소스로 하는 스트림을 생성하는 메서드도 있다. 

- IntStream, LongStream, ...


## 2.3 스트림의 중간연산
### mapToInt(), mapToLong(), mapToDouble()
map()은 연산 결과로 Stream<T> 타입의 스트림을 반환하는데, 스트림 요소가 기본형이라면 IntStream 같은 기본형 스트림으로 변환하는 것이 더 유용할 수 있다.  
기본형 스트림을 쓴다면 스트림 요소끼리 연산할 때 Integer를 int로 변환하지 않고 바로 연산할 수 있기 때문이다.

게다가 count()만 지원하는 Stream<T>와 달리 IntStream 같은 기본형 스트림은 숫자를 다루는데 편리한 메서드들을 제공한다.

- `int sum()`: 스트림의 모든 요소의 총합
- `OptionalDouble average()`: `sum() / (double) count()`
- `OptionalInt max()`: 스트림의 요소 중 가장 큰 값
- `OptionalInt min()`: 스트림의 요소 중 가장 작은 값

위 메서드들은 최종 연산이기 때문에 sum()과 average()를 모두 사용해야 할 때 스트림을 여러 번 생성해야 하는 불편함이 있다. 그래서 summaryStatistics()이라는 메서드가 따로 제공된다.



