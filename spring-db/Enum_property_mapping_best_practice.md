Enum 타입의 프로퍼티는 어떻게 dto에 매핑하는게 좋을까?

두 가지 방법이 떠오른다. 

1. 명시적으로 .toString()을 사용하는 방식

2. Jackson의 @JsonValue 어노테이션을 사용하는 방식

Best Practice 관점에서는 Jackson의 @JsonValue 어노테이션을 사용하는 것이 더 권장된다.

- 관심사의 분리: DTO 변환 로직은 단순히 데이터 매핑에 집중하고, Enum의 직렬화 방식은 Enum 자체에서 정의하는 것이 더 객체지향적이다.
- 일관성: Enum 클래스에서 직렬화 방식을 정의하면, 해당 Enum을 사용하는 모든 곳에서 동일한 방식으로 직렬화된다.
- 유지보수성: Enum의 직렬화 방식을 변경해야 할 경우, Enum 클래스 한 곳만 수정하면 된다.
- 테스트 용이성: Enum의 직렬화 로직을 Enum 클래스에서 테스트할 수 있어 단위 테스트가 더 용이하다.

```java
private final String key;
private final String description;

@JsonValue
public String getKey() {
    return key;
}
```

이런 식으로 할 수 있다.

경우에 따라 그냥 Enum 타입을 생으로 넣는 게 더 적합하다면 그렇게 사용하자. String으로 바꿔 쓴다고 얻는 명확한 이점이 없다(JSON 스펙만 생각하면 이게 더 좋을 것 같은 착각이 들지만 아니다. 매퍼를 활용하자.). 