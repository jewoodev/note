# RequestInit: fetch 요청 옵션을 구성하는 방법

웹 화면에서 서버를 호출할 때는 주소뿐 아니라 HTTP 메서드, 헤더, 본문, 쿠키 전송 정책 등을 정해야 한다. `RequestInit`은 이러한 **요청 옵션 객체의 형태**를 나타낸다. `fetch(url, options)`의 두 번째 인수나 `new Request(url, options)`의 옵션으로 사용한다. [MDN: RequestInit](https://developer.mozilla.org/en-US/docs/Web/API/RequestInit)

이 문서는 JavaScript 객체와 `async`·`await`를 알고 있는 독자를 대상으로 한다. 특정 프로젝트나 프레임워크에 대한 지식은 필요하지 않다. 예제는 브라우저용 TypeScript이며, `/api/users` 등의 경로는 설명용이다. HTTP 예제를 실행하려면 해당 경로를 처리하는 서버가 필요하다.

## 1. 옵션 객체와 타입을 구분하기

```ts
const options: RequestInit = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ name: '민수' }),
};
```

이 코드에서 `options`는 실행 중에 존재하는 일반 JavaScript 객체이고, `RequestInit`은 컴파일 시 속성의 타입을 검사하는 데 사용된다. 브라우저용 TypeScript의 DOM 타입 선언에 포함되어 있으므로 일반적인 브라우저 프로젝트에서는 별도 import가 필요 없다.

객체를 선언하기만 해서는 요청이 전송되지 않는다. `fetch('/api/users', options)`를 호출해야 전송이 시작된다. `new RequestInit()`으로 만드는 클래스도 아니다.

JavaScript로 작성한다면 `: RequestInit`만 제거하면 된다. TypeScript 타입 표기는 실행되는 JavaScript에서 제거되므로, 잘못된 서버 응답을 런타임에 검증하는 기능까지 제공하지 않는다. [TypeScript: 타입과 타입 단언](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)

## 2. RequestInit·Request·Response의 관계

| 구성요소 | 역할 | 생성 또는 사용 예 |
| --- | --- | --- |
| `RequestInit` | 요청을 구성할 옵션의 형태 | `{ method: 'GET' }` |
| `Request` | URL과 옵션을 반영한 요청 객체 | `new Request(url, options)` |
| `fetch` | 요청을 수행하는 함수 | `fetch(url, options)` 또는 `fetch(request)` |
| `Response` | 응답 상태·헤더·본문을 제공하는 객체 | `await fetch(...)`의 결과 |

```ts
const request = new Request('https://example.com/api/users', {
  method: 'GET',
  headers: { Accept: 'application/json' },
});

console.log(request.method); // GET
console.log(request.headers.get('Accept')); // application/json
// 아직 요청을 전송하지 않았다. 전송하려면 fetch(request)를 호출한다.
```

`Request` 생성자는 요청 객체를 만들고, `fetch`가 실제 요청을 수행한다. 이미 만든 Request에 `fetch(request, options)`로 옵션을 추가하면 겹치는 설정은 fetch에 직접 전달한 옵션이 우선한다. [MDN: Request 생성자](https://developer.mozilla.org/en-US/docs/Web/API/Request/Request)

## 3. 자주 사용하는 옵션

모든 옵션을 매번 채울 필요는 없다. 필요한 속성만 지정하고 나머지는 기본 동작을 사용한다. [MDN: RequestInit 옵션](https://developer.mozilla.org/en-US/docs/Web/API/RequestInit)

| 속성 | 의미 | 사용 예 |
| --- | --- | --- |
| `method` | HTTP 메서드. 생략 시 GET | `'POST'`, `'PATCH'`, `'DELETE'` |
| `headers` | 요청 헤더 | `{ Accept: 'application/json' }` |
| `body` | 보낼 본문 | JSON 문자열, FormData 등 |
| `credentials` | 쿠키 등 인증정보를 포함하는 정책 | `'same-origin'`, `'include'`, `'omit'` |
| `signal` | 비동기 작업의 취소 신호 | `controller.signal` |
| `cache` | 브라우저 HTTP 캐시 사용 정책 | `'no-store'`, `'no-cache'` |
| `mode` | 출처가 다른 요청의 처리 방식 | `'cors'`, `'same-origin'`, `'no-cors'` |
| `redirect` | 리다이렉트 처리 정책 | `'follow'`, `'error'`, `'manual'` |

`timeout`이나 `retry`는 표준 RequestInit의 옵션이 아니다. 시간 제한은 AbortSignal 등을 이용해 연결하고, 재시도는 호출 코드나 별도 라이브러리에서 설계한다.

## 4. GET으로 조회하기

GET 요청의 검색 조건은 보통 URL의 쿼리 문자열로 보낸다. fetch의 GET·HEAD 요청에는 본문을 넣을 수 없다. [MDN: Fetch 사용법](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch)

```ts
async function searchUsers(keyword: string): Promise<unknown> {
  const params = new URLSearchParams({ keyword });
  const response = await fetch(`/api/users?${params}`, {
    headers: { Accept: 'application/json' },
  });

  if (!response.ok) {
    throw new Error(`조회 실패: HTTP ${response.status}`);
  }

  return response.json();
}
```

`URLSearchParams`를 사용하면 검색어의 공백이나 특수문자를 쿼리 문자열에 맞게 인코딩할 수 있다. `method`를 생략했으므로 GET으로 요청한다.

`fetch`는 404·500 응답을 받았다는 이유만으로 Promise를 거부하지 않는다. `response.ok`를 확인해 HTTP 오류를 처리해야 한다. 네트워크 실패와 요청 취소는 별도로 Promise가 거부되는 경로다. [MDN: fetch()](https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch)

## 5. POST로 JSON 보내기

```ts
async function createUser(name: string): Promise<unknown> {
  const init: RequestInit = {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ name }),
  };

  const response = await fetch('/api/users', init);
  if (!response.ok) {
    throw new Error(`등록 실패: HTTP ${response.status}`);
  }
  if (response.status === 204) return undefined;
  return response.json();
}
```

`Content-Type`은 **보내는 본문 형식**, `Accept`는 **받고 싶은 응답 형식**을 나타낸다. 둘 중 어느 것도 JavaScript 객체를 자동으로 JSON 문자열로 변환하지 않는다. 본문 직렬화는 `JSON.stringify`가 수행한다. [MDN: Fetch의 헤더와 본문](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch)

이 예제는 성공 응답이 JSON이거나 204라는 API 계약을 가정한다. 204처럼 본문이 없는 응답에 `response.json()`을 호출하면 JSON 해석에 실패한다. 서버가 텍스트나 파일을 반환한다면 각각 `text()`나 `blob()` 등의 읽기 메서드를 선택해야 한다.

## 6. 파일은 FormData로 보내기

```ts
async function uploadDocument(file: File): Promise<void> {
  const form = new FormData();
  form.append('document', file);
  form.append('description', '첨부 문서');

  const response = await fetch('/api/documents', {
    method: 'POST',
    body: form,
  });

  if (!response.ok) {
    throw new Error(`업로드 실패: HTTP ${response.status}`);
  }
}
```

FormData를 사용할 때는 `Content-Type: multipart/form-data`를 직접 지정하지 않는다. 브라우저가 본문의 각 부분을 구분하는 boundary를 포함해 적절한 헤더를 생성한다. 공통 API 함수가 모든 요청에 `application/json`을 강제로 넣으면 이런 업로드가 잘못될 수 있다. [MDN: FormData 사용법](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest_API/Using_FormData_Objects)

## 7. 공통 API 함수에서 옵션 합치기

공통 함수는 호출자의 method·body·signal을 전달하면서 기본 헤더 등을 추가할 수 있다.

```ts
async function request(
  url: string,
  init: RequestInit = {},
): Promise<Response> {
  const headers = new Headers(init.headers);
  if (!headers.has('Accept')) {
    headers.set('Accept', 'application/json');
  }

  const response = await fetch(url, {
    ...init,
    credentials: 'same-origin',
    headers,
  });

  init.signal?.throwIfAborted();
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response;
}
```

`init`은 요청 옵션 매개변수의 이름이다. `RequestInit = {}`은 옵션을 생략하면 빈 객체를 사용한다는 뜻이다. `request('/api/users')`와 `request('/api/users', { method: 'DELETE' })`처럼 같은 함수를 여러 요청에 사용할 수 있다.

이 함수는 Response를 반환한다. JSON 해석·파일 다운로드·빈 응답 처리는 호출자가 응답 계약에 맞게 결정한다.

### 7-1. 객체를 펼치는 순서가 우선순위를 결정한다

```ts
const init: RequestInit = { credentials: 'omit' };

const callerWins: RequestInit = {
  credentials: 'same-origin',
  ...init,
};
// 최종 credentials: omit

const policyWins: RequestInit = {
  ...init,
  credentials: 'same-origin',
};
// 최종 credentials: same-origin
```

같은 속성을 여러 번 지정하면 뒤쪽 값이 적용된다. 앞의 공통 함수는 인증정보 전송 정책을 `same-origin`으로 고정하는 예제다. 호출자가 재정의해도 되는 기본값인지, 공통 함수가 강제할 정책인지 먼저 정하고 순서를 선택해야 한다.

또한 객체 펼치기는 얕은 복사다. `{ ...defaults, ...init }`만으로는 두 객체의 headers 내부가 자동으로 합쳐지지 않는다.

### 7-2. 헤더는 Headers로 정규화한다

`headers`에는 일반 객체, 이름·값 쌍 배열, Headers 객체를 전달할 수 있다. 따라서 `...init.headers`로 일반 객체처럼 합치면 모든 입력 형태를 올바르게 처리하지 못한다.

`new Headers(init.headers)`는 다양한 입력을 같은 인터페이스로 다룰 수 있게 한다. `has`·`get`·`set`으로 헤더 이름의 대소문자를 구별하지 않고 처리하며, 새 Headers 객체를 만들었으므로 호출자가 넘긴 헤더를 직접 수정하지 않는다. [MDN: Headers](https://developer.mozilla.org/en-US/docs/Web/API/Headers)

## 8. signal로 요청 취소 연결하기

앞 절의 `request` 함수가 같은 모듈에 있다고 가정하면 다음처럼 사용할 수 있다.

```ts
const controller = new AbortController();

void request('/api/users', { signal: controller.signal })
  .then(async (response) => {
    const users = await response.json();
    controller.signal.throwIfAborted();
    console.log(users);
  })
  .catch((error: unknown) => {
    if (controller.signal.aborted) return;
    console.error('조회 실패:', error);
  });

// 취소 버튼 클릭 또는 화면 이탈 시 실행한다.
controller.abort();
```

RequestInit이 취소를 실행하는 것은 아니다. signal을 fetch에 전달하고, controller가 취소 시점을 결정한다. 예제를 그대로 실행하면 조회 시작 직후 취소한다. 이미 취소된 signal은 새 요청에 재사용하지 않는다.

이 catch는 취소된 작업의 늦은 실패를 화면에 반영하지 않는 정책이다. 취소 원인과 후속 처리에 대한 자세한 설명은 [AbortSignal 문서](abort-signal.md)를 참고한다.

## 9. 쿠키·CORS·캐시 옵션을 구분하기

### 9-1. credentials는 쿠키 전송 정책이다

`credentials`의 기본값은 `same-origin`이다. `omit`은 쿠키 등 인증정보를 포함하지 않는 정책, `include`는 다른 출처의 요청에도 포함하도록 요청하는 정책이다. 출처는 스킴·호스트·포트의 조합으로 구분한다. [MDN: RequestInit](https://developer.mozilla.org/en-US/docs/Web/API/RequestInit)

`include`를 지정해도 서버의 CORS 설정이나 쿠키의 SameSite·Secure·브라우저 정책을 무시하지는 못한다. 다른 출처에서 쿠키를 사용하는 응답을 읽으려면 서버도 자격증명 사용과 구체적인 요청 출처를 허용해야 한다. [MDN: 인증정보 포함](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#including_credentials)

이 옵션은 로그인 동작을 대신하거나 없는 세션을 생성하지 않는다. 실제 인증·권한 검사는 서버가 수행한다.

### 9-2. no-cors는 CORS 오류 해결 옵션이 아니다

다른 출처의 요청에 `mode: 'no-cors'`를 지정하면 메서드·헤더가 제한되고, 응답이 opaque가 되어 JavaScript에서 상태·본문을 읽을 수 없게 될 수 있다. JSON API의 CORS 문제는 클라이언트 옵션으로 숨기기보다 서버의 허용 출처와 요청 구조를 확인해야 한다. [MDN: Fetch의 mode 설정](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#making_cross-origin_requests)

### 9-3. cache는 브라우저 HTTP 캐시에 관한 옵션이다

| 값 | 의미 |
| --- | --- |
| `default` | 일반적인 HTTP 캐시 규칙 사용 |
| `no-store` | HTTP 캐시를 조회하지 않고, 받은 응답으로 캐시를 갱신하지 않음 |
| `no-cache` | 기존 캐시가 있으면 서버에 유효성을 확인한 뒤 사용 가능 |
| `reload` | 기존 캐시를 사용하지 않고 가져온 결과로 캐시 갱신 |

`no-cache`는 저장 금지와 다르다. 또한 `cache: 'no-store'`는 상태 관리 라이브러리의 메모리 캐시나 브라우저 영구 저장소에 애플리케이션이 직접 보관한 값을 지우지 않는다. [MDN: Request.cache](https://developer.mozilla.org/en-US/docs/Web/API/Request/cache)

## 10. 자주 생기는 오해

| 오해 | 실제로 필요한 처리 |
| --- | --- |
| RequestInit 객체를 만들면 요청이 시작된다 | fetch를 호출해야 전송됨 |
| Content-Type을 JSON으로 지정하면 객체가 직렬화된다 | JSON.stringify 등으로 본문을 구성해야 함 |
| fetch는 모든 HTTP 오류에서 catch로 이동한다 | response.ok 또는 status를 확인해야 함 |
| headers를 펼치면 모든 형태의 헤더가 병합된다 | Headers로 정규화하고 병합 규칙을 적용해야 함 |
| TypeScript 응답 타입을 지정하면 JSON이 검증된다 | 필요하면 런타임 구조 검증을 별도로 수행해야 함 |
| RequestInit에 retry를 넣으면 재시도한다 | 표준 옵션이 아니므로 별도 동작을 구현해야 함 |
| 옵션이 같으면 모든 본문을 그대로 재전송해도 된다 | 이미 소비된 Request 본문·스트림의 재사용 가능성을 확인해야 함 |

특히 재시도를 구현할 때는 본문을 다시 만들 수 있는지와 서버 작업의 중복 실행 가능성을 함께 검토한다. Request의 본문은 소비되면 그대로 다시 읽어 전송할 수 없으며, 필요하면 소비 전에 clone하거나 새 요청을 구성해야 한다. [MDN: Fetch의 요청 본문 재사용](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#setting_a_body)
