# React `useMemo` 훅

이 문서는 `LiquidityClassificationPage.tsx`의 코드를 예로 들어 React의 `useMemo` 훅을 정리한 개인 노트다.

## `useMemo`의 역할

`useMemo()`는 컴포넌트가 다시 렌더링될 때 이전 계산 결과를 재사용할 수 있게 하는 React 훅이다.

`Memo`는 메모이제이션(memoization)을 뜻한다. 메모이제이션은 입력이 같으면 이전에 계산한 결과를 다시 사용하는 최적화 기법이다.

기본 형태는 다음과 같다.

```tsx
const cachedValue = useMemo(
  () => calculateValue(),
  [dependencies],
);
```

`useMemo()`는 두 가지를 전달받는다.

1. 값을 계산해서 반환하는 함수
2. 계산에 사용되는 의존성 배열

첫 렌더링에서는 계산 함수를 실행한다. 이후 렌더링에서는 의존성이 이전과 같으면 저장해 둔 결과를 반환하고, 의존성이 달라지면 다시 계산한다.

```text
첫 렌더링
→ 계산 함수 실행
→ 계산 결과 저장·반환

다음 렌더링
→ 의존성 비교
→ 같으면 이전 결과 반환
→ 다르면 다시 계산하고 새 결과 저장·반환
```

React는 각 의존성을 이전 값과 `Object.is` 방식으로 비교한다.

## 일반 계산과의 차이

컴포넌트 함수는 렌더링할 때마다 다시 실행된다.

```tsx
const filteredContracts = filterLiquidityContracts(
  contracts,
  filters,
);
```

이 코드는 렌더링할 때마다 필터 계산을 다시 한다.

`useMemo()`로 감싸면 관련 데이터가 바뀌지 않은 렌더링에서는 이전 결과를 재사용할 수 있다.

```tsx
const filteredContracts = useMemo(
  () => filterLiquidityContracts(contracts, filters),
  [contracts, filters],
);
```

다만 `filters`가 렌더링할 때마다 새 객체로 만들어지면 객체의 내용이 같아도 참조가 달라져 다시 계산한다. 이 경우 객체 자체보다 실제 원시값을 의존성으로 사용하는 것이 더 명확할 수 있다.

## 유동성 화면의 필터 계산

현재 유동성 화면은 다음처럼 계약 목록과 필터 값이 달라질 때만 필터링을 다시 수행한다.

```tsx
const filteredContracts = useMemo(() => {
  if (asOf === null) return [];

  return filterLiquidityContracts(contracts, {
    corporation: corporationFilter,
    installmentCompany: companyFilter,
    vehicleNumber: activeVehicleSearch,
  });
}, [
  activeVehicleSearch,
  asOf,
  companyFilter,
  contracts,
  corporationFilter,
]);
```

다음 값이 모두 이전 렌더링과 같으면 기존 `filteredContracts` 배열을 재사용한다.

- `activeVehicleSearch`
- `asOf`
- `companyFilter`
- `contracts`
- `corporationFilter`

예를 들어 사용자가 아직 확정하지 않은 기준일 입력값 `asOfInput`만 바꿨다면 위 의존성은 바뀌지 않는다. 화면은 다시 렌더링되지만 계약 필터는 다시 계산하지 않는다.

반대로 법인 필터를 변경하면 `corporationFilter`가 달라지므로 계약 목록을 다시 필터링한다.

## 유동성 합계 계산

필터 결과가 달라질 때만 유동·비유동 원금 합계를 다시 계산한다.

```tsx
const totals = useMemo(
  () => sumLiquidityContracts(filteredContracts),
  [filteredContracts],
);
```

동작 관계는 다음과 같다.

```text
계약 또는 필터 변경
→ filteredContracts 다시 계산
→ filteredContracts 참조 변경
→ totals 다시 계산
```

필터 결과가 재사용되면 `totals`도 이전 계산 결과를 재사용한다.

## 필터 선택지 계산

서버가 반환한 계약이 바뀔 때만 법인과 할부사 선택지를 다시 만든다.

```tsx
const corporations = useMemo(
  () => [
    ...new Set(
      contracts
        .map(({ corporation }) => corporation)
        .filter(Boolean),
    ),
  ].sort((left, right) => left.localeCompare(right, 'ko-KR')),
  [contracts],
);
```

```tsx
const companies = useMemo(
  () => [
    ...new Set(
      contracts.map(
        ({ installmentCompany }) => installmentCompany,
      ),
    ),
  ].sort((left, right) => left.localeCompare(right, 'ko-KR')),
  [contracts],
);
```

계약 목록에서 값을 꺼내고, 중복을 제거하고, 한글 순서로 정렬하는 작업을 매 렌더링마다 반복하지 않도록 한다.

## `useState`와의 차이

`useState()`는 사용자의 입력이나 이벤트로 변경되는 상태를 저장한다.

```tsx
const [asOfInput, setAsOfInput] = useState(koreaLocalDate());
```

`useMemo()`는 기존 값들로부터 계산할 수 있는 파생값을 캐시한다.

```tsx
const totals = useMemo(
  () => sumLiquidityContracts(filteredContracts),
  [filteredContracts],
);
```

```text
useState
→ 값을 상태로 보관한다.
→ 변경 함수를 통해 직접 변경한다.

useMemo
→ 다른 값으로부터 계산한 결과를 임시로 재사용한다.
→ 의존성이 바뀌면 자동으로 다시 계산한다.
```

`useMemo()`의 결과를 변경하려고 별도 변경 함수를 호출하지 않는다.

## `useEffect`와의 차이

`useMemo()`의 계산 함수는 렌더링 중 실행되며 값을 반환해야 한다.

```tsx
const total = useMemo(
  () => rows.reduce((sum, row) => sum + row.principal, 0),
  [rows],
);
```

`useEffect()`는 렌더링 이후 URL, 브라우저 API, 네트워크 연결 같은 외부 상태를 동기화한다.

```tsx
useEffect(() => {
  document.title = `${rows.length}건`;
}, [rows.length]);
```

`useMemo()` 안에서 URL을 변경하거나 네트워크 요청을 보내는 등의 부수 효과를 수행하면 안 된다.

```tsx
// 잘못된 사용
useMemo(() => {
  setSearchParams({ page: '2' });
}, [setSearchParams]);
```

값 계산은 순수해야 한다. 같은 입력을 받으면 같은 결과를 반환하고 외부 상태를 변경하지 않아야 한다.

## 의존성 배열

계산 함수 안에서 사용하는 컴포넌트의 반응형 값은 의존성 배열에 포함해야 한다.

```tsx
const filtered = useMemo(
  () => contracts.filter(
    (contract) => contract.corporation === corporationFilter,
  ),
  [contracts, corporationFilter],
);
```

`corporationFilter`를 누락하면 필터가 바뀌어도 이전 결과가 남을 수 있다.

```tsx
// 잘못된 의존성 배열
const filtered = useMemo(
  () => contracts.filter(
    (contract) => contract.corporation === corporationFilter,
  ),
  [contracts],
);
```

React Hooks 린터가 설정되어 있다면 누락된 의존성을 검사해 준다.

## 객체와 배열 의존성 주의

JavaScript에서는 내용이 같은 객체와 배열을 새로 만들더라도 서로 다른 값으로 비교된다.

```ts
{} !== {};
[] !== [];
```

따라서 다음 코드는 렌더링할 때마다 `filters`가 새 객체가 되어 메모이제이션 효과를 없앨 수 있다.

```tsx
const filters = {
  corporation: corporationFilter,
};

const filtered = useMemo(
  () => filterLiquidityContracts(contracts, filters),
  [contracts, filters],
);
```

필요하다면 객체를 계산 함수 안에서 만들고 실제 원시값을 의존성으로 사용한다.

```tsx
const filtered = useMemo(
  () => filterLiquidityContracts(contracts, {
    corporation: corporationFilter,
  }),
  [contracts, corporationFilter],
);
```

## 성능 최적화 용도

`useMemo()`는 정확한 동작을 보장하기 위한 상태 저장소가 아니라 성능 최적화 수단이다.

다음과 같은 경우에 가치가 있다.

- 큰 배열을 필터링하거나 정렬하는 계산
- 눈에 띄게 느린 계산
- 의존성은 자주 바뀌지 않지만 컴포넌트는 자주 렌더링되는 경우
- 메모이제이션된 자식 컴포넌트에 배열이나 객체를 전달하는 경우
- 다른 훅의 의존성으로 안정된 객체 참조가 필요한 경우

다음과 같은 단순 계산은 바로 수행해도 충분할 수 있다.

```tsx
const total = currentPrincipal + nonCurrentPrincipal;
```

모든 계산을 습관적으로 `useMemo()`로 감싸면 코드가 복잡해지고 의존성 관리 부담이 생긴다.

## 캐시를 동작의 전제로 사용하지 않기

React는 특정한 이유로 `useMemo()`의 캐시를 버릴 수 있다. 따라서 캐시가 사라져 계산 함수가 다시 실행되어도 결과가 동일해야 한다.

다음처럼 최초 한 번만 만들어져야 하는 값이나 사용자 상태를 `useMemo()`에 의존하면 안 된다.

```tsx
// 상태 보관 목적으로 사용하지 않는다.
const draft = useMemo(() => createDraft(), []);
```

값이 컴포넌트 상태라면 `useState()`, 렌더링과 무관하게 같은 객체를 유지해야 한다면 상황에 따라 `useRef()`가 더 적합할 수 있다.

## 첫 렌더링과 Strict Mode

`useMemo()`는 첫 렌더링의 계산을 생략하지 않는다. 첫 렌더링에서는 반드시 계산 함수를 실행한다. 이후 렌더링에서 불필요한 재계산을 줄이는 역할이다.

개발 환경의 React Strict Mode에서는 계산 함수의 순수성을 확인하기 위해 계산이 추가로 실행될 수 있다. 계산 함수가 순수하다면 결과에 문제가 없어야 한다.

## 훅 호출 위치

다른 React 훅과 마찬가지로 `useMemo()`는 컴포넌트나 사용자 정의 훅의 최상위에서 호출한다.

```tsx
// 올바른 사용
const filtered = useMemo(
  () => filterLiquidityContracts(contracts, filters),
  [contracts, filters],
);
```

조건문이나 반복문 안에서 호출하면 안 된다.

```tsx
// 잘못된 사용
if (contracts.length > 0) {
  const filtered = useMemo(
    () => filterLiquidityContracts(contracts, filters),
    [contracts, filters],
  );
}
```

## 핵심 요약

```text
useMemo
→ 렌더링 사이에 계산 결과를 캐시한다.
→ 의존성이 같으면 이전 결과를 반환한다.
→ 의존성이 바뀌면 계산 함수를 다시 실행한다.
→ 계산 함수는 순수하고 반환값이 있어야 한다.
→ 상태 저장이나 부수 효과가 아니라 성능 최적화에 사용한다.
→ 코드가 useMemo 없이도 올바르게 동작해야 한다.
```

## 참고 자료

- [React 공식 문서: useMemo](https://react.dev/reference/react/useMemo)
