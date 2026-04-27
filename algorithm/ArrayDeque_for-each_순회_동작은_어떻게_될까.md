# "stream 형태로 만든다"는 (필자의) 오해
이건 오해야. for-each는 **Stream과 무관**해. Java의 for-each 문법(`for (T x : collection)`)은 컴파일 시점에 다음과 같이 변환돼:

```java
Iterator<T> it = collection.iterator();
while (it.hasNext()) {
    T x = it.next();
    ...
}
```

즉, **`Iterator`를 가져와서 `hasNext()` / `next()`로 순회**하는 거야. Stream API와는 전혀 별개의 메커니즘이지.

Stream은 `collection.stream()`으로 명시적으로 만들어야 하고, 용도가 달라 (필터/맵/리듀스 같은 함수형 파이프라인).

# "인덱스 순서대로"
`ArrayDeque`는 내부적으로 원형 배열(circular array)로 구현돼 있고, `iterator()`는 **head부터 tail 방향으로** (즉, **먼저 들어온 원소부터**) 순회해.

여기서 중요한 건 **`push()`와 `head`의 관계**야.

### `ArrayDeque`에서 `push()`가 하는 일

`push(x)`는 `Deque` 인터페이스 관점에서 **스택처럼** 동작해. 내부적으로는 `addFirst(x)`랑 같아. 즉, **head 쪽에 추가**돼.

예시:

```java
ArrayDeque<Integer> s = new ArrayDeque<>();
s.push(1);  // deque: [1]           (head=1, tail=1)
s.push(2);  // deque: [2, 1]        (head=2, tail=1)
s.push(3);  // deque: [3, 2, 1]     (head=3, tail=1)

for (int x : s) System.out.print(x + " ");
// 출력: 3 2 1
```

iterator는 head(=3)부터 tail(=1) 방향으로 가니까, **가장 최근에 push된 것부터** 나와. 즉, **LIFO 순서**로 순회돼.

---

### 정리

- `ArrayDeque` + `push()`로 스택처럼 쓰면, for-each는 **LIFO 순서**로 순회 (최근 push된 것부터)
- 만약 `offer()`나 `add()`로 채웠다면 FIFO 순서 (먼저 들어온 것부터)
- 이 문제에서는 **순회 순서가 결과에 영향을 주지 않음** (스택에 남은 모든 원소를 그냥 X로 바꾸는 거라서)