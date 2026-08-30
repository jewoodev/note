# Kotlin `Set`의 `+`와 `-`

## 예제

다음 코드는 사용자의 역할을 부여하거나 회수한다.

```kotlin
fun grantRole(role: AppRole): AppUser =
    copy(roles = roles + role)

fun revokeRole(role: AppRole): AppUser =
    copy(roles = roles - role)
```

여기서 `+`와 `-`는 숫자 계산이 아니라 컬렉션 연산자로 사용된다.

## `roles + role`

```kotlin
roles + role
```

위 표현은 다음 함수 호출 형태로 이해할 수 있다.

```kotlin
roles.plus(role)
```

원본 `roles`를 직접 변경하지 않고, `role`을 포함한 새로운 `Set`을 반환한다.

```kotlin
val original = setOf(AppRole.MANAGEMENT_SUPPORT)
val granted = original + AppRole.SYSTEM_ADMIN

// original: [MANAGEMENT_SUPPORT]
// granted:  [MANAGEMENT_SUPPORT, SYSTEM_ADMIN]
```

`Set`은 같은 값을 중복해서 보관하지 않는다. 따라서 이미 들어 있는 역할을 다시
더해도 결과에는 하나만 남는다.

```kotlin
val roles = setOf(AppRole.MANAGEMENT_SUPPORT)
val result = roles + AppRole.MANAGEMENT_SUPPORT

// result: [MANAGEMENT_SUPPORT]
```

이 성질 덕분에 역할 부여를 여러 번 요청해도 역할이 중복되지 않는다.

## `roles - role`

```kotlin
roles - role
```

위 표현은 다음 함수 호출 형태로 이해할 수 있다.

```kotlin
roles.minus(role)
```

원본 `roles`를 직접 변경하지 않고, `role`을 제외한 새로운 `Set`을 반환한다.

```kotlin
val original = setOf(
    AppRole.MANAGEMENT_SUPPORT,
    AppRole.SYSTEM_ADMIN,
)
val revoked = original - AppRole.SYSTEM_ADMIN

// original: [MANAGEMENT_SUPPORT, SYSTEM_ADMIN]
// revoked:  [MANAGEMENT_SUPPORT]
```

존재하지 않는 원소를 빼더라도 오류가 발생하지 않는다. 결과의 내용이 원본과 같을
뿐이다.

```kotlin
val roles = setOf(AppRole.MANAGEMENT_SUPPORT)
val result = roles - AppRole.SYSTEM_ADMIN

// result: [MANAGEMENT_SUPPORT]
```

## `MutableSet.add()`·`remove()`와의 차이

`MutableSet`의 `add()`와 `remove()`는 기존 컬렉션을 직접 변경한다.

```kotlin
val roles = mutableSetOf(AppRole.MANAGEMENT_SUPPORT)

roles.add(AppRole.SYSTEM_ADMIN)
roles.remove(AppRole.MANAGEMENT_SUPPORT)

// roles 자체의 내용이 바뀐다.
```

반면 읽기 전용 `Set`에서 사용하는 `+`와 `-`는 연산 결과를 새로운 값으로 돌려준다.

```kotlin
val roles: Set<AppRole> = setOf(AppRole.MANAGEMENT_SUPPORT)

val granted = roles + AppRole.SYSTEM_ADMIN
val revoked = roles - AppRole.MANAGEMENT_SUPPORT

// roles는 그대로이고 granted와 revoked가 별도로 만들어진다.
```

| 표현 | 기존 컬렉션 변경 | 반환 결과 |
| --- | --- | --- |
| `set + element` | 하지 않음 | 원소를 포함한 `Set` |
| `set - element` | 하지 않음 | 원소를 제외한 `Set` |
| `mutableSet.add(element)` | 변경함 | 실제 추가 여부를 나타내는 `Boolean` |
| `mutableSet.remove(element)` | 변경함 | 실제 제거 여부를 나타내는 `Boolean` |

## `AppUser`에서 새 객체가 만들어지는 과정

`roles + role`만으로 `AppUser`가 바뀌는 것은 아니다. 컬렉션 연산 결과를
`copy(...)`에 전달해 새로운 `AppUser`를 만든다.

```kotlin
fun grantRole(role: AppRole): AppUser =
    copy(roles = roles + role)
```

이 코드는 다음 순서로 동작한다.

1. 현재 `roles`와 부여할 `role`을 이용해 새로운 `Set`을 만든다.
2. 새로운 `Set`을 `copy(roles = ...)`에 전달한다.
3. `copy(...)`가 변경된 역할을 가진 새로운 `AppUser`를 반환한다.
4. 기존 `AppUser`와 기존 `roles`는 그대로 남는다.

이 프로젝트의 `AppUser`는 `data class`가 아니다. 클래스 내부에 정의된 비공개
`copy(...)` 함수가 새로운 인스턴스를 생성한다.

```kotlin
private fun copy(
    passwordHash: PasswordHash = this.passwordHash,
    accountStatus: AccountStatus = this.accountStatus,
    passwordChangeRequired: Boolean = this.passwordChangeRequired,
    roles: Set<AppRole> = this.roles,
): AppUser =
    AppUser(
        id,
        email,
        passwordHash,
        accountStatus,
        passwordChangeRequired,
        roles.toSet(),
    )
```

따라서 역할 부여와 회수는 기존 객체를 수정하는 명령이라기보다, 변경된 상태를 가진
새 객체로 전이하는 함수로 이해하는 편이 알맞다.

## `Set`과 `toSet()`을 함께 사용하는 이유

프로퍼티 타입이 `Set<AppRole>`이면 `AppUser`를 사용하는 쪽에서는 `add()`나
`remove()`를 호출할 수 없다.

```kotlin
val roles: Set<AppRole>
```

하지만 Kotlin의 `Set`은 읽기 전용 인터페이스이지, 전달받은 실제 객체가 절대로
변경되지 않는다는 뜻까지 보장하지는 않는다. 외부에서 만든 `MutableSet`을 `Set`
타입으로 전달할 수도 있기 때문이다.

```kotlin
val external = mutableSetOf(AppRole.MANAGEMENT_SUPPORT)
val readOnlyView: Set<AppRole> = external

external.add(AppRole.SYSTEM_ADMIN)

// readOnlyView에서도 SYSTEM_ADMIN이 보인다.
```

생성 시점에 `roles.toSet()`을 호출하면 전달받은 컬렉션의 현재 내용을 독립된
`Set`으로 보관할 수 있다. 외부의 가변 컬렉션이 나중에 바뀌면서 `AppUser`의 역할도
몰래 바뀌는 상황을 막는 방어적 복사 역할을 한다.

## 이 설계가 주는 효과

- 역할 컬렉션을 객체 외부에서 직접 수정할 수 없다.
- 역할 변경 경로가 `grantRole()`과 `revokeRole()`로 드러난다.
- 같은 역할을 여러 번 부여해도 중복되지 않는다.
- 없는 역할을 회수해도 안전하게 같은 상태가 유지된다.
- 기존 객체를 변경하지 않아 상태 변화 전후를 구분하기 쉽다.
- 테스트에서 역할 변경 결과를 독립된 반환값으로 검증하기 쉽다.

역할처럼 원소 수가 작고 상태 변경이 빈번하지 않은 컬렉션에는 이 방식이 간결하고
안전하다. 반대로 매우 큰 컬렉션을 반복해서 변경하는 성능 민감 구간에서는 매번 새
컬렉션을 만드는 비용을 고려해 `MutableSet`을 제한된 범위에서 사용하는 설계를 따로
검토할 수 있다.

## 요약

```kotlin
roles + role
```

은 “현재 역할 집합에 역할을 직접 추가한다”가 아니라 “해당 역할을 포함한 새 역할
집합을 만든다”는 뜻이다.

```kotlin
roles - role
```

은 “현재 역할 집합에서 역할을 직접 삭제한다”가 아니라 “해당 역할을 제외한 새 역할
집합을 만든다”는 뜻이다.

`AppUser`는 이 결과를 `copy(...)`에 전달해 변경된 상태를 가진 새 객체를 만든다.
