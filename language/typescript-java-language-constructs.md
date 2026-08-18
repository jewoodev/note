# TypeScript와 Java의 선언 및 언어 구성 요소

이 문서는 TypeScript와 Java의 주요 선언과 언어 구성 요소를 비교해 정리한 개인 노트다.

## 가장 먼저 구분할 개념

코드는 크게 선언, 문장, 표현식, 수정자·어노테이션으로 나누어 이해할 수 있다.

```text
선언 declaration
→ 이름과 의미를 새로 정의한다.

문장 statement
→ 어떤 동작을 수행한다.

표현식 expression
→ 하나의 값을 계산한다.

수정자·어노테이션 modifier/annotation
→ 선언의 성질을 추가한다.
```

예를 들어 다음 TypeScript 코드가 있다.

```ts
const total = principal + interest;
```

- `const total = ...`: 변수 선언
- `principal + interest`: 덧셈 표현식
- `principal`, `interest`: 변수 참조 표현식

## TypeScript의 주요 선언

### 타입 선언

값이 어떤 형태여야 하는지 정의한다.

| 구성 요소 | 예 | 의미 |
|---|---|---|
| 인터페이스 | `interface User {}` | 객체 등의 구조 정의 |
| 타입 별칭 | `type UserId = number` | 타입에 새로운 이름 부여 |
| 클래스 | `class User {}` | 인스턴스 타입과 생성자 정의 |
| 열거형 | `enum Status {}` | 이름 있는 값의 집합 정의 |
| 타입 매개변수 | `<T>` | 제네릭 타입 변수 선언 |

```ts
interface User {
  id: number;
  name: string;
}

type UserId = number;

enum Status {
  ACTIVE,
  INACTIVE,
}

class UserService<T> {
  // ...
}
```

TypeScript의 `interface`와 `type`은 타입 검사에만 사용되고 일반적으로 JavaScript 결과물에서는 사라진다.

### 값 선언

실행 중 사용할 값을 정의한다.

| 구성 요소 | 예 |
|---|---|
| 상수 | `const count = 1` |
| 블록 변수 | `let count = 1` |
| 함수 범위 변수 | `var count = 1` |
| 함수 | `function save() {}` |
| 클래스 | `class User {}` |
| 열거형 | `enum Status {}` |

```ts
const pageSize = 50;
let currentPage = 1;

function calculateTotal() {
  return 100;
}
```

### 타입과 값을 동시에 만드는 선언

TypeScript에서는 하나의 선언이 타입과 런타임 값을 동시에 만들기도 한다.

| 선언 | 타입 생성 | 런타임 값 생성 |
|---|---:|---:|
| `interface` | O | X |
| `type` | O | X |
| `class` | O | O |
| `enum` | O | O |
| `function` | X | O |
| `const`, `let`, `var` | 추론된 타입 보유 | O |
| `namespace` | 경우에 따라 | O |

예를 들어 `class`는 인스턴스의 타입과 인스턴스를 만드는 생성자 값을 함께 만든다.

```ts
class User {
}

const user: User = new User();
```

- 타입 위치의 `User`: 인스턴스 타입
- `new User()`의 `User`: 생성자 값

### 함수 관련 선언

```ts
function add(left: number, right: number): number {
  return left + right;
}
```

포함된 선언은 다음과 같다.

- 함수 선언: `add`
- 매개변수 선언: `left`, `right`
- 반환 타입 표기: `number`

화살표 함수는 함수 표현식을 변수에 넣은 형태다.

```ts
const add = (left: number, right: number) => left + right;
```

- `const add`: 변수 선언
- `(left, right) => ...`: 함수 표현식
- `left`, `right`: 매개변수 선언

### 클래스와 객체의 멤버 선언

```ts
class User {
  private name: string;

  constructor(name: string) {
    this.name = name;
  }

  get displayName(): string {
    return this.name;
  }

  save(): void {
    // ...
  }
}
```

포함된 구성 요소는 다음과 같다.

- 프로퍼티 선언: `name`
- 생성자 선언: `constructor`
- 접근자 선언: `get displayName`
- 메서드 선언: `save`
- 매개변수 선언: `name`

인터페이스 안에는 구현이 아니라 멤버의 형태를 선언한다.

```ts
interface UserRepository {
  findById(id: number): User | null;
  readonly size: number;
}
```

- 메서드 시그니처: `findById`
- 읽기 전용 프로퍼티 시그니처: `size`

### 모듈 관련 선언

```ts
import { useMemo } from 'react';

export interface User {
  id: number;
}

export function findUser(): User {
  // ...
}
```

주요 구성 요소는 다음과 같다.

- `import` 선언
- `export` 선언 또는 수정자
- 네임스페이스 선언
- 외부 모듈 선언
- `declare`를 사용하는 앰비언트 선언

```ts
declare const API_URL: string;

declare module '*.xlsx' {
  const url: string;
  export default url;
}
```

현대 TypeScript에서는 일반적으로 `namespace`보다 ES 모듈의 `import`와 `export`를 사용한다.

## Java의 주요 선언

### 타입 선언

| 구성 요소 | 예 | 의미 |
|---|---|---|
| 클래스 | `class User {}` | 객체의 상태와 동작 정의 |
| 인터페이스 | `interface UserRepository {}` | 구현해야 할 계약 정의 |
| 열거형 | `enum Status {}` | 정해진 인스턴스 집합 정의 |
| 레코드 | `record User(...) {}` | 데이터 중심 클래스 정의 |
| 어노테이션 인터페이스 | `@interface Audited {}` | 어노테이션 타입 정의 |
| 타입 매개변수 | `<T>` | 제네릭 타입 변수 선언 |

```java
class User {
}

interface UserRepository {
}

enum Status {
    ACTIVE,
    INACTIVE
}

record UserSummary(long id, String name) {
}

@interface Audited {
}
```

Java 언어 명세는 일반 클래스, enum 클래스, record 클래스를 클래스 선언의 종류로 분류한다.

### 클래스 멤버 선언

```java
class UserService {
    private final UserRepository repository;

    UserService(UserRepository repository) {
        this.repository = repository;
    }

    User findById(long id) {
        return repository.findById(id);
    }

    static class Result {
    }
}
```

포함된 선언은 다음과 같다.

- 필드 선언: `repository`
- 생성자 선언: `UserService(...)`
- 메서드 선언: `findById(...)`
- 중첩 클래스 선언: `Result`
- 매개변수 선언: `repository`, `id`

Java에는 독립적인 함수 선언이 없다. 실행 가능한 이름 있는 동작은 클래스나 인터페이스의 메서드로 선언한다.

```java
long calculateTotal() {
    return 100L;
}
```

이 코드는 Java에서 함수 선언이 아니라 메서드 선언이라고 부른다.

TypeScript에서는 모듈 최상위에 독립적인 함수를 선언할 수 있다.

```ts
function calculateTotal(): number {
  return 100;
}
```

### 변수 선언

Java의 변수 선언은 위치와 역할에 따라 이름이 달라진다.

| 종류 | 예 |
|---|---|
| 필드 | `private int count;` |
| 지역 변수 | `int count = 0;` |
| 메서드 매개변수 | `void save(User user)` |
| 생성자 매개변수 | `User(String name)` |
| 예외 매개변수 | `catch (Exception exception)` |
| 람다 매개변수 | `user -> user.getName()` |
| 패턴 변수 | `value instanceof String text` |

```java
class Example {
    private int field;

    void execute(String parameter) {
        int localVariable = 1;

        try {
            // ...
        } catch (Exception exception) {
            // ...
        }
    }
}
```

### 초기화 구성 요소

```java
class Example {
    static {
        // 정적 초기화 블록
    }

    {
        // 인스턴스 초기화 블록
    }
}
```

이들은 클래스 본문 구성 요소지만 새로운 이름을 정의하지 않으므로 타입·변수 선언과 구분하여 초기화 블록이라고 부른다.

### 패키지와 모듈 선언

```java
package com.icar.finance.contract;

import java.time.LocalDate;
```

- 패키지 선언
- import 선언
- static import 선언

Java 모듈 시스템을 사용하면 모듈 선언도 작성할 수 있다.

```java
module com.icar.finance {
    requires java.sql;
    exports com.icar.finance.contract;
}
```

관련 구성 요소는 다음과 같다.

- 모듈 선언
- `requires`
- `exports`
- `opens`
- `uses`
- `provides`

## 선언이 아닌 주요 언어 구성 요소

`if`, `for`, `new` 같은 것은 중요한 언어 구성 요소지만 선언은 아니다.

### 문장

문장은 동작이나 제어 흐름을 나타낸다.

```text
if
switch
for
while
do-while
return
break
continue
throw
try-catch-finally
synchronized
```

```java
if (contract.isCompleted()) {
    return;
}
```

- 전체 코드: `if` 문장
- `contract.isCompleted()`: 메서드 호출 표현식
- `return`: 반환 문장

### 표현식

표현식은 값을 계산한다.

```text
리터럴
변수 참조
함수·메서드 호출
객체 생성
산술 연산
비교 연산
논리 연산
할당
람다
조건 표현식
```

Java 객체 생성 코드를 나누면 다음과 같다.

```java
User user = new User();
```

- `User user`: 지역 변수 선언
- `new User()`: 클래스 인스턴스 생성 표현식
- 생성된 결과: `User` 객체

### 수정자

수정자는 선언의 접근 범위나 성질을 지정한다.

TypeScript의 주요 수정자:

```text
export
default
public
private
protected
readonly
abstract
static
declare
async
```

Java의 주요 수정자:

```text
public
protected
private
static
final
abstract
sealed
non-sealed
synchronized
native
strictfp
```

수정자는 일반적으로 독립적인 선언이 아니라 선언에 붙는 요소다.

```java
public final class User {
}
```

- `class User`: 클래스 선언
- `public`, `final`: 클래스 수정자

### 어노테이션과 데코레이터

Java:

```java
@Entity
class FinanceContractJpaEntity {
}
```

- `FinanceContractJpaEntity`: 클래스 선언
- `@Entity`: 어노테이션

TypeScript는 설정과 버전에 따라 데코레이터를 사용할 수 있다.

```ts
@injectable
class ContractService {
}
```

- `ContractService`: 클래스 선언
- `@injectable`: 데코레이터

## TypeScript와 Java의 대응 관계

| 개념 | TypeScript | Java |
|---|---|---|
| 객체 구조 계약 | `interface` | `interface` |
| 타입에 별칭 부여 | `type` | 직접 대응 없음 |
| 구현 타입 | `class` | `class` |
| 고정된 값 집합 | `enum` | `enum` |
| 데이터 중심 타입 | 객체 타입·클래스 | `record` |
| 독립 함수 | `function` | 일반적으로 없음 |
| 클래스 동작 | method | method |
| 불변 변수 | `const` | `final` 변수 |
| 모듈 사용 | `import`/`export` | `package`/`import`/`module` |
| 컴파일 전용 타입 | `interface`, `type` | 대부분 런타임 클래스 정보 존재 |
| 익명 동작 | 화살표 함수 | 람다식 |

## 클래스와 객체를 구분하기

클래스 선언 자체를 객체라고 부르지는 않는다.

TypeScript:

```ts
class User {
}

const user = new User();
```

- `User`: 클래스 선언이 만든 타입과 생성자
- `user`: `User`의 객체 또는 인스턴스

Java:

```java
class User {
}

User user = new User();
```

- `User`: 클래스 또는 타입
- `user`: `User` 클래스의 객체 또는 인스턴스
- `User.class`: `java.lang.Class<User>` 객체

Java enum도 타입 선언 자체와 열거형 상수를 구분한다.

```java
enum Status {
    ACTIVE,
    COMPLETED
}
```

- `Status`: enum 타입
- `Status.ACTIVE`: `Status` 타입의 객체

## 핵심 요약

```text
선언
→ 이름을 만든다.
→ class, interface, function, method, variable 등

문장
→ 동작과 흐름을 만든다.
→ if, for, return, try 등

표현식
→ 값을 만든다.
→ a + b, new User(), save(), x -> x.name 등

수정자·어노테이션
→ 선언의 성질을 설명한다.
→ public, private, readonly, @Entity 등
```

프로젝트 코드를 설명할 때는 다음과 같이 표현하는 편이 정확하다.

```text
부정확하거나 모호한 표현
→ 이 파일에는 어떤 객체들이 있는가?

더 정확한 표현
→ 이 파일에는 어떤 타입, 함수, 변수와 클래스 멤버가 선언되어 있는가?
```

## 참고 자료

- [TypeScript 선언 구조](https://www.typescriptlang.org/docs/handbook/declaration-files/deep-dive.html)
- [TypeScript 모듈](https://www.typescriptlang.org/docs/handbook/modules/reference)
- [Java 언어 명세: 패키지와 모듈](https://docs.oracle.com/javase/specs/jls/se25/html/jls-7.html)
- [Java 언어 명세: 클래스](https://docs.oracle.com/javase/specs/jls/se25/html/jls-8.html)
