# Kotlin non-null 인수와 Mockito matcher

## 문제

Java Mockito의 matcher를 Kotlin 코드에서 직접 사용하면 Kotlin의 non-null 인수와 충돌할 수 있다.

```kotlin
org.mockito.Mockito.doReturn(result)
    .`when`(provider)
    .register(org.mockito.ArgumentMatchers.any())
```

`ArgumentMatchers.any()`는 stubbing이나 verification에 사용할 실제 값을 만드는 함수가 아니다. Mockito 내부에 matcher를 등록하고 호출 자리에 전달할 임시 값으로 `null`을 반환한다. Java에서는 이 동작이 자연스럽지만, Kotlin에서 반환값을 non-null 인수에 전달하면 Kotlin이 삽입한 null 검사 때문에 Mockito가 호출을 가로채기 전에 예외가 발생할 수 있다.

이 문제는 mock 대상 메서드의 반환값이나 비즈니스 로직과 무관하다. 테스트 준비 코드에서 Java와 Kotlin의 null 계약이 맞지 않아 발생하는 상호 운용성 문제다.

## 잘못된 우회 방식

다음과 같은 helper를 테스트마다 만드는 방식은 피한다.

```kotlin
@Suppress("UNCHECKED_CAST")
private fun <T> anyValue(): T {
    org.mockito.ArgumentMatchers.any<T>()
    return null as T
}
```

이 helper는 Java Mockito가 사용하는 `null` 임시 값을 unchecked cast로 감출 뿐이다.

- 테스트마다 구현이 중복된다.
- matcher가 등록되는 과정과 반환값이 분리되어 코드를 이해하기 어렵다.
- `null as T`와 경고 억제가 정상적인 테스트 관례처럼 퍼진다.
- 타입과 호출 문맥이 바뀌면 런타임 예외가 다시 발생할 수 있다.
- 팀에서 사용하는 Mockito API가 Java 방식과 Kotlin 방식으로 섞인다.

문제를 우회하는 로컬 helper보다 Kotlin용으로 설계된 Mockito-Kotlin API를 사용한다.

## 해결 방법

테스트 의존성에 Mockito-Kotlin을 추가한다.

```kotlin
testImplementation("org.mockito.kotlin:mockito-kotlin:5.4.0")
```

그리고 matcher를 `org.mockito.kotlin`에서 가져온다.

```kotlin
import org.mockito.kotlin.any
import org.mockito.kotlin.whenever

whenever(provider.register(any())).thenReturn(result)
```

`org.mockito.kotlin.any()`는 Java Mockito matcher를 Kotlin의 타입 체계에서 사용할 수 있게 감싼 API다. 테스트 코드가 Java 메서드의 nullable한 임시 반환값을 직접 다루지 않게 해 준다.

stubbing과 verification도 Mockito-Kotlin API로 통일한다.

```kotlin
import org.mockito.kotlin.any
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

whenever(provider.register(any())).thenReturn(result)

verify(provider).register(any())
```

## `any()`를 사용할지 판단하는 기준

Kotlin용 `any()`가 안전하다는 것과 모든 인수를 `any()`로 검증하는 것이 좋은 테스트라는 것은 별개의 문제다.

테스트가 해당 인수의 값에 관심이 없다면 `any()`가 적절하다. 예를 들어 인증 통합 테스트의 목적이 다음과 같다면 등록 Command의 세부 필드를 다시 검증할 필요가 없다.

- 인증되지 않은 요청이 401인지
- 읽기 권한만 가진 사용자의 등록 요청이 403인지
- 관리 권한과 CSRF 토큰을 가진 요청이 애플리케이션 포트까지 도달하는지
- 성공·실패 요청에 request ID와 감사 로그가 남는지

이 경우 다음 stubbing은 테스트 책임을 보안 경계로 제한한다.

```kotlin
whenever(registerMaintenance.register(any())).thenReturn(summary)
```

반대로 Controller 테스트가 JSON 요청을 Command로 정확히 변환하는지 검증해야 한다면 `any()`만 사용해서는 부족하다. `argThat()`이나 `argumentCaptor()`로 전달값을 확인한다.

```kotlin
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

whenever(registerMaintenance.register(any())).thenReturn(summary)

// HTTP 요청 수행

val commandCaptor = argumentCaptor<RegisterMaintenanceCommand>()
verify(registerMaintenance).register(commandCaptor.capture())

with(commandCaptor.firstValue) {
    assertThat(vehicleId).isEqualTo(1)
    assertThat(registeredByName).isEqualTo("운영자")
    assertThat(items).singleElement().satisfies { item ->
        assertThat(item.itemName).isEqualTo("엔진오일")
    }
}
```

고정된 인수에 값 동등성이 정의되어 있다면 matcher 없이 실제 값을 전달하거나 `eq()`를 사용할 수 있다.

```kotlin
import org.mockito.kotlin.eq
import org.mockito.kotlin.verify

verify(queryProvider).getMaintenanceRecords(eq(1L), eq(0), eq(20))
```

단, 모든 인수가 고정값이라면 다음처럼 실제 값으로 검증하는 편이 더 단순하다.

```kotlin
verify(queryProvider).getMaintenanceRecords(1, 0, 20)
```

## ArgumentCaptor에도 같은 원칙 적용

Java Mockito의 `ArgumentCaptor.capture()` 역시 matcher처럼 호출 자리에 `null` 임시 값을 반환할 수 있다. Kotlin non-null 인수에는 Java captor를 직접 전달하지 않고 Mockito-Kotlin의 `argumentCaptor()`를 사용한다.

```kotlin
val captor = argumentCaptor<RegisterMaintenanceCommand>()
verify(provider).register(captor.capture())
```

## 의존성 버전에서 배운 점

라이브러리의 최신 버전이 현재 프로젝트에 항상 적합한 것은 아니다.

이 프로젝트에서 Mockito-Kotlin 6.3.0을 먼저 적용했을 때 다음 컴파일 오류가 발생했다.

```text
Module was compiled with an incompatible version of Kotlin.
The binary version of its metadata is 2.1.0, expected version is 1.9.0.
```

프로젝트는 Kotlin 1.9.25를 사용하지만 Mockito-Kotlin 6.3.0은 Kotlin 메타데이터 2.1로 빌드되어 있었다. 따라서 Kotlin 1.9와 호환되는 Mockito-Kotlin 5.4.0을 선택했다.

테스트 보조 라이브러리를 추가할 때도 다음을 함께 확인해야 한다.

- 프로젝트 Kotlin 컴파일러 버전
- 라이브러리가 사용한 Kotlin 메타데이터 버전
- JVM target
- 기존 Mockito 버전과 Spring Boot dependency management의 영향
- 의존성 추가 후 전체 테스트 소스의 컴파일 여부

## 프로젝트 규칙

- Kotlin 테스트의 Mockito stubbing과 verification에는 `org.mockito.kotlin` API를 사용한다.
- Kotlin non-null 인수에 Java Mockito의 `Mockito.any()`나 `ArgumentMatchers.any()`를 직접 전달하지 않는다.
- Java `ArgumentCaptor.capture()`를 Kotlin non-null 인수에 직접 전달하지 않는다.
- matcher가 필요하면 Mockito-Kotlin의 `any()`, `eq()`, `argThat()`을 사용한다.
- 인수 캡처가 필요하면 Mockito-Kotlin의 `argumentCaptor()`를 사용한다.
- `null as T`를 반환하는 `anyValue()` 같은 테스트별 우회 helper를 만들지 않는다.
- 고정된 입력은 가능한 한 실제 값으로 검증한다.
- `any()`는 테스트가 의도적으로 해당 값에 관심이 없을 때 사용한다.

## 리뷰 체크리스트

- Java Mockito matcher가 Kotlin non-null 인수에 직접 전달되고 있지 않은가?
- `null as T` 또는 `UNCHECKED_CAST`로 matcher 문제를 감추고 있지 않은가?
- `any()` 때문에 중요한 요청 매핑이나 Command 필드 검증이 빠지지 않았는가?
- 테스트 이름과 matcher의 범위가 같은 책임을 표현하는가?
- Controller 매핑 검증과 인증·권한 검증이 서로 다른 테스트에 분리되어 있는가?
- Mockito-Kotlin 버전이 프로젝트 Kotlin 버전과 실제로 호환되는가?

핵심은 null 예외를 없애는 데서 끝나지 않는다. Kotlin에 맞는 API를 선택하고, `any()`가 감추는 범위를 테스트 책임에 맞게 제한해야 한다.
