# React Query `QueryClient`와 query key 이해하기

## 전체 개념

다음 코드는 `QueryClient` 객체를 하나 만들고, 그 객체의 캐시에서 특정 계약 데이터를 읽는 구조다.

```ts
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});

const contract = queryClient.getQueryData([
  'finance-contracts',
  42,
]);
```

두 코드는 서로 다른 역할을 한다.

- `new QueryClient(...)`: 설정과 캐시를 관리할 객체를 생성한다.
- `queryClient.getQueryData(...)`: 생성한 객체의 캐시에서 데이터를 읽는다.

## `new QueryClient(...)`: 인스턴스 생성

`QueryClient`는 클래스이고 `new`는 그 클래스로 실제 객체, 즉 인스턴스를 만드는 연산자다.

```ts
const queryClient = new QueryClient(options);
```

개념적으로 다음 클래스와 비슷하게 이해할 수 있다.

```ts
class QueryClient {
  options;
  cache;

  constructor(options) {
    this.options = options;
    this.cache = createCache();
  }
}
```

생성된 `queryClient`는 기본 설정과 여러 query key의 데이터를 저장하는 캐시를 함께 관리한다.

```text
queryClient
├── 기본 설정
│   └── retry: false
└── 캐시
    ├── 계약 목록
    ├── 42번 계약 상세
    └── 43번 계약 상세
```

`const`는 객체 자체를 불변으로 만드는 것이 아니라 `queryClient` 변수가 다른 객체를 다시 가리키지 못하게 한다. `queryClient` 내부의 캐시 상태는 계속 변경될 수 있다.

## 생성자에 전달하는 중첩 객체

다음 부분은 JavaScript 객체 리터럴이다.

```ts
{
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
}
```

객체 안에 객체가 중첩되어 있다. 각 단계를 변수로 분리하면 다음과 같다.

```ts
const queryOptions = {
  retry: false,
};

const defaultOptions = {
  queries: queryOptions,
};

const clientOptions = {
  defaultOptions,
};

const queryClient = new QueryClient(clientOptions);
```

`retry: false`는 조회 요청이 실패했을 때 React Query가 자동으로 재시도하지 않도록 하는 기본 설정이다. 이 설정이 계약 데이터를 만들거나 query key를 등록하는 것은 아니다.

## 점 표기법과 메서드 호출

다음 표현에서 점 `.`은 객체가 가진 속성이나 메서드에 접근하는 연산자다.

```ts
queryClient.getQueryData
```

뒤에 괄호를 붙이면 메서드를 호출한다.

```ts
queryClient.getQueryData(queryKey)
```

일반적인 객체 메서드 호출과 같은 문법이다.

```ts
user.getName();
car.start();
queryClient.getQueryData(queryKey);
```

## `['finance-contracts', 42]`: query key

React Query는 배열을 캐시 데이터의 식별자인 query key로 사용한다.

```ts
['finance-contracts']
```

는 금융계약 목록을 나타낼 수 있고,

```ts
['finance-contracts', 42]
```

는 42번 금융계약 상세를 나타낼 수 있다.

```text
['finance-contracts']      -> 계약 목록
['finance-contracts', 42]  -> 42번 계약 상세
['finance-contracts', 43]  -> 43번 계약 상세
```

`(['finance-contracts', 42])`는 여러 인수를 전달하는 문법이 아니다. 배열 하나를 메서드의 첫 번째 인수로 전달하는 문법이다.

```ts
const queryKey = ['finance-contracts', 42];

queryClient.getQueryData(queryKey);
```

query key는 구조적으로 일치해야 같은 캐시 데이터를 가리킨다. 목록 키와 상세 키는 서로 다른 데이터다.

## 캐시 저장과 조회

`QueryClient`를 생성하는 것만으로 데이터가 캐시에 들어가지는 않는다. 조회 성공이나 직접적인 캐시 갱신을 통해 데이터가 먼저 저장되어야 한다.

직접 저장할 때는 `setQueryData()`를 사용할 수 있다.

```ts
queryClient.setQueryData(
  ['finance-contracts', 42],
  {
    contractId: 42,
    vehicleNumber: '123가4567',
  },
);
```

같은 query key를 사용해 저장된 값을 읽을 수 있다.

```ts
const contract = queryClient.getQueryData(
  ['finance-contracts', 42],
);
```

개념적인 흐름은 다음과 같다.

```text
setQueryData(query key, data)
            |
            v
       QueryClient 캐시
            |
            v
getQueryData(query key)
```

서로 다른 `QueryClient` 인스턴스는 일반적으로 서로 다른 캐시를 갖는다. 어떤 인스턴스에 데이터를 저장했다면 같은 인스턴스에서 조회해야 한다.

```ts
const firstClient = new QueryClient();
const secondClient = new QueryClient();

firstClient.setQueryData(['finance-contracts', 42], contract);

firstClient.getQueryData(['finance-contracts', 42]);
// contract

secondClient.getQueryData(['finance-contracts', 42]);
// undefined
```

## `getQueryData()`는 서버 요청이 아니다

`getQueryData()`는 현재 메모리 캐시를 동기적으로 읽는다. 이 메서드 자체는 서버에 요청하지 않는다.

```ts
const contract = queryClient.getQueryData(
  ['finance-contracts', 42],
);
```

해당 query key의 데이터가 있으면 그 값을 반환하고, 없으면 `undefined`를 반환한다.

서버에서 데이터를 가져오는 query 실행과 캐시에 있는 값을 읽는 작업은 구분해야 한다.

## 제네릭 타입 인수

캐시에서 읽을 데이터의 TypeScript 타입을 지정할 수 있다.

```ts
const contracts = queryClient.getQueryData<FinanceContractSummary[]>(
  ['finance-contracts'],
);
```

`<FinanceContractSummary[]>`는 반환값을 금융계약 요약 배열로 다루도록 TypeScript에 알려준다. 이 타입 표기는 런타임 데이터를 검사하거나 변환하지 않는다.

따라서 실제 캐시에 다른 형태의 값이 들어 있더라도 제네릭 타입 인수가 런타임 오류를 막아주지는 않는다. 저장하는 코드와 조회하는 코드가 같은 query key와 데이터 타입 규칙을 지켜야 한다.

## React 컴포넌트와 `QueryClientProvider`

React 애플리케이션에서는 보통 `QueryClientProvider`를 통해 하위 컴포넌트가 같은 `QueryClient` 인스턴스를 사용하게 한다.

```tsx
const queryClient = new QueryClient();

root.render(
  <QueryClientProvider client={queryClient}>
    <App />
  </QueryClientProvider>,
);
```

이 구조에서는 하위 컴포넌트의 React Query 훅과 직접 호출하는 `queryClient.getQueryData()`가 같은 캐시를 바라볼 수 있다.

테스트에서도 검사하려는 `queryClient`를 Provider에 전달해야 컴포넌트가 갱신한 캐시를 동일한 객체에서 확인할 수 있다.

## 정리

```ts
const queryClient = new QueryClient(options);
```

는 설정과 캐시를 관리하는 객체를 생성한다.

```ts
queryClient.getQueryData(['finance-contracts', 42]);
```

는 그 객체의 캐시에서 `['finance-contracts', 42]`라는 query key에 해당하는 데이터를 읽는다.

핵심은 다음 세 가지다.

1. `new QueryClient(...)`는 캐시를 가진 인스턴스를 만든다.
2. query key 배열은 캐시 데이터의 주소 역할을 한다.
3. `getQueryData()`는 서버 요청 없이 같은 인스턴스의 메모리 캐시를 읽는다.
