Flux에서 중복을 제거하고 고유한 값만 유지하기 위해서는 `distinct()` 연산자를 사용할 수 있다. `distinct()`는 기본적으로 `equals()`와 `hashCode()`를 사용하여 중복을 판단한다.
예를 들어, 다음과 같이 코드를 작성할 수 있다.

```java
Flux<SomeObject> flux = someFlux
    .flatMap(item -> getDataFromDB(item))
    .distinct();  // 중복 제거
```

만약 특정 필드를 기준으로 중복을 제거하고 싶다면 `distinctUntilChanged()`를 사용할 수 있다.

```java
Flux<SomeObject> flux = someFlux
    .flatMap(item -> getDataFromDB(item))
    .distinctUntilChanged(SomeObject::getId);  // id 필드를 기준으로 중복 제거
```

또는 `distinctUntilChanged()`에 비교 로직을 직접 구현할 수도 있다.

```java
Flux<SomeObject> flux = someFlux
    .flatMap(item -> getDataFromDB(item))
    .distinctUntilChanged((prev, curr) -> prev.getId().equals(curr.getId()));
```

이렇게 하면 flatMap으로 변환된 Flux에서 중복된 결과를 제거하고 고유한 값만 유지할 수 있다. 선택한 방법은 데이터의 특성과 중복을 판단하는 기준에 따라 달라질 수 있다.

ChatRoomResponse[
    id=681da5f4ba280764e1f8d7eb, 
    orderId=Test order id 1, 
    roomName=Test chat room 1, 
    participantIds=[681da5f4ba280764e1f8d7ea], 
    lastMessage=Test last message of chat room, 
    lastSender=Test last sender of chat room, 
    lastMessageTime=2025-05-09T14:51:20.560]