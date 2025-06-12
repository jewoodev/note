TSX는 TypeScript XML의 약자로, React 컴포넌트를 TypeScript로 작성할 때 사용하는 파일 확장자이다. Next.js에서 TSX 파일은 다음과 같은 특징을 가진다.
1. **TypeScript + JSX의 조합**
   - `.tsx` 확장자는 TypeScript와 JSX(JavaScript XML)를 함께 사용할 수 있게 해준다.
   - React 컴포넌트를 TypeScript의 타입 안정성과 함께 작성할 수 있다.

2. **사용 예시**:
``` typescript
// example.tsx
interface Props {
  name: string;
  age: number;
}

const UserComponent: React.FC<Props> = ({ name, age }) => {
  return (
    <div>
      <h1>사용자 정보</h1>
      <p>이름: {name}</p>
      <p>나이: {age}</p>
    </div>
  );
};

export default UserComponent;
```
1. **Next.js에서의 주요 사용 사례**:
    - 페이지 컴포넌트 (`pages` 디렉토리)
    - 리액트 컴포넌트 (`components` 디렉토리)
    - 레이아웃 파일 (`app` 디렉토리)
    - API 라우트 (`pages/api` 또는 `app/api` 디렉토리)

2. **장점**:
    - 타입 체크를 통한 개발 시 오류 방지
    - 더 나은 IDE 자동 완성 지원
    - 컴포넌트 props의 타입 안정성 보장
    - 코드의 가독성과 유지보수성 향상

3. **일반 `.ts` 파일과의 차이점**:
    - `.ts` 파일: 일반 TypeScript 코드를 작성할 때 사용
    - `.tsx` 파일: JSX 문법을 포함한 React 컴포넌트를 작성할 때 사용

프로젝트에서 TypeScript를 사용하면서 React 컴포넌트를 작성할 때는 `.tsx` 확장자를 사용하고, 일반 TypeScript 로직(유틸리티 함수, 타입 정의 등)을 작성할 때는 `.ts` 확장자를 사용하는 것이 일반적입니다.


## JSX란?

JSX는 JavaScript에 XML/HTML과 유사한 문법을 추가한 JavaScript의 확장 문법이다. React에서 UI를 표현할 때 주로 사용된다.

### 1. JSX의 기본 특징

```textmate
// JSX 예시
const element = (
  <div className="greeting">
    <h1>안녕하세요!</h1>
    <p>JSX 예시입니다.</p>
  </div>
);
```


### 2. JSX의 주요 규칙과 사용법

1. **JavaScript 표현식 사용**
```textmate
const name = "사용자";
const element = <h1>안녕하세요, {name}님!</h1>;
```

2. **속성(Attributes) 정의**
```textmate
// HTML 클래스는 className으로 사용
const element = <div className="container">내용</div>;

// 변수를 속성값으로 사용
const imgUrl = "example.jpg";
const element = <img src={imgUrl} alt="예시 이미지" />;
```

3. **여러 요소는 하나의 부모 요소로 감싸야 함**
```textmate
// 올바른 사용
const element = (
  <div>
    <h1>제목</h1>
    <p>내용</p>
  </div>
);

// Fragment 사용
const element = (
  <>
    <h1>제목</h1>
    <p>내용</p>
  </>
);
```

4. **조건부 렌더링**
```textmate
const isLoggedIn = true;

const element = (
  <div>
    {isLoggedIn ? (
      <h1>환영합니다!</h1>
    ) : (
      <h1>로그인해주세요.</h1>
    )}
  </div>
);
```

5. **리스트 렌더링**
```textmate
const items = ['사과', '바나나', '오렌지'];

const element = (
  <ul>
    {items.map((item, index) => (
      <li key={index}>{item}</li>
    ))}
  </ul>
);
```

### 3. JSX vs 일반 HTML의 주요 차이점

1. **속성 이름의 차이**
- `class` → `className`
- `for` → `htmlFor`
- `onclick` → `onClick` (카멜 케이스 사용)

```textmate
// HTML
<label for="name" class="label">이름:</label>

// JSX
<label htmlFor="name" className="label">이름:</label>
```

2. **스타일 적용 방식**
```textmate
// HTML
<div style="background-color: blue; color: white;">텍스트</div>

// JSX
<div style={{ backgroundColor: 'blue', color: 'white' }}>텍스트</div>
```

### 4. JSX의 장점

1. **가독성**
   - HTML과 유사한 문법으로 UI 구조를 직관적으로 파악 가능

2. **안전성**
   - XSS(Cross-Site Scripting) 공격 방지를 위해 자동으로 이스케이프됨

3. **컴포넌트 기반 개발**
   - 재사용 가능한 UI 컴포넌트를 쉽게 만들고 관리할 수 있음

4. **개발 도구 지원**
   - 구문 강조, 자동 완성 등 IDE의 다양한 지원 기능 활용 가능

JSX는 React 개발에서 필수적인 부분이며, TypeScript와 함께 사용할 때는 TSX 확장자를 사용하여 타입 안정성까지 확보할 수 있다.
