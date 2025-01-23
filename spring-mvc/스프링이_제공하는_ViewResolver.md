# 스프링이 제공하는 ViewResolver

![](https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/_images/RequestLifecycle.png)
> 이미지 출처: https://terasolunaorg.github.io/guideline/5.0.1.RELEASE/en/Overview/SpringMVCOverview.html#overview-of-spring-mvc-processing-sequence

어떤 뷰 리졸버들을 제공할까? 너무 많다. 그 중에 중요한 부분들을 살펴보자

```
1 = BeanNameViewResolver           : 빈 이름으로 뷰를 찾아서 반환한다. (예: 엑셀 파일 생성 기능에 사용)
2 = InternalResourceViewResolver   : JSP를 처리할 수 있는 뷰를 반환한다.
```

DispatcherServlet은 `HandlerAdapter`를 통해 논리 뷰 이름을 획득한다. 획득한 뷰 이름으로 viewResolver를 순서대로 호출한다. 위의 순서대로다.

획득한 뷰 이름이 `index`였다고 하자. 이 이름의 스프링 빈이 없고 프로젝트에 "/WEB-INF/views/index.jsp" 가 있다면 InternalResourceViewResolver가 선택되어 정상적으로 뷰를 반환한다.

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
        return new ModelAndView("index");
    }
}
```

InternalResourceViewResolver는 논리 뷰 이름에 `application.properties`에서 데이터를 가져와서 물리 뷰 이름을 만든다.

이 경우에는 다음의 코드가 `application.properties`에 있어야 한다.

```
spring.mvc.view.prefix=/WEB-INF/views/
spring.mvc.view.suffix=.jsp
```
> 스프링 부트가 InternalResourceViewResolver를 등록할 때 application.properties에서 정보를 가져간다.  
> 
> 권장되진 않지만 `return new ModelAndView("/WEB-INF/views/index.jsp");` 가 실행되어도 정상 동작하긴 한다.

> Thymeleaf 같은 뷰 템플릿을 사용하면 `ThymeleafViewResolver`가 등록되어야 한다. 최근에는 라이브러리만 추가해도 스프링 부트가 자동으로 처리한다.