Redis Reactive를 사용하면 `redisTemplate.opsForValue().get(key)`의 결과가 `Mono<String>` 타입을 반환한다. 만약 해당 키에 대한 값이 없으면 `Mono.empty()`가 반환된다.

Reactive Streams의 `Mono`에서 `map` 오퍼레이터는 다음과 같이 동작한다.

1. `Mono`가 값을 가지고 있을 때만 `map` 함수가 실행된다.
2. `Mono.empty()`인 경우 (값이 없는 경우) `map` 함수는 실행되지 않고, 그대로 `Mono.empty()`가 반환된다.

따라서 Redis에서 키에 대한 값이 없는 경우에는

- `get`은 `Mono.empty()`를 반환
- `map` 오퍼레이터는 실행되지 않음
- 최종적으로 `Mono.empty()`가 반환됨

이것은 Reactive 프로그래밍의 중요한 특징 중 하나이다. 값이 없는 경우에 대한 처리를 명시적으로 하지 않아도 되며, 스트림이 자연스럽게 빈 결과를 전파한다.
