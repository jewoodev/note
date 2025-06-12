Next.js에서 요청을 전송하는 Best practice는 Server Functions를 사용하는 것이다. 이는 네트워크를 통해 서버의 API를 호출하는 것으로, 비동기 방식으로 동작해야만 하는 문맥을 갖는 함수들을 뜻한다.  
`action` 문맥에서 Server Actions로도 불린다.

Server Action은 [`startTrasaction`](https://react.dev/reference/react/startTransition)을 사용하는 비동기 함수다. 이것은 함수가 다음과 같은 조건을 만족할 때 발생한다.
- Passed to a `<form>` using the `action` prop. 
- Passed to a `<button>` using the `formAction` prop. 
- Passed to `useActionState`.

Next.js에서 서버 액션은 프레임워크의 [캐싱](https://nextjs.org/docs/app/deep-dive/caching) 아키텍처와 통합된다. 액션이 호출되면 Next.js는 업데이트된 UI와 새 데이터를 단일 서버 왕복으로 모두 반환할 수 있다.

## Server Functions 만들기
Server Funtion은 [`use server`](https://react.dev/reference/rsc/use-server) 지시어를 사용하여 정의할 수 있다. 비동기 함수의 맨 위에 지시어를 추가하여 해당 함수를 서버 함수로 표시하거나, 별도 파일의 맨 위에 추가하여 해당 파일이 export하는 모든 함수를 Server Funtion으로 만들 수 있다.

```typescript
export async function createPost(formData: FormData) {
  'use server'
  const title = formData.get('title')
  const content = formData.get('content')
 
  // Update data
  // Revalidate cache
}
 
export async function deletePost(formData: FormData) {
  'use server'
  const id = formData.get('id')
 
  // Update data
  // Revalidate cache
}
```

### Server Components
Server Component는 Next.js 13 이후 도입된 개념으로, 서버에서 렌더링되는 컴포넌트입니다.
**주요 특징:**
1. **기본 설정**: Next.js에서 모든 컴포넌트는 기본적으로 Server Component입니다.
2. **성능 최적화**:
    - 클라이언트로 전송되는 JavaScript 번들 크기를 줄입니다.
    - 서버에서 데이터를 직접 가져올 수 있습니다.

3. **제한사항**:
    - `useState`, `useEffect`와 같은 React hooks 사용 불가
    - 브라우저 API 사용 불가
    - 이벤트 리스너 추가 불가

### 일괄적으로 Server Functions 만들기
Server Functions는 `"use server"` 지시어가 함수 body 최상단에 더해진 Server Components안에서 inline 될 수 있다.

```typescript
'use server'

export async function createPost() {}
```

> 서버 구성 요소는 기본적으로 점진적 향상을 지원한다. 즉, JavaScript가 아직 로드되지 않았거나 비활성화되어 있어도 서버 작업을 호출하는 양식이 제출된다.

### Client Components
브라우저에서 렌더링되는 컴포넌트이다.

**주요 특징:**
1. **선언 방법**: 파일 최상단에 `'use client'` 지시어를 추가하여 선언한다.
2. **사용 사례**:
    - 사용자 상호작용이 필요한 경우
    - 브라우저 API가 필요한 경우
    - React hooks 사용이 필요한 경우

3. **기능**:
    - `useState`, `useEffect` 등 모든 React hooks 사용 가능
    - 브라우저 API 접근 가능
    - 이벤트 핸들링 가능

### 예시
아래의 `LoginForm` 컴포넌트는 Client Component의 좋은 예시이다.
```typescript
'use client'; // Client Component 선언

function LoginForm() {
    // useActionState hook 사용
    const [state, formAction] = useActionState(login, initialState)
    // ... 
}
```
이 컴포넌트가 Client Component로 선언된 이유:
1. `useActionState` hook을 사용
2. 사용자 입력을 처리
3. 폼 제출과 같은 상호작용 처리
4. 라우터 조작 (`useRouter`)


```typescript
'use client'
 
import { createPost } from '@/app/actions'
 
export function Button() {
  return <button formAction={createPost}>Create</button>
}
```

## Invoking Server Functions
Server Function은 두 가지의 주요한 방법으로 호출할 수 있다.
1. Forms in Server and Client Components
2. Event Handlers and useEffect in Client Components

### Forms
React 는 HTML `<form>` element를 Server Function를 HTML action prop에 지정함으로써 호출하는 것이 가능하도록 확장한다.

When invoked in a form, the function automatically receives the FormData object. You can extract the data using the native FormData methods:

```typescript
import { createPost } from '@/app/actions'
 
export function Form() {
  return (
    <form action={createPost}>
      <input type="text" name="title" />
      <input type="text" name="content" />
      <button type="submit">Create</button>
    </form>
  )
}
```

```typescript
'use server'
 
export async function createPost(formData: FormData) {
  const title = formData.get('title')
  const content = formData.get('content')
 
  // Update data
  // Revalidate cache
}
```

### Redirecting
You may want to redirect the user to a different page after performing an update. You can do this by calling redirect within the Server Function:

```typescript
'use server'
 
import { redirect } from 'next/navigation'
 
export async function createPost(formData: FormData) {
  // Update data
  // ...
 
  redirect('/posts')
}
```

`redirect` can be directly used in a Client Component.

```typescript
'use client'
 
import { redirect, usePathname } from 'next/navigation'
 
export function ClientRedirect() {
  const pathname = usePathname()
 
  if (pathname.startsWith('/admin') && !pathname.includes('/login')) {
    redirect('/admin/login')
  }
 
  return <div>Login Page</div>
}
```

> Good to know: When using redirect in a Client Component on initial page load during Server-Side Rendering (SSR), it will perform a server-side redirect.

Client Component에서는 `useRouter`를 사용해 하는 것이 유용했다.

The `useRouter` hook allows you to programmatically change routes inside Client Components.

> Recommendation: Use the [`<Link>` component](https://nextjs.org/docs/app/api-reference/components/link) for navigation unless you have a specific requirement for using useRouter.


```typescript
'use client'
 
import { useRouter } from 'next/navigation'
 
export default function Page() {
  const router = useRouter()
 
  return (
    <button type="button" onClick={() => router.push('/dashboard')}>
      Dashboard
    </button>
  )
}
```