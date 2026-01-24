# In Spring Framework 7.0.3 Reference Documentation
@ExceptionHandler, @InitBinder, @ModelAttribute 메서드는 해당 메서드가 선언된 @Controller 클래스 또는 클래스 계층 구조에만 적용된다. 하지만 @ControllerAdvice 또는 @RestControllerAdvice 클래스에 선언된 경우에는 모든 컨트롤러에 적용된다. 또한, 5.3 버전부터는 @ControllerAdvice의 @ExceptionHandler 메서드를 사용하여 모든 @Controller 또는 다른 핸들러에서 발생하는 예외를 처리할 수 있다.

@ControllerAdvice는 @Component 메타 어노테이션이 붙어 있으므로 컴포넌트 스캔을 통해 Spring 빈으로 등록할 수 있다.

@RestControllerAdvice는 @ControllerAdvice와 @ResponseBody를 결합한 단축 어노테이션으로, 예외 처리 메서드가 응답 본문에 출력되는 @ControllerAdvice와 같다.

RequestMappingHandlerMapping과 ExceptionHandlerExceptionResolver는 시작 시 컨트롤러 어드바이스 빈을 감지하고 런타임에 적용한다. @ControllerAdvice 어노테이션의 전역 @ExceptionHandler 메서드는 @Controller 어노테이션의 지역 메서드 다음에 적용된다. 반대로, 전역 @ModelAttribute 및 @InitBinder 메서드는 지역 메서드보다 먼저 적용된다.

기본적으로 @ControllerAdvice와 @RestControllerAdvice는 @Controller 및 @RestController를 포함한 모든 컨트롤러에 적용됩니다. 어노테이션의 속성을 사용하여 적용 대상 컨트롤러 및 핸들러 집합을 좁힐 수 있다. 예를 들면 다음과 같다:

```java
// Target all Controllers annotated with @RestController
@ControllerAdvice(annotations = RestController.class)
public class ExampleAdvice1 {}

// Target all Controllers within specific packages
@ControllerAdvice("org.example.controllers")
public class ExampleAdvice2 {}

// Target all Controllers assignable to specific classes
@ControllerAdvice(assignableTypes = {ControllerInterface.class, AbstractController.class})
public class ExampleAdvice3 {}
```
앞의 예제에 나온 셀렉터는 런타임에 평가되므로, 과도하게 사용하면 성능에 부정적인 영향을 미칠 수 있다. 자세한 내용은 @ControllerAdvice의 Javadoc을 참조하자.

# In JavaDoc
@ExceptionHandler, @InitBinder, 또는 @ModelAttribute 메서드를 선언하여 여러 @Controller 클래스에서 공유할 수 있도록 하는 @Component의 특수화이다.

@ControllerAdvice로 어노테이션된 클래스는 Spring 빈으로 명시적으로 선언되거나 클래스패스 스캐닝을 통해 자동 감지될 수 있다. 이러한 모든 빈은 Ordered 시맨틱 또는 @Order / @Priority 선언을 기반으로 정렬되며, Ordered 시맨틱이 @Order / @Priority 선언보다 우선순위를 갖는다. 그런 다음 @ControllerAdvice 빈은 런타임에 해당 순서로 적용된다. 그러나 PriorityOrdered를 구현하는 @ControllerAdvice 빈이 Ordered를 구현하는 @ControllerAdvice 빈보다 우선순위를 갖지는 않는다. 또한 스코프가 지정된 @ControllerAdvice 빈(예: request-scoped 또는 session-scoped 빈으로 구성된 경우)에 대해서는 Ordered가 적용되지 않는다. 예외 처리의 경우, 일치하는 예외 핸들러 메서드가 있는 첫 번째 advice에서 @ExceptionHandler가 선택된다. 모델 속성 및 데이터 바인딩 초기화의 경우, @ModelAttribute 및 @InitBinder 메서드는 @ControllerAdvice 순서를 따른다.

참고: @ExceptionHandler 메서드의 경우, 특정 advice 빈의 핸들러 메서드 중에서 현재 예외의 원인(cause)만 일치하는 것보다 루트 예외 일치가 우선된다. 그러나 우선순위가 높은 advice의 원인 일치는 우선순위가 낮은 advice 빈의 모든 일치(루트 또는 원인 레벨 여부와 관계없이)보다 여전히 우선된다. 따라서 우선순위가 지정된 advice 빈에 해당 순서와 함께 주요 루트 예외 매핑을 선언하는 것이 권장된다.

기본적으로 @ControllerAdvice의 메서드는 모든 컨트롤러에 전역적으로 적용된다. annotations(), basePackageClasses(), basePackages() (또는 별칭인 value())와 같은 셀렉터를 사용하여 대상 컨트롤러의 더 좁은 하위 집합을 정의할 수 있다. 여러 선택자가 선언된 경우 불린 OR 논리가 적용되므로, 선택된 컨트롤러는 최소한 하나의 선택자와 일치해야 한다. 선택자 검사는 런타임에 수행되므로 많은 선택자를 추가하면 성능에 부정적인 영향을 미치고 복잡성이 증가할 수 있다.