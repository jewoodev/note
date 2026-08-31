# `vehicles` 문자열 컬럼의 문자셋과 Collation

## 문서 목적

이 문서는 렌트카 ERP 데이터베이스의 Flyway `V18__add_vehicle_catalog_and_vehicles.sql`에 있는 
`vehicles` 테이블에 명시한 문자셋과 collation의 선택 이유를 기록한다.

문자셋은 컬럼에 저장할 수 있는 문자의 범위를 결정하고, collation은 문자열의 동등성 비교와
정렬 방식을 결정한다. 따라서 collation은 단순한 표시 설정이 아니라 `UNIQUE`, `CHECK`, 검색과
외래 키의 동작에도 영향을 준다.

현재 `vehicles` 테이블은 문자열의 성격에 따라 다음 세 조합을 사용한다.

| 문자셋과 collation               | 적용 대상 | 목적 |
|----------------------------------| --- | --- |
| `utf8mb4` / `utf8mb4_0900_as_ci` | 이름, 차량번호, 색상, 메모 등 | 한글을 포함한 일반 문자열 저장과 비교 |
| `ascii` / `ascii_bin`            | enum-style 코드 | ASCII만 허용하고 대소문자를 엄격하게 구분 |
| `ascii` / `ascii_generalv_ci`    | VIN | ASCII로 저장하되 대소문자만 다른 VIN을 동일하게 비교 |

## 일반 문자열: `utf8mb4_0900_as_ci`

다음 컬럼에 적용한다.

- `name`
- `registration_number`
- `engine_displacement_class`
- `exterior_color`
- `spare_key_info`
- `vehicle_memo`
- `parking_location`

구성 요소의 의미는 다음과 같다.

- `utf8mb4`: 한글을 포함한 전체 유니코드를 지원한다.
- `0900`: Unicode Collation Algorithm 9.0을 기반으로 한다.
- `as`: accent-sensitive를 의미한다. 예를 들어 `a`와 `á`를 다르게 비교한다.
- `ci`: case-insensitive를 의미한다. 예를 들어 `A`와 `a`를 같게 비교한다.

한글 이름과 원문 문자열을 손실 없이 저장하면서 일반적인 검색과 정렬을 지원하기 위한
선택이다. `VARCHAR`뿐 아니라 자유 입력 원문인 `vehicle_memo`의 `TEXT`에도 같은 문자셋과
collation을 사용한다.

### 차량번호 UNIQUE에 미치는 영향

`registration_number`에는 다음 UNIQUE 제약이 있다.

```sql
CONSTRAINT uk_vehicles_registration_number UNIQUE (registration_number)
```

차량번호는 주로 숫자와 한글로 구성되므로 대소문자 구분의 영향은 사실상 없다. 이 제약은
동일한 차량번호가 두 차량 행에 저장되는 것을 방지한다.

## Enum-style 코드: `ascii_bin`

다음 컬럼에 적용한다.

- `origin_type`
- `rental_company_type`
- `fuel_type`
- `rental_operation_status`
- `registration_status`

이 컬럼들은 사용자 표시 문자열이나 확장 가능한 기준정보 코드가 아니라 애플리케이션이 알고
있는 제한된 값 집합을 저장한다.

`ascii`는 영문, 숫자 등 ASCII 문자만 허용한다. `ascii_bin`은 바이트 단위로 비교하므로
대소문자를 구분한다.

```text
DOMESTIC != domestic
AVAILABLE != available
```

이 특성 때문에 다음 CHECK 제약은 소문자나 혼합 표기를 허용하지 않는다.

```sql
origin_type IN ('DOMESTIC', 'IMPORTED')

fuel_type IN (
    'GASOLINE',
    'DIESEL',
    'LPG',
    'ELECTRIC',
    'HYBRID'
)

rental_operation_status IN (
    'PENDING_REGISTRATION',
    'AVAILABLE',
    'AWAITING_DISPATCH',
    'ON_RENT',
    'IN_REPAIR'
)

registration_status IN ('REGISTERED', 'PENDING', 'UNKNOWN')
```

MySQL `ENUM` 대신 `VARCHAR + CHECK`를 사용하므로, 새로운 값을 추가할 때 기존 컬럼 타입을
재정의하지 않고 CHECK 허용 범위를 먼저 확장하는 방식으로 배포할 수 있다.

### 회사 유형 외래 키에 미치는 영향

`rental_company_type`은 항상 `RENTAL_OPERATOR`이며, `rental_company_id`와 함께
`companies(id, company_type)`을 참조한다.

```sql
FOREIGN KEY (rental_company_id, rental_company_type)
    REFERENCES companies (id, company_type)
```

외래 키 양쪽의 회사 유형 컬럼이 동일한 `ascii` / `ascii_bin` 정의를 사용하므로 데이터 타입과
비교 규칙이 일치한다. 이를 통해 참조한 회사가 존재하는지만 확인하는 것이 아니라 실제 회사
유형도 `RENTAL_OPERATOR`인지 DB가 검증한다.

## VIN: `ascii_general_ci`

`vin`에는 `ascii` / `ascii_general_ci`를 사용한다.

VIN은 영문과 숫자로 구성되므로 `ascii`로 표현할 수 있다. `ascii_general_ci`는 대소문자를
구분하지 않으므로 다음 두 값은 문자열 비교에서 동일하다.

```text
KMH1234567890 = kmh1234567890
```

`vin`에는 다음 UNIQUE 제약이 있다.

```sql
CONSTRAINT uk_vehicles_vin UNIQUE (vin)
```

따라서 대소문자만 다른 VIN을 별도 차량으로 중복 등록할 수 없다. 이 설계는 원본 VIN의 표기를
강제로 대문자로 변경하지 않으면서 논리적인 중복을 방지한다.

`vin`은 `NULL`을 허용한다. MySQL UNIQUE는 여러 `NULL`을 허용하므로 VIN이 아직 확인되지 않은
차량을 여러 건 저장할 수 있다.

## Collation이 적용되지 않는 컬럼

다음 타입은 문자열 비교가 필요하지 않으므로 collation을 사용하지 않는다.

- `BIGINT`, `INT`, `SMALLINT`
- `BOOLEAN`
- `DATE`
- `DATETIME`
- 외래 키 ID

## 설계 요약

- 한글과 자유 입력 문자열은 `utf8mb4_0900_as_ci`를 사용한다.
- 대문자 enum-style 코드는 `ascii_bin`으로 대소문자를 엄격히 구분한다.
- VIN은 원문을 보존하되 대소문자만 다른 중복을 막기 위해 `ascii_general_ci`를 사용한다.
- collation은 UNIQUE, CHECK와 외래 키 비교에 영향을 주므로 컬럼의 업무 의미에 맞춰 명시한다.
