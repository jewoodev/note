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

| 함수형 인터페이스           | 메서드                      | 설명                                  |
|---------------------|--------------------------|-------------------------------------|
| DoubleToIntFunction | int applyAsInt(double d) | AToBFunction은 입력이 A타입, 출력이 B타입      |
| ToIntFunction<T>    | int applyAsInt(T value)  | ToBFunction은 출력이 B타입이다. 입력은 지네릭 타입. |
| IntFunction<R>      | R apply(T t, U u)        | AFunction은 입력이 A타입이고 출력은 지네릭 타입.    |
| ObjIntCunsumer      | void accept(T t, U u)    | ObjAFunction은 입력이 T, A타입이고 출력은 없다.  |

## 1.5 Function의 합성과 Predicate의 결합
java.util.function 패키지의 함수형 인터페이스에는 추상메서드 외에도 디폴트 메서드와 static 메서드가 정의되어 있다. 그 중 Function과 Predicate의 메서드만 살펴보자. 이것과 대부분 흡사하다.

- **Function**
  - default <V> Function<T, V> andThen(Function<? super R, ? extends V> after)
  - default Function<V, R> compose(Function<? super V, ? extends T> before)
  - static <T> Function<T, T> identity()
- **Predicate**
  - default Predicate<T> and(Predicate<? super T> other)
  - default Predicate<T> or(Predicate<? super T> other)
  - default Predicate<T> negate()
  - static <T> Predicate<T> isEqual(Object targetRef)

### Function의 합성
수학에서 두 함수를 합성해서 하나의 새로운 함수를 만들어낼 수 있는 것처럼 두 람다식을 합성해서 새로운 람다식을 만들 수 있다.  

두 함수의 합성은 어느 함수를 먼저 적용하느냐에 따라 다른 결과로 이어진다. 함수 f, g가 있을 때 f.andThen(g)는 함수 f를 먼저 적용하고, 그 다음에 함수 g를 적용한다. 그리고 f.compose(g)는 반대로 g를 먼저 적용하고 f를 적용한다.

그리고 identity()는 함수를 적용하기 전과 후과 동일한 '항등 함수'가 필요할 때 사용한다. 이 함수를 람다식으로 표현해보면 `x -> x`이다. 아래의 두 코드는 동등하다.

```java
Function<String, String> f = x -> x;
Function<String, String> f = Function.identity(); // 위와 동일
```
항등 함수는 잘 사용되지 않는 편이며, map()으로 변환작업을 할 때, 변환없이 그대로 처리하고자할 때 사용된다.

### Predicate의 결합
여러 조건식을 논리 연산자 &&, ||, !로 연겨랳서 하나의 식으로 구성할 수 있는 것처럼 여러 Predicate로 결합할 수 있다.

```java
Predicate<Integer> p = x -> x < 100;
Predicate<Integer> q = x -> x < 2000;
Predicate<Integer> r = x -> x%2 == 0;
Predicate<Integer> notP = p.negate();

Predicate<Integer> all = notP.and(q.or(r));
System.out.println(all.test(150)); // true
```
이렇게 and(), or(), negate()로 여러 조건식을 하나로 합칠 수 있다. 물론 아래처럼 람다식을 직접 넣어도 괜찮다.

```java
Predicate<Integer> all = notP.and(x -> x < 200).or(x -> x%2 ==0);
```
그리고 static 메서드인 isEqual()은 두 대상을 비교하는 Predicate를 만들 때 사용한다. 사용 방법은 isEqual()의 매개변수로 비교대상 하나를 지정하고, 다른 비교대상을 test()의 매개변수로 지정하는 것이다.

```java
Predicate<String> p = Predicate.isEqual("hello");
boolean result = p.test("hello"); // true

boolean result = Predicate.isEqual("hello").test("world"); // 같은 명령어임
```

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

스트림의 특징을 먼저 살펴보자. 간단하게 나열만 할 것이므로 자세한 내용은 따로 공부하자.

- 스트림은 **데이터 소스를 변경하지 않는**다.
- 스트림은 **일회용**이다.
- 스트림은 작업을 **내부 반복으로 처리**한다.

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

### 람다식 - iterate(), generate()
Stream 클래스의 iterate()와 generate()는 람다식을 매개변수로 받아서 람다식에 의해 계산되는 값들을 요소로 하는 무한 스트림을 생성한다.

```java
static <T> Stream<T> iterate(T seed, UnaryOperator<T> f)
static <T> Stream<T> generate(Supplier<T> s)
```
iterate()는 씨앗값(seed)으로 지정된 값부터 시작해서 람다식 f에 의해 계산된 결과를 다시 seed값으로 계산하는 걸 반복한다. 

generate()도 iterate()와 동일하게 람다식에 의해 계산되는 값을 요소로 하는 무한 스트림을 생성해서 반환하지만, iterate() 처럼 이전 결과가 다음 연산에 사용되지 않는다. 그리고 generate()의 매개변수 타입은 Supplier<T>라서 매개변수가 없는 람다식만 허용된다. 

한 가지 유의할 점은 iterate()와 generate()에 의해 생성된 스트림을 아래처럼 기본형 스트림 타입의 참조 변수로 다룰 수 없다는 점이다.

```java
IntStream evenStream = Stream.iterate(0, n -> n + 2); // 에러
DoubleStream randomStream = Stream.generate(Math::random); // 에러
```
굳이 필요하다면 mapToInt()같은 메서드로 변환해야 한다.

```java
IntStream evenStream = Stream.iterate(0, n -> n + 2).mapToInt(Integer::valueOf);
Stream<Integer> stream = evenStream.boxed(); // IntStream -> Stream<Integer>
```

### 파일
java.nio.file.Files는 파일을 다루는데 필요한 메서드들을 제공한다. 그 중 list()는 지정된 디렉토리에 있는 파일 목록을 소스로 하는 스트림을 생성해 반환한다.

```java
Stream<Path> Files.list(Path dir)
```
파일의 한 행을 요소로 하는 스트림을 생성하는 메서드도 있다. 아래의 세 번째 메서드는 BufferedReader 클래스에 속한 것으로 파일 뿐 아니라 다른 입력대상으로부터도 데이터를 행단위로 읽어올 수 있다.

```java
Stream<String> Files.lines(Path path)
Stream<String> Files.lines(Path path, Charset cs)
Stream<String> lines()
```

### 빈 스트림
요소가 하나도 없는 스트림을 생성할 수 있다. 스트림에 연산을 수행한 결과가 하나도 없을 때 null보다 빈 스트림을 반환하는 것이 낫다.

```java
Stream emptyStream = Stream.empty();
long count = emptyStream.count(); // 0
```

### 두 스트림의 연결
Stream의 static 메서드 concat()을 사용하면 두 스트림을 하나로 연결할 수 있다. 물론 연결하려는 두 스트림의 요소는 같은 타입이어야 한다.

```java
String[] str1 = {"123", "456", "789"};
String[] str2 = {"abc", "ABC", "DEF"};

Stream<String> stream1 = Arrays.stream(str1);
Stream<String> stream2 = Arrays.stream(str2);
Stream<String> stream3 = Stream.concat(stream1, stream2);
```


## 2.3 스트림의 중간연산
### 요소 자르기 - skip(), limit()
두 메서드는 스트림의 일부를 잘라낼 때 사용한다.

```java
Stream<T> skip(long n)
Stream<T> limit(long maxSize)
```
기본형 스트림에도 두 메서드가 정의되어 있는데, 반환 타입이 기본형이라는 차이만 있다.

### 요소 걸러내기 - filter(), distinct()
distinct()는 스트림에서 중복된 요소를 제거하고, filter()는 주어진 조건(Predicate)을 만족하지 않는 요소들을 걸러낸다.

### 정렬 - sorted()
스트림을 정렬할 때 사용하는 메서드이다.

```java
Stream<T> sorted()
Stream<T> sorted(Comparator<? super T> comparator)
```

sorted()는 지정된 Comparator로 스트림을 정렬하는데, Comparator 대신 int값을 반환하는 람다식을 사용하는 것도 가능하다. Comparator를 지정하지 않으면 스트림 요소의 기본 정렬 기준(Comparable)으로 정렬한다. 단, 그 요소가 Comparable을 구현하지 않았다면 예외가 발생한다.

정렬에 사용되는 메서드가 매우 다양하고 많지만, 가장 기본적인 메서드는 comparing()이다.

```java
comparing(Function<T, U> keyExtractor)
comparing(Function<T, U> keyExtractor, Comparator<U> keyComparator)
```

스트림 요소가 Comparable을 구현한 경우, 매개변수 하나 짜리를 사용하면 되고 그렇지 않은 경우, 추가적인 매개변수로 정렬기준(Comparator)을 따로 지정해줘야 한다.

```java
comparingInt(ToIntFunction<T> keyExtractor)
comparingLong(ToLongFunction<T> keyExtractor)
comparingDouble(ToDoubleFunction<T> keyExtractor)
```

비교대상이 기본형인 경우, comparing() 대신 위의 메서드를 사용하면 오토박싱과 언박싱 과정이 없어 더 효율적이다. 그리고 정렬 조건을 추가할 땐 thenComparing()을 사용한다.

```java
thenComparing(Comparing<T> other)
thenComparing(Function<T, U> keyExtractor)
thenComparing(Function<T, U> keyExtractor, Comparator<U> keyComp)
```

### 변환 - map()

스트림 요소에 저장된 값 중에 원하는 필드만 뽑아내거나 특정 형태로 변환해야할 때가 있다. 그럴 때 사용하는게 map()이다. 

```java
Stream<R> map(Function<? super T, ? extends R> mapper)
```

예를 들어 File 스트림에서 파일 이름만 뽑아서 출력하고 싶다면 다음과 같이 사용한다.

```java
Stream<String> filenameStream = Stream.of(new File("ex1.java"), new File("ex2.java")).map(File::getName);
filenameStream.forEach(System.out::println);
```

### 조회 - peek()

연산과 연산 사이에 올바르게 처리되었는지를 확인하고 싶다면 peek() 를 사용하자. forEach()와 달리 스트림 요소를 소모하지 않으므로 연산 사이에 여러 번 사용해도 문제가 되지 않는다.

### mapToInt(), mapToLong(), mapToDouble()

map()은 연산 결과로 Stream<T> 타입의 스트림을 반환하는데, 스트림 요소가 기본형이라면 IntStream 같은 기본형 스트림으로 변환하는 것이 더 유용할 수 있다.  
기본형 스트림을 쓴다면 스트림 요소끼리 연산할 때 Integer를 int로 변환하지 않고 바로 연산할 수 있기 때문이다.

게다가 count()만 지원하는 Stream<T>와 달리 IntStream 같은 기본형 스트림은 숫자를 다루는데 편리한 메서드들을 제공한다.

- `int sum()`: 스트림의 모든 요소의 총합
- `OptionalDouble average()`: `sum() / (double) count()`
- `OptionalInt max()`: 스트림의 요소 중 가장 큰 값
- `OptionalInt min()`: 스트림의 요소 중 가장 작은 값

count()만 지원하는 Stream<T>와 달리 IntStream과 같은 기본형 스트림은 숫자를 다루는데 효과적인 메서드들을 제공한다.

```java
int sum()
OptionalDouble average()
OptionalInt max()
OptionalInt min()
```

이 메서드들은 최종연산이기 때문에 호출 후 스트림이 닫힌다는 것에 주의하자. 그래서 sum()과 average()를 연속해서 호출하려면 스트림을 한 번더 생성해야 하므로 불편하다. 그래서 summaryStatistics()라는 메서드가 따로 제공된다.

## 2.5 스트림의 최종 연산

최종 연산은 스트림의 요소를 소모해서 결과를 만들어낸다. 그래서 최종 연산 후에는 스트림이 닫히게 되고 더 이상 사용할 수 없게 된다. 최종 연산의 결과는 스트림 요소의 합과 같은 단일 값이거나, 스트림 요소가 담긴 배열 또는 컬렉션일 수 있다. 

### forEach()

이 메서드는 peek()와 달리 스트림의 요소를 소모하는 최종 연산으로 반환 타입이 void이기 때문에 스트림의 요소를 출력하는 용도로 많이 사용된다.

### 조건 검사 - allMatch(), anyMatch(), noneMatch(), findFirst(), findAny()

스트림의 요소가 지정된 조건을 모두 만족하는지, 일부가 만족하는지, 아니면 어떤 것도 만족하지 않는지 확인하는데 사용할 수 있는 메서드들이다. 이 메서드들은 모두 매개변수로 Predicate를 요구하며, 연산결과로 boolean을 반환한다.

이 메서드들 외에 스트림의 요소 중에서 조건에 일치하는 첫 번째 것을 반환하는 findFirst()가 있는데, 주로 filter()와 함께 사용되어 조건에 맞는 스트림의 요소가 있는지 확인하는데에 사용된다. 병렬 스트림의 경우 findFirst() 대신 findAny()를 사용해야 한다.

findFirst()와 findAny()의 반환 타입은 Optional<T>이며 스트림의 요소가 없을 땐 비어있는 Optional 객체를 반환한다.

### 리듀싱 - reduce()

이 메서드는 스트림의 요소를 줄여나가면서 연산을 수행하고 최종결과를 반환한다. 그래서 매개변수의 타입이 BinaryOperator<T>인 것이다. 처음 두 요소를 가지고 연산한 결과를 가지고 그 다음 요소와 연산한다. 그 과정에서 스트림 요소를 하나씩 소모하게 되어 결국 모든 요소를 소모함으로써 그 결과를 반환한다.

연산결과의 초기값(identity)을 갖는 reduce()도 있는데, 이 메서드들은 초기값과 스트림의 첫 번째 요소로 연산을 시작한다. 스트림의 요소가 하나도 없는 경우엔 초기값이 반환되어 반환 타입이 Optional<T>가 아니라 T이다.

## 2.6 collect()

collect()는 스트림의 요소를 수집하는 최종 연산으로 reducing과 비슷하다. collect()가 스트림의 요소를 수집하려면 '어떻게 수집할 것인가'에 대한 방법이 정의되어 있어야 하는데, 이 방법을 정의한 것이 바로 컬렉터(collector)이다.

컬렉터는 Collector 인터페이스를 구현한 것으로, 직접 구현할 수도 있고 미리 작성된 것을 사용할 수도 있다. Collectors 클래스는 미리 작성된 다양한 종류의 컬렉터를 반환하는 static 메서드를 가지고 있으며, 이 클래스를 통해 제공되는 컬렉터만으로도 많은 걸 할 수 있다.

### 스트림을 컬렉션과 배열로 변환 - toList(), toSet(), toMap(), toCollection(), toArray()

스트림의 모든 요소를 컬렉션에 수집하려면, Collectors 클래스의 toList()와 같은 메서드를 사용하면 된다. List나 Set이 아닌 특정 컬렉션을 지정하려면, toCollection()에 해당 컬렉션의 생성자 참조를 매개변수로 넣어주면 된다.

### 통계 - counting(), summingInt(), averagingInt(), maxBy(), minBy()

collect()로 통계 정보를 얻는 최종 연산을 사용할 수 있다. 이 것들은 groupingBy()와 함께 사용할 때 비로소 효용가치가 생긴다.

### 리듀싱 - reducing()

collect()로 리듀싱이 가능하다. IntSteam에는 매개변수 3개짜리 collect()만 정의되어 있으므로 boxed()를 통해 IntStream을 Stream<Integer>로 변환해야 매개변수 1개짜리 collect()를 쓸 수 있다.

```java
OptionalInt max = intStream.reduce(Integer::new);
Optional<Integer> max = instream.boxed().collect(reducing(Integer:new));
```

### 문자열 결합 - joining()

문자열 스트림의 모든 요소를 하나의 문자열로 연결해서 반환한다. 구분자를 지정해줄 수 있고, 접두사와 접미사를 지정하는 게 가능하다. 스트림의 요소가 String이나 StringBuffer처럼 CharSequence의 자손인 경우에만 결합이 가능하다.

### 그룹화와 분할 - groupingBy(), partitioningBy()

그룹화는 스트림의 요소를 특정 기준으로 그룹화하는 걸 의미하고, 분할은 스트림의 요소를 두 가지, 지정된 조건에 일치하는 그룹과 일치하지 않는 그룹으로의 분할을 의미한다. 

```java
Collector groupingBy(Function classifier)
Collector groupingBy(Function classifier, Collector downstream)
Collector groupingBy(Function classifier, Supplier mapFactory, Collector downstream)

Collector partitioningBy(Predicate predicate)
Collector partitioningBy(Predicate predicate, Collector downstream)
```

메서드의 정의를 보면 groupingBy()와 partitioningBy()가 분류를 Function으로 하느냐 Predicate로 하느냐의 차이만 있을 뿐 동일하다는 걸 알 수 있다. 스트림을 두 개의 그룹으로 나눠야 한다면 당연히 partitioningBy()로 분할하는 것이 더 빠르다. 그 외에는 groupingBy()를 쓰면 된다. 그리고 그룹화와 분할의 결과는 Map에 담겨 반환된다.

### paritioningBy()에 의한 분류

```java
Map<Boolean, List<Student>> stuBySex = stuStream.collect(partitioningBy(Student:isMale));

List<Student> maleStudent = stuBySex.get(true); // 남학생
List<Student> femaleStudent = stuBySex.get(false); // 여학생
```

이렇게 분류를 할 때 counting()을 사용하면 각 학생 수를 구할 수 있다.

```java
Map<Boolean, Long> stuNumBySex = stuStream.collect(partitioningBy(Student:isMale, counting()));
```

counting() 대신 summingLong()을 사용하면, 남학생과 여학생의 총점을 구할 수 있다. 그럼 남학생 1등과 여학생 1등은 어떻게 구할 수 있을까?

```java
Map<Boolean, Optional<Student>> topScoreBySex = stuStream.collect(
															partitioningBy(Student::isMale,
                                                                          maxBy(comparingInt(Student::getScore))
                                                  )
);
```

maxBy()는 반환 타입이 Optional<Student>라서 위와 같은 형태라 되지만, collectingAndThen()과 Optional::get을 함께 사용하면 더 직관적으로 변한다.

```java
Map<Boolean, Student> topScoreBySex = stuStream.collect(
															partitioningBy(Student::isMale,
                                                                      collectingAndThen(
                                                                      maxBy(comparingInt(Student::getScore), Optional::get)
                                                  )
);
```

### groupingBy()에 의한 분류

stuStream을 반 별로 그룹지어 Map에 저장하는 방법은 다음과 같다.

```java
Map<Integer, List<Student>> stuByBan = stuStream.collect(groupingBy(Student::getBan)); // toList()가 생략됨
```

groupingBy()로 그룹화를 하면 기본적으로 List<T>에 담는다. 만일 원한다면, toSet()이나 toCollection(HashSet::new)을 사용할 수도 있다. 단, Map의 지네릭 타입도 적절히 변경해줘야 한다.

```java
Map<Integer, HashSet<Student>> stuByHak = stuStream.collect(groupingBy(Student::getHak, toCollection(HashSet::new)));
```



















