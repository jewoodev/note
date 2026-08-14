# React `useState` 훅

이 문서는 `LiquidityClassificationPage.tsx`의 코드를 예로 들어 React의 `useState` 훅을 정리한 개인 노트다.

## 배열 구조 분해

다음 문법은 배열의 원소를 순서대로 변수에 대입하는 배열 구조 분해다.

```ts
const [first, second] = ['첫 번째 값', '두 번째 값'];
```

결과는 다음과 같다.

```ts
first === '첫 번째 값';
second === '두 번째 값';
```

`const [a, b]` 문법 자체가 `a`를 현재값, `b`를 변경 함수로 만드는 것은 아니다. 호출한 함수가 어떤 배열을 반환하는지에 따라 두 변수의 역할이 결정된다.

React의 `useState()`는 다음 순서의 배열을 반환한다.

```ts
[현재 상태값, 상태 변경 함수]
```

따라서 다음처럼 구조 분해해서 사용한다.

```tsx
const [value, setValue] = useState(initialValue);
```

변수 이름은 자유롭게 지을 수 있지만 일반적으로 상태값은 `value`, 변경 함수는 `setValue` 형태로 짓는다.

## `useState`의 역할

`useState()`는 컴포넌트가 다시 렌더링되어도 기억해야 하는 값을 React에 저장하는 훅이다.

기본 형태는 다음과 같다.

```tsx
const [현재값, 값을변경하는함수] = useState(초기값);
```

유동성 분류 화면에서는 사용자가 입력란에서 편집 중인 기준일을 저장한다.

```tsx
const [asOfInput, setAsOfInput] = useState(asOf ?? koreaLocalDate());
```

각 값의 역할은 다음과 같다.

- `asOfInput`: 입력란에 표시되는 현재 기준일
- `setAsOfInput`: 기준일 입력값을 변경하는 함수
- `asOf ?? koreaLocalDate()`: 컴포넌트가 처음 만들어질 때 사용할 초기값

`??`는 왼쪽 값이 `null` 또는 `undefined`일 때 오른쪽 값을 사용한다. 따라서 URL에 유효한 기준일이 있으면 그 날짜를 사용하고, 없으면 현재 한국 날짜를 사용한다.

## 입력 필드와 상태 연결

입력 필드에서는 다음처럼 상태를 연결한다.

```tsx
<input
  type="date"
  value={asOfInput}
  onChange={(event) => {
    setAsOfInput(event.target.value);
  }}
/>
```

사용자가 날짜를 선택하면 다음 흐름으로 동작한다.

```text
setAsOfInput() 호출
→ React가 상태값 변경
→ 컴포넌트 다시 렌더링
→ input에 변경된 날짜 표시
```

상태값을 직접 대입해서는 안 된다.

```tsx
// 잘못된 방식
asOfInput = '2026-08-20';

// 올바른 방식
setAsOfInput('2026-08-20');
```

변경 함수는 React에 상태 변경과 재렌더링을 요청한다. 호출 직후 같은 실행 흐름에서 상태 변수가 즉시 새 값으로 바뀐다고 가정하면 안 된다.

## 일반 변수와의 차이

다음과 같은 일반 변수는 컴포넌트가 다시 실행될 때 초기화된다.

```tsx
let asOfInput = '2026-08-14';
```

`useState()`로 저장한 값은 React가 관리하므로 렌더링 사이에도 유지된다.

```tsx
const [asOfInput, setAsOfInput] = useState('2026-08-14');
```

화면에 표시되고 사용자의 동작으로 변경되는 값은 대체로 상태로 관리한다.

## URL 상태와 입력 상태를 분리하는 이유

유동성 분류 화면에는 서로 다른 두 값이 있다.

- `asOf`: URL에 반영되어 조회 기준으로 확정된 날짜
- `asOfInput`: 사용자가 입력란에서 편집 중인 날짜

사용자가 날짜를 바꿀 때는 `asOfInput`만 변경된다. 이때는 URL을 변경하거나 API를 호출하지 않는다.

사용자가 `분류 실행` 버튼을 누르면 입력값을 URL에 반영한다.

```tsx
setSearchParams({ asOf: asOfInput });
```

이렇게 하면 사용자는 날짜를 편집한 뒤 명시적으로 조회를 실행할 수 있다.

## 여러 상태값

하나의 컴포넌트에서 `useState()`를 여러 번 사용할 수 있다.

```tsx
const [asOfInput, setAsOfInput] = useState(asOf ?? koreaLocalDate());
const [validationError, setValidationError] = useState<string | null>(null);
const [vehicleSearchInput, setVehicleSearchInput] = useState(activeVehicleSearch);
```

각 상태는 독립적으로 관리된다.

- `asOfInput`: 기준일 입력값
- `validationError`: 입력 검증 오류
- `vehicleSearchInput`: 차량번호 검색 입력값

## 핵심 요약

```text
useState
→ 렌더링 사이에 값을 기억한다.
→ [현재값, 변경 함수]를 반환한다.
→ 변경 함수를 호출하면 React가 다시 렌더링한다.

const [a, b]
→ 배열의 첫 번째와 두 번째 값을 변수로 꺼내는 문법이다.
→ a와 b의 실제 역할은 호출한 함수의 반환값에 따라 결정된다.
```
