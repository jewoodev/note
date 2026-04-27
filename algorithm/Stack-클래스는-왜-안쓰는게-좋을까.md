### 1. 불필요한 동기화 오버헤드

`Stack`은 `Vector`를 상속받고, `Vector`의 모든 메서드는 `synchronized`야. 멀티스레드 환경에서 안전하게 쓰려고 만든 건데, **대부분의 경우 단일 스레드에서 쓰잖아**. 그럴 때마다 락을 걸고 푸는 비용이 공짜로 따라와. 코테에서도 `Stack` 쓴 풀이가 `ArrayDeque` 쓴 풀이보다 느린 경우가 종종 있어.

### 2. 잘못된 상속 관계

`Stack extends Vector`라는 설계 자체가 Java의 유명한 실수 중 하나야. 스택은 **LIFO만 지원**해야 하는데, `Vector`를 상속받으면서 `get(int index)`, `add(int index, E element)` 같은 **임의 위치 접근 메서드**가 다 딸려와. 즉, `Stack`으로 선언해놓고도 중간 원소에 접근할 수 있어서 스택의 불변식이 깨져.

```java
Stack<Integer> s = new Stack<>();
s.push(1); s.push(2); s.push(3);
s.get(0);  // 1 ← 이게 왜 되지? 스택인데?
```

이걸 **LSP(리스코프 치환 원칙) 위반**이라고도 하지.

### 3. `ArrayDeque`가 더 빠름

`ArrayDeque`는 원형 배열 기반이라 캐시 친화적이고, 동기화 오버헤드도 없어. push/pop 모두 amortized O(1)이고, `Stack`보다 2~3배 빠르다는 벤치마크가 많아.

---

### 대안 정리

| 용도 | 추천 |
| --- | --- |
| 단일 스레드 스택 | `ArrayDeque` (push/pop/peek) |
| 단일 스레드 큐 | `ArrayDeque` (offer/poll/peek) |
| 멀티 스레드 스택/큐 | `java.util.concurrent`의 `ConcurrentLinkedDeque`, `LinkedBlockingDeque` 등 |
| 레거시 코드 | `Stack`, `Vector` (새로 쓰지 말 것) |

`ArrayDeque`는 스택으로도 쓸 수 있고 큐로도 쓸 수 있어서 아주 유용해. 실무에서도 `Deque<Integer> stack = new ArrayDeque<>();` 패턴을 많이 봐.

---

Java 공식 문서의 `Stack` 클래스 javadoc에는 이런 문구도 있어:

> "A more complete and consistent set of LIFO stack operations is provided by the `Deque` interface and its implementations, which should be used in preference to this class."
>