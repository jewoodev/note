# @ModelAttrbute는 setter를 좋아해
`@ModelAttribute` 어노테이션을 통해 데이터를 바인딩 할 때 setter가 꼭 필요한 건 아니다. 기본 생성자가 없다면, Jackson 라이브러리의 기능을 통해 데이터를 바인딩 한다.  
이렇게 `@ModelAttribute` 관련해서 Jackson 라이브러리 기능을 사용할 수 있게 된 건 2.9.* 버전 부터이다.

그런데 기본 생성자가 있다면, setter가 없을 때 바인딩이 이루어지지 않는다.  
Spring 내부 구현체 `ModelAttributeMethodProcessor` 의 `constructAttribute` 메서드를 보면 
```java
public class ModelAttributeMethodProcessor implements HandlerMethodArgumentResolver, HandlerMethodReturnValueHandler {
    
    // ...
    
    protected Object constructAttribute(Constructor<?> ctor, String attributeName, MethodParameter parameter, WebDataBinderFactory binderFactory, NativeWebRequest webRequest) throws Exception {

        if (ctor.getParameterCount() == 0) {
            // A single default constructor -> clearly a standard JavaBeans arrangement.
            return BeanUtils.instantiateClass(ctor);
        }

        // A single data class constructor -> resolve constructor arguments from request parameters.
        String[] paramNames = BeanUtils.getParameterNames(ctor);
        Class<?>[] paramTypes = ctor.getParameterTypes();
        Object[] args = new Object[paramTypes.length];
        WebDataBinder binder = binderFactory.createBinder(webRequest, null, attributeName);
        String fieldDefaultPrefix = binder.getFieldDefaultPrefix();
        String fieldMarkerPrefix = binder.getFieldMarkerPrefix();
        boolean bindingFailure = false;
        Set<String> failedParams = new HashSet<>(4);
    
        // ...생략
    }
}
```

if (ctor.getParameterCount() == 0) 분기에 의해서 파라미터 개수가 0개인 기본 생성자가 확인되면 우선 인스턴스(객체)를 생성하고, setter 메서드를 통한 바인딩을 시도한다.

그렇지 않을 경우 필드에 맞는 파라미터를 가진 생성자를 찾아 바인딩을 시도한다.

## 참고 자료
- [현구막님의 개발 블로그](https://hyeon9mak.github.io/model-attribute-without-setter/)