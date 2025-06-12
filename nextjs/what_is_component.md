컴포넌트는 React에서 UI를 구성하는 독립적이고 재사용 가능한 코드 조각을 말합니다. 크게 다음과 같은 것들을 컴포넌트라고 부른다.

### 1. 함수형 컴포넌트 (Function Components)
```
function WelcomeMessage({ name }: { name: string }) {
    return <h1>안녕하세요, {name}님!</h1>;
}
```

### 2. 클래스형 컴포넌트 (Class Components)
```
class WelcomeMessage extends React.Component<{ name: string }> {
    render() {
        return <h1>안녕하세요, {this.props.name}님!</h1>;
    }
}
```
※ 현재는 함수형 컴포넌트를 주로 사용하며, 클래스형 컴포넌트는 레거시 코드에서 주로 볼 수 있다.

### 컴포넌트의 주요 특징:

1. **UI 조각**
    - HTML 요소들의 집합
    - CSS 스타일
    - JavaScript 로직

2. **입력과 출력**
    - 입력: props (properties)
    - 출력: React 엘리먼트 (JSX)

3. **구성 요소별 분류**
    - **presentational 컴포넌트**: UI만 담당 (예: 버튼, 카드 등)
    - **container 컴포넌트**: 데이터 처리와 상태 관리 담당
    - **layout 컴포넌트**: 페이지 구조를 담당 (예: Header, Footer, Sidebar)
    - **페이지 컴포넌트**: 라우팅의 대상이 되는 전체 페이지

4. **크기별 분류**
    - **원자(Atomic) 컴포넌트**: 버튼, 입력 필드 등 가장 작은 단위
    - **분자(Molecular) 컴포넌트**: 검색 폼처럼 여러 원자 컴포넌트의 조합
    - **유기체(Organism) 컴포넌트**: 헤더처럼 여러 분자 컴포넌트의 조합
    - **템플릿**: 페이지의 구조를 잡는 와이어프레임
    - **페이지**: 최종 사용자가 보는 실제 콘텐츠

### 예시 컴포넌트 구조:
```typescript jsx
// 원자 컴포넌트
function Button({ children, onClick }: { children: React.ReactNode; onClick: () => void }) {
    return (
        <button onClick={onClick} className="btn">
            {children}
        </button>
    );
}

// 분자 컴포넌트
function SearchBar() {
    return (
        <div className="search-bar">
            <input type="text" placeholder="검색어를 입력하세요" />
            <Button onClick={() => console.log('검색')}>검색</Button>
        </div>
    );
}

// 유기체 컴포넌트
function Header() {
    return (
        <header>
            <nav>
                <logo />
                <SearchBar />
                <UserMenu />
            </nav>
        </header>
    );
}

// 페이지 컴포넌트
function HomePage() {
    return (
        <div>
            <Header />
            <MainContent />
            <Footer />
        </div>
    );
}
```

이러한 컴포넌트들은 모두:
1. 재사용 가능
2. 독립적으로 동작
3. 단일 책임 원칙을 따름
4. props를 통해 데이터를 받을 수 있음
5. 필요한 경우 내부 상태를 가질 수 있음

위와 같은 특징들을 가지고 있다.