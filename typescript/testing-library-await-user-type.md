# Testing Library `await user.type(...)` 이해하기

## 전체 의미

다음 코드는 테스트에서 사용자가 입력칸에 문자열을 타이핑하는 동작을 실행하고, 관련 처리가 끝날 때까지 기다린다.

```ts
await user.type(input, '99가9999');
```

문법을 나누면 다음과 같다.

```text
await  user  .type  (input, '99가9999')
|      |      |       |
|      |      |       +-- 메서드에 전달하는 인수
|      |      +---------- user 객체의 type 메서드
|      +----------------- userEvent.setup()으로 만든 객체
+------------------------ 비동기 처리가 끝날 때까지 기다림
```

## `userEvent.setup()`과 `user` 객체

Testing Library에서는 보통 각 테스트 안에서 사용자 이벤트 세션을 만든다.

```ts
const user = userEvent.setup();
```

`user`는 실제 사용자의 동작과 비슷한 이벤트를 발생시키는 메서드들을 가진 객체다.

```ts
await user.click(button);
await user.type(input, '내용');
await user.clear(input);
await user.paste('붙여넣을 내용');
```

점 `.`은 객체의 속성이나 메서드에 접근하는 JavaScript 연산자다.

```ts
user.type
```

는 `user` 객체의 `type` 메서드를 선택하고, 뒤에 괄호를 붙이면 호출한다.

```ts
user.type(input, '99가9999');
```

## `type()`에 전달하는 인수

`type()`은 일반적으로 두 값을 받는다.

```ts
user.type(입력요소, 입력할문자열)
```

예를 들어 Testing Library로 입력 요소를 찾은 뒤 문자열을 입력할 수 있다.

```ts
const input = screen.getByLabelText('차량번호');

await user.type(input, '99가9999');
```

`screen.getByLabelText('차량번호')`는 `차량번호` 레이블과 연결된 요소를 동기적으로 찾는다. 요소가 없거나 조건에 맞는 요소가 여러 개이면 그 자리에서 테스트가 실패한다.

## `type()`은 사용자 입력 이벤트를 발생시킨다

`user.type()`은 input의 값을 테스트 코드에서 직접 대입하는 것과 다르다.

```ts
input.value = '99가9999';
```

대신 실제 입력에 가까운 이벤트 흐름을 발생시킨다.

```text
입력 요소에 focus
-> 첫 글자의 keydown
-> input 이벤트
-> keyup
-> 다음 글자의 keydown
-> input 이벤트
-> keyup
-> 반복
```

이 과정에서 React의 `onChange`, `onKeyDown` 같은 이벤트 처리 코드도 실행된다.

따라서 `user.type()`은 입력값 자체뿐 아니라 사용자 입력에 연결된 화면 동작까지 검증할 때 사용한다.

## `Promise`와 `await`

최신 `userEvent`의 사용자 동작 메서드는 비동기 처리를 나타내는 `Promise`를 반환한다.

```ts
const promise = user.type(input, '99가9999');
```

`await`는 이 Promise가 완료될 때까지 현재 `async` 함수의 다음 코드 실행을 미룬다.

```ts
const promise = user.type(input, '99가9999');
await promise;
```

이를 한 줄로 작성하면 다음과 같다.

```ts
await user.type(input, '99가9999');
```

`await`가 JavaScript 전체 실행을 멈추는 것은 아니다. 현재 `async` 함수의 나머지 실행만 잠시 중단하고 다른 비동기 작업은 계속 진행될 수 있다.

## `async` 테스트 함수

`await`는 일반적으로 `async` 함수 안에서 사용한다.

```ts
it('차량번호를 입력한다', async () => {
  const user = userEvent.setup();
  const input = screen.getByLabelText('차량번호');

  await user.type(input, '99가9999');

  expect(input).toHaveValue('99가9999');
});
```

테스트 콜백에 `async`를 붙이면 콜백이 Promise를 반환할 수 있다. Vitest는 그 Promise가 완료될 때까지 테스트 종료를 기다린다.

## `await`가 필요한 이유

사용자 입력은 React의 이벤트 처리와 상태 변경을 일으킬 수 있다.

```ts
await user.type(input, '99가9999');

expect(input).toHaveValue('99가9999');
```

`await`를 생략하면 입력 처리가 끝나기 전에 `expect()`가 실행될 수 있다.

```ts
user.type(input, '99가9999');

expect(input).toHaveValue('99가9999');
```

이런 테스트는 실행 시점에 따라 성공하거나 실패하는 불안정한 테스트가 될 수 있다. `userEvent`의 비동기 메서드는 반환된 Promise를 기다리는 것을 기본 원칙으로 삼는다.

## 특수 키 입력

`type()` 문자열에는 키보드의 특수 키를 나타내는 표현을 넣을 수 있다.

```ts
await user.type(input, '99가9999{Enter}');
```

이 코드는 다음 순서로 동작한다.

```text
99가9999 입력
-> Enter 키 입력
```

다른 예시는 다음과 같다.

```ts
await user.type(input, '내용{Backspace}');
await user.type(input, '{Escape}');
await user.type(input, '{Tab}');
```

특수 키를 사용하면 `onKeyDown`이나 Enter 제출 같은 키보드 동작도 사용자 관점에서 검증할 수 있다.

## 다른 `userEvent` 메서드와의 차이

### 기존 내용 뒤에 입력하기

```ts
await user.type(input, '추가 내용');
```

`type()`은 일반적으로 현재 입력값 뒤에 문자를 입력한다.

### 기존 내용 지우기

```ts
await user.clear(input);
```

입력값을 지우는 사용자 동작을 실행한다.

### 버튼 클릭하기

```ts
await user.click(button);
```

마우스로 버튼을 클릭하는 동작과 관련 이벤트를 발생시킨다.

### 붙여넣기

```ts
await user.click(input);
await user.paste('11가1111,22나2222');
```

현재 포커스를 가진 요소에 클립보드 내용을 붙여넣는다. 입력 컴포넌트의 `onPaste` 처리를 검증할 때 사용할 수 있다.

## `getBy...`와 `findBy...`의 비동기 차이

다음 코드에서 요소 탐색은 동기적이고 사용자 입력은 비동기적이다.

```ts
await user.type(
  screen.getByLabelText('차량번호'),
  '99가9999',
);
```

`getByLabelText()`는 즉시 요소를 찾고, `user.type()`이 Promise를 반환한다.

나중에 나타나는 요소를 기다려야 한다면 `findBy...`를 사용할 수 있다.

```ts
const input = await screen.findByLabelText('차량번호');
await user.type(input, '99가9999');
```

두 `await`는 서로 다른 작업을 기다린다.

1. 첫 번째 `await`: 입력 요소가 화면에 나타날 때까지 기다린다.
2. 두 번째 `await`: 사용자의 타이핑 처리가 끝날 때까지 기다린다.

## 정리

```ts
await user.type(input, '99가9999');
```

는 다음 의미를 가진다.

1. `userEvent.setup()`으로 만든 `user` 객체를 사용한다.
2. `type()` 메서드로 입력 요소에 사용자 타이핑 이벤트를 발생시킨다.
3. 반환된 Promise가 완료될 때까지 `await`로 기다린다.
4. React 이벤트와 상태 변경이 처리된 뒤 다음 테스트 코드를 실행한다.

테스트에서는 사용자 동작 메서드의 Promise를 기다리고, 그 뒤 화면이나 상태의 결과를 검증하는 순서를 유지하는 것이 중요하다.
