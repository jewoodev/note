## 2. Sinks.Many

Spring Webflux 의 Sinks.Many 는 Sinks.many() 메서드를 통해 여러 건의 데이터를 여러가지 방식으로 전송하는 기능을 정의해둔 기능 명세이다.

> Sinks 는 Publisher 의 역할을 할 경우 기본적으로 Hot Publisher 로 동작한다.

Sinks.many()는 내부적으로 ManySpec 인터페이스를 리턴한다. ManySpec 은 총 세가지 기능을 정의하는데 각각의 기능은 또다시 별도의 Spec을 정의한다.

```java
public interface ManySpec {
    UnicastSpec unicast();
    MulticastSpec multicast();
    MulticastReplaySpec replay();
}
```

- UnicastSpec 은 단 하나의 Subscriber 에게만 데이터를 emit 한다.
- MulticastSpec 은 하나 이상의 Subscriber 에게 데이터를 emit 한다.
- MulticastReplaySpec 은 emit 된 데이터 중에서 특정 시점으로 되돌린 데이터부터 emit 한다.


