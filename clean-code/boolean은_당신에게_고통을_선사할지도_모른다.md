최근 [Don't use booleans](https://www.luu.io/posts/dont-use-booleans)라는 글을 읽고, 저자와 같은 고민을 해볼 필요가 있다는 생각이 들어 작성하게 되었다. 해당 글에서는 함수 파라미터에 boolean을 사용하는 것이 코드 가독성과 유지보수성에 얼마나 부정적인 영향을 미치는지 이야기하며 열거형을 대안으로 제안하고 있다.

나도 boolean 파라미터를 사용할 때 유사한 문제에 직면할 수도 있겠다는 생각이 들었다. 이번 글에서는 이런 문제와 해결책을 Java/Spring 관점에서 살펴보고자 한다.

## 1. Boolean 파라미터의 문제점

Spring 애플리케이션에서 boolean 파라미터는 흔히 다음과 같이 사용될 수 있다.

- 조건적인 로직 처리: 특정 로직을 실행할지 여부를 결정.
- 옵션 플래그: 데이터베이스 조회시 캐시를 사용할지 여부를 나타내는 경우.
  <br/>

다음은 boolean 파라미터가 사용되는 예시 코드다.

```java
public void fetchData(boolean includeDetails, boolean useCache) {
    if (useCache) {
        // 캐시에서 데이터 조회
    } else {
        // 원본 데이터베이스 조회
    }

    if (includeDetails) {
        // 추가 데이터를 조회
    }
}
```

이 함수 호출 부분을 보면 가독성이 떨어지는 문제가 발생한다.

```java
fetchData(true, false); // 이게 무슨 뜻일까?
```

여기서 true, false가 무엇을 의미하는지 코드를 따로 찾아보지 않으면 이해하기 어렵다.

---

## 2. Enum 활용하기

위 문제를 해결하기 위해 boolean 대신 Enum을 활용할 수 있다. Enum을 사용하면 파라미터의 의미를 명확히 표현할 수 있다.

```java
public enum FetchOption {
    INCLUDE_DETAILS,
    USE_CACHE,
    NO_CACHE
}
```

이제 메서드는 다음과 같이 개선될 수 있다.
```java
public void fetchData(Set<FetchOption> options) {
    if (options.contains(FetchOption.USE_CACHE)) {
        // 캐시에서 데이터 조회
    } else {
        // 원본 데이터베이스 조회
    }

    if (options.contains(FetchOption.INCLUDE_DETAILS)) {
        // 추가 데이터를 조회
    }
}
```

그리고 호출부는 더 명확해진다.

```java
fetchData(Set.of(FetchOption.INCLUDE_DETAILS, FetchOption.NO_CACHE));
```

---

## 3. Spring 컨트롤러에서도 활용하기

Spring MVC 환경에서도 boolean 플래그는 흔히 쿼리 파라미터로 전달된다.

```java
@GetMapping("/users")
public List<User> getUsers(@RequestParam boolean includeDetails) {
    if (includeDetails) {
        // 상세 정보 포함
    } else {
        // 기본 정보만
    }
}
```

이 경우도 Enum으로 대체할 수 있다.

```java
public enum UserFetchType {
    BASIC,
    DETAILED
}
```

컨트롤러 메서드는 다음과 같이 변경된다.

```java
@GetMapping("/users")
public List<User> getUsers(@RequestParam UserFetchType fetchType) {
    if (fetchType == UserFetchType.DETAILED) {
        // 상세 정보 포함
    } else {
        // 기본 정보만
    }
}
```

API 호출부에서도 `fetchType=DETAILED`처럼 명확한 값을 사용할 수 있어, 클라이언트와 서버 간의 의사소통도 더 명확해진다.

---

## 4. 결론

늦은 밤까지 작업을 하고 있는 상황을 상상해보면, 아마도 저는 눈을 가늘게 뜨고 잘못된 곳에 true/false를 전달할 거 같다. 그리고 이로 인한 문제는 나중에 발견되어서 원인을 찾기 어려울 것만 같다.

모든 코드베이스에는 항상 얼마나 ‘오버 엔지니어링’ 해야 하는지에 대해 고민해봐야 할 필요가 있다. 이 포스팅에서 살펴본 주제에 대해 나는 boolean을 열거형으로 대신하는 것으로 생기는 오버헤드보다 얻을 수 있는 이점이 크다고 생각한다.

코드에서 boolean 파라미터를 사용할 때 “Enum이나 더 명확한 대안을 사용할 수는 없는지” 한 번 고민해보는 건 어떨까? 그런 고민에서 만들어지는 작은 변화가 코드의 품질을 크게 개선할 수 있다고 생각한다.
