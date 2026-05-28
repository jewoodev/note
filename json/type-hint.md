> [Spring Data Redis #2697에서 살펴보는 타입 힌트](https://github.com/spring-projects/spring-data-redis/issues/2697)

## 1. 왜 타입 힌트가 필요한가 — JSON은 Java 타입을 잃어버린다

Java 객체를 JSON으로 직렬화하면 클래스 정보가 사라집니다. 예를 들어:

```java
Person p = new Person("Kim", 30);
// → {"name":"Kim","age":30}
```

이 JSON만 봐서는 역직렬화할 때 이게 Person인지, Map<String,Object>인지, Employee인지 알 수 없습니다. 보통은 objectMapper.readValue(json, Person.class)처럼 목표 타입을 명시하니까 문제가 없죠.

그런데 Spring Data Redis의 직렬/역직렬화 도구 `GenericJackson2JsonRedisSerializer`는 이름 그대로 "제네릭(generic)" 입니다. Redis 캐시에 들어오는 게 `Person`일지 `List`일지 `Map`일지 미리 알 수 없는 상태에서 아무 객체나 직렬화하고, 다시 정확히 같은 타입으로 복원해야 합니다. 역직렬화 시 목표 타입이 사실상 `Object`인 거죠.

```java
// 역직렬화 진입점 — 목표 타입을 모른 채 Object로 읽음
Object value = objectMapper.readValue(bytes, Object.class);
```

Object.class로 읽으면 Jackson은 `{"name":"Kim"}`을 그냥 `LinkedHashMap`으로 만들어 버립니다. `Person`으로 복원이 안 되죠. 이걸 해결하려고 타입 정보를 JSON 안에 같이 박아 넣는 기능이 바로 Jackson의 default typing이고, 그렇게 박힌 타입 정보가 타입 힌트입니다.

## 2. 타입 힌트는 실제로 어떻게 생겼나

대상이 객체냐 배열이냐에 따라 모양이 다릅니다.

객체(JSON {}) — 프로퍼티로 @class를 추가 (As.PROPERTY 방식):

```json
{"@class":"com.example.Person","name":"Kim","age":30}
```

여기서 `"@class":"com.example.Person"`이 타입 힌트입니다. 역직렬화 시 이 값을 보고 `Class.forName("com.example.Person")`으로 클래스를 찾아 `Person`을 만듭니다.

배열/컬렉션(JSON []) — 배열에는 프로퍼티를 못 붙이니까 앞에 타입을 끼운 2-원소 배열로 감쌈 (As.WRAPPER_ARRAY 방식):

```
["java.util.ArrayList",[2953]]
```

`"java.util.ArrayList"`가 타입 힌트, `[2953]`이 실제 데이터입니다. 이게 이슈에서 `gcharondkt`가 디버깅하며 발견한 `"With ArrayList: ["java.util.ArrayList",[2953]]"` 의 정체입니다.

## 3. 어떤 타입은 힌트를 일부러 안 붙인다

모든 값에 힌트를 붙이는 건 아닙니다. `GenericJackson2JsonRedisSerializer.java:640-660`의 `useForType`이 "이 타입에 힌트를 붙일지" 판단합니다.

- `Integer`, `String`, `Boolean` 같은 원시/래퍼 → JSON 리터럴(30, "Kim", true)만 봐도 타입이 명확하므로 힌트 불필요 (:649)
- `final`이면서 `java.` 패키지인 타입 → 힌트를 생략 (:653-656)

두 번째 규칙이 왜 있냐면 — `Stream.toList()`가 반환하는 실제 타입은 `java.util.ImmutableCollections$ListN`인데, 이건 `private final` 클래스입니다. 외부에서 `Class.forName(...)`으로 접근할 수 없어요. 그래서 "@class":"java.util.ImmutableCollections$ListN"이라고 적어봤자 역직렬화 때 클래스를 못 찾아서 어차피 실패합니다. 그래서 "어차피 못 읽을 거 아예 힌트를 안 적는다"는 의도로 만든 규칙입니다.

## 4. 그런데 여기서 비대칭(버그)이 생긴다

문제는 직렬화 쪽은 "힌트 안 붙임"을 결정했는데, 역직렬화 쪽은 여전히 "힌트가 있을 것"이라고 가정한다는 점입니다.

```
Stream.toList()  ──직렬화──▶  [2953]      ← 힌트 생략됨
──역직렬화─▶  💥 InvalidTypeIdException
```

역직렬화 시 루트 타입이 `Object`이고 `default typing`이 켜져 있으니, Jackson은 JSON 배열을 보면 `["타입", 데이터]` 포맷일 거라고 가정합니다 (AsArrayTypeDeserializer). 그래서 [2953]의 첫 원소 2953을 타입 ID(클래스 이름)로 해석하려다가:

```
Could not resolve type id '2953' as a subtype of java.lang.Object
```

이런 에러가 납니다. 2953이라는 클래스가 있을 리 없죠.

반면 `new ArrayList<>(...)`는 `ArrayList`가 `non-final`이라 `:653` 조건에 안 걸려 힌트가 정상적으로 붙고(`["java.util.ArrayList",[2953]]`), 역직렬화도 잘 됩니다. 이게 "직렬화는 되는데 역직렬화만 안 되는" 비대칭 버그의 정체입니다.
