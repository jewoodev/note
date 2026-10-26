# TypeScript의 satisfies: 타입 조건을 검사하면서 구체적인 추론 유지하기

`satisfies`는 **표현식이 특정 타입에 할당 가능한지 검사하는 TypeScript 연산자**다. 설정 객체나 이름별 값 목록을 작성할 때 구조를 검사하면서, 각 값의 구체적인 타입 정보도 활용하려는 경우에 유용하다. TypeScript 4.9에서 추가되었다. [공식 소개](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator)

이 문서는 JavaScript의 객체·함수와 TypeScript의 기본 타입 표기를 알고 있는 독자를 대상으로 한다. 특정 프레임워크나 프로젝트에 대한 지식은 필요하지 않다. 예제는 각각 독립적이며 TypeScript 5.9.3의 `strict` 설정으로 확인했다. `@ts-expect-error`는 다음 줄에서 타입 오류가 발생해야 한다는 검증용 주석이다. 예제를 학습할 때 주석을 지우면 오류 내용을 볼 수 있다.

## 1. 기본 문법

형태는 `표현식 satisfies 검사할타입`이다.

```ts
type PageOptions = {
  contentWidth: 'standard' | 'wide';
  title?: string;
};

const options = {
  contentWidth: 'wide',
} satisfies PageOptions;

const width: 'wide' = options.contentWidth;

// @ts-expect-error: 허용된 폭은 standard 또는 wide다.
const invalid = { contentWidth: 'full' } satisfies PageOptions;
```

`'standard' | 'wide'`는 둘 중 하나의 문자열만 허용하는 유니온 타입이다. `title?`의 물음표는 선택적 속성을 뜻한다.

위 예제는 객체가 `PageOptions` 조건을 만족하는지 검사하고, `options.contentWidth`에는 구체적인 `'wide'` 타입을 유지한다. `title`을 생략했다고 기본값을 넣거나 객체에 속성을 추가하지는 않는다.

## 2. 타입 주석과 무엇이 다른가?

변수에 `: Type`을 붙이는 **타입 주석**은 변수가 어떤 타입으로 사용될지를 지정한다. `satisfies`는 조건을 검사하되 결과를 그 타입으로 일괄 확장하지 않는다. 차이는 서로 다른 종류의 값을 담는 객체에서 잘 드러난다.

```ts
type SettingValue = string | number;
type SettingName = 'label' | 'retries';

const annotated: Record<SettingName, SettingValue> = {
  label: 'service',
  retries: 3,
};

// @ts-expect-error: label은 선언된 타입상 string | number다.
annotated.label.toUpperCase();

const checked = {
  label: 'service',
  retries: 3,
} satisfies Record<SettingName, SettingValue>;

checked.label.toUpperCase(); // label은 string으로 추론된다.
checked.retries.toFixed(0);  // retries는 number로 추론된다.
```

`Record<K, V>`는 키가 `K`이고 각 값이 `V`인 객체 타입을 만든다. 여기서는 `label`과 `retries`가 모두 필요하며, 값은 문자열이나 숫자여야 한다.

두 선언 모두 잘못된 값을 검사할 수 있다. 차이는 선언 이후에 각 속성을 얼마나 구체적으로 사용할 수 있느냐다. 이 예제의 `checked.label`이 문자열 리터럴 `'service'` 자체로 고정되는 것은 아니다. 추론 결과는 `string`이다. [satisfies와 추론 보존](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html#the-satisfies-operator)

## 3. as와는 무엇이 다른가?

`as Type`은 **타입 단언**이다. 컴파일러가 가진 정보보다 개발자가 더 정확한 타입을 알고 있을 때 사용한다. 호환성에 대한 일부 제한은 있지만, 객체의 필수 속성이 실제로 존재하는지 검증하는 용도로 쓰면 잘못된 확신을 줄 수 있다. 타입 단언은 런타임 검사도 수행하지 않는다. [타입 단언 문서](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)

```ts
type ServerOptions = { port: number };

const asserted = {} as ServerOptions; // 타입 검사를 통과한다.
const port: number = asserted.port;   // 타입은 number지만 실제 값은 undefined다.

// @ts-expect-error: 필수 속성 port가 없다.
const checked = {} satisfies ServerOptions;
```

직접 작성한 설정 객체가 올바른지 확인하려면 `satisfies` 또는 타입 주석이 적합하다. 오류를 없애기 위해 `as`를 붙이면 검사가 보장해야 할 조건을 놓칠 수 있다.

| 표기 | 목적 | 결과에 사용하는 타입 |
| --- | --- | --- |
| `const x: T = value` | 변수를 T로 선언하고 할당을 검사 | 선언한 T |
| `const x = value as T` | 개발자가 T로 취급하도록 단언 | 단언한 T |
| `const x = value satisfies T` | T와의 호환성을 검사 | 문맥을 반영해 추론된 표현식의 타입 |

## 4. 활용: 빠진 키와 잘못된 키를 발견한다

이름이 정해진 설정표·메시지표를 작성할 때 사용할 수 있다.

```ts
type Status = 'idle' | 'running' | 'failed';

const labels = {
  idle: '대기',
  running: '진행 중',
  failed: '실패',
} satisfies Record<Status, string>;

// @ts-expect-error: failed 키가 빠졌다.
const missing = { idle: '대기', running: '진행 중' } satisfies Record<Status, string>;

// @ts-expect-error: 새 객체 리터럴에 정의되지 않은 done 키가 있다.
const extra = { idle: '대기', running: '진행 중', failed: '실패', done: '완료' } satisfies Record<Status, string>;
```

키의 집합을 검사하려면 `Status`처럼 범위를 정해야 한다. `Record<string, string>`은 임의의 문자열 키를 허용하므로 특정 키의 누락이나 철자 오류를 같은 방식으로 잡지 못한다.

다만 **모든 상황에서 추가 속성을 금지하는 정확한 객체 타입 검사는 아니다.** TypeScript는 새 객체 리터럴에 초과 속성 검사를 적용하지만, 이미 변수에 담긴 객체는 필요한 구조를 갖추면 추가 속성이 있어도 호환될 수 있다. [초과 속성 검사](https://www.typescriptlang.org/docs/handbook/2/objects.html#excess-property-checks)

```ts
type Endpoint = { url: string };

const candidate = { url: '/health', debug: true };
const checked = candidate satisfies Endpoint; // 추가 속성이 있어도 통과한다.
checked.debug; // 추가 속성이 삭제되지 않는다.
```

## 5. 활용: 설정을 고정하려면 as const와 조합한다

`satisfies` 자체는 객체를 읽기 전용으로 만들지 않는다. 직접 작성한 리터럴의 값을 좁게 유지하고 속성 변경을 타입 수준에서 막으려면 `as const`를 함께 사용할 수 있다. `as const`는 객체 속성을 readonly로, 배열 리터럴을 readonly 튜플로 추론하게 한다. [const assertion 문서](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-4.html#const-assertions)

```ts
type MenuItem = { label: string; path: string };

const menus = [
  { label: '홈', path: '/' },
  { label: '설정', path: '/settings' },
] as const satisfies readonly MenuItem[];

type MenuPath = typeof menus[number]['path']; // '/' | '/settings'
const path: MenuPath = '/settings';

// @ts-expect-error: 선언된 메뉴 경로가 아니다.
const unknownPath: MenuPath = '/missing';

// @ts-expect-error: as const로 readonly가 된 속성이다.
menus[0].label = '시작';
```

여기서 `as const`는 리터럴 정보와 readonly를, `satisfies`는 메뉴 항목 구조의 검사를 담당한다. `readonly MenuItem[]`은 읽기 전용 배열을 받을 수 있는 검사 대상 타입이다.

이 처리는 런타임의 `Object.freeze()`와 다르다. JavaScript 객체를 실제로 동결하지 않으며, 외부에서 가져온 객체의 참조까지 재귀적으로 불변으로 만드는 기능도 아니다.

## 6. 추론에 전혀 영향을 주지 않는다는 뜻은 아니다

`satisfies`는 검사 대상 타입을 문맥으로 제공할 수 있다. 이를 **문맥적 타이핑(contextual typing)**이라고 한다. 예를 들어 함수의 매개변수 타입을 주변 타입에서 추론할 수 있다. [문맥적 타이핑](https://www.typescriptlang.org/docs/handbook/type-inference.html#contextual-typing)

```ts
type Formatter = { format: (value: number) => string };

const formatter = {
  format: (value) => value.toFixed(2), // value를 number로 추론한다.
} satisfies Formatter;

type Layout = { width: 'standard' | 'wide'; padding: number };

const layout = { width: 'wide', padding: 16 } satisfies Layout;
layout.padding = 24; // padding은 number이며 변경할 수 있다.

// @ts-expect-error: width는 현재 객체에서 'wide'로 좁게 추론되었다.
layout.width = 'standard';

const mutable: Layout = { width: 'wide', padding: 16 };
mutable.width = 'standard'; // 전체 유니온 범위의 변경을 허용하려면 타입 주석을 사용한다.
```

`satisfies`를 붙이기 전과 추론 결과가 언제나 동일하다고 이해하면 안 된다. 첫 절의 리터럴 유지나 위 함수의 매개변수 추론처럼 문맥의 영향을 받는다. 나중에 값을 바꿀 상태 객체라면 타입 주석이 더 적합한지 확인한다.

## 7. 런타임 검증이나 boolean 반환 기능은 아니다

`satisfies`는 타입 검사 단계의 문법이며 JavaScript 출력에서는 제거된다. 표현식의 값은 그대로 사용된다.

```ts
const original = { timeout: 1000 };
const result = original satisfies { timeout: number };

console.log(result === original); // true: 같은 객체다.
console.log(result);              // { timeout: 1000 }, true/false가 아니다.
```

따라서 `if (value satisfies SomeType)`으로 외부 데이터의 타입을 검사할 수 없다. 검사에 통과한 경우에도 조건식은 원래 값의 참·거짓 여부를 평가한다.

특히 API 응답·사용자 입력·JSON은 실행 중에 별도로 검증해야 한다. `any`로 들어온 값은 타입 검사를 쉽게 통과하므로 `satisfies`로 감싸도 안전성이 생기지 않는다. 외부 값을 `unknown`으로 받은 다음 속성 검사나 스키마 검증을 수행하는 편이 적합하다. 아래 예제는 직접 속성을 검사하는 방식이다. [any와 타입 검사](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#any)

```ts
type Settings = { timeout: number };
const input: unknown = JSON.parse('{"timeout":"slow"}');

// @ts-expect-error: unknown만으로 Settings 조건을 보장할 수 없다.
const unchecked = input satisfies Settings;

function isSettings(value: unknown): value is Settings {
  return typeof value === 'object'
    && value !== null
    && 'timeout' in value
    && typeof value.timeout === 'number'
    && Number.isFinite(value.timeout);
}

if (isSettings(input)) {
  console.log(input.timeout.toFixed(0));
} else {
  console.log('timeout은 유한한 숫자여야 합니다.');
}
```

`isSettings`는 실행 시 실제 값을 검사한다. `satisfies`의 역할과 구별해야 한다.

## 8. 어떤 경우에 선택하면 좋은가?

| 필요 | 선택 |
| --- | --- |
| 설정 객체의 구조를 검사하면서 개별 속성의 추론을 활용 | `satisfies` |
| 값이 나중에 선언된 타입 범위 안에서 바뀌어야 함 | `: Type` 타입 주석 |
| 고정된 리터럴 목록에서 타입을 추출하고 구조도 검사 | `as const satisfies ...` |
| 컴파일러가 모르는 타입 정보를 개발자가 근거를 갖고 지정 | `as Type` 타입 단언 |
| 서버 응답이나 사용자 입력의 실제 내용을 검사 | 런타임 검사 함수 또는 스키마 검증 |

문법을 선택할 때는 **무엇을 검사할지**와 **검사 이후 어떤 타입으로 사용할지**를 함께 결정한다. `satisfies`는 직접 작성한 값의 구조를 확인하면서 구체적인 타입 정보를 활용하려는 경우에 특히 유용하다.
