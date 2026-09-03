# Overview
앞서 `AOP`의 개념에 대해 알아보고 자바 AOP를 구현하기 위해 `Dynamic Proxy`와 `CGLib`, `AspectJ`를 쓸 수 있음을 알았다.

`spring AOP`에서는 인터페이스 유무에 따라 인터페이스 기반의 프록시 생성 시 `Dynamic Proxy`를 사용하고 인터페이스 기반이 아닐 시 `CGLib`을 사용하는데

`spring boot AOP`에서는 `CGLib`을 default로 사용한다고 한다.

> Hibernate uses cglib for generation of dynamic proxies. For example, it will not return full object stored in a database but it will return an instrumented version of stored class that lazily loads values from the database on demand.

JPA Hibernate에서도 기본적으로 CGLib을 사용한다고 한다.

오늘은 `spring AOP`를 완벽하게 이해하기 위해 먼저 스프링 없이 순수 자바로 `Dynamic Proxy`와 `CGLib`를 실습해보며 이해해보려고 한다.

# JDK Dynamic Proxy와 CGLib
Dynamic Proxy와 CGLib은 모두 런타임 위빙 방식이며 **프록시 패턴**으로 동작한다. 따라서 메서드 실행 시에만 위빙이 가능하다. 그래서 Dynamic Proxy와 CGLib를 사용하는 스프링 AOP도 메서드 실행 조인포인트만 지원한다.

# Proxy Pattern이란?
> 프록시 패턴이란 소프트웨어 디자인 패턴 중 하나로 오리지널 객체(Real Object) 대신 프록시 객체(Proxy Object)를 사용해 로직의 흐름을 제어하는 디자인 패턴이다.

`Dynamic Proxy`와 `CGLib`는 기본적으로 프록시 패턴으로 동작하여 원래 소스코드를 수정하지 않고 프록시 객체를 생성하여 흐름을 제어해 기능을 삽입할 수 있다. 오리지널 객체의 메서드 호출 결과를 바꿀 순 없다.

# JDK Dynamic Proxy
JDK 에서 제공하는 Dynamic Proxy는 **Interface를 기반으로 Proxy를 생성**해주는 방식이다.

Interface를 기반으로 Proxy를 생성해주기 때문에 인터페이스의 존재가 필수적이다.

자바에서는 리플렉션을 활용한 Proxy 클래스를 제공해주고 있다.

`Java.lang.reflect.Proxy` 클래스의 `newProxyInstance()` 메소드를 이용해 프록시 객체를 생성한다.

## Reflection이란?
`Reflection`이란 구체적인 클래스 타입을 알지 못해도 그 클래스의 정보(메서드, 타입, 변수 등등)에 접근할 수 있게 해주는 자바 API다.

자바에서는 `JVM`이 실행되면 사용자가 작성한 자바 코드가 컴파일러를 거쳐 바이트 코드로 변환되어 static 영역에 저장된다. `Reflection API`는 이 정보를 활용해 필요한 정보를 가져온다.

자바의 `Reflection API`는 값비싼 API이기 때문에 `Dynamic Proxy`는 리플렉션을 하는 과정에서 성능이 좀 떨어진다는 단점이 있다.

## 다이나믹 프록시 실습해보기
### 1. 인터페이스 작성
다이나믹 프록시는 인터페이스 존재가 필수적이므로 인터페이스를 작성한다.

```java
public interface Animal {
    void eat();
    void drink();
}
```

### 2. 인터페이스 구현
인터페이스를 상속받아 타켓을 구현한다.

`eat()`메서드와 `drink()`메서드를 정의하고 메서드 호출 시 `Dynamic Proxy`를 이용해 앞 뒤로 로그를 weaving 해보려고 한다.

```java
public class Rabbit implements Animal{
    @Override
    public void eat() {
        System.out.println("토끼가 음식을 먹습니다.");
    }

    @Override
    public void drink() {
        System.out.println("토끼가 물을 마십니다.");
    }
}
```

```java
public class Tiger implements Animal{
    @Override
    public void eat() {
        System.out.println("호랑이가 음식을 먹습니다.");
    }

    @Override
    public void drink() {
        System.out.println("호랑이가 물을 마십니다.");
    }
}
```

### 3. 프록시 핸들러 구현
프록시 객체를 생성할 때 필요한 핸들러를 구현한다. `InvocationHandler`를 상속받아 구현한다. 메서드 호출 전 후에 로그를 찍어보겠다.

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class AnimalProxyHandler implements InvocationHandler {

    Object target;

    public AnimalProxyHandler(Object target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object result = null;
        System.out.println("****before****");

        //메서드가 eat 이라면
        if(method.getName().equals("eat")) {
            System.out.println("----eat 메서드 호출 전----");

            result = method.invoke(target, args); // 메서드 호출

            System.out.println("----eat 메서드 호출 후----");
        } else if(method.getName().equals("drink")) { // 메서드가 drink 라면
            System.out.println("----drink 메서드 호출 전----");

            result = method.invoke(target, args); // 메서드 호출

            System.out.println("----drink 메서드 호출 후----");
        }

        System.out.println("****after****");
        return result; // 호출결과 반환
    }
}
```

### 4. 예제 테스트코드 작성
핸들러도 구현하였으니 프록시 객체를 생성해보겠다.

`Java.lang.reflect.Proxy` 클래스의 `newProxyInstance()` 메소드를 이용한다.

```java
import org.junit.Test;

import java.lang.reflect.Proxy;

public class DynamicProxyTests {
    @Test
    public void dynamicProxyExample() {
        // Create the proxy
        //동적으로 프록시 생성
        // rabbit
        Animal rabbit = (Animal) Proxy.newProxyInstance(Animal.class.getClassLoader(),
                new Class[]{Animal.class},
                new AnimalProxyHandler(new Rabbit()));
        // tiger
        Animal tiger = (Animal) Proxy.newProxyInstance(Animal.class.getClassLoader(),
                new Class[]{Animal.class},
                new AnimalProxyHandler(new Tiger()));

        // Invoke the target instance method through the proxy
        rabbit.eat();
        System.out.println();
        rabbit.drink();
        System.out.println();

        tiger.eat();
        System.out.println();
        tiger.drink();
        System.out.println();
    }
}
```

### 5. 실행 결과
오오오,, 느낌이 `spring AOP`와 굉장히 비슷하다.

```bash
/Users/suhongkim/Library/Java/JavaVirtualMachines/openjdk-15.0.2/...

****before****
----eat 메서드 호출 전----
토끼가 음식을 먹습니다.
----eat 메서드 호출 후----
****after****

****before****
----drink 메서드 호출 전----
토끼가 물을 마십니다.
----drink 메서드 호출 후----
****after****

****before****
----eat 메서드 호출 전----
호랑이가 음식을 먹습니다.
----eat 메서드 호출 후----
****after****

****before****
----drink 메서드 호출 전----
호랑이가 물을 마십니다.
----drink 메서드 호출 후----
****after****

Process finished with exit code 0
```

다이나믹 프록시는 인터페이스가 필수이다. 인터페이스 없을 때도 프록시 패턴을 사용하고 싶지 않을까, `CGLib`가 이 문제를 해결해준다.

# CGLib
CGLib는 JDK Dynamic Proxy와는 다르게 인터페이스가 아닌 **클래스 기반으로 바이트코드를 조작하여 프록시를 생성**하는 방식이다.

`CGLib`은 바이트코드 조작을 위해 **ASM**이라는 자바 바이트코드 조작 및 분석 프레임워크를 사용한다. ASM을 통해 클래스를 동적으로 생성하거나 수정한다.

인터페이스가 아닌 클래스를 대상으로 동작 가능하고 바이트코드를 조작해 프록시를 만들기 때문에 Dynamic Proxy에 비해 성능이 우수하다는 장점이 있지만

Extends(상속) 방식을 이용해서 Proxy화 할 메서드를 오버라이딩하는 방식인만큼 `final`이나 `private`와 같이 상속된 객체에 오버라이딩을 지원하지 않는 경우 Proxy에서 해당 메소드에 대한 Aspect를 적용할 수 없다.

## CGLib 실습해보기
### 1. CGLib 의존성 추가
spring에서는 spring AOP를 위해 spring core 패키지에 CGLib가 기본적으로 포함되어 있다. 스프링 환경이 아닌 자바에서 CGLib을 사용하고자 하니 의존성을 추가해주겠다.

```xml
<!-- https://mvnrepository.com/artifact/cglib/cglib -->
<dependency>
    <groupId>cglib</groupId>
    <artifactId>cglib</artifactId>
    <version>3.3.0</version>
</dependency>
```

### 2. 클래스 작성

다이나믹 프록시를 사용할 땐 인터페이스 구현이 필수였지만 CGLib은 그렇지 않다. 클래스만 작성해준다.

```java
public class Rabbit {
    public void eat() {
        System.out.println("토끼가 음식을 먹습니다.");
    }

    public void drink() {
        System.out.println("토끼가 물을 마십니다.");
    }
}
```

### 3. 프록시 핸들러 구현

![](https://velog.velcdn.com/images%2Fsuhongkim98%2Fpost%2Fe99b4fdf-6451-43d5-ba8f-a79082d01be3%2Fimage.png)

CGLib를 사용하여 프록시를 생성할 때에는 크게 크게 두가지 작업을 필요로 한다.

- `net.sf.cglib.proxy.Enhancer` 클래스를 사용하여 원하는 프록시 객체 만들기
- `net.sf.cglib.proxy.Callback`을 사용하여 프록시 객체 조작하기

프록시 객체를 조작하기 위해 `MethodInterceptor` 방식과 다이나믹 프록시에서 사용했던 `InvocationHandler` 방식을 사용해 핸들러를 사용할 수 있다.

`InvocationHandler` 방식을 사용할 경우 바이트코드 조작이 아니라 다이나믹 프록시와 마찬가지로 리플렉션을 활용한다. CGLib의 성능을 활용하기 위해서는 `MethodInterceptor`를 사용하는 것이 일반적이다.

먼저 다이나믹 프록시에서 사용했던 `InvocationHandler`를 재사용하는 것을 보여주기 위해 `InvocationHandler` 방식을 먼저 확인해보자

### 3-1 InvocationHandler 방식으로 핸들러 구현
모든 코드는 한 줄만 빼고 위의 다이나믹 프록시에서 사용했던 `InvocationHandler`코드와 일치하다.

import 시 `java.lang.reflect.InvocationHandler` 를 `net.sf.cglib.proxy.InvocationHandler`로 `InvocationHandler` 경로만 바꿔주면 된다.

```java
import net.sf.cglib.proxy.InvocationHandler;

import java.lang.reflect.Method;

//CGLib 에서 Dynamic Proxy 에서 사용했던 핸들러 방식 사용하기
// 이는 자바 리플렉션을 사용한다.
public class AnimalProxyCGLibHandler implements InvocationHandler {

    Object target;

    public AnimalProxyCGLibHandler(Object target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object result = null;
        System.out.println("****before****");

        //메서드가 eat 이라면
        if(method.getName().equals("eat")) {
            System.out.println("----eat 메서드 호출 전----");

            result = method.invoke(target, args); // 메서드 호출 //자바의 리플렉션 사용

            System.out.println("----eat 메서드 호출 후----");
        } else if(method.getName().equals("drink")) { // 메서드가 drink 라면
            System.out.println("----drink 메서드 호출 전----");

            result = method.invoke(target, args); // 메서드 호출

            System.out.println("----drink 메서드 호출 후----");
        }

        System.out.println("****after****");
        return result; // 호출결과 반환
    }
}
```

### 3-1 InvocationHandler 방식 프록시 객체 생성 예제 코드
`Enhancer`를 이용해 프록시를 생성한다.

`setCallback`를 이용해 핸들러를 적용한다.

```java
//CGLib 에서 Dynamic Proxy 에서 사용했던 핸들러 방식 사용하기
    // 이는 자바 리플렉션을 사용한다.
    @Test
    public void byHandlerExample() {
        //Enhancer 객체를 생성
        Enhancer rabbitEnhancer = new Enhancer();
        // setSuperclass() 메소드에 프록시할 클래스 지정
        rabbitEnhancer.setSuperclass(Rabbit.class);
        rabbitEnhancer.setCallback(new AnimalProxyCGLibHandler(new Rabbit())); // 핸들러 지정
        Rabbit rabbit = (Rabbit) rabbitEnhancer.create(); // 프록시 생성

        rabbit.eat();
        System.out.println();
        rabbit.drink();
    }
```

### 3-1 InvocationHandler 예제 실행 결과
다이나믹 프록시와 결과가 동일하다.

```bash
/Users/suhongkim/Library/Java/JavaVirtualMachines/openjdk-15.0.2/...

****before****
----eat 메서드 호출 전----
토끼가 음식을 먹습니다.
----eat 메서드 호출 후----
****after****

****before****
----drink 메서드 호출 전----
토끼가 물을 마십니다.
----drink 메서드 호출 후----
****after****

Process finished with exit code 0
```

### 3-2 MethodInterceptor 방식으로 핸들러 구현
`MethodInterceptor`를 상속받아 앞 뒤로 로그 출력을 해주는 인터셉터를 구현해보겠다.

```java
public class PrintLogInterceptor implements MethodInterceptor {
    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        Object result = null;
        System.out.println("****before log****");
        result = methodProxy.invokeSuper(o, objects);
        System.out.println("****after log****");
        return result;
    }
}
```

### 3-2 MethodInterceptor 예제 테스트코드 작성

```java
@Test
    public void byInterceptorExample() {
        //Enhancer 객체를 생성
        Enhancer rabbitEnhancer = new Enhancer();
        // setSuperclass() 메소드에 프록시할 클래스 지정
        rabbitEnhancer.setSuperclass(Rabbit.class);
        // 로그 출력해주는 인터셉터 지정
        rabbitEnhancer.setCallback(new PrintLogInterceptor());
        Rabbit rabbit = (Rabbit) rabbitEnhancer.create(); // 프록시 생성

        rabbit.eat();
        System.out.println();
        rabbit.drink();
    }
```

### 3-2 인터셉터 예제 실행 결과

```bash
/Users/suhongkim/Library/Java/JavaVirtualMachines/openjdk-15.0.2/...

****before log****
토끼가 음식을 먹습니다.
****after log****

****before log****
토끼가 물을 마십니다.
****after log****

Process finished with exit code 0
```

## CGLib의 Callback Filter
지금까지는 `setCallback()` 메서드를 이용해 인터셉터를 적용하였다.

항상 같은 인터셉터를 적용해야하나? 필터 조건에 따라 다른 인터셉터를 적용하고 싶지 않을까? Callback Filter을 구현함으로써 해결 가능하다.

CallbackFilter를 구현할 때 `accept()` 메서드를 재정의한다.

`accept()` 메서드는 int형의 index값을 반환하는데 이 인덱스를 이용해 callback 배열에 있는 인터셉터를 적용한다.

### 1. CallbackFilter 구현
메서드 이름에 따라 다른 인터셉터를 적용해보려고 한다.

나는 호출하고자 하는 메서드가 `eat()`인 경우 `EatInterceptor`를 적용하고자 0을 반환하고 메서드가 `drink()`인 경우 `EatInterceptor`를 적용하고자 1을 반환하도록 했다.

```java
// 메서드가 eat 이냐 drink 냐에 따라 해당하는 인덱스 반환해주는 필터
public class AnimalMethodCallbackFilter implements CallbackFilter {
    @Override
    public int accept(Method method) {
        if(method.getName().equals("eat")) return 0;
        if(method.getName().equals("drink")) return 1;
        return 0; // 해당하지 않으면 그냥 0반환
    }
}
```

### 2. 적용하고자 하는 인터셉터들 구현
인터셉터 구현 방법은 스크롤을 올려 예제를 참고하자.

### 3. callback filter 예제 테스트코드 작성
`setCallbackFilter()`메서드를 통해 구현했던 callback 필터를 적용한다.

`setCallbacks()` 메서드를 통해 인터셉터 배열을 적용한다.

그럼 메서드 호출할 때마다 메서드 이름에 따라 반환하는 인덱스값을 이용해 해당하는 인터셉터를 적용해줄 것이다.

```java
@Test
    public void callbackFilterExample() {
        //콜백 필터를 이용해 필터 조건에 따라 다른 인터셉터 적용하기 예제
        //메서드가 무엇이냐에 따라 해당 인터셉터를 적용한다.
        //Enhancer 객체를 생성
        Enhancer rabbitEnhancer = new Enhancer();
        // setSuperclass() 메소드에 프록시할 클래스 지정
        rabbitEnhancer.setSuperclass(Rabbit.class);
        //메서드 이름에 따라 인덱스 반환해주는 콜백 필터 지정, 0 반환 시 EatInterceptor, 1 반환 시 DrinkInterceptor
        rabbitEnhancer.setCallbackFilter(new AnimalMethodCallbackFilter());
        // 콜백 배열 지정
        rabbitEnhancer.setCallbacks(new Callback[]{
                new EatInterceptor(), // 0
                new DrinkInterceptor() // 1
        });
        Rabbit rabbit = (Rabbit) rabbitEnhancer.create(); // 프록시 생성

        rabbit.eat();
        System.out.println();
        rabbit.drink();
    }
```

### 4. callback filter 적용 예제 실행 결과

```bash
/Users/suhongkim/Library/Java/JavaVirtualMachines/openjdk-15.0.2/...

-- eat 메서드 호출 전 --
토끼가 음식을 먹습니다.
-- eat 메서드 호출 후 --

-- drink 메서드 호출 전 --
토끼가 물을 마십니다.
-- drink 메서드 호출 후 --

Process finished with exit code 0

```

# 마무리
오늘은 spring AOP를 완벽하게 이해하기 위해 먼저 Dynamic Proxy와 CGLib를 알아보았다.

Dynamic Proxy와 CGLib를 알아보며 리플렉션의 개념과 프록시 패턴이 무엇인지 알게 되었고 대표적인 spring AOP라고 할 수 있는 `@Transactional`의 동작 원리에 대해 알게된 것 같다.

# 전체 실습 예제 코드

[[실습 예제 github로 이동]](https://github.com/suhongkim98/java-aop)

# 참고자료

- https://velog.io/@hanblueblue/Spring-Proxy-1-Java-Dynamic-Proxy-vs.-CGLIB#java-dynamic-proxy-what-is-a-proxy-and-how-can-we-use-it
- https://huisam.tistory.com/entry/springAOP
- https://javacan.tistory.com/entry/114

## 보면 좋은 것

- spring **ProxyFactoryBean**
  -  = https://velog.io/@hanblueblue/Spring-Proxy-2-Spring-with-proxy