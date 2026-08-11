# React `useEffect` 훅

이 문서는 `LiquidityClassificationPage.tsx`의 코드를 예로 들어 React의 `useEffect` 훅을 정리한 개인 노트다.

## `useEffect`의 역할

`useEffect()`는 렌더링 결과가 반영된 후 외부 상태를 동기화하거나 다른 부수 효과를 수행하는 훅이다.

기본 형태는 다음과 같다.

```tsx
useEffect(() => {
  // 렌더링 후 실행할 작업
}, [의존하는 값들]);
```

대표적인 부수 효과는 다음과 같다.

- URL 변경
- 네트워크 요청
- 브라우저 API 사용
- 이벤트 구독과 해제
- 타이머 생성과 제거

화면을 계산하는 렌더링 과정에서는 외부 상태를 직접 변경하지 않고, 이런 작업을 `useEffect()`에서 처리한다.

## 기준일 입력값 동기화

URL의 기준일이 바뀌면 입력 필드도 같은 날짜를 보여줘야 한다.

```tsx
useEffect(() => {
  if (asOf !== null) setAsOfInput(asOf);
}, [asOf]);
```

의존성 배열에 `asOf`가 있으므로 `asOf`가 바뀐 뒤 효과가 다시 실행된다. 브라우저 뒤로 가기 등으로 URL이 변경되어도 입력값이 URL과 일치하게 된다.

동작 흐름은 다음과 같다.

```text
브라우저 URL의 asOf 변경
→ 컴포넌트 렌더링
→ useEffect 실행
→ setAsOfInput(asOf)
→ 입력 필드가 URL 기준일과 동기화
```

## 유효한 페이지 번호와 URL 동기화

유동성 분류 화면은 필터 결과에 따라 존재할 수 있는 마지막 페이지가 달라진다.

```tsx
const page = normalizeLiquidityPage(
  requestedPage,
  filteredContracts.length,
);
```

예를 들어 URL이 `page=99`지만 실제로 3페이지까지만 존재하면 계산된 `page`는 3이 된다. 다음 효과가 이 계산 결과를 URL에 반영한다.

```tsx
useEffect(() => {
  if (!classificationQuery.data) return;

  const pageParameter = searchParams.get('page');
  const normalizedParameter = page === 1 ? null : String(page);

  if (pageParameter === normalizedParameter) return;

  const next = new URLSearchParams(searchParams);

  if (normalizedParameter === null) next.delete('page');
  else next.set('page', normalizedParameter);

  setSearchParams(next, { replace: true });
}, [classificationQuery.data, page, searchParams, setSearchParams]);
```

동작 예시는 다음과 같다.

```text
/liquidity?asOf=2026-08-14&page=99
→ 실제 마지막 페이지 계산: 3
→ /liquidity?asOf=2026-08-14&page=3
```

1페이지는 기본값이므로 URL에서 `page`를 제거한다.

```text
/liquidity?asOf=2026-08-14&page=1
→ /liquidity?asOf=2026-08-14
```

## 의존성 배열

두 번째 인수인 의존성 배열은 효과를 다시 검사해야 하는 값들을 나타낸다.

```tsx
[
  classificationQuery.data,
  page,
  searchParams,
  setSearchParams,
]
```

이 값 중 하나가 이전 렌더링과 달라지면 효과가 다시 실행된다.

의존성 배열 형태에 따른 차이는 다음과 같다.

```tsx
// 렌더링할 때마다 실행
useEffect(() => {
  // ...
});

// 컴포넌트가 처음 화면에 반영된 뒤 실행
useEffect(() => {
  // ...
}, []);

// value가 달라진 뒤 실행
useEffect(() => {
  // ...
}, [value]);
```

개발 환경의 React Strict Mode에서는 잘못된 부수 효과를 찾기 위해 효과가 추가로 실행될 수 있다. 따라서 효과는 같은 조건에서 다시 실행되어도 문제가 없도록 작성하는 것이 좋다.

## 반복 실행 방지

효과 안에서 상태나 URL을 변경하면 다시 렌더링되고 효과도 다시 실행될 수 있다. 이미 원하는 상태라면 바로 종료하는 방어가 필요하다.

```tsx
if (pageParameter === normalizedParameter) return;
```

이 조건이 있기 때문에 URL이 이미 올바르면 `setSearchParams()`를 다시 호출하지 않는다.

## `replace: true`

```tsx
setSearchParams(next, { replace: true });
```

`replace: true`는 브라우저 방문 기록에 새 항목을 추가하지 않고 현재 항목을 교체한다.

자동으로 잘못된 `page=99`를 `page=3`으로 보정하는 것은 사용자의 새로운 이동이 아니므로 기록을 추가하지 않는 것이 자연스럽다. 그렇지 않으면 사용자가 뒤로 가기를 눌렀을 때 잘못된 `page=99` URL로 다시 돌아갈 수 있다.

## 정리 함수

`useEffect()`는 필요하면 정리 함수를 반환할 수 있다.

```tsx
useEffect(() => {
  const timerId = window.setInterval(doSomething, 1_000);

  return () => {
    window.clearInterval(timerId);
  };
}, []);
```

정리 함수는 효과가 다시 실행되기 전이나 컴포넌트가 화면에서 제거될 때 실행된다. 이벤트 구독, 타이머처럼 사용 후 해제가 필요한 자원에 사용한다.

## `useEffect`가 필요하지 않은 경우

렌더링 중 기존 값으로 바로 계산할 수 있는 값은 `useEffect()`와 별도 상태로 만들 필요가 없다.

```tsx
const pageCount = liquidityPageCount(filteredContracts.length);
```

이 값은 `filteredContracts`로부터 바로 계산할 수 있으므로 효과에서 갱신하지 않는다.

```tsx
// 불필요하게 복잡한 방식
const [pageCount, setPageCount] = useState(1);

useEffect(() => {
  setPageCount(liquidityPageCount(filteredContracts.length));
}, [filteredContracts]);
```

`useEffect()`는 렌더링 계산이 아니라 외부 시스템이나 별도 상태를 동기화할 때 사용한다.

## 핵심 요약

```text
useEffect
→ 렌더링 후 부수 효과를 수행한다.
→ 의존하는 값이 바뀌면 다시 실행된다.
→ 이미 원하는 상태인지 확인해 반복 변경을 막는다.
→ 구독이나 타이머는 정리 함수로 해제한다.
```
