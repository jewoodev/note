Reactor 의 Context 는 ThreadLocal 과 유사하지만, ThreadLocal 과 달리 Subscriber 와 매핑된다.

## 1. 컨텍스트에 데이터 쓰기

`contextWrite()` Operator 를 통해 Context 에 데이터를 쓸 수 있다. 이 Operator 의 파라미터는 람다 파라미터의 타입과 리턴값이 Context 이다. 따라서 (or 이를 사용하는 방법은) `contextWrite()` Operator 의 파라미터로 Context 의 API 인 `put()`을 사용해 write 를 한다.

## 2. 컨텍스트에 쓰인 데이터 읽기

컨텍스트에서 데이터를 읽는 방식은 크게 두가지다. 하나는 **원본 데이터 소스 레벨에서 읽는 방식**, 또 하나는 **Operator 체인의 중간에서 읽는 방식**이다.

전자는 `deferContextual()` 이라는 Operator 를 사용해야 한다. 이는 `defer()` Operator 와 같은 방식으로 동작한다. 

`deferContextual()`는 `Function<ContextView, ? extends Mono<? extends T>> contextualMonoFactory`를 파라미터로 갖는다. ContextView API 인 `get()` 류를 사용해 read 를 한다.

따라서 

```java
Mono.deferContextual(ctx ->
                Mono.just(ctx.get(key1) + ", " +
                        ctx.getOrEmpty(key2).orElse("no firstName") + " " +
                        ctx.getOrDefault(key3, "no lastName"))
        )
```

와 같이 사용할 수 있다. 