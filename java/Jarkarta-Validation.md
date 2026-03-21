스프링 Validation 의 기반이 되는 라이브러리다.

# 컨트롤러 메소드 List 타입 파라미터를 검증할 시 주의할 점
이 헤더에서 말하는 대로 코딩하면 의도한 대로 검증 흐름이 흘러가지 않을 것이다. 만약 당신의 Spring이 6.1+  버전이면 검증 에러 처리 방식이 다음과 같다.

1. 단일 파라미터: `MethodArgumentNotValidException`
2. List 타입 파라미터: `HandlerMethodValidationException`

만약 파라미터가 단일 파라미터였다면 `MethodArgumentNotValidException`가 던져진다. 필자는 이 예외가 던져질 것이라 기대하고 테스트하다가 상당히 혼란스러웠다. 디버깅해보니 `HandlerMethodValidationException`가 던져지는게 확인되었는데 좀 더 자세히 이 현상을 이해해보자.

## `HandlerMethodValidationException`
이 예외는 "**메서드 레벨의 모든 파라미터 검증을 통합하여 표현**" 이라는 의도로 설계되었다. 

이 예외가 **발생하는 경우**:
```
// 1. 경로 변수 검증
public void get(@PathVariable @Min(1) Long id) { }

// 2. 쿼리 파라미터 검증
public void search(@RequestParam @NotBlank String keyword) { }

// 3. 헤더 검증
public void process(@RequestHeader @Pattern(regexp = "\\d+") String version) { }

// 4. 컬렉션 내부 요소 검증
public void batch(@RequestBody List<@Valid ProductRequest> products) { }

// 5. 여러 파라미터의 검증을 하나로
public void complex(
    @PathVariable @Min(1) Long id,
    @RequestParam @NotBlank String name,
    @RequestBody @Valid DataRequest data
) { }
```

**핵심 특징**:
```
public class HandlerMethodValidationException extends MethodValidationException {
    private final HandlerMethod handlerMethod;  // 어떤 핸들러 메서드인지
    private final List<ParameterValidationResult> validationResults; // 파라미터별 검증 결과들
}

public class ParameterValidationResult {
    private final MethodParameter methodParameter; // 어떤 파라미터
    private final Object argument;                  // 실제 값
    private final List<MessageSourceResolvable> resolvableErrors; // 에러들
    private final Object container;                 // List, Map 등의 컨테이너
    private final Integer containerIndex;           // 컨테이너 내 인덱스
    private final Object containerKey;              // Map의 키
}

-----------------------------------------------------------------------------------------------------
- **메서드 실행 전** 모든 파라미터를 검증
- 여러 파라미터의 검증 실패를 **하나의 예외로 통합**
- 각 파라미터별로 독립적인 검증 결과 보관
- 컬렉션/배열 내부 요소의 위치 정보 포함
-----------------------------------------------------------------------------------------------------

### 처리 흐름
Controller Method 호출 직전
    ↓
Method Validation Interceptor
    ↓
각 파라미터 검증 (병렬적)
  ├─ @PathVariable 검증
  ├─ @RequestParam 검증
  ├─ @RequestHeader 검증
  └─ @RequestBody List<@Valid> 검증
    ↓
실패 시 → HandlerMethodValidationException
  (모든 파라미터의 검증 결과를 담음)
```

**역사적 배경**:
Spring Framework 6.1 (Spring Boot 3.2, 2023년)에 도입되었다. 기존에는
```
// Spring 6.0 이전
public void process(
    @PathVariable @Min(1) Long id,        // ConstraintViolationException
    @RequestParam @NotBlank String name,   // ConstraintViolationException
    @RequestBody @Valid Data data         // MethodArgumentNotValidException
) { }
```
위와 같이 세 가지 다른 예외가 발생할 수 있어서 예외 처리가 복잡했다. 이를 통합하기 위해 `HandlerMethodValidationException`이 설계되었다.

## MethodArgumentNotValidException
**설계 의도**: `@RequestBody`/`@RequestPart`로 바인딩된 객체의 Bean Validation 실패를 표현

**사용 시점**:
```java
// 1. @RequestBody로 단일 객체를 받을 때
public void create(@Valid @RequestBody UserRequest request) { }

// 2. @ModelAttribute로 폼 데이터를 받을 때
public void register(@Valid @ModelAttribute UserForm form) { }

// 3. @RequestPart로 멀티파트 데이터를 받을 때
public void upload(@Valid @RequestPart("data") FileMetadata metadata) { }
```

**핵심 특징**:
```
public class MethodArgumentNotValidException extends BindException {
    private final MethodParameter parameter;  // 어떤 파라미터에서 발생했는지
    private final BindingResult bindingResult; // 검증 실패 상세 정보
}

-----------------------------------------------------------------------------------------------------
- **Message Converter 바인딩 이후** 검증
- HTTP 요청 본문(JSON/XML 등)을 객체로 변환한 **후** 검증
- `BindingResult`에 모든 검증 에러가 담김
- Spring MVC의 전통적인 폼 검증 모델 계승
-----------------------------------------------------------------------------------------------------

### 처리 흐름
HTTP Request (JSON)
↓
Message Converter (Jackson 등)
↓
Object 생성 및 바인딩
↓
@Valid 검증 실행
↓
실패 시 → MethodArgumentNotValidException
```

**역사적 배경**:
Spring 3.0부터 Bean Validation(JSR-303) 지원을 시작하면서 도입되었다. 당시에는 주로 폼 바인딩과 `@RequestBody` 검증에 초점이 맞춰져 있었고, "인자로 전달된 객체 전체"를 하나의 검증 단위로 보았다.

## 두 예외의 차이점 요약

| 구분         | MethodArgumentNotValidException | HandlerMethodValidationException |
|------------|---------------------------------|----------------------------------|
| **도입 시기**  | Spring 3.0 (2009년)              | Spring 6.1 (2023년)               |
| **검증 대상**  | 단일 @RequestBody 객체              | 메서드의 모든 파라미터                     |
| **검증 시점**  | 메시지 변환 후                        | 메서드 실행 직전                        |
| **에러 구조**  | 단일 BindingResult                | 파라미터별 ValidationResult 목록        |
| **주 사용처**  | RESTful API 단일 요청               | 복합 검증, 컬렉션 검증                    |
| **컬렉션 지원** | 제한적 (래퍼 필요)                     | 직접 지원 (`List<@Valid`>)           |




```
HandlerMethodValidationException
  ├─ validationResults (List<ParameterValidationResult>)
      └─ ParameterValidationResult (parameterValidationResults[0])
          ├─ methodParameter (메서드 파라미터 정보)
          ├─ argument (실제 전달된 인자값)
          └─ resolvableErrors (검증 에러들)
              └─ BeanPropertyBindingResult
                  └─ FieldError
                      - field: "empty"
                      - rejectedValue: false
                      - defaultMessage: "수정할 정보가 없습니다."
```

