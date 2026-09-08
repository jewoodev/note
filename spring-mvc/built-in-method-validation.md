# Spring MVC 내장 메서드 검증과 `@Validated`

## 배경

Controller의 경로 변수나 쿼리 매개변수를 검증하기 위해 클래스 수준에 `@Validated`를 붙이는 패턴이 널리 사용되어 왔다.

```kotlin
@Validated
@RestController
class MaintenanceController {
    @GetMapping("/vehicles/{vehicleId}/maintenance-records")
    fun getMaintenanceRecords(
        @PathVariable @Positive vehicleId: Long,
        @RequestParam @Min(0) page: Int,
        @RequestParam @Min(1) @Max(100) size: Int,
    ) = TODO()
}
```

이 패턴은 Bean Validation의 메서드 검증을 Spring AOP 프록시로 적용한다. 하지만 Spring Framework 6.1부터 Spring MVC가 `@RequestMapping` 메서드에 대한 내장 검증을 지원한다. 내장 검증을 사용하려면 오히려 Controller의 클래스 수준 `@Validated`를 제거해야 한다.

Spring 공식 문서: [Spring MVC Validation](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-validation.html)

## 두 가지 Controller 검증

Spring MVC Controller의 검증은 크게 요청 객체 검증과 메서드 검증으로 나뉜다.

### 요청 객체 검증

`@RequestBody`, `@ModelAttribute`, `@RequestPart` 객체에 `@Valid`를 선언하면 객체 내부의 필드 제약을 검증한다.

```kotlin
@PostMapping("/maintenance-records")
fun registerMaintenance(
    @Valid @RequestBody request: RegisterMaintenanceRequest,
) = TODO()

data class RegisterMaintenanceRequest(
    @field:NotNull @field:Positive
    val vehicleId: Long?,

    @field:NotBlank
    val registeredByName: String?,
)
```

이 경로에서 일반적으로 발생하는 예외는 `MethodArgumentNotValidException`이다.

`@Valid`는 그 자체로 제약조건이 아니다. 객체 안의 제약을 연쇄적으로 검사하도록 지시하는 애노테이션이다.

### 메서드 검증

`@PathVariable`, `@RequestParam` 같은 메서드 인수에 `@Positive`, `@Min`, `@Max`, `@NotBlank` 등의 제약을 직접 선언하면 Spring MVC가 메서드 전체를 검증한다.

```kotlin
@GetMapping("/vehicles/{vehicleId}/maintenance-records")
fun getMaintenanceRecords(
    @PathVariable @Positive vehicleId: Long,
    @RequestParam(defaultValue = "0") @Min(0) page: Int,
    @RequestParam(defaultValue = "20") @Min(1) @Max(100) size: Int,
) = TODO()
```

Spring MVC 내장 메서드 검증에서 발생하는 예외는 `HandlerMethodValidationException`이다. Controller 메서드는 모든 인수가 유효할 때만 호출된다.

## 클래스 수준 `@Validated`가 만드는 차이

Controller에 클래스 수준 `@Validated`가 있으면 Spring MVC 내장 검증 대신 AOP 기반 메서드 검증이 적용된다.

| 구분 | 클래스 수준 `@Validated` 사용 | Spring MVC 내장 검증 |
|---|---|---|
| 적용 방식 | AOP 프록시 | MVC 요청 처리 과정 |
| Controller 애노테이션 | 필요 | 제거 |
| 직접 인수 제약 예외 | `ConstraintViolationException` | `HandlerMethodValidationException` |
| 오류 위치 정보 | Bean Validation property path | MVC `MethodParameter` 기반 결과 |
| MVC 요청 정보 활용 | 제한적 | Controller 인수 단위로 구조화됨 |

MVC 내장 검증은 요청 매개변수 이름과 오류를 `ParameterValidationResult`로 제공한다. 이를 이용하면 `page`, `size`, `vehicleId`처럼 API 사용자가 이해할 수 있는 필드 이름으로 오류 응답을 만들기 쉽다.

Kotlin 프로젝트에서는 컴파일 시 Java parameter metadata가 보존되어야 안정적으로 매개변수 이름을 얻을 수 있다.

```kotlin
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        javaParameters = true
    }
}
```

## 예외 처리 설계

공통 API 예외 처리기는 요청 객체 검증과 메서드 검증을 구분해 처리한다.

```kotlin
@ExceptionHandler(MethodArgumentNotValidException::class)
fun handleBodyValidation(exception: MethodArgumentNotValidException) {
    // request body의 fieldErrors 변환
}

@ExceptionHandler(HandlerMethodValidationException::class)
fun handleMethodValidation(exception: HandlerMethodValidationException) {
    // path variable과 request parameter 오류 변환
}
```

전환 기간이 있거나 Controller 이외 계층에서 AOP 메서드 검증을 사용한다면 `ConstraintViolationException` 처리도 유지할 수 있다. 다만 어떤 검증 경로가 이 예외를 발생시키는지 분명해야 한다. 사용처가 사라진 뒤에는 관성적으로 handler를 남기지 말고 실제 발생 경로를 다시 점검한다.

Spring 공식 문서는 Controller 메서드 형태에 따라 `MethodArgumentNotValidException`과 `HandlerMethodValidationException`이 모두 발생할 수 있으므로 양쪽을 처리하라고 권장한다.

## `@Validated`를 유지해야 하는 곳

Controller에서 불필요해졌다고 해서 프로젝트 전체에서 `@Validated`를 제거하면 안 된다. 애노테이션의 역할은 적용 대상에 따라 다르다.

### `@ConfigurationProperties` 검증

설정값 바인딩 클래스의 `@Validated`는 Spring MVC와 무관하다.

```kotlin
@Validated
@ConfigurationProperties("application.security")
data class SessionSecurityProperties(
    @field:NotEmpty
    val allowedOrigins: List<String>,
)
```

이 애노테이션은 애플리케이션 시작 시 외부 설정값을 Bean Validation으로 검사한다. 제거하면 잘못된 보안 설정이 시작 단계에서 거부되지 않고 실행 중에 문제를 일으킬 수 있다.

중첩 설정 객체까지 검사하려면 해당 필드에 `@Valid`가 필요하다. Spring Boot 공식 문서: [Configuration Properties Validation](https://docs.spring.io/spring-boot/reference/features/external-config.html#features.external-config.typesafe-configuration-properties.validation)

### 일반 Spring Bean의 메서드 검증

Service 같은 일반 Spring Bean에서 메서드 인수나 반환값을 검증하려면 AOP 기반 메서드 검증과 `@Validated`가 여전히 필요할 수 있다. Spring MVC와 WebFlux만 요청 처리 과정에서 별도의 내장 검증을 제공한다.

Spring 공식 문서: [Spring-driven Method Validation](https://docs.spring.io/spring-framework/reference/core/validation/beanvalidation.html#validation-beanvalidation-spring-method)

## 테스트에서 확인할 것

애노테이션 제거만으로 전환이 끝났다고 판단하면 안 된다. 다음 동작을 HTTP 경계에서 검증한다.

- 음수 `page`가 400으로 거부되는가?
- `size`의 최솟값과 최댓값이 적용되는가?
- 0 이하의 식별자가 거부되는가?
- 검증 실패 시 Controller 이후의 application port가 호출되지 않는가?
- 오류 코드가 기존 API 계약과 동일한가?
- 오류 응답의 field가 `page`, `size`, `vehicleId`처럼 안정적인가?
- 유효한 요청은 기존과 동일하게 처리되는가?

```kotlin
mockMvc.get("/api/v1/vehicles/1/maintenance-records") {
    param("page", "-1")
}.andExpect {
    status { isBadRequest() }
    jsonPath("$.code") { value("VALIDATION_ERROR") }
    jsonPath("$.fieldErrors[0].field") { value("page") }
}

verifyNoInteractions(maintenanceQuery)
```

이번 변경에서는 정비와 차량 Controller 테스트로 잘못된 페이지 입력이 계속 400 `VALIDATION_ERROR`로 처리되는 것을 확인했다. 정비 Controller 테스트에서는 검증 실패 후 application port가 호출되지 않는 것까지 확인했다.

## 전환 체크리스트

1. 프로젝트의 모든 `@Validated` 사용처를 찾는다.
2. Controller, 설정값 클래스, 일반 Spring Bean으로 분류한다.
3. Spring Framework 6.1 이상인지 확인한다.
4. Bean Validation 구현체가 classpath에 있는지 확인한다.
5. Controller의 클래스 수준 `@Validated`와 불필요한 import를 제거한다.
6. `@PathVariable`, `@RequestParam`의 제약 애노테이션은 유지한다.
7. 요청 객체의 `@Valid`를 실수로 제거하지 않는다.
8. `HandlerMethodValidationException`을 공통 오류 응답으로 변환한다.
9. Kotlin parameter metadata 보존 여부를 확인한다.
10. 경계값 테스트와 application port 미호출 검증을 실행한다.
11. 설정값 검증이나 일반 Bean 검증에 필요한 `@Validated`는 유지한다.

## 핵심 교훈

애노테이션의 이름만 보고 일괄적으로 추가하거나 제거해서는 안 된다. 같은 `@Validated`라도 Controller에서는 AOP 검증을 선택하는 스위치이고, `@ConfigurationProperties`에서는 시작 시 설정값 검증을 활성화하는 역할을 한다.

Spring MVC 6.1 이상에서는 Controller 검증을 MVC 요청 처리 과정에 맡기는 편이 예외와 오류 위치 정보를 웹 계층의 개념으로 다루기 쉽다. 중요한 것은 `@Validated`를 제거했다는 사실이 아니라, 검증 책임을 어느 실행 경계에 둘지 명시적으로 선택하고 그 경계를 테스트로 고정하는 것이다.
