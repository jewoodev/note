# TanStack Query의 gcTime: 사용하지 않는 조회 캐시의 보관 시간

`gcTime`은 **TanStack Query에서 더 이상 사용하지 않는 쿼리 캐시를 제거하기 전까지 기다리는 시간**이다. 화면에서 사용하는 데이터의 유효기간이나 자동 조회 주기를 뜻하지 않는다.

이 문서는 React와 비동기 HTTP 조회의 기본 개념을 아는 독자를 대상으로 한다. 특정 프로젝트에 대한 지식은 필요하지 않다. 설명과 예제는 **TanStack Query v5**의 `@tanstack/react-query`를 기준으로 한다.

## 1. 조회 캐시는 왜 화면을 떠나도 남아 있을까?

상품 목록 화면에서 데이터를 조회한 뒤 상세 화면으로 이동했다고 가정해 보자. 목록으로 돌아왔을 때 이전 결과가 남아 있으면 표를 바로 보여 줄 수 있다. 필요하다면 그 상태에서 새 데이터를 조회할 수도 있다.

TanStack Query는 QueryClient의 캐시에 조회 결과를 보관하고, 같은 `queryKey`를 사용하는 조회끼리 결과를 공유한다. 화면의 마지막 사용자가 사라져도 재방문을 위해 잠시 남겨 두며, 이때 보관 기간을 정하는 옵션이 `gcTime`이다. [공식 문서: 캐시 동작 예제](https://tanstack.com/query/v5/docs/framework/react/guides/caching)

여기서 캐시는 기본적으로 실행 중인 애플리케이션의 메모리 캐시다. 브라우저 HTTP 캐시나 localStorage와 구분한다. 별도 영속화 기능을 연결하지 않았다면 새로고침 뒤에도 유지되는 저장소로 생각해서는 안 된다.

## 2. 이름과 기본값

`gc`는 garbage collection의 약자다. 이전 버전에서 사용하던 `cacheTime`이 v5에서 `gcTime`으로 바뀌었다. 쿼리를 사용하는 동안의 데이터 만료 시간으로 오해하기 쉬웠기 때문에, 사용하지 않는 캐시의 정리라는 의미를 드러내도록 이름을 변경했다. [공식 문서: v5 이름 변경](https://tanstack.com/query/v5/docs/framework/react/guides/migrating-to-v5#rename-cachetime-to-gctime)

| 설정 | 의미 |
| --- | --- |
| `gcTime: 5 * 60 * 1000` | 사용하지 않는 캐시를 5분 보관. 브라우저의 기본값 |
| `gcTime: 30_000` | 사용하지 않는 캐시를 30초 보관 |
| `gcTime: 0` | 사용하지 않게 되면 보관 대기 시간을 두지 않고 제거 예약 |
| `gcTime: Infinity` | 시간 경과에 따른 자동 제거를 사용하지 않음 |

단위는 밀리초다. 서버 렌더링 환경의 기본값은 Infinity이며, 같은 쿼리에 서로 다른 gcTime이 적용되면 더 긴 값이 사용된다. 일반 타이머의 최대 지연 시간 제약도 있으므로 매우 큰 유한값을 무기한 보관의 대용으로 쓰지 않는다. [공식 문서: useQuery의 gcTime](https://tanstack.com/query/v5/docs/framework/react/reference/useQuery)

라이브러리가 캐시에서 제거하는 것과 JavaScript 엔진이 실제 메모리를 회수하는 것은 구분해야 한다. 다른 코드가 응답 객체를 참조하고 있다면 그 객체의 참조까지 gcTime이 제거해 주지는 않는다.

## 3. 언제부터 시간을 세는가?

일반적인 `useQuery` 화면에서는 쿼리를 구독하는 마지막 컴포넌트가 해제될 때 제거 대기가 시작된다. 여러 컴포넌트가 같은 쿼리를 사용한다면 하나가 사라져도 다른 구독자가 남아 있는 동안 유지된다.

다음은 요청이 이미 완료됐고, 같은 쿼리를 사용하는 다른 컴포넌트가 없으며, `gcTime`이 5분인 상황이다.

| 시각 | 사건 | 캐시 상태 |
| --- | --- | --- |
| 10:00 | 목록 화면에서 조회 완료 | 사용 중이므로 유지 |
| 10:20 | 여전히 목록 화면을 보는 중 | 5분이 지났어도 사용 중이므로 유지 |
| 10:21 | 목록 화면에서 다른 화면으로 이동 | 구독 종료, 제거 대기 시작 |
| 10:23 | 목록 화면으로 복귀 | 남은 캐시 재사용, 제거 대기 취소 |
| 10:24 | 다시 다른 화면으로 이동 | 마지막 구독 종료, 다시 제거 대기 |
| 10:29 이후 | 계속 사용하지 않음 | 타이머가 실행되면 제거 |

복귀했을 때 서버를 다시 조회하는지는 별도 정책이다. 캐시가 남아 있다는 사실만으로 재조회를 하지 않는다고 판단할 수 없다. [공식 문서: 캐시 재사용과 백그라운드 조회](https://tanstack.com/query/v5/docs/framework/react/guides/caching)

화면에서 CSS로 숨기는 것과 컴포넌트를 해제하는 것도 다르다. 숨겼더라도 구독이 유지된다면 캐시 수명이 끝난 것으로 볼 수 없다.

## 4. staleTime과 무엇이 다른가?

| 옵션 | 답하는 질문 | 기본 동작 |
| --- | --- | --- |
| `staleTime` | 성공 데이터를 언제까지 최신으로 취급할까? | 기본 0이므로 즉시 stale로 취급 |
| `gcTime` | 사용하지 않는 쿼리 캐시를 언제 제거할까? | 브라우저 기본 5분 |
| `refetchInterval` | 일정 간격으로 다시 조회할까? | 별도 설정이 없으면 주기 조회 없음 |

`stale`은 재조회가 필요할 수 있다는 판단 상태다. stale이 되었다고 기존 데이터를 즉시 지우거나 그 순간 반드시 요청을 보내지는 않는다. 기본적으로 마운트, 창 포커스 복귀, 네트워크 재연결 등의 계기와 결합해 재조회한다. [공식 문서: 기본 동작](https://tanstack.com/query/v5/docs/framework/react/guides/important-defaults)

예를 들어 `staleTime: 60_000`, `gcTime: 300_000`이면 성공 데이터는 1분 동안 최신으로 취급하고, 아무도 사용하지 않게 된 캐시는 5분 보관한다. 이후 새 마운트에서 캐시가 남아 있지만 stale이라면 이전 데이터를 보여 주면서 백그라운드 조회를 수행할 수 있다.

반대로 `staleTime: 600_000`, `gcTime: 30_000`이면 데이터를 10분간 최신으로 취급하더라도, 화면 이탈 후 사용하지 않는 상태가 30초 이어지면 제거될 수 있다. 다시 들어왔을 때 캐시가 없으면 새로 조회한다. gcTime과 staleTime은 서로 다른 시점에서 시작하는 정책이다.

`staleTime: Infinity` 역시 캐시를 무기한 보관한다는 뜻은 아니다. 자동 제거 여부는 gcTime이 결정한다. [공식 문서: useQuery 옵션](https://tanstack.com/query/v5/docs/framework/react/reference/useQuery)

## 5. 기본 사용 예제

다음 예제는 상품 목록을 1분간 최신으로 취급하고, 사용하지 않는 캐시는 5분 보관한다. `QueryClientProvider`는 하위 컴포넌트에 QueryClient를 제공한다. 브라우저의 단일 애플리케이션 예제이며, 서버 렌더링에서는 사용자 요청 간 캐시를 공유하지 않도록 QueryClient의 수명을 따로 설계해야 한다.

```tsx
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';

type Product = { id: number; name: string };

async function fetchProducts(signal?: AbortSignal): Promise<Product[]> {
  const response = await fetch('/api/products', { signal });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

function ProductList() {
  const query = useQuery({
    queryKey: ['products'],
    queryFn: ({ signal }) => fetchProducts(signal),
    staleTime: 60_000,
    gcTime: 5 * 60 * 1000,
  });

  if (query.isPending) return <p>불러오는 중입니다.</p>;
  if (query.isError) return <p role="alert">조회에 실패했습니다.</p>;

  return <ul>{query.data.map((product) => (
    <li key={product.id}>{product.name}</li>
  ))}</ul>;
}

const queryClient = new QueryClient();

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ProductList />
    </QueryClientProvider>
  );
}
```

`/api/products`는 설명용 경로이며 상품 배열을 반환하는 서버가 필요하다. 반환 타입 선언은 서버 JSON의 런타임 검증을 대신하지 않는다. 또한 예제의 간단한 오류 화면은 갱신 실패 시 기존 목록을 유지하는 UX까지 구현한 것은 아니다.

QueryClient를 렌더링할 때마다 새로 만들면 이전 캐시를 재사용할 수 없다. 캐시를 공유해야 하는 컴포넌트들이 안정적인 하나의 QueryClient를 사용하도록 구성한다. [공식 문서: QueryClient](https://tanstack.com/query/v5/docs/reference/QueryClient)

## 6. gcTime: 0의 의미와 활용

화면을 떠난 뒤 결과를 남겨 둘 이유가 적거나, 큰 응답을 재사용하지 않는 화면이라면 0을 선택할 수 있다. 앞 예제의 `fetchProducts`를 사용한다고 가정한 훅이다.

```ts
function useTemporaryProducts() {
  return useQuery({
    queryKey: ['temporary-products'],
    queryFn: ({ signal }) => fetchProducts(signal),
    gcTime: 0,
    retry: false,
    refetchOnMount: 'always',
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
  });
}
```

이 조합은 진입 시 조회하고 사용이 끝난 캐시를 오래 보관하지 않는 정책이다. gcTime이 다른 재조회 옵션까지 설정하는 것은 아니므로 필요한 정책을 각각 지정한다.

**0은 캐시 기능을 완전히 끄는 값이 아니다.** 구독 중에는 결과를 보관하고, 같은 키의 구독자끼리 공유할 수 있다. 또한 해제와 동시에 동기적으로 메모리를 지우는 보안 장치도 아니다.

문서 작성 시 확인한 v5.101.4 구현에서는 제거를 타이머로 예약하고, 실제 제거 시 구독자가 없고 fetch 상태가 idle인지 확인한다. 제거 전에 다시 구독하면 예약이 해제된다. 진행 중인 요청이 남아 있다면 처리 종료 시점도 영향을 준다. 따라서 아주 빠른 재진입이나 개발 환경의 마운트 반복에서 무조건 새 캐시가 만들어진다고 가정하면 안 된다. 참고 소스 링크는 변경 가능한 main 브랜치이므로 사용하는 버전의 구현과 대조해야 한다. [소스: Removable](https://github.com/TanStack/query/blob/main/packages/query-core/src/removable.ts), [소스: Query](https://github.com/TanStack/query/blob/main/packages/query-core/src/query.ts)

`enabled: false`도 구독 해제와 동일하지 않다. 자동 조회가 꺼진 컴포넌트라도 구독자가 남아 있을 수 있으므로 이를 캐시 삭제 수단으로 사용하지 않는다.

## 7. 전역 기본값과 특정 쿼리의 설정

```ts
const sharedClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: 10 * 60 * 1000,
    },
  },
});

// 특정 기능의 기본값을 별도로 지정할 수도 있다.
sharedClient.setQueryDefaults(['large-report'], {
  gcTime: 30_000,
});
```

전역 기본값은 공통 정책, `setQueryDefaults`는 특정 쿼리 키 범위의 기본 정책, `useQuery`의 옵션은 개별 사용처의 정책을 표현한다. [공식 문서: QueryClient 설정](https://tanstack.com/query/v5/docs/reference/QueryClient)

같은 키를 여러 곳에서 사용한다면 각 사용처가 서로 다른 gcTime을 지정하는지 확인한다. 한 곳에 0을 적었다고 다른 곳의 더 긴 설정까지 무효화하는 것은 아니다. 캐시를 함께 사용할 데이터인지부터 결정하는 편이 좋다.

아래 값은 보편적인 정답이 아니라 검토를 시작하기 위한 예시다.

| 화면 특성 | 고려할 설정 | 판단 근거 |
| --- | --- | --- |
| 목록과 상세를 자주 오감 | 기본값 또는 수분 | 재방문 시 이전 결과를 바로 표시 |
| 큰 보고서를 잠깐 확인 | 0 또는 짧은 시간 | 사용 후 큰 응답을 오래 보관하지 않음 |
| 자주 재사용하는 기준정보 | 긴 gcTime, 별도의 staleTime | 재사용 빈도와 변경 빈도를 각각 반영 |
| 사용자별 정보 | 사용자·세션 구분과 제거 정책을 함께 설계 | 보관 시간만으로 사용자 간 격리를 해결할 수 없음 |

## 8. 요청 취소·무효화·명시적 제거와 구분하기

| 기능 | 책임 |
| --- | --- |
| `gcTime` | 사용하지 않는 캐시의 자동 제거 시점 |
| `AbortSignal`·`cancelQueries` | 진행 중인 조회의 취소 |
| `invalidateQueries` | 데이터를 다시 확인해야 한다고 표시하고 조건에 따라 재조회 |
| `removeQueries` | 조건에 맞는 쿼리를 캐시에서 명시적으로 제거 |
| `clear` | QueryClient에 연결된 쿼리·뮤테이션 캐시 전체 정리 |

gcTime을 0으로 지정하는 것만으로 fetch 취소가 구현되는 것은 아니다. queryFn에서 전달받은 signal을 fetch에 연결하면 TanStack Query의 취소를 실제 요청까지 전달할 수 있다. 이미 서버에 도착한 작업의 중단이나 롤백까지 보장하지는 않는다. [공식 문서: 요청 취소](https://tanstack.com/query/v5/docs/framework/react/guides/query-cancellation)

로그아웃 때 특정 사용자의 조회를 정리해야 한다면, 보호된 화면의 구독을 먼저 종료하고 관련 요청과 캐시를 명시적으로 정리하는 방식을 검토할 수 있다.

```ts
async function discardUserQueries(client: QueryClient, userId: string) {
  const filter = { queryKey: ['user', userId] };
  await client.cancelQueries(filter);
  client.removeQueries(filter);
}
```

이 예제는 관련 쿼리가 `['user', userId, ...]` 형식의 키를 사용하고, 호출 전에 해당 화면의 구독이 종료됐다는 전제다. 화면이 계속 구독하고 있으면 재조회로 캐시가 다시 생길 수 있다. 쿼리 삭제 자체가 로그인 세션을 종료시키는 것도 아니다. [공식 문서: QueryClient의 취소·제거](https://tanstack.com/query/v5/docs/reference/QueryClient)

사용자별 데이터는 queryKey에 사용자 식별자를 넣어 구분한다. 같은 계정의 재로그인까지 별도 결과로 취급해야 한다면 인증 세션이나 화면 진입을 구분하는 정책도 필요하다. 다만 매 렌더링마다 새 키를 만들면 안정적인 조회·캐시 공유가 깨지므로 식별자의 수명을 명확히 정한다. [공식 문서: Query Keys](https://tanstack.com/query/v5/docs/framework/react/guides/query-keys)

## 9. 동작을 확인하는 방법

gcTime을 검증할 때는 단순히 일정 시간을 기다리는 것보다 **구독 여부와 제거 시점**을 함께 확인한다.

- 구독 중에는 gcTime보다 오래 기다려도 데이터가 유지되는가?
- 마지막 구독 해제 후 설정한 시간이 지나면 제거되는가?
- 제거 전에 재구독하면 캐시가 유지되는가?
- 같은 쿼리를 사용하는 다른 컴포넌트가 남아 있으면 유지되는가?
- gcTime을 0으로 설정한 경우 제거 예약 이후의 결과를 확인하는가?
- 사용자 변경 뒤 이전 키의 데이터를 새 화면에서 사용하지 않는가?

테스트마다 독립된 QueryClient를 사용하면 이전 테스트의 캐시 영향을 줄일 수 있다. 시간이 관련된 검증에서는 가짜 타이머로 제거 예약을 실행하고, `getQueryData`나 `getQueryCache().find`로 결과를 확인할 수 있다.

## 10. 자주 생기는 오해

| 오해 | 실제 의미 |
| --- | --- |
| gcTime이 지나면 화면의 데이터가 사라진다 | 구독 중인 데이터에는 그런 만료 시간이 적용되지 않음 |
| gcTime을 늘리면 서버 요청이 줄어든다 | 재사용 가능성은 높아지지만 재조회 여부는 별도 정책에 따름 |
| staleTime이 지나면 캐시가 삭제된다 | 오래된 것으로 취급할 뿐 삭제 시점은 gcTime과 다름 |
| gcTime: 0이면 캐시를 전혀 사용하지 않는다 | 구독 중에는 캐시를 사용하고, 사용 종료 후 제거를 예약 |
| gcTime: Infinity이면 항상 최신 데이터다 | 자동 제거를 끌 뿐 최신성은 보장하지 않음 |
| enabled: false이면 캐시가 제거된다 | 자동 조회 제어이며 구독 종료·캐시 제거와 다름 |
| 짧은 gcTime이면 사용자별 격리가 해결된다 | 쿼리 키, 화면 구독, 세션 종료 처리까지 함께 설계해야 함 |
