# React Router `useSearchParams` 훅

이 문서는 `LiquidityClassificationPage.tsx`의 코드를 예로 들어 React Router의 `useSearchParams` 훅을 정리한 개인 노트다.

## URL의 검색 파라미터

다음 URL은 경로와 검색 파라미터로 나눌 수 있다.

```text
/liquidity?asOf=2026-08-14&corporation=아이카&page=2
```

```text
/liquidity
└─ 경로(pathname)

?asOf=2026-08-14&corporation=아이카&page=2
└─ 검색 파라미터(search parameters)
```

검색 파라미터는 `?` 뒤에 `이름=값` 형태로 기록한다. 여러 파라미터는 `&`로 연결한다.

## `useSearchParams`의 역할

`useSearchParams()`는 현재 URL의 검색 파라미터를 `URLSearchParams` 객체로 읽고 변경할 수 있게 해주는 React Router 훅이다.

```tsx
const [searchParams, setSearchParams] = useSearchParams();
```

`useSearchParams()`가 반환하는 배열을 구조 분해해서 사용한다.

- `searchParams`: 현재 URL 파라미터를 읽는 `URLSearchParams` 객체
- `setSearchParams`: URL 파라미터를 변경하는 함수

`const [a, b]` 문법 자체가 현재값과 변경 함수를 의미하는 것은 아니다. `useSearchParams()`가 `[URLSearchParams 객체, 변경 함수]` 순서로 반환하기 때문에 두 변수가 그런 역할을 갖는다.

## 파라미터 읽기

현재 URL이 다음과 같다고 가정한다.

```text
/liquidity?asOf=2026-08-14&corporation=아이카&page=2
```

각 값은 `get()`으로 읽는다.

```tsx
const asOf = searchParams.get('asOf');
const corporation = searchParams.get('corporation');
const page = searchParams.get('page');
```

결과는 다음과 같다.

```ts
asOf === '2026-08-14';
corporation === '아이카';
page === '2';
```

`get()`의 결과는 항상 문자열 또는 `null`이다. 숫자처럼 보이는 `page=2`도 문자열 `'2'`로 반환된다.

```tsx
const requestedPage = Number(searchParams.get('page') ?? '1');
```

이 코드는 `page`를 숫자로 변환하고, 파라미터가 없으면 기본값 1을 사용한다.

존재하지 않는 파라미터를 읽으면 `null`이 반환된다.

```tsx
searchParams.get('vehicle') === null;
```

빈 문자열을 기본값으로 사용하려면 `??`를 사용할 수 있다.

```tsx
const corporationFilter = searchParams.get('corporation') ?? '';
```

## 파라미터 변경

`setSearchParams()`를 호출하면 객체만 바뀌는 것이 아니라 브라우저 URL이 변경된다.

```tsx
setSearchParams({
  asOf: '2026-08-14',
  page: '2',
});
```

URL은 다음처럼 바뀐다.

```text
/liquidity?asOf=2026-08-14&page=2
```

URL이 바뀌면 React Router가 변경을 감지하고 관련 컴포넌트를 다시 렌더링한다.

## 기존 파라미터를 보존하면서 변경하기

`setSearchParams()`에 새 객체만 전달하면 기존 파라미터가 사라질 수 있다.

예를 들어 현재 URL이 다음과 같을 때:

```text
/liquidity?asOf=2026-08-14&corporation=아이카&page=2
```

다음 코드를 실행하면:

```tsx
setSearchParams({ page: '3' });
```

URL은 다음처럼 되고 기존 `asOf`, `corporation`이 사라진다.

```text
/liquidity?page=3
```

기존 파라미터를 유지하려면 현재 값을 복사한 뒤 필요한 값만 수정한다.

```tsx
const next = new URLSearchParams(searchParams);
next.set('page', '3');
setSearchParams(next);
```

결과:

```text
/liquidity?asOf=2026-08-14&corporation=아이카&page=3
```

현재 프로젝트의 공통 변경 함수도 같은 방법을 사용한다.

```tsx
function updateSearchParams(
  changes: Record<string, string | null>,
  replace = false,
) {
  const next = new URLSearchParams(searchParams);

  Object.entries(changes).forEach(([key, value]) => {
    if (value) next.set(key, value);
    else next.delete(key);
  });

  setSearchParams(next, { replace });
}
```

## `set()`과 `delete()`

파라미터를 추가하거나 변경할 때는 `set()`을 사용한다.

```tsx
const next = new URLSearchParams(searchParams);
next.set('page', '2');
```

파라미터를 제거할 때는 `delete()`를 사용한다.

```tsx
next.delete('page');
```

유동성 화면에서는 1페이지가 기본값이므로 `page=1`을 URL에 기록하지 않는다.

```tsx
if (page === 1) next.delete('page');
else next.set('page', String(page));
```

## `replace: true`

기본적으로 URL을 변경하면 브라우저 방문 기록에 새로운 항목이 추가된다.

```tsx
setSearchParams(next);
```

현재 기록을 교체하려면 `replace: true`를 사용한다.

```tsx
setSearchParams(next, { replace: true });
```

자동 보정처럼 사용자의 새로운 이동으로 볼 필요가 없는 변경에 적합하다.

예를 들어 실제 마지막 페이지가 3인데 URL에 `page=99`가 들어오면 이를 `page=3`으로 보정한다. 이때 기록을 추가하면 사용자가 뒤로 가기를 눌렀을 때 잘못된 `page=99`로 돌아갈 수 있으므로 현재 기록을 교체한다.

## URL을 화면 상태로 사용하는 이유

필터, 기준일, 페이지를 컴포넌트의 `useState()`에만 저장하면 새로고침하거나 다른 화면으로 이동했을 때 상태를 복원하기 어렵다.

검색 상태를 URL에 저장하면 다음 장점이 있다.

- 새로고침해도 검색 조건 유지
- URL 복사와 공유 가능
- 브라우저 뒤로 가기와 앞으로 가기 지원
- 상세 화면에서 목록으로 돌아올 때 필터와 페이지 복원
- 직접 URL을 입력해 같은 화면 상태로 접근 가능

현재 유동성 화면은 다음 상태를 URL에 저장한다.

```text
asOf        기준일
corporation 법인 필터
company     할부사 필터
vehicle     차량번호 검색어
page        페이지 번호
```

예시:

```text
/liquidity
?asOf=2026-08-14
&corporation=아이카
&company=테스트캐피탈
&vehicle=3456
&page=2
```

## `useParams`와의 차이

`useSearchParams()`는 `?` 뒤의 검색 파라미터를 읽는다. 경로에 포함된 값은 `useParams()`로 읽는다.

```text
/liquidity/contracts/123?asOf=2026-08-14
                     │  └─ useSearchParams
                     └─ useParams
```

라우트가 다음과 같이 정의되어 있다면:

```tsx
<Route
  path="/liquidity/contracts/:contractId"
  element={<LiquidityContractDetailPage />}
/>
```

각 값은 다음처럼 읽는다.

```tsx
const { contractId } = useParams();
const [searchParams] = useSearchParams();

contractId === '123';
searchParams.get('asOf') === '2026-08-14';
```

정리하면 다음과 같다.

```text
useParams
→ URL 경로의 :변수 값을 읽는다.

useSearchParams
→ URL의 ? 뒤에 있는 검색 파라미터를 읽고 변경한다.
```

## 핵심 요약

```text
useSearchParams()
→ 현재 URL의 검색 파라미터를 URLSearchParams 객체로 제공한다.
→ [searchParams, setSearchParams]를 반환한다.
→ get()으로 문자열 값을 읽는다.
→ setSearchParams()로 URL을 변경한다.
→ 기존 파라미터를 보존하려면 URLSearchParams를 복사해서 수정한다.
→ 필터와 페이지를 URL 상태로 관리하면 새로고침, 공유, 뒤로 가기를 지원할 수 있다.
```
