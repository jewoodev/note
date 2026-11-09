# AbortSignal: 비동기 작업의 취소를 전달하는 방법

HTTP 요청을 시작한 뒤 사용자가 화면을 떠나거나 검색어를 바꾸면, 이전 요청의 결과는 더 이상 필요하지 않을 수 있다. 이때 요청을 중단하고 오래된 결과가 현재 화면에 반영되지 않도록 만드는 데 `AbortSignal`을 사용할 수 있다.

이 문서는 JavaScript의 Promise와 `async`·`await`를 알고 있는 독자를 대상으로 한다. 특정 프로젝트나 서버 구조에 대한 지식은 필요하지 않다. 예제의 `/api/users/1` 같은 주소는 설명용이며, HTTP 예제를 실행하려면 해당 주소에서 JSON을 반환하는 서버가 필요하다.

## 1. 취소를 지시하는 객체와 전달받는 객체

`AbortController`는 취소를 지시하고, `AbortSignal`은 그 사실을 작업에 전달한다. 둘은 웹 표준 API이며 `controller.signal`로 연결된다. [MDN: AbortSignal](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal)

| 구성요소 | 책임 |
| --- | --- |
| `AbortController` | 작업의 수명을 관리하는 쪽에서 생성하고 취소를 지시 |
| `controller.abort()` | 연결된 signal을 취소 상태로 변경 |
| `controller.signal` | 작업에 전달하는 `AbortSignal` 객체 |
| `signal.aborted` | 취소 여부를 나타내는 boolean |
| `signal.reason` | 취소 사유. 취소 전에는 undefined |
| `signal.throwIfAborted()` | 취소 상태라면 취소 사유를 던지고, 아니면 그대로 진행 |

```text
화면·호출자
  └─ AbortController.abort()
       └─ AbortSignal에 취소 상태 전달
            ├─ fetch: 요청·응답 본문 읽기 중단
            └─ 사용자 정의 작업: 취소를 감지하고 정리
```

일반적으로 호출자는 controller를 보관하고 하위 함수에는 signal만 넘긴다. 이렇게 하면 취소 시점을 결정하는 책임과 실제 작업을 수행하는 책임이 분리된다.

## 2. 먼저 상태 변화부터 확인하기

다음 코드는 서버 없이 브라우저 콘솔에서 실행할 수 있다.

```js
const controller = new AbortController();
const signal = controller.signal;

console.log(signal.aborted); // false

signal.addEventListener('abort', () => {
  console.log('취소 통지를 받았습니다.');
}, { once: true });

controller.abort();

console.log(signal.aborted); // true
console.log(signal.reason.name); // AbortError
```

사유 없이 `abort()`를 호출하면 기본 취소 사유는 이름이 `AbortError`인 `DOMException`이다. `abort(reason)`으로 사유를 직접 지정할 수도 있으며 그 값은 반드시 Error 객체일 필요가 없다. 따라서 모든 취소를 `error.name === 'AbortError'`만으로 판별할 수 있다고 가정하면 안 된다. [MDN: abort()](https://developer.mozilla.org/en-US/docs/Web/API/AbortController/abort)

이미 취소된 signal은 다시 정상 상태로 되돌릴 수 없다. 독립적인 새 작업에는 새 controller를 만든다. 반대로 여러 작업을 함께 취소하려는 경우에는 같은 signal을 여러 작업에 전달할 수 있다. [DOM 표준: 작업 취소](https://dom.spec.whatwg.org/#aborting-ongoing-activities)

## 3. fetch 요청 취소하기

`fetch`의 두 번째 인수에 `{ signal }`을 전달하면 요청이 취소 신호와 연결된다.

```js
const controller = new AbortController();

async function loadUser() {
  try {
    const response = await fetch('/api/users/1', {
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const user = await response.json();
    controller.signal.throwIfAborted();
    console.log('조회 결과:', user);
  } catch (error) {
    if (controller.signal.aborted) {
      console.log('이 조회 결과는 더 이상 사용하지 않습니다.');
      return;
    }
    console.error('조회 실패:', error);
  }
}

void loadUser();

// 취소 버튼 클릭 또는 화면 이탈 시 실행할 코드다.
controller.abort();
```

위 코드를 그대로 실행하면 조회 시작 직후 취소한다. 실제 화면에서는 마지막 줄을 취소 버튼이나 화면 해제 처리에 연결한다.

`fetch`는 404·500 같은 HTTP 오류 상태만으로 Promise를 거부하지 않는다. 그래서 `response.ok`를 따로 확인해야 한다. 요청 취소, 네트워크 실패, HTTP 오류는 서로 다른 처리 경로다. [MDN: fetch()](https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch)

예제의 catch는 **이 작업이 이미 취소됐다면 뒤늦게 도착한 성공·실패를 화면에 반영하지 않는다**는 정책을 사용한다. 취소가 실제 오류의 원인이었다는 엄밀한 진단은 아니다. 운영 로그에서 원인을 분석할 때는 받은 오류와 취소 사유를 별도로 살펴볼 수 있다.

## 4. API 함수 여러 단계를 지나도 signal을 전달하기

API를 감싼 함수가 있다면 각 단계에서 signal을 전달해야 한다. 다음은 TypeScript 예제다.

```ts
async function getJson<T>(
  url: string,
  signal?: AbortSignal,
): Promise<T> {
  const response = await fetch(url, { signal });
  signal?.throwIfAborted();

  if (!response.ok) {
    const detail = await response.text();
    signal?.throwIfAborted();
    throw new Error(`HTTP ${response.status}: ${detail}`);
  }

  const result = await response.json();
  signal?.throwIfAborted();
  return result as T;
}

type User = { id: number; name: string };

function getUser(id: number, signal?: AbortSignal) {
  return getJson<User>(`/api/users/${id}`, signal);
}
```

호출 흐름은 `호출자 → getUser → getJson → fetch`다. 중간에서 signal을 누락하면 가장 안쪽 작업까지 취소를 전달할 수 없다.

`signal?: AbortSignal`은 선택적 매개변수다. `signal?.throwIfAborted()`의 `?.`는 signal이 없으면 호출을 생략한다. 이 방식으로 취소 기능을 추가하면서 signal을 전달하지 않는 기존 호출도 유지할 수 있다.

`fetch`에 넘기는 `{ signal }`은 요청 옵션 객체다. TypeScript에서는 그 형태를 `RequestInit`이라는 타입으로 제공하며, method·headers·body 등의 옵션과 함께 사용할 수 있다. [MDN: RequestInit](https://developer.mozilla.org/en-US/docs/Web/API/RequestInit)

예제의 `as T`는 컴파일 시 타입 단언이며 JSON 구조를 검증하지 않는다. 또한 서버 오류 본문을 Error에 넣는 것은 흐름 설명용이다. 사용자에게 보여 줄 문구와 서버 진단 정보의 구분은 실제 API 클라이언트에서 별도로 설계해야 한다.

## 5. fetch에 전달했는데도 throwIfAborted를 쓰는 이유

`throwIfAborted()`는 취소를 지시하는 메서드가 아니다. 호출한 시점의 signal이 취소 상태인지 검사하고, 취소됐다면 `signal.reason`을 던진다. [MDN: throwIfAborted()](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/throwIfAborted)

fetch가 응답을 반환한 뒤에도 본문 읽기, 다른 비동기 변환, 상태 갱신 같은 후속 처리가 남을 수 있다. 특히 다른 작업을 `await`하는 동안 화면의 유효성이 바뀔 수 있으므로, 그 다음 결과를 반영하기 전에 취소를 확인하는 것이 유용하다.

다음 상황을 생각해 보자.

1. 이전 로그인 세션에서 조회 요청을 시작한다.
2. 서버가 401 응답을 보내고 클라이언트가 오류 본문을 읽는다.
3. 그 사이 사용자가 화면을 떠나 이전 요청이 취소된다.
4. 새 로그인이 완료된다.
5. 이전 오류를 전역 인증 처리기에 전달하면 새 세션까지 로그아웃시킬 수 있다.

이 경우 오류 본문을 읽은 뒤, 인증 처리기를 호출하기 전에 취소 여부를 확인한다. 오류 본문 읽기 실패를 catch해서 기본값으로 바꾸는 코드가 있다면 취소 예외까지 삼킬 수 있으므로 특히 주의한다.

다만 취소 확인은 임의의 동기 코드를 강제로 중단시키지 않는다. 긴 동기 반복문으로 실행 흐름을 점유하면 사용자 취소 이벤트를 처리할 기회도 늦어진다. 큰 연산은 작업을 나누어 이벤트 처리가 가능하게 하거나 별도의 Worker에서 수행하는 등의 설계가 필요하다.

## 6. React에서 화면 수명과 연결하기

React의 effect는 의존성이 바뀌어 다시 실행되기 전과 컴포넌트가 해제될 때 정리 함수를 실행한다. 그 정리 함수에서 controller를 취소할 수 있다. [React: useEffect](https://react.dev/reference/react/useEffect)

다음 예제는 앞 절의 `getUser`와 `User` 타입을 같은 모듈에서 사용할 수 있다고 가정한다.

```tsx
import { useEffect, useState } from 'react';

function UserPanel({ userId }: { userId: number }) {
  const [user, setUser] = useState<User | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setUser(null);
    setError(null);

    void getUser(userId, controller.signal)
      .then((result) => {
        controller.signal.throwIfAborted();
        setUser(result);
      })
      .catch(() => {
        if (controller.signal.aborted) return;
        setError('사용자 정보를 불러오지 못했습니다.');
      });

    return () => controller.abort();
  }, [userId]);

  if (error) return <p role="alert">{error}</p>;
  if (!user || user.id !== userId) {
    return <p role="status">불러오는 중입니다.</p>;
  }
  return <p>{user.name}</p>;
}
```

userId가 바뀌면 이전 effect의 요청을 취소하고 새 controller로 조회한다. 컴포넌트가 해제될 때도 진행 중인 요청을 취소한다. 이전 요청의 catch가 새 화면에 오류를 표시하지 않도록 signal을 확인한다.

개발 환경의 StrictMode에서는 effect의 설정·정리 과정이 추가로 실행될 수 있다. 매 effect 실행마다 새 controller를 만들면 취소된 signal을 재사용하지 않는다. 그래도 첫 요청이 서버에 도착했을 수 있으므로 서버 호출 횟수가 반드시 1회라고 보장할 수는 없다. [React: effect 정리와 StrictMode](https://react.dev/reference/react/useEffect#my-effect-runs-twice-when-the-component-mounts)

## 7. 시간 제한과 여러 취소 조건 결합하기

`AbortSignal.timeout(ms)`는 지정한 시간이 지나면 취소되는 signal을 만든다. 기본 취소 사유는 `TimeoutError`다. 브라우저 문서나 Worker가 중단된 동안의 시간을 제외하는 활성 시간 기준이므로, 서버의 절대적인 처리 기한과 동일하게 해석하지 않는다. [MDN: timeout()](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/timeout_static)

`AbortSignal.any(signals)`는 입력 signal 중 먼저 취소된 signal의 사유를 사용하는 결합 signal을 만든다. 이미 취소된 입력이 있으면 반환 signal도 취소 상태가 된다. [MDN: any()](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/any_static)

```js
const controller = new AbortController();
const signal = AbortSignal.any([
  controller.signal,
  AbortSignal.timeout(5000),
]);

async function loadWithDeadline() {
  try {
    const response = await fetch('/api/users/1', { signal });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const user = await response.json();
    signal.throwIfAborted();
    console.log(user);
  } catch (error) {
    if (signal.aborted) {
      if (signal.reason instanceof DOMException &&
          signal.reason.name === 'TimeoutError') {
        console.log('조회 시간이 초과되었습니다.');
      } else {
        console.log('조회가 취소되었습니다.');
      }
      return;
    }
    console.error('조회 실패:', error);
  }
}

void loadWithDeadline();
// 사용자 취소 버튼에서는 controller.abort()를 호출한다.
```

이 예제는 사용자 취소에 기본 사유를 사용하므로 `TimeoutError`와 구별할 수 있다. 사용자 정의 사유를 사용할 때는 구분 규칙도 함께 정해야 한다. 기본 AbortController 지원 여부와 `any()`·`timeout()` 지원 여부는 별개이므로 대상 브라우저의 호환성 표를 확인한다.

## 8. 사용자 정의 비동기 작업에도 연결하기

signal은 Promise 자체를 자동으로 취소하지 않는다. 사용자 정의 작업은 취소를 감지했을 때 타이머·이벤트·연결 등 자신이 만든 자원을 정리해야 한다. 다음은 서버 없이 실행할 수 있는 대기 함수다. [DOM 표준: API에서 AbortSignal 사용](https://dom.spec.whatwg.org/#using-abortcontroller-and-abortsignal-objects-in-apis)

```js
function delay(ms, signal) {
  return new Promise((resolve, reject) => {
    // 이미 취소됐다면 새 abort 이벤트를 기다리지 않는다.
    if (signal?.aborted) {
      reject(signal.reason);
      return;
    }

    const onAbort = () => {
      clearTimeout(timer);
      reject(signal.reason);
    };

    const timer = setTimeout(() => {
      signal?.removeEventListener('abort', onAbort);
      resolve();
    }, ms);

    signal?.addEventListener('abort', onAbort, { once: true });
  });
}

const controller = new AbortController();

void delay(3000, controller.signal)
  .then(() => console.log('대기 완료'))
  .catch((error) => console.log('대기 취소:', error));

controller.abort();
```

취소되면 타이머를 제거하고 Promise를 거부한다. 정상 완료 때는 abort 리스너를 직접 제거한다. `{ once: true }`는 취소 이벤트가 발생한 뒤 리스너를 제거하므로, 취소가 발생하지 않는 정상 완료의 정리까지 대신하지는 않는다.

## 9. 취소가 보장하는 범위

| 상황 | 구분해야 할 점 |
| --- | --- |
| signal을 받지 않는 작업 | controller를 취소해도 자동으로 멈추지 않음 |
| 이미 완료된 작업 | 취소해도 완료된 결과나 부수 효과를 되돌리지 않음 |
| 서버에 도착한 요청 | 클라이언트 취소만으로 서버 처리 중단·롤백을 보장하지 않음 |
| 저장·결제 등 상태 변경 요청 | 취소를 실패 확정으로 해석하지 말고 결과 확인·중복 방지 설계 필요 |
| 화면 상태·캐시 | 취소만으로 이미 보관한 데이터를 지우지 않음. 별도 수명 관리 필요 |
| 여러 요청이 같은 signal 사용 | 하나의 취소가 연결된 작업 전체에 적용됨 |

취소 설계에서는 호출자가 언제 결과를 더 이상 필요로 하지 않는지, 그 시점에 어떤 자원을 정리해야 하는지, 이미 시작된 서버 작업의 결과는 어떻게 확인할지를 함께 정한다.

## 10. 적용 시 확인할 항목

- 호출자가 controller를 소유하고 하위 작업까지 signal을 전달하는가?
- 독립적인 새 작업에 취소된 signal을 재사용하지 않는가?
- 취소된 작업의 늦은 결과·오류가 현재 화면이나 세션을 변경하지 않는가?
- 사용자 취소·시간 초과·HTTP 오류·네트워크 오류를 목적에 맞게 구분하는가?
- 사용자 정의 작업의 타이머와 이벤트 리스너가 정리되는가?
- 요청 취소와 서버 처리 중단, 캐시 제거를 별개로 다루는가?

취소 시점과 응답 완료 시점이 가까운 경우가 중요하다. 테스트에서는 요청 도중 취소, 응답 본문 처리 중 취소, 취소 직후 새 요청 시작, 이전 요청의 늦은 완료를 각각 재현해 결과 반영 여부를 확인할 수 있다.
