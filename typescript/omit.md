# TypeScript `Omit` 이해하기

## 개념

`Omit`은 기존 객체 타입에서 지정한 속성을 제외한 새로운 타입을 만드는 TypeScript 유틸리티 타입이다.

기본 문법은 다음과 같다.

```ts
Omit<원본타입, 제외할속성>
```

- 첫 번째 타입 인수는 기준이 되는 객체 타입이다.
- 두 번째 타입 인수는 제외할 속성 이름이다.
- 여러 속성을 제외할 때는 속성 이름을 유니온(`|`)으로 연결한다.

## 기본 예시

```ts
interface User {
  id: number;
  name: string;
  password: string;
}

type PublicUser = Omit<User, 'password'>;
```

`PublicUser`는 다음 타입과 같은 의미다.

```ts
interface PublicUser {
  id: number;
  name: string;
}
```

여러 속성을 제외할 수도 있다.

```ts
type UserName = Omit<User, 'id' | 'password'>;
```

## 배열 요소에 사용하기

`Omit`으로 만든 타입도 다른 타입과 마찬가지로 배열의 요소 타입으로 사용할 수 있다.

```ts
interface ContractDetail {
  contractId: number;
  vehicleNumber: string;
  rows: RepaymentScheduleEntry[];
}

interface RegistrationResponse {
  contracts: Array<Omit<ContractDetail, 'rows'>>;
  repaymentSchedule: RepaymentScheduleEntry[];
}
```

`contracts` 배열의 각 요소는 `ContractDetail`과 같지만 `rows`는 갖지 않는다.

개념적으로 다음 선언과 같다.

```ts
interface RegisteredContract {
  contractId: number;
  vehicleNumber: string;
}

interface RegistrationResponse {
  contracts: RegisteredContract[];
  repaymentSchedule: RepaymentScheduleEntry[];
}
```

이 구조는 여러 계약이 동일한 상환 일정을 공유할 때 유용하다. 각 계약 객체에 같은 `rows`를 반복해서 넣지 않고, 공통 상환 일정을 응답 최상위에 한 번만 둘 수 있다.

개별 계약 상세 객체가 필요하면 다시 결합할 수 있다.

```ts
const details: ContractDetail[] = response.contracts.map((contract) => ({
  ...contract,
  rows: response.repaymentSchedule,
}));
```

## `Omit`은 런타임 변환이 아니다

`Omit`은 컴파일 단계에서만 사용하는 타입 도구다. 실제 JavaScript 객체의 속성을 삭제하거나 API 응답을 변환하지 않는다.

```ts
type WithoutRows = Omit<ContractDetail, 'rows'>;
```

이 선언만으로 런타임 객체에서 `rows`가 사라지지는 않는다. 서버 응답을 변경하거나 객체에서 속성을 제거하려면 실제 변환 코드가 필요하다.

```ts
const { rows, ...withoutRows } = contract;
```

따라서 API 응답 타입에 `Omit`을 사용했다면 서버가 실제로도 그 구조를 반환하는지 별도로 검증해야 한다.

## `Pick`과의 차이

`Omit`은 제외할 속성을 지정하고, `Pick`은 남길 속성을 지정한다.

```ts
type WithoutPassword = Omit<User, 'password'>;
type UserIdentity = Pick<User, 'id' | 'name'>;
```

- 원본 타입의 대부분을 유지하고 일부만 제외할 때는 `Omit`이 읽기 쉽다.
- 필요한 속성이 몇 개뿐이라면 `Pick`이 의도를 더 명확하게 표현할 수 있다.

## 얕은 타입 연산

`Omit`은 최상위 속성만 제외한다. 중첩 객체 내부의 속성까지 재귀적으로 제거하지 않는다.

```ts
interface Contract {
  id: number;
  owner: {
    name: string;
    phoneNumber: string;
  };
}

type Result = Omit<Contract, 'id'>;
```

`Result`에서는 `id`만 없어지고 `owner.phoneNumber`는 그대로 남는다. 중첩 속성을 변경하려면 중첩 타입을 별도로 다시 구성해야 한다.

## 타입 별칭으로 의도를 드러내기

복잡한 `Omit` 표현이 여러 곳에서 반복되거나 별도의 도메인 의미를 가진다면 이름을 붙이는 편이 좋다.

```ts
type RegisteredContract = Omit<ContractDetail, 'rows'>;

interface RegistrationResponse {
  contracts: RegisteredContract[];
  repaymentSchedule: RepaymentScheduleEntry[];
}
```

이 방식은 단순히 `rows`가 빠졌다는 구현 사실뿐 아니라, 해당 타입이 “등록 결과에 포함되는 계약 정보”라는 역할도 표현한다.

## 정리

```ts
Omit<T, K>
```

는 타입 `T`에서 속성 `K`를 제외한 타입을 만든다. 기존 타입과의 구조적 연관성을 유지하면서 응답, 입력 또는 화면 상태에 맞는 변형 타입을 표현할 때 유용하다. 다만 실제 객체를 변환하지 않는 컴파일 전용 기능이고 최상위 속성만 다루므로, 런타임 데이터 구조와 중첩 타입은 별도로 확인해야 한다.
