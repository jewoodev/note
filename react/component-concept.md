# TypeScript와 React에서 컴포넌트 이해하기

## 컴포넌트란 무엇인가

React에서 컴포넌트는 화면의 일부를 독립적으로 표현하고 동작시키는 재사용 가능한 단위다.

예를 들어 계약 등록 화면은 다음과 같은 컴포넌트들로 나눌 수 있다.

```text
계약 등록 화면
├── 차량번호 목록 편집기
├── 계약 기본정보 입력 영역
├── 상환 일정 표
├── 검증 결과 영역
└── 등록 버튼 영역
```

각 컴포넌트는 자신이 화면에 무엇을 보여줄지, 어떤 입력을 받을지, 사용자 행동을 부모에게 어떻게 알릴지를 정의한다.

## 컴포넌트는 TypeScript 문법이 아니다

`component`라는 별도의 TypeScript 키워드는 없다. 컴포넌트는 React가 함수 또는 클래스에 부여하는 역할이다.

현대 React에서는 주로 함수를 컴포넌트로 사용한다.

```tsx
function Greeting() {
  return <p>안녕하세요.</p>;
}
```

이 코드는 문법적으로는 JavaScript 또는 TypeScript 함수다. React가 이 함수를 UI를 만드는 단위로 호출하므로 React 컴포넌트가 된다.

TypeScript는 컴포넌트가 받을 값의 타입을 검사하고 잘못된 사용을 컴파일 단계에서 발견하도록 돕는다.

## 컴포넌트 함수와 JSX

React 함수 컴포넌트는 일반적으로 JSX를 반환한다.

```tsx
function VehicleNumberLabel() {
  return <span>차량번호</span>;
}
```

JSX는 HTML과 비슷하게 보이지만 JavaScript 표현식이다. 빌드 과정에서 React가 처리할 수 있는 객체 생성 코드로 변환된다.

컴포넌트는 다른 JSX 안에서 태그처럼 사용할 수 있다.

```tsx
function ContractPage() {
  return (
    <section>
      <h1>계약 등록</h1>
      <VehicleNumberLabel />
    </section>
  );
}
```

사용자 정의 컴포넌트 이름은 일반적으로 대문자로 시작한다. 소문자로 시작하는 이름은 React가 HTML 요소로 해석한다.

```tsx
<VehicleNumberLabel /> // React 컴포넌트
<span />               // HTML 요소
```

## props: 부모가 전달하는 입력값

컴포넌트는 부모 컴포넌트로부터 props를 받을 수 있다.

```tsx
function VehicleNumber({ value }: { value: string }) {
  return <span>{value}</span>;
}
```

부모는 JSX 속성 문법으로 값을 전달한다.

```tsx
<VehicleNumber value="123가4567" />
```

위 코드는 개념적으로 다음 함수를 호출하는 것과 비슷하다.

```ts
VehicleNumber({ value: '123가4567' });
```

실제로 컴포넌트 함수를 애플리케이션 코드에서 직접 호출하기보다는 JSX로 사용하여 React가 렌더링 과정을 관리하도록 한다.

TypeScript에서는 props의 구조를 별도 타입으로 선언할 수 있다.

```tsx
interface VehicleNumberProps {
  value: string;
  disabled: boolean;
}

function VehicleNumber({ value, disabled }: VehicleNumberProps) {
  return <button disabled={disabled}>{value}</button>;
}
```

이 타입 덕분에 필수 props가 빠지거나 잘못된 타입을 전달하면 TypeScript 오류가 발생한다.

## props는 컴포넌트가 직접 변경하지 않는다

props는 부모가 전달한 입력값이다. 자식 컴포넌트가 props 객체를 직접 수정하지 않는 것이 React의 기본 규칙이다.

```tsx
function Counter({ count }: { count: number }) {
  // count를 직접 변경하지 않는다.
  return <span>{count}</span>;
}
```

자식이 변경을 요청해야 한다면 부모가 콜백 함수를 props로 전달한다.

```tsx
interface CounterProps {
  count: number;
  onChange: (nextCount: number) => void;
}

function Counter({ count, onChange }: CounterProps) {
  return (
    <button onClick={() => onChange(count + 1)}>
      {count}
    </button>
  );
}
```

데이터는 부모에서 자식으로 내려가고, 사용자 행동은 콜백을 통해 자식에서 부모로 전달된다.

```text
부모 상태
   |
   | props
   v
자식 컴포넌트
   |
   | onChange(nextValue)
   v
부모가 상태 갱신
```

## state: 컴포넌트가 기억하는 값

컴포넌트 내부에서 사용자 입력이나 화면 상태를 기억해야 할 때 state를 사용할 수 있다.

```tsx
import { useState } from 'react';

function VehicleNumberInput() {
  const [value, setValue] = useState('');

  return (
    <input
      value={value}
      onChange={(event) => setValue(event.target.value)}
    />
  );
}
```

`useState('')`는 두 값을 반환한다.

```ts
const [value, setValue] = useState('');
```

- `value`: 현재 상태값
- `setValue`: 새 상태를 요청하는 함수

`setValue()`를 호출하면 React는 상태를 변경하고 해당 컴포넌트를 다시 렌더링한다.

상태 변수를 직접 대입하는 방식은 사용하지 않는다.

```ts
value = '새 값'; // React 상태 변경 방식이 아님
setValue('새 값'); // React에 상태 변경 요청
```

## 렌더링과 재렌더링

React는 컴포넌트 함수를 호출하여 현재 props와 state에 맞는 UI 결과를 계산한다. 이를 렌더링이라고 한다.

props 또는 state가 바뀌면 React는 컴포넌트 함수를 다시 호출할 수 있다.

```text
props 또는 state 변경
-> 컴포넌트 함수 다시 실행
-> 새로운 JSX 결과 계산
-> 이전 결과와 비교
-> 필요한 DOM만 갱신
```

따라서 함수 컴포넌트 안의 지역 변수는 렌더링마다 다시 만들어진다.

```tsx
function Example() {
  const temporary = 0;
  return <span>{temporary}</span>;
}
```

렌더링 사이에 값을 유지해야 한다면 `useState()`나 `useRef()` 같은 React Hook을 사용한다.

## Hook

Hook은 함수 컴포넌트가 상태, 생명주기, context 같은 React 기능을 사용하도록 제공되는 함수다.

대표적인 Hook은 다음과 같다.

```ts
useState();
useEffect();
useMemo();
useRef();
useContext();
```

프로젝트나 라이브러리가 자체 Hook을 만들 수도 있다.

```ts
const registration = useFinanceContractDraftRegistration(...);
```

컴포넌트는 Hook을 사용해 복잡한 상태와 동작을 별도 함수로 분리할 수 있다. Hook 자체는 UI를 반환하지 않고 상태와 동작을 제공한다는 점에서 컴포넌트와 다르다.

## 컴포넌트 합성

큰 화면은 작은 컴포넌트들을 조합하여 만든다. 이를 컴포넌트 합성이라고 한다.

```tsx
function FinanceContractDraftReview({ draft, onChange }: Props) {
  return (
    <section>
      <VehicleNumberListEditor
        draft={draft}
        onChange={onChange}
      />
      <RepaymentScheduleTable draft={draft} />
      <RegistrationActions draft={draft} />
    </section>
  );
}
```

상위 컴포넌트는 전체 흐름을 조정하고, 하위 컴포넌트는 특정 화면 영역과 사용자 동작을 담당한다.

## 컴포넌트의 책임

컴포넌트를 나눌 때는 단순히 JSX의 길이보다 함께 변경되는 상태와 행동을 기준으로 판단하는 것이 좋다.

예를 들어 차량번호 목록 편집기는 다음 책임을 가질 수 있다.

- 현재 등록할 차량번호 목록 표시
- 차량번호 입력과 추가 이벤트 처리
- 항목 제거와 자동값 확인 버튼 제공
- 자신에게 해당하는 검증 오류 표시
- 등록 중 입력 비활성화

반면 다음 책임은 상위 계약 검토 컴포넌트나 별도 Hook이 담당할 수 있다.

- 계약 전체의 로컬 검증
- 서버 검증 요청
- 멱등성 키 관리
- 등록 성공 후 화면 전환
- 계약 목록 캐시 갱신

책임이 명확하면 컴포넌트 테스트도 해당 UI 동작에 집중할 수 있다.

## 제어 컴포넌트

입력값을 React state와 연결한 입력 요소를 제어 컴포넌트라고 한다.

```tsx
function NameInput() {
  const [name, setName] = useState('');

  return (
    <input
      value={name}
      onChange={(event) => setName(event.target.value)}
    />
  );
}
```

화면에 표시되는 값은 DOM 자체가 아니라 React state가 기준이다.

부모가 값을 소유하는 형태도 가능하다.

```tsx
interface NameInputProps {
  value: string;
  onChange: (value: string) => void;
}

function NameInput({ value, onChange }: NameInputProps) {
  return (
    <input
      value={value}
      onChange={(event) => onChange(event.target.value)}
    />
  );
}
```

이 경우 자식은 값을 표시하고 변경 요청만 전달하며, 실제 상태는 부모가 관리한다.

## 조건부 렌더링

컴포넌트는 조건에 따라 일부 UI를 표시하거나 숨길 수 있다.

```tsx
function Feedback({ message }: { message: string | null }) {
  return (
    <div>
      {message && <p role="alert">{message}</p>}
    </div>
  );
}
```

`message`가 비어 있지 않을 때만 `<p>` 요소가 렌더링된다.

삼항 연산자를 사용할 수도 있다.

```tsx
return isLoading
  ? <p>불러오는 중</p>
  : <p>완료</p>;
```

## 컴포넌트와 React element의 차이

컴포넌트와 element는 관련되어 있지만 같은 개념은 아니다.

```tsx
function Greeting() {
  return <p>안녕하세요.</p>;
}
```

- `Greeting`: 컴포넌트 함수
- `<Greeting />`: 컴포넌트를 사용하여 React element를 만드는 JSX 표현식
- `<p>안녕하세요.</p>`: 컴포넌트가 반환하는 element
- 실제 `<p>` DOM: React가 브라우저에 반영한 결과

개념적인 흐름은 다음과 같다.

```text
컴포넌트 함수
-> React element 계산
-> React가 이전 element와 비교
-> 필요한 DOM 생성 또는 갱신
```

## 컴포넌트는 일반 함수와 완전히 같지는 않다

컴포넌트의 구현 형태는 함수지만 React가 렌더링 순서와 Hook 상태를 관리한다. 따라서 일반 함수처럼 임의로 직접 호출하지 않는 것이 원칙이다.

```ts
Greeting(); // 일반 애플리케이션 코드에서 권장하지 않음
```

대신 JSX로 React에 렌더링을 요청한다.

```tsx
<Greeting />
```

컴포넌트 렌더링 중에는 외부 시스템을 직접 변경하는 부수 효과를 피해야 한다. 서버 요청, 구독, 브라우저 API 연동 같은 효과는 이벤트 처리 함수나 `useEffect()` 같은 적절한 경계에서 수행한다.

## 컴포넌트 테스트

컴포넌트 테스트는 구현 내부보다 사용자가 보는 화면과 행동을 검증하는 것이 좋다.

```tsx
render(<VehicleNumberInput />);

const user = userEvent.setup();
await user.type(screen.getByLabelText('차량번호'), '123가4567');

expect(screen.getByLabelText('차량번호')).toHaveValue('123가4567');
```

일반적으로 다음을 검증한다.

- 필요한 정보가 화면에 표시되는가
- 사용자가 입력하고 버튼을 누를 수 있는가
- 검증 오류가 올바른 위치에 표시되는가
- 비활성화 조건이 UI에 반영되는가
- 사용자 행동이 부모 콜백으로 전달되는가

순수 계산이나 상태 전이 규칙은 React 없이 단위 테스트하고, 컴포넌트 테스트는 그 규칙이 UI에 올바르게 연결됐는지 확인하면 테스트 중복을 줄일 수 있다.

## 정리

React 컴포넌트는 화면의 일부와 그 행동을 표현하는 재사용 가능한 UI 단위다.

핵심 개념은 다음과 같다.

1. 컴포넌트는 TypeScript 전용 문법이 아니라 React가 함수에 부여하는 역할이다.
2. props는 부모가 전달하는 입력이고, state는 렌더링 사이에 유지되는 내부 상태다.
3. props와 state가 바뀌면 React가 컴포넌트를 다시 렌더링한다.
4. 큰 화면은 작은 컴포넌트를 조합하여 구성한다.
5. 자식은 props를 직접 수정하지 않고 콜백을 통해 부모에게 변경을 요청한다.
6. TypeScript는 props와 반환 구조의 타입 안정성을 제공한다.
7. 컴포넌트 테스트는 사용자가 관찰하는 화면과 상호작용에 집중한다.
