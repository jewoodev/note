# 타임 리프 에러(Error resolving template)

## 1. 에러 발생 상황
thymeleaf 를 사용하면서, Intelli J에서 개발할 때는 이상 없이 html 파일을 찾아가며 화면이 노출되었는데, 리눅스 환경(AWS)에서 jar로 build 하고 외부에서 실행하면 아래와 같은 에러를 발생시키면서 화면에 접근하지 못하는 경우가 생겼다.

```
2025-03-13 13:32:24 [http-nio-8088-exec-2] ERROR o.a.c.c.C.[.[.[.[dispatcherServlet] - Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: org.thymeleaf.exceptions.TemplateInputException: Error resolving template [/order/remake-detail], template might not exist or might not be accessible by any of the configured Template Resolvers]
```

## 2. 해결 방법

```java
public class ExampleController {
    @GetMapping("/swagger")
    public String swagger() {
    	
    	//return "/spring/swagger/swagger";     <-- 리눅스에서 파일위치를 찾지 못함
    	return "spring/swagger/swagger";
    }
}
```

> 아직 환경 차이로 인한 경로를 인식하지 못하는 이유는 정확하게 파악하진 못하였지만, 예상하기로는 로컬에서는 SpringBoot는 내장 톰캣으로 동작하게 되고, 배포 환경(AWS 등)에서는 jar나 war 파일로 배포하여 서버를 띄우기 때문에 다르게 동작(ex:외부 톰캣으로 실행) 하는 것 같다.

## Reference

- [JaeWon's Devlog](https://dev-jwblog.tistory.com/40)