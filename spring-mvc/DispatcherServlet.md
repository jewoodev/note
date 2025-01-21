# DispatcherServlet

비즈니스 로직과 뷰 렌더링을 서블릿과 JSP에서 모두 처리하던 것에 MVC 패턴을 적용하면 몰려있던 역할들이 각각의 변경의 라이프 사이클에 맞게 분리되어 유지보수성이 좋아진다.

하지만 각 컨트롤러마다 쓰이는 일이 거의 없는 response를 매번 파라미터로 받아야 하고, view로 이동하는 코드가 중복되는 등 비효율적인 점이 여전히 남아있다.

이런 상황에서 모든 요청을 처리하는 컨트롤러 앞에 수문장처럼 위치하여 공통 처리를 하는 객체가 있어 보일러 플레이트를 없앨 수 있다면 얼마나 좋을까? (프론트 컨트롤러 패턴 도입)

그게 바로 스프링의 핵심 기술인 `DispatcherServlet`이다. 

![](https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/_images/RequestLifecycle.png)
> 이미지 출처: https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/Overview/SpringMVCOverview.html#overview-of-spring-mvc-processing-sequence

DispatcherServlet의 동작 과정은 크게보면 다음과 같다.

1. DispatcherServlet가 클라이언트의 모든 요청을 받는다.
2. 요청 정보에 대해 HandlerMapping에 위임해 처리할 Handler(Controller)를 찾는다.
3. 2번에서 찾은 Handler를 수행할 수 있는 HandlerAdapter를 찾는다.
4. HandlerAdapter는 Controller에 비즈니스 로직 처리를 호출한다.
5. Controller는 비즈니스 로직을 수행하고, 처리 결과를 Model에 입력하고 HandlerAdapter에 view name을 반환한다.
6. 5번에서 반환받은 view name을 ViewResolver에게 전달하고, ViewResolver는 그것에 해당하는 View 객체를 반환한다.
7. DispatcherServlet은 View에게 Model을 전달하고 화면 표시를 요청한다.
8. 최종적으로 서버의 응답을 클라이언트에게 반환한다.

몇가지 낯선 명칭들이 있다. 그것에 대한 설명은 아래와 같다.

1. **HandlerMapping**
   1. 역할 : 클라이언트 요청 URL을 기반으로 적합한 핸들러(Controller)를 찾아주는 객체. 어떤 요청이 어떤 컨트롤러 메소드로 매핑될지 결정함.
   2. 객체 타입 : `HandlerMapping` 인터페이스를 구현하는 객체(예: `RequestMappingHandlerMapping`)
2. **HandlerAdapter**
   1. 역할 : `HandlerMapping`이 찾아낸 핸들러를 실행하기 위한 어댑터 역할을 함. 핸들러가 특정한 인터페이스를 구현하지 않아도 일관되게 실행되도록 지원함.
   2. 객체 타입 : `HandlerAdapter` 인터페이스를 구현하는 객체(예: `RequestMappingHandlerAdapter`)

HandlerAdapter의 역할은 꼭 필요할까? 싶은데 스프링 MVC가 지원하는 핸들러의 타입이 다양하다는 걸 상기하면 어떤 역할을 하는건지 이해할 수 있다. 여기서 말하는 타입들의 예시를 살펴보면 

1. `@Controller`에서 정의된 메서드
2. `HttpRequestHandler` 인터페이스를 구현한 객체
3. Spring 2.x에서 사용된 `Controller` 인터페이스 구현체

인데, 이렇듯 다양한 타입이 있어 실행 방식이 제각각이라 타입에 맞는 실행 방식을 제공할 역할이 필요하다. 이를 수행하는것이 HandlerAdapter이다. 

> HandlerAdapter는 핸들러와 DispatcherServlet의 사이를 느슨하게 결합시킨다. DispatcherServlet은 핸들러의 세부적인 호출 방식이나 구현에 신경쓰지 않고, 단지 HandlerAdapter를 통해 핸들러를 실행하게 된다. 이렇게 하면
> - 새로운 핸들러 타입을 추가할 때 DispatcherServlet을 수정하지 않아도 된다.

## 어떻게 등록될까?

DispatcherServlet은 부모 클래스에서 `HttpServlet`을 상속 받아서 사용하고, 서블릿으로 동작한다.

> DispatcherServlet &rarr; FrameworkServlet &rarr; HttpServletBean &rarr; HttpServlet

스프링 부트의 내장 톰캣이 DispatcherServlet을 생성한 후 **모든 경로**(urlPatterns="/") 에 대해서 매핑한다.

## 요청은 세부적으로 어떤 흐름으로 처리될까?

- 서블릿은 기본적으로 호출되면 `HttpServlet`이 제공하는 `service()`를 호출한다.
- 스프링 MVC는 `DispatcherServlet`의 부모인 `FrameworkServlet`에 `HttpServlet`의 `service()`를 오버라이드 해두었다.
- `FrameworkServlet.service()`를 시작으로 여러 메서드가 호출되면서 `DispatcherServlet.doDispatch`가 호출된다.

`doDispatch()` 메서드는 DispatcherServlet의 핵심이다. 이 메서드를 구성하는 코드 중 주요한 코드만 살펴보자.

```java
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
    HttpServletRequest processedRequest = request;
    HandlerExecutionChain mappedHandler = null;
    ModelAndView mv = null;
    
    // 1. Handler 조회
    mappedHandler = getHandler(processedRequest);
    if (mappedHandler == null) {
        noHandlerFound(processedRequest, response);
        return;
    }
    
    // 2. HandlerAdapter 조회
    HandlerAdapter ha = getHandlerAdater(mappedHandler.getHandler());
    
    // 3. HandlerAdapter 실행 -> 핸들러 실행 -> ModelAndView 반환
    mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
    
    processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
}

private void proecessDispatchResult(HttpServletRequest request, HttpServletResponse response, HandlerExecutionChain mappedHandler, ModelAndView mv, Exception exception) throws Exception {
    // 4. 뷰 렌더링 호출
    render(mv, request, response);
}

protected void render(ModelAndView mv, HttpServletRequest request, HttpServletResponse response) throws Exception {
    View view;
    String viewName = mv.getViewName();

    // 5. 뷰 리졸버를 통해서 뷰를 찾아 반환
    view = resolveViewName(viewName, mv.getModelInternal(), locale, request);

    // 6. 뷰 렌더링
    view.render(mv.getModelInternal(). request, response);
}   
```

