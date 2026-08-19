# React `useRef`

## 1. `useRef`란?

`useRef`는 React 함수 컴포넌트가 **렌더링 사이에 하나의 값을 계속 기억할 수 있게 하는 훅**이다.

```tsx
import { useRef } from 'react';

const countRef = useRef(0);
```

`useRef()`가 반환하는 객체는 다음과 같은 형태다.

```ts
{
  current: 0,
}
```

저장된 값은 `current` 프로퍼티로 읽고 변경한다.

```tsx
countRef.current += 1;
console.log(countRef.current);
```

컴포넌트가 다시 렌더링되어도 `countRef` 객체와 `countRef.current` 값은 유지된다.

## 2. 일반 변수와의 차이

함수 컴포넌트의 본문은 렌더링할 때마다 다시 실행된다. 따라서 일반 변수는 렌더링마다 다시 만들어진다.

```tsx
function Example() {
  let count = 0;

  count += 1;
  // 다음 렌더링에서는 다시 0부터 시작한다.
}
```

반면 `useRef`로 만든 값은 같은 컴포넌트가 화면에 존재하는 동안 유지된다.

```tsx
function Example() {
  const countRef = useRef(0);

  countRef.current += 1;
  // 다음 렌더링에서도 변경된 값이 유지된다.
}
```

## 3. `useState`와의 차이

`useRef`와 `useState`는 모두 렌더링 사이에 값을 유지하지만, 값을 변경했을 때의 동작이 다르다.

| 구분 | `useState` | `useRef` |
|---|---|---|
| 렌더링 사이에 값 유지 | O | O |
| 값 변경 시 재렌더링 | O | X |
| 화면에 표시되는 값 관리 | 적합 | 부적합 |
| 내부 작업용 값이나 객체 보관 | 가능하지만 불필요한 렌더링이 생길 수 있음 | 적합 |

다음 코드에서 상태를 변경하면 화면이 다시 렌더링된다.

```tsx
const [count, setCount] = useState(0);

setCount(1);
```

반면 참조 값을 변경해도 React는 화면을 다시 렌더링하지 않는다.

```tsx
const countRef = useRef(0);

countRef.current = 1;
```

따라서 사용자가 화면에서 확인해야 하는 값은 일반적으로 `useState`로 관리한다.

```tsx
const [isLoading, setIsLoading] = useState(false);
```

화면을 변경할 필요 없이 내부적으로만 기억하면 되는 값은 `useRef`로 관리할 수 있다.

```tsx
const requestInProgressRef = useRef(false);
```

## 4. 대표적인 사용 사례

### 4.1 DOM 요소 참조

`useRef`를 JSX의 `ref` 속성에 연결하면 실제 DOM 요소를 참조할 수 있다.

```tsx
function SearchForm() {
  const inputRef = useRef<HTMLInputElement | null>(null);

  function focusSearchInput() {
    inputRef.current?.focus();
  }

  return (
    <>
      <input ref={inputRef} />
      <button type="button" onClick={focusSearchInput}>
        검색어 입력으로 이동
      </button>
    </>
  );
}
```

렌더링이 완료되면 React가 `inputRef.current`에 해당 `<input>` DOM 객체를 넣어준다. 요소가 아직 연결되지 않았거나 제거된 상태에서는 `null`일 수 있다.

### 4.2 렌더링 사이에 객체 유지

렌더링할 때마다 다시 만들 필요가 없는 객체를 보관할 수 있다.

```tsx
const generatorRef = useRef<WorkbookGenerator | null>(null);

if (generatorRef.current === null) {
  generatorRef.current = new WorkbookGenerator();
}
```

이렇게 하면 컴포넌트가 다시 렌더링되더라도 기존 `WorkbookGenerator` 인스턴스를 계속 사용한다.

컴포넌트가 화면에서 제거될 때 객체가 사용하던 자원을 정리할 수도 있다.

```tsx
useEffect(() => {
  return () => {
    generatorRef.current?.dispose();
  };
}, []);
```

### 4.3 비동기 작업 중 컴포넌트 생존 여부 확인

서버 응답을 기다리는 동안 사용자가 다른 페이지로 이동할 수 있다. 이때 컴포넌트가 아직 화면에 있는지를 참조 값으로 기록할 수 있다.

```tsx
const mountedRef = useRef(true);

useEffect(() => {
  mountedRef.current = true;

  return () => {
    mountedRef.current = false;
  };
}, []);
```

비동기 작업이 끝난 뒤 값을 확인한다.

```tsx
const result = await loadData();

if (!mountedRef.current) return;

setData(result);
```

이미 화면에서 제거된 컴포넌트라면 후속 작업을 중단한다.

서버 요청 자체도 취소할 수 있다면 `AbortController`와 함께 사용하는 편이 더 좋다. `mountedRef`는 작업 결과를 무시하는 장치이고, 요청 취소는 불필요한 작업 자체를 멈추는 장치다.

### 4.4 중복 작업 방지

React 상태가 반영되어 버튼이 비활성화되기 전에 연속 이벤트가 들어오는 상황을 참조 값으로 방어할 수 있다.

```tsx
const inProgressRef = useRef(false);

async function execute() {
  if (inProgressRef.current) return;

  inProgressRef.current = true;
  try {
    await runTask();
  } finally {
    inProgressRef.current = false;
  }
}
```

이 값은 화면에 보여줄 필요가 없으므로 `useRef`가 적합하다. 로딩 문구나 버튼 비활성화처럼 화면에도 반영해야 한다면 별도의 `useState`를 함께 사용할 수 있다.

### 4.5 타이머 ID 보관

나중에 취소해야 하는 타이머의 ID를 보관할 수 있다.

```tsx
const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

timerRef.current = setTimeout(() => {
  // 작업
}, 500);

function cancelTimer() {
  if (timerRef.current !== null) {
    clearTimeout(timerRef.current);
    timerRef.current = null;
  }
}
```

## 5. TypeScript에서의 타입 선언

초깃값이 `null`이고 나중에 객체가 들어간다면 유니언 타입으로 선언한다.

```tsx
const inputRef = useRef<HTMLInputElement | null>(null);
const workerRef = useRef<Worker | null>(null);
```

항상 숫자만 저장한다면 타입을 명시하지 않아도 초깃값으로부터 추론된다.

```tsx
const retryCountRef = useRef(0);
// current가 number인 ref 객체로 추론된다.
```

참조 값이 `null`일 수 있다면 사용할 때 안전하게 확인한다.

```tsx
workerRef.current?.terminate();
```

또는 조건문으로 타입을 좁힌다.

```tsx
if (workerRef.current !== null) {
  workerRef.current.terminate();
}
```

`workerRef.current!`처럼 non-null assertion을 사용할 수도 있지만, 실제로 `null`이 될 수 없는 흐름인지 확실할 때만 사용해야 한다.

## 6. 주의할 점

### 6.1 화면에 표시되는 값을 `useRef`로 관리하지 않는다

다음 코드는 `countRef.current`를 변경해도 재렌더링되지 않으므로 화면의 숫자가 바로 바뀌지 않는다.

```tsx
function Counter() {
  const countRef = useRef(0);

  return (
    <button onClick={() => { countRef.current += 1; }}>
      {countRef.current}
    </button>
  );
}
```

화면에 보여야 하는 값은 `useState`로 관리하는 것이 맞다.

### 6.2 렌더링 도중 `current`를 무분별하게 변경하지 않는다

렌더링은 JSX를 계산하는 순수한 과정으로 유지하는 것이 좋다. 이벤트 처리나 Effect에서 참조 값을 변경하는 것이 일반적이다.

다만 다음처럼 **한 번만 필요한 객체를 지연 초기화**하고, 같은 입력에서 항상 같은 결과가 나오도록 사용하는 패턴은 허용되는 대표적인 예다.

```tsx
if (generatorRef.current === null) {
  generatorRef.current = new WorkbookGenerator();
}
```

### 6.3 참조 값을 변경해도 Effect가 다시 실행되지 않는다

`ref.current`의 변경은 React가 추적하는 상태 변경이 아니다.

```tsx
useEffect(() => {
  // ref.current가 바뀐 것만으로는 다시 실행되지 않는다.
}, [valueRef.current]);
```

값의 변화에 따라 렌더링이나 Effect를 다시 실행해야 한다면 `useState` 등 React가 추적하는 값을 사용해야 한다.

### 6.4 외부 자원은 정리해야 한다

Worker, 타이머, 구독, 이벤트 리스너처럼 컴포넌트 밖의 자원을 참조로 보관했다면 컴포넌트가 제거될 때 함께 정리한다.

```tsx
useEffect(() => {
  return () => {
    workerRef.current?.terminate();
  };
}, []);
```

## 7. 선택 기준

다음 질문으로 `useState`와 `useRef` 중 무엇을 사용할지 판단할 수 있다.

> 이 값이 바뀌면 사용자가 보는 화면도 다시 계산되어야 하는가?

- 그렇다면 `useState`를 우선 고려한다.
- 아니라면 `useRef`가 적합할 수 있다.

`useRef`는 단순히 “재렌더링되지 않는 state”가 아니다. React의 화면 상태와는 별개로, 컴포넌트가 살아 있는 동안 유지해야 하는 **가변 참조 저장소**라고 이해하는 편이 정확하다.

## 8. 요약

```tsx
const valueRef = useRef(initialValue);
```

- 값은 `valueRef.current`에서 읽고 변경한다.
- 컴포넌트가 다시 렌더링되어도 값이 유지된다.
- `current`를 변경해도 재렌더링되지 않는다.
- DOM 요소, 장기 사용 객체, 타이머 ID, 비동기 작업 상태 등을 보관하는 데 적합하다.
- 화면을 결정하는 값은 일반적으로 `useState`로 관리한다.
- Worker나 타이머 같은 외부 자원은 컴포넌트가 제거될 때 정리한다.
