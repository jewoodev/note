# 스프링이 제공하는 HandlerMapping과 HandlerAdapter

![](https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/_images/RequestLifecycle.png)
> 이미지 출처: https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/Overview/SpringMVCOverview.html#overview-of-spring-mvc-processing-sequence

스프링은 이미 필요한 HandlerMapping과 HandlerAdapter을 대부분 구현해두었다. 그 중 중요한 몇가지를 살펴보자.

**HandlerMapping**

```
0 = RequestMappingHandlerMapping   : @RequestMapping이나 @Controller가 클래스 타입에 붙어있는 애노테이션 기반의 핸들러를 찾음
1 = BeanNameUrlHandlerMapping      : 스프링 빈의 이름으로 핸들러를 찾음
```

**HandlerAdapter**

```
0 = RequestMappingHandlerAdapter   : @RequestMapping나 @Controller를 사용한 핸들러를 실행하기 위한 어댑터
1 = HttpRequestHandlerAdapter      : HttpRequestHandler를 구현한 핸들러를 실행하기 위한 어댑터
2 = SimpleControllerHandlerAdapter : Controller 인터페이스(애노테이션x) 를 구현한 핸들러를 실행하기 위한 어댑터
```

둘 다 순서대로 핸들러와 어댑터를 찾고 없으면 다음 순서로 넘어가는 형식으로 동작한다. 어떻게 동작하는지 살펴보자.

1. 핸들러 매핑이 핸들러를 조회한다.
   1. `HandlerMapping`을 순서대로 실행해서, 핸들러를 찾는다.
   2. 스프링 컨테이너에 등록된 핸들러 종류를 보고 알맞은 핸들러 매핑이 실행되어 요청을 처리하기 위한 핸들러를 반환한다.
2. 핸들러 어댑터를 조회한다.
   1. `HandlerAdapter`의 `support()`를 순서대로 호출하여 핸들러 타입에 해당하는 어댑터를 찾는다.
3. 핸들러 어댑터 실행
   1. DispatcherServlet이 조회된 어댑터에 핸들러 정보를 전달하고 실행한다.
   2. 어댑터는 핸들러를 실행하여 그 결과를 반환한다.

서블릿과 가장 유사한 형태의 HttpRequestHandler가 사용되는 예시를 살펴보자.

```java
public interface HttpRequestHandler {
    void handleRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException;
}
```

구현체의 예시는 아래와 같다.

```java
import org.springframework.stereotype.Component;
import org.springframework.web.HttpRequestHandler;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component("/springmvc/request-handler")
public class MyHttpRequestHandler implements HttpRequestHandler {
    @Override
    public void handleRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        System.out.println("MyHttpRequestHandler.handleRequest");
    }
}
```

이렇게 구현된 서버에 "/springmvc/request-handler"로 요청을 보내면 현재 핸들러는 빈 이름으로 Url을 매핑하고 있기 때문에 `HandlerMapping`은 이를 감지해서 `BeanNameUrlHandlerMapping`를 실행해 `MyHttpRequestHandler`를 찾는다.

그리고 HttpRequestHandler의 구현체 이므로 `HttpRequestHandlerAdapter`가 선택되어서 이게 `MyHttpRequestHandler`의 `handleRequest()`를 실행해 응답을 보내게 되는 것이다.


