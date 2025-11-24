Websocket 연결을 서버에서 사용할 때는 Http 연결을 사용할 때와 어떠한 차이점이 있는지, 그 중에서 개발 과정에서 어떤 차이점이 있는지 살펴보자.

WebSocket 핸들러(`WebSocketHandler`)를 사용할 때는 일반적인 HTTP 요청과 달리, Spring이 제공하는 자동 객체 매핑 기능을 사용할 수 없다. 그 이유를 아래에서 설명하며, 요청 및 응답 처리 로직에서 왜 이런 차이가 생기는지 다룬다.

---

## 1. 요청 처리 (WebSocket 메시지로 받은 Payload)

### 1.1 Spring HTTP 요청 처리와의 차이점

- HTTP 요청의 경우, `@RequestBody`, `@PathVariable`, 또는 `@RequestParam` 등을 사용하면 Spring이 Jackson과 같은 JSON 변환 라이브러리를 통해, 요청 데이터를 객체로 매핑해준다.
- WebSocket 처리에서는 요청 데이터가 텍스트 또는 바이너리 메시지의 **raw 형태**(Payload)로 전달된다. 이 데이터는 단순히 WebSocket 세션을 통해 전달되며, HTTP 메시지 바인딩 컨텍스트(`HandlerMethodArgumentResolver`)가 적용되지 않는다.

### 1.2 **결과적으로...**

WebSocket으로 전달된 메시지는 `WebSocketMessage` 객체 안에 단순히 작동하며, 이를 직접 파싱하거나 변환해야 한다.

```java
.map(WebSocketMessage::getPayloadAsText)
.flatMap(chatService::processMessage) // 직접 파싱
```

Spring이 자동으로 데이터를 객체로 매핑해 줄 수 없는 이유는 WebSocket은 HTTP와 달리 명확한 MIME 타입(예: application/json)이 없으며, 메시지의 형식이 서버와 클라이언트 간의 약속에 의해 정의되기 때문이다.

---

## 2. 응답 처리

### 2.1 Spring HTTP 응답 처리와의 차이점

- HTTP 방식에서는 컨트롤러 메서드에서 반환된 DTO 객체를 Spring이 Jackson과 같은 JSON 직렬화 도구를 이용해 응답으로 자동 변환한다.

    ```java
    @GetMapping("/example")
    public MyResponse getResponse() {
        return new MyResponse(...);
    }
    ```

    여기서 `MyResponse` 객체는 `application/json`으로 변환되어 클라이언트로 보내진다.

- WebSocket에서는 응답 역시 명시적으로 직렬화를 처리해야 한다. WebSocket은 HTTP의 Content Negotiation 방식을 따르지 않으며, 메시지의 직렬화/역직렬화는 클라이언트와 서버가 어떤 데이터 형식을 사용할지 약속해야 하는 영역이다.

#### 2.2 **결과적으로...**

WebSocket 응답에서도 Spring이 Jackson을 통해 자동으로 객체를 직렬화하지 않으므로 직접적으로 처리해야 한다.

```java
.map(response -> {
    // Java 객체 -> JSON 형식으로 변환
    return objectMapper.writeValueAsString(response);
})
.map(session::textMessage)  // 변환 후 WebSocketMessage 생성
```

---

## 3. 왜 HTTP처럼 자동 변환이 어려운가?

1. **WebSocket은 프레임워크 표준이 부족**
    - WebSocket 메시지의 구조와 데이터 직렬화 방식이 HTTP처럼 표준화되어 있지 않고, 텍스트 또는 바이너리 메시지를 그대로 사용한다.
    - Spring MVC / WebFlux HTTP 요청과 달리, WebSocket은 일반적으로 사용되는 메시징 포맷(e.g., JSON, Protocol Buffers)을 명시적으로 설정해야 한다.

2. **WebSocket은 상태 유지 세션 기반** (연속된 메시지를 사용)
    - HTTP는 요청-응답 사이클 기반으로 작동하지만, WebSocket은 지속적인 연결 속에서 다수의 메시지를 송수신한다. 각각의 메시지는 컨텍스트 정보를 가지지 않으므로 메시지 자체를 직접 처리해야 한다.

3. **WebSocket은 압축 또는 특정 표현 방법을 강제하지 않음**
    - 클라이언트에 따라 텍스트 형식, 바이너리 형식 등 여러 메시지 표현 방법을 사용할 수 있다. 따라서 모든 메시지를 객체로 직렬화/역직렬화하려면 공통적인 프로토콜 구현이 필요하다.

---

## 4. 개선 방안

### 4.1 JSON 데이터 자동 처리 (ObjectMapper 활용)

ObjectMapper 혹은 JSON 직렬화 도구를 사용해 메시지를 파싱할 수 있다. WebSocket에서 JSON 데이터를 사용할 때 이를 한 곳에서 쉽게 처리할 수 있도록 Message Decoder를 만들어 관리하는 것도 좋은 방법이다.

```java
public class WebSocketMessageUtil {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    public static <T> T fromMessage(String payload, Class<T> valueType) {
        try {
            return objectMapper.readValue(payload, valueType);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid message format", ex);
        }
    }

    public static String toMessage(Object response) {
        try {
            return objectMapper.writeValueAsString(response);
        } catch (Exception ex) {
            throw new RuntimeException("Failed to serialize response", ex);
        }
    }
}
```


이 유틸 클래스를 활용해 클라이언트와 서버 간 데이터 직렬화/역직렬화를 관리할 수 있다.

```java
.map(WebSocketMessage::getPayloadAsText)
.map(payload -> WebSocketMessageUtil.fromMessage(payload, ChatMessageReq.class))
.flatMap(chatService::processMessage)
.map(WebSocketMessageUtil::toMessage)
```


### 4.2 메시지 형식 통일

Server와 Client가 사용하는 메시지 포맷(JSON, XML 등)에 대해 명확히 정의하고 이를 활용하자. 예를 들어, JSON 메시지를 규칙으로 삼고 Spring의 `ObjectMapper`를 활용하여 모든 메시지를 처리할 수 있다.

---

### 결론

1. 요청(`messagePayload`)과 응답 전환에서 Spring이 제공하는 HTTP 자동 매핑 또는 직렬화를 사용할 수 없는 이유는 **WebSocket이 MIME 타입에 기반한 표준화된 데이터 처리 방식이 없기 때문**이다.
2. 따라서, 메시지의 파싱과 직렬화/역직렬화는 직접적인 JSON 변환 도구(`ObjectMapper`) 등을 통해 수동으로 처리해야 한다.
3. WebSocket 전용 유틸리티를 작성하거나, 메시지 형식을 통일해 관리하는 방법이 비효율성을 줄이는 데 유효하다.
