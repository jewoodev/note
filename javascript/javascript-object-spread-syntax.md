# JavaScript/TypeScript 객체 전개 문법

## 객체 전개란?

객체 전개(object spread)는 객체의 프로퍼티를 다른 객체 리터럴 안으로 복사하는 문법이다.
객체 앞에 점 세 개(`...`)를 붙여 표현한다.

```ts
const original = {
  name: '홍길동',
  age: 30,
};

const copied = {
  ...original,
};
```

`copied`는 `original`의 프로퍼티를 가진 새로운 객체다.

```ts
console.log(copied); // { name: '홍길동', age: 30 }
console.log(copied === original); // false
```

## 일부 프로퍼티를 바꾼 새 객체 만들기

객체를 전개한 다음 같은 이름의 프로퍼티를 선언하면, 뒤에 선언된 값이 앞의 값을 덮어쓴다.

```ts
const contract = {
  id: 1,
  vehicleNumber: '11가1111',
  contractClassification: 'VEHICLE_INSTALLMENT_GENERAL',
};

const revised = {
  ...contract,
  vehicleNumber: '88다8888',
  contractClassification: 'OPERATING_FUNDS_GENERAL',
};
```

결과는 다음과 같다.

```ts
console.log(revised);
// {
//   id: 1,
//   vehicleNumber: '88다8888',
//   contractClassification: 'OPERATING_FUNDS_GENERAL'
// }
```

- `id`는 별도의 새 값이 없으므로 `contract`의 값이 유지된다.
- `vehicleNumber`와 `contractClassification`은 전개 뒤에 다시 선언했으므로 새 값으로 교체된다.
- 원본인 `contract`는 변경되지 않는다.

이 패턴은 기존 객체를 직접 수정하지 않고 일부 값만 바꾼 새 객체를 만들 때 자주 사용한다.

## 선언 순서가 중요한 이유

프로퍼티가 중복되면 객체 리터럴에서 가장 뒤에 선언된 값이 최종값이 된다.

### 전개 뒤에 새 값을 선언하는 경우

```ts
const revised = {
  ...contract,
  vehicleNumber: '88다8888',
};
```

`vehicleNumber`의 최종값은 `'88다8888'`이다.

### 새 값을 선언한 뒤 객체를 전개하는 경우

```ts
const revised = {
  vehicleNumber: '88다8888',
  ...contract,
};
```

이번에는 뒤에서 복사된 `contract.vehicleNumber`가 앞의 값을 덮어쓴다. 따라서 새로 지정한
`'88다8888'`이 아니라 `contract`가 원래 가지고 있던 차량번호가 최종값이 된다.

## 얕은 복사

객체 전개가 만드는 것은 깊은 복사(deep copy)가 아니라 얕은 복사(shallow copy)다. 객체의
첫 번째 단계에 있는 프로퍼티는 새 객체로 복사되지만, 중첩된 객체나 배열은 원본과 같은 값을
참조한다.

```ts
const contract = {
  id: 1,
  vehicle: {
    number: '11가1111',
  },
};

const copied = {
  ...contract,
};

copied.vehicle.number = '88다8888';

console.log(contract.vehicle.number); // '88다8888'
```

`copied` 자체는 새로운 객체지만 `copied.vehicle`과 `contract.vehicle`은 같은 중첩 객체를
가리킨다.

중첩 객체까지 변경하지 않고 복사하려면 해당 객체도 별도로 전개해야 한다.

```ts
const revised = {
  ...contract,
  vehicle: {
    ...contract.vehicle,
    number: '88다8888',
  },
};
```

## `as const`와의 차이

다음 코드의 `as const`는 객체 전개 문법의 일부가 아니라 TypeScript의 const assertion이다.

```ts
const revised = {
  ...contract,
  contractClassification: 'OPERATING_FUNDS_GENERAL' as const,
};
```

`as const`는 TypeScript가 문자열을 일반적인 `string` 타입으로 넓혀 해석하지 않고,
`'OPERATING_FUNDS_GENERAL'`이라는 구체적인 문자열 리터럴 타입으로 취급하게 한다. 런타임의
객체 복사나 프로퍼티 덮어쓰기 동작에는 영향을 주지 않는다.

## 요약

```ts
const changed = {
  ...original,
  propertyToChange: newValue,
};
```

위 코드는 다음 의미를 가진다.

1. `original`의 프로퍼티를 새 객체에 얕게 복사한다.
2. `propertyToChange`를 `newValue`로 덮어쓴다.
3. `original`은 수정하지 않는다.
4. 중첩 객체와 배열은 원본과 참조를 공유할 수 있다.
5. 같은 이름의 프로퍼티가 여러 번 나오면 가장 뒤에 선언된 값이 사용된다.
