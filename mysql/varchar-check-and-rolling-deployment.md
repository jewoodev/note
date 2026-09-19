# `VARCHAR + CHECK`와 ECS Rolling Deployment의 스키마 호환성

## 문서 목적

이 문서는 상태값을 MySQL `ENUM` 대신 `VARCHAR + CHECK`로 저장할 때 얻는 장점과 한계를
정리한다. 특히 Amazon ECS rolling deployment에서 구버전과 신버전 애플리케이션이 동시에
실행되는 상황을 기준으로, 상태값을 안전하게 추가하거나 제거하는 방법을 설명한다.

핵심 결론은 다음과 같다.

- `VARCHAR + CHECK`가 rolling deployment의 호환성 문제를 자동으로 해결하지는 않는다.
- 장점은 문자열을 저장하는 컬럼 형식과 허용값 정책을 분리할 수 있다는 점이다.
- DB가 새 상태값을 허용하는 것과 모든 애플리케이션 인스턴스가 그 상태값을 이해하는 것은
  별개의 문제다.
- 상태값 변경은 스키마 변경 한 번으로 끝내지 않고 읽기 호환, 제약 확장, 쓰기 활성화 순서로
  배포해야 한다.

## ECS Rolling Deployment에서 발생하는 호환성 문제

ECS rolling deployment는 실행 중인 구버전 task를 한 번에 모두 종료하지 않는다. 설정된 최소
정상 task 수와 최대 task 수 범위 안에서 구버전 task를 신버전 task로 순차 교체한다.

따라서 배포 중에는 다음 상태가 일시적으로 존재할 수 있다.

```text
클라이언트 요청
    ├── 구버전 task
    └── 신버전 task
            │
            └── 동일한 운영 DB
```

신버전 task가 새로운 상태값을 저장한 뒤 구버전 task가 그 행을 조회하면, DB가 값을 정상적으로
반환하더라도 구버전 애플리케이션이 실패할 수 있다.

예를 들어 기존 코드가 다음 상태만 알고 있다고 가정한다.

```kotlin
enum class RentalContractStatus {
    UNSIGNED,
    ACTIVE,
    ENDED,
}
```

신버전이 `CANCELLED`를 DB에 저장하면 구버전의 enum 변환, 분기문 또는 역직렬화 코드가 이 값을
처리하지 못할 수 있다. 이 문제는 DB 컬럼이 `ENUM`인지 `VARCHAR`인지와 무관하다.

즉, rolling deployment에서 중요한 호환성 경계는 다음 두 가지다.

1. DB가 새 값을 저장할 수 있는가?
2. 동시에 실행 중인 모든 애플리케이션 버전이 새 값을 읽을 수 있는가?

두 조건을 모두 만족하기 전에는 새 값을 운영 데이터에 쓰면 안 된다.

## MySQL `ENUM`

`ENUM`은 허용값 목록을 컬럼 자료형에 포함한다.

```sql
CREATE TABLE rental_contracts (
    id BIGINT NOT NULL AUTO_INCREMENT,
    status ENUM('UNSIGNED', 'ACTIVE', 'ENDED') NOT NULL,
    CONSTRAINT pk_rental_contracts PRIMARY KEY (id)
);
```

`CANCELLED`를 추가하려면 컬럼 정의를 변경해야 한다.

```sql
ALTER TABLE rental_contracts
    MODIFY COLUMN status
        ENUM('UNSIGNED', 'ACTIVE', 'ENDED', 'CANCELLED') NOT NULL;
```

MySQL 8.4에서는 다음 조건을 만족하면 `ENUM` 목록 끝에 값을 추가하는 작업을 metadata-only로
처리할 수 있다.

- 새 값을 기존 목록의 끝에 추가한다.
- 값의 개수가 증가해도 내부 저장 크기가 변하지 않는다.

반면 목록 중간에 값을 넣거나 순서를 바꾸면 기존 값의 내부 번호가 달라질 수 있어 테이블 복사가
필요할 수 있다. 허용값, 내부 표현과 정렬 순서가 컬럼 자료형에 함께 결합된다는 점도 고려해야
한다.

따라서 `ENUM`이 항상 운영 변경에 위험하거나 느린 것은 아니다. 값이 거의 바뀌지 않고 순서도
고정된 작은 집합이라면 유효한 선택이다.

## `VARCHAR + CHECK`

`VARCHAR + CHECK`는 저장 형식과 허용값을 별도로 정의한다.

```sql
CREATE TABLE rental_contracts (
    id BIGINT NOT NULL AUTO_INCREMENT,
    status VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    CONSTRAINT pk_rental_contracts PRIMARY KEY (id),
    CONSTRAINT ck_rental_contracts_status CHECK (
        status IN ('UNSIGNED', 'ACTIVE', 'ENDED')
    )
);
```

새 상태를 허용할 때 `status VARCHAR(32)`는 바꾸지 않고 이름이 붙은 제약조건만 교체한다.

```sql
ALTER TABLE rental_contracts
    DROP CHECK ck_rental_contracts_status,
    ADD CONSTRAINT ck_rental_contracts_status CHECK (
        status IN ('UNSIGNED', 'ACTIVE', 'ENDED', 'CANCELLED')
    );
```

이 방식의 장점은 다음과 같다.

- 컬럼의 물리적 문자열 형식이 상태 목록 변경과 분리된다.
- 상태 정책이 이름이 붙은 제약조건으로 명확하게 드러난다.
- 허용값을 확장하거나 축소할 때 컬럼 정의 전체를 다시 선언하지 않는다.
- MySQL `ENUM`의 내부 번호와 선언 순서에 의존하지 않는다.
- 애플리케이션 enum 이름과 DB 문자열을 같은 값으로 유지하기 쉽다.
- 이미 `VARCHAR + CHECK`를 사용하는 다른 테이블과 DDL 규칙을 통일할 수 있다.

MySQL은 `CHECK` 제약조건을 추가·삭제하고 `ENFORCED` 또는 `NOT ENFORCED`로 변경할 수 있다.
다만 운영에서 제약조건을 일시적으로 비활성화하는 것을 기본 전략으로 삼아서는 안 된다. 허용되지
않은 값이 들어갈 수 있는 기간과 복구 책임이 생기기 때문이다.

## 안전한 상태값 추가 순서

새 상태 `CANCELLED`를 추가할 때는 다음과 같이 두 번 이상의 애플리케이션 배포와 스키마 확장을
분리한다.

### 1. 읽기 호환 애플리케이션 배포

애플리케이션이 `CANCELLED`를 읽고 처리할 수 있도록 먼저 변경한다. 이 버전에서는 아직
`CANCELLED`를 생성하지 않는다.

```kotlin
enum class RentalContractStatus {
    UNSIGNED,
    ACTIVE,
    ENDED,
    CANCELLED,
}
```

모든 구버전 task가 종료되고 읽기 호환 버전만 실행 중인지 확인한다.

### 2. DB 허용값 확장

이름이 붙은 `CHECK` 제약조건에 `CANCELLED`를 추가한다. 기존 행이 변경된 제약조건을 모두
만족하는지 확인한다.

DB 변경에는 metadata lock이나 기존 데이터 검증이 발생할 수 있으므로, 실제 운영 데이터 규모와
같은 조건에서 실행 계획과 소요 시간을 미리 검증한다.

### 3. 새 상태 쓰기 활성화

새 상태를 생성하는 API, 배치 또는 기능을 배포하거나 feature flag로 활성화한다. 이 시점에는 DB와
모든 실행 중인 task가 `CANCELLED`를 이해한다.

### 4. Rollback 경계 기록

`CANCELLED` 데이터가 한 건이라도 생성된 뒤에는 이 값을 모르는 애플리케이션 버전으로 바로
rollback할 수 없다. 배포 기록에 최소 호환 애플리케이션 버전을 남기고, rollback 절차도 해당
버전 이후로 제한한다.

```text
읽기 호환 코드 배포
    → 구버전 task 종료 확인
    → DB 제약조건 확장
    → 새 값 쓰기 활성화
    → 최소 rollback 버전 기록
```

## 안전한 상태값 제거 순서

상태값 제거는 추가보다 더 신중해야 한다.

1. 애플리케이션이 제거 대상 상태를 더 이상 생성하지 않도록 한다.
2. 기존 행을 대체 상태로 전환할 정책을 확정한다.
3. 대상 행 수와 전환 결과를 검증한다.
4. 제거 대상 값이 DB에 0건인지 확인한다.
5. `CHECK` 제약조건에서 값을 제거한다.
6. 충분한 호환 기간이 지난 뒤 애플리케이션의 읽기 지원을 제거한다.

기존 행을 어떻게 변환할지 문서화되지 않았다면 값을 임의로 바꾸거나 제약조건에서 제거하지
않는다.

## `VARCHAR + CHECK`의 한계

`VARCHAR + CHECK`에도 다음 비용과 한계가 있다.

- `ENUM`보다 값 저장 공간을 더 사용할 수 있다.
- 제약조건 변경에도 metadata lock과 데이터 검증이 발생할 수 있다.
- `CHECK`를 비활성화하면 잘못된 문자열이 저장될 수 있다.
- 애플리케이션이 모르는 새 값을 읽는 문제는 해결하지 못한다.
- 상태 전이 규칙은 단순한 허용값 목록만으로 보호할 수 없다.

예를 들어 `UNSIGNED`에서 `ACTIVE`로의 전환 조건이나 취소 시각 필수 규칙은 domain 로직, DB의
추가 제약조건과 integration test로 별도 보호해야 한다.

## 선택 기준

다음 조건에서는 `VARCHAR + CHECK`가 적합하다.

- 상태값이 업무 정책에 따라 앞으로 추가되거나 정리될 가능성이 있다.
- rolling deployment 중 구버전과 신버전의 호환성을 명시적으로 관리한다.
- 컬럼 자료형과 허용값 정책을 분리하고 싶다.
- 프로젝트의 기존 DDL이 `VARCHAR + CHECK` 규칙을 사용한다.

다음 조건에서는 `ENUM`도 적합할 수 있다.

- 값의 집합과 순서가 사실상 고정돼 있다.
- MySQL에 종속되는 스키마 표현을 허용한다.
- 값 추가는 항상 목록 끝에서 이루어지고 내부 저장 크기 변화를 관리할 수 있다.
- 동일한 방식이 프로젝트 전반의 일관된 표준이다.

ICar ERP 통합 스키마에서는 기존 대상 테이블의 규칙과 앞으로의 상태 확장 가능성을 고려해
`VARCHAR + CHECK`를 기본 방식으로 사용한다. 단, 실제 무중단 호환성은 자료형 선택이 아니라
읽기 호환 코드, DB 제약 확장과 새 값 쓰기 활성화를 분리하는 배포 절차로 보장한다.

## 운영 점검 목록

- 새 상태값을 모든 실행 버전이 읽을 수 있는가?
- 새 상태값을 예상보다 먼저 생성하는 코드나 배치가 없는가?
- 기존 행이 새 `CHECK` 조건을 모두 만족하는가?
- DDL의 algorithm, metadata lock과 실행 시간을 사전 검증했는가?
- ECS에서 구버전 task가 모두 종료됐는가?
- 새 값 생성 이후 돌아갈 수 있는 최소 rollback 버전을 기록했는가?
- 상태값을 제거할 때 기존 데이터 전환 정책과 검증 쿼리가 있는가?
- schema migration을 기존 운영 DB와 빈 DB 양쪽에서 검증했는가?

## 참고 자료

- [MySQL 8.4 `ALTER TABLE`](https://dev.mysql.com/doc/refman/8.4/en/alter-table.html)
- [MySQL 8.4 `CHECK` Constraints](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html)
- [MySQL 8.4 `ENUM` Type](https://dev.mysql.com/doc/refman/8.4/en/enum.html)
- [Amazon ECS rolling deployment](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html)
