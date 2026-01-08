## 1. CustomDeserializer의 필요성, 구현 시 장점

특정한 경우의 역직렬화 과정에서 생길 수 있는 예외를 핸들링하기 위해서는 `Deserializer`를 구현해야 한다. 그러한 예로 Enum 타입을 사용하는 요청 DTO를 역직렬화하는 경우가 있다. 

`null` 값이 Enum 프로퍼티의 값으로 요청되거나, Enum에 존재하지 않는 값이 요청되면 역직렬화 과정에서 예외가 발생하는데, JacksonException을 통틀어서 400 에러로 처리할 수 없으니 이를 넘겨서 Validator에 에러 처리의 책임을 전가하는 것이 옳다. 이를 위한 `Deserializer`를 구현하는 방법을 알아보자. 아래는 그것의 한 예시이다.

```java
public class CustomEnumDeserializer extends StdDeserializer<Enum<?>> implements ContextualDeserializer {

    public CustomEnumDeserializer() {
        this(null);
    }

    protected CustomEnumDeserializer(Class<?> vc) {
        super(vc);
    }

    @SuppressWarnings("unchecked")
    @Override
    public Enum<?> deserialize(JsonParser p, DeserializationContext ctxt) throws IOException, JacksonException {
        String enumName = p.getValueAsString();
        if (enumName == null) return null;
        Class<? extends Enum> enumType = (Class<? extends Enum>) this._valueClass;
        return Arrays.stream(enumType.getEnumConstants())
                .filter(constant -> constant.name().equals(enumName))
                .findAny()
                .orElse(null);
    }

    @Override
    public JsonDeserializer<?> createContextual(DeserializationContext ctxt, BeanProperty property) throws JsonMappingException {
        return new CustomEnumDeserializer(property.getType().getRawClass());
    }
}
```

1. **클래스 구조**

```java
public class CustomEnumDeserializer extends StdDeserializer<Enum<?>> implements ContextualDeserializer
```

- `StdDeserializer`: Jackson의 기본 Deserializer 클래스를 상속
- `Enum<?>`: 모든 Enum 타입을 처리할 수 있도록 제네릭 사용
- `ContextualDeserializer`: 현재 컨텍스트의 타입 정보를 알 수 있게 해주는 인터페이스

2. **생성자**

```java
public CustomEnumDeserializer() {
    this(null);
}

protected CustomEnumDeserializer(Class<?> vc) {
    super(vc);
}
```

- 기본 생성자: Jackson이 인스턴스화할 때 사용
- protected 생성자: 실제 타입 정보를 받아서 초기화할 때 사용

3. **deserialize 메소드**

```java
@Override
public Enum<?> deserialize(JsonParser p, DeserializationContext ctxt) throws IOException, JacksonException {
    JsonNode jsonNode = p.getCodec().readTree(p);
    JsonNode nameNode = jsonNode.get("name");
    if (nameNode == null) return null;
    String text = jsonNode.asText();
    Class<? extends Enum> enumType = (Class<? extends Enum>) this._valueClass;
    return Arrays.stream(enumType.getEnumConstants())
            .filter(constant -> constant.name().equals(text))
            .findAny()
            .orElse(null);
}
```

- JSON 파싱 과정
    1. JSON을 `JsonNode`로 변환
    2. "name" 필드가 없으면 null 반환
    3. JSON 값을 문자열로 변환
    4. 현재 처리 중인 Enum 타입의 모든 상수를 스트림으로 변환
    5. 입력된 문자열과 일치하는 Enum 상수를 찾음
    6. 일치하는 값이 없으면 null 반환

4. **createContextual 메소드**

```java
@Override
public JsonDeserializer<?> createContextual(DeserializationContext ctxt, BeanProperty property) throws JsonMappingException {
    return new CustomEnumDeserializer(property.getType().getRawClass());
}
```

- 현재 처리 중인 필드의 실제 타입 정보를 받아서 새로운 Deserializer 인스턴스 생성
- 이 메소드가 필요한 이유:
    - 기본 생성자로 생성된 인스턴스는 타입 정보가 없음
    - 실제 JSON 파싱 시점에 타입 정보가 필요
    - `ContextualDeserializer` 인터페이스를 구현하여 타입 정보를 주입받음

이 메소드를 구현하면 Jackson이 타입 정보를 주입해주어 올바른 Enum 타입을 역직렬화할 수 있게 된다.

이 외에도 다양한 예외 상황에 대한 처리를 위해 커스텀 Deserializer를 구현할 수 있다.

이 구현이 프로젝트에 불어넣는 장점이 무엇인지는 아래와 같다.

1. 알 수 없는 Enum 값에 대해 예외를 발생시키지 않고 null 반환
2. 모든 Enum 타입에 대해 재사용 가능
3. 타입 안전성 보장 (제네릭 사용)
4. 컨텍스트 기반의 타입 정보 처리

이러한 구현으로 인해

- JSON 파싱 시 발생하는 예외를 방지
- Validation 단계까지 도달할 수 있게 함
-  더 우아한 에러 처리 가능
- 코드 재사용성 향상

## 2. CustomDesializer의 동작 방식

1. **기본 동작 흐름**

```java
// 1. Jackson이 처음 Deserializer를 생성할 때는 기본 생성자 사용
public CustomEnumDeserializer() {
    this(null);  // _valueClass는 null
}

// 2. 실제 JSON 파싱 전에 createContextual이 호출됨
@Override
public JsonDeserializer<?> createContextual(DeserializationContext ctxt, BeanProperty property) {
    // property.getType().getRawClass()로 실제 Enum 타입 정보를 얻음
    return new CustomEnumDeserializer(property.getType().getRawClass());
}

// 3. 파싱 시점에는 타입 정보가 있는 새로운 인스턴스가 사용됨
@Override
public Enum<?> deserialize(JsonParser p, DeserializationContext ctxt) {
    // this._valueClass에 실제 Enum 타입이 들어있음
    Class<? extends Enum> enumType = (Class<? extends Enum>) this._valueClass;
    ...
}
```

2. **실제 사용 예시로 보는 동작**

```
public class EventRequest {
    private EventStatus status;  // EventStatus enum 타입
}

// JSON 요청
{
    "status": "OPEN"
}
```

동작 순서:

1. Jackson이 `EventRequest` 클래스를 파싱하기 시작
2. `status` 필드를 만나면 `CustomEnumDeserializer`의 기본 생성자로 인스턴스 생성
3. `createContextual` 메소드가 호출되며 `property` 파라미터를 통해 `EventStatus` 타입 정보 전달
4. 타입 정보가 있는 새로운 `CustomEnumDeserializer` 인스턴스 생성
5. 이 인스턴스가 실제 JSON 파싱에 사용됨

3. **BeanProperty의 역할**

```java
public interface BeanProperty {
    // 현재 처리 중인 필드의 타입 정보를 제공
    JavaType getType();
    
    // 필드의 이름
    String getName();
    
    // 필드가 속한 클래스
    Class<?> getDeclaringClass();
    
    // 기타 메타데이터
    ...
}
```

4. **DeserializationContext의 역할**

```java
public abstract class DeserializationContext {
    // 현재 처리 중인 객체의 타입 정보
    public abstract JavaType getActiveView();
    
    // 현재 처리 중인 객체의 클래스
    public abstract Class<?> getActiveViewClass();
    
    // 기타 컨텍스트 정보
    ...
}
```

5. **실제 타입 정보가 필요한 이유**

```java
@Override
public Enum<?> deserialize(JsonParser p, DeserializationContext ctxt) {
    // 타입 정보가 없으면 어떤 Enum의 상수들을 검색해야 할지 알 수 없음
    Class<? extends Enum> enumType = (Class<? extends Enum>) this._valueClass;
    return Arrays.stream(enumType.getEnumConstants())
            .filter(constant -> constant.name().equals(text))
            .findAny()
            .orElse(null);
}
```

이런 방식으로 `ContextualDeserializer`는  

1. 초기에는 타입 정보가 없는 상태로 생성됨
2. 실제 파싱 전에 `createContextual`을 통해 타입 정보를 주입받음
3. 타입 정보가 있는 새로운 인스턴스로 교체
4. 이 인스턴스가 실제 JSON 파싱을 수행

`ContextualDeserializer`의 JavaDoc 내용은 다음과 같다.

```
ObjectMapper(및 그 외에 연결된 JsonDeserializer들)에서 사용되는 API를 정의하는 추상 클래스입니다. JsonParser를 사용하여 임의의 타입의 객체를 JSON에서 역직렬화(deserialize)합니다.
커스텀 deserializer는 보통 이 클래스를 직접 상속하지 않고, 대신 com.fasterxml.jackson.databind.deser.std.StdDeserializer(또는 그 하위 타입인 com.fasterxml.jackson.databind.deser.std.StdScalarDeserializer 등)를 상속해야 합니다.
만약 deserializer가 집합형(aggregate) — 즉, 일부 내용을 다른 deserializer에 위임하는 경우 — 이라면, 보통 ResolvableDeserializer도 구현해야 합니다. 이 인터페이스는 종속된 deserializer를 동적으로 오버라이드할 수 있도록 해줍니다. (종속 deserializer의 분리된 해석이 필요할 수 있기 때문입니다. 예를 들어, deserializer 자신에게 직접 또는 간접적으로 순환 참조가 있을 수 있습니다.)
또한, 프로퍼티별 애노테이션(프로퍼티별로 역직렬화의 특성을 설정)을 지원하기 위해, deserializer는 ContextualDeserializer를 구현할 수 있습니다. 이 인터페이스는 deserializer의 특수화를 허용합니다. ContextualDeserializer.createContextual 호출 시 프로퍼티에 대한 정보가 전달되며, 해당 프로퍼티를 처리할 새로 구성된 deserializer를 생성할 수 있습니다.
만약 ResolvableDeserializer와 ContextualDeserializer가 모두 구현되어 있다면, deserializer의 해석은 contextualization(컨텍스트화) 전에 먼저 수행됩니다.
```

## 3. `getCodec().readTree()`를 사용하는 방법

Enum 타임을 역직렬화하는 부분에서 `getCodec().readTree(p)`를 사용할 수 있다.

### 3.1 getCodec().readTree(p)의 의미
- `p.getCodec().readTree(p)`는 JSON 파서를 통해 현재 위치의 JSON 데이터를 트리 구조(JsonNode)로 읽어오는 것이다.
- 즉, JSON이 단순 문자열이든, 객체든, 배열이든 모두 JsonNode로 변환할 수 있다.

### 3.2 어떨 때 사용하기 좋은가?

#### (1) 복잡한 구조를 지원하려는 의도

만약 JSON이 단순히 `"role": "USER"`이 아니라,  
`"role": { "name": "USER" }`처럼 객체로 들어올 수도 있다고 생각했다면, 
`JsonNode`로 받아서 내부에서 "name" 필드를 꺼내는 식으로 처리할 수 있다.

실제로, 많은 커스텀 역직렬화 예제에서  
다양한 입력 형태(문자열, 객체 등)를 모두 지원하려고 `JsonNode`를 쓴다.

#### (2) Jackson의 유연성 활용

Jackson은 다양한 JSON 구조를 지원한다.

그래서 혹시라도 enum 값이 객체로 올 때를 대비해 `JsonNode`로 받아서 필요한 값을 꺼내는 식으로 작성했을 수 있다.

### 3.3 요약

- `getCodec().readTree(p)`: 다양한 구조 지원(특히 객체 형태)
- `getValueAsString()`: 단순 문자열에 최적, 더 간단하고 안전