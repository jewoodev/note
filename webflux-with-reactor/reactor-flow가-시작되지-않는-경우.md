Reactor 개발을 하다보니 꽤나 자주 flow가 시작되지 않는 코드를 작성하는 일이 생겨났다. 이건 언제 flow가 시작되고 되지 않는지를 이해하지 못해서 생겨난 문제다.

Reactor flow는 Publisher가 구독되는 시점에 시작된다. 즉, Publisher가 데이터를 emit하기 시작하려면 구독이 일어나아만 한다.

그래서 구독해서 emit된 데이터가 또다른 Publisher인 경우에는 flow가 흐르지 않는다.

```java
class RedisDao {
    public Mono<Boolean> setString(String key, String value) {
        return Mono.just(true);
    }
}

@RequiredArgsConstructor
class WebsocketHandler {
    private final RedisDao redisDao;

    private Mono<Void> handle1(WebsocketSession session) {
        return session.receive()
            .then(Mono.just(redisDao.setString("key", "value")))
            .then();
    }

    private Mono<Void> handle2(WebsocketSession session) {
        return session.receive()
            .then(Mono.just(redisDao.setString("key", "value")))
            .then();
    }
}
```

위의 예시를 살펴보자. 

- `handle1`은 redisDao.setString()이 반환하는 Mono<Boolean>을 직접 구독한다
- `handle2`는 redisDao.setString()이 반환하는 Mono<Boolean>을 값으로 가지는 Mono를 구독한다

그래서 `handle2`의 `setString()`은 실행되지 않는다.

Reactor의 핵심 개념을 정리하고 넘어가자.

## Reactor의 핵심 개념

- Publisher는 구독이 일어나야만 데이터를 emit하기 시작한다
- 구독이 없으면 아무것도 emit하지 않는다 (lazy evaluation)