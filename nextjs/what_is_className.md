className은 React/TSX에서 HTML 요소의 CSS 클래스를 지정하는 속성이다. HTML의 `class` 속성과 동일한 역할을 하지만, React에서는 `className`을 사용한다. 이는 JavaScript의 `class` 키워드와의 충돌을 피하기 위해서다.

### 1. 기본 사용법

```textmate
// 단일 클래스 적용
const Component = () => {
  return <div className="container">내용</div>;
};

// 여러 클래스 적용
const Component = () => {
  return <div className="container main-content">내용</div>;
};
```

### 2. 조건부 클래스 적용

1. **템플릿 리터럴 사용**
```textmate
const Component = ({ isActive }: { isActive: boolean }) => {
  return (
    <div className={`btn ${isActive ? 'active' : ''}`}>
      버튼
    </div>
  );
};
```

2. **clsx 라이브러리 사용** (프로젝트에 이미 설치되어 있음)
```textmate
import clsx from 'clsx';

const Component = ({ isActive, isLarge }: { isActive: boolean; isLarge: boolean }) => {
  return (
    <div
      className={clsx(
        'btn',
        isActive && 'active',
        isLarge && 'btn-large',
        'text-center'
      )}
    >
      버튼
    </div>
  );
};
```

### 3. Tailwind CSS와 함께 사용 (프로젝트에서 사용 중)

```textmate
// 기본적인 Tailwind 클래스 사용
const Component = () => {
  return (
    <div className="flex items-center justify-center p-4 bg-blue-500 text-white">
      Tailwind CSS 예시
    </div>
  );
};

// 조건부 스타일링과 함께 사용
const Button = ({ isPrimary }: { isPrimary: boolean }) => {
  return (
    <button
      className={clsx(
        'px-4 py-2 rounded-md',
        isPrimary 
          ? 'bg-blue-500 text-white' 
          : 'bg-gray-200 text-gray-800'
      )}
    >
      버튼
    </button>
  );
};
```

### 4. TypeScript와 함께 사용할 때 타입 안정성

```textmate
interface Props {
  variant: 'primary' | 'secondary';
  size?: 'small' | 'medium' | 'large';
}

const Button: React.FC<Props> = ({ variant, size = 'medium' }) => {
  const buttonClasses = clsx(
    'rounded-md font-semibold',
    // 변형에 따른 스타일
    {
      'bg-blue-500 text-white': variant === 'primary',
      'bg-gray-200 text-gray-800': variant === 'secondary',
    },
    // 크기에 따른 스타일
    {
      'px-2 py-1 text-sm': size === 'small',
      'px-4 py-2': size === 'medium',
      'px-6 py-3 text-lg': size === 'large',
    }
  );

  return (
    <button className={buttonClasses}>
      버튼
    </button>
  );
};
```

### 5. 주의사항과 모범 사례

1. **동적 클래스 관리**
```textmate
// 좋은 예시
const Component = ({ isError }: { isError: boolean }) => {
  return (
    <div
      className={clsx(
        'base-styles',
        isError && 'error-styles'
      )}
    >
      내용
    </div>
  );
};

// 피해야 할 예시
const Component = ({ isError }: { isError: boolean }) => {
  // 문자열 연결은 가독성이 떨어지고 관리가 어려움
  return (
    <div className={'base-styles' + (isError ? ' error-styles' : '')}>
      내용
    </div>
  );
};
```

2. **성능 최적화**
```textmate
// 컴포넌트 외부에서 정적 클래스 정의
const staticClasses = 'fixed top-0 left-0 w-full';

const Header = () => {
  return (
    <header className={staticClasses}>
      헤더 내용
    </header>
  );
};
```

className은 React/TSX 개발에서 매우 중요한 부분이며, 특히 Tailwind CSS와 같은 유틸리티 기반 CSS 프레임워크와 함께 사용할 때 더욱 강력해진다. clsx와 같은 유틸리티 라이브러리를 활용하면 조건부 스타일링을 더욱 깔끔하게 관리할 수 있다.