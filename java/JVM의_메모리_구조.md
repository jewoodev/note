# JVM의 메모리 구조

JVM의 주요 영역에 대해 정리해보겠다. 각 영역은 다른 용도로 쓰인다.

![img.png](https://github.com/jewoodev/blog_img/blob/main/java/JVM%EC%9D%98_%EB%A9%94%EB%AA%A8%EB%A6%AC_%EA%B5%AC%EC%A1%B0/jvm_%EB%A9%94%EB%AA%A8%EB%A6%AC_%EA%B5%AC%EC%A1%B0.png?raw=true)

## 1. 메소드 영역

프로그램 실행 중 어떤 클래스가 사용되면, JVM은 해당 클래스의 클래스파일(*.class)을 읽어서 분석한 클래스에 대한 정보(클래스 데이터)를 이곳에 저장한다. 이 때, 그 클래스의 클래스 변수(class variable)도 이 영역에 함께 생성된다.

## 2. Heap

인스턴스가 생성되는 공간이다. 인스턴스가 생성될 때 인스턴스 변수도 함께 생성된다.

## 3. 호출스택

이곳은 메서드의 작업에 필요한 메모리 공간을 제공한다. 메소드가 호출되면, 호출스택에 호출된 메소드를 위한 메모리가 할당되며, 메소드가 작업을 수행하는 동안 지역변수(매개변수 포함)들과 연산의 중간 결과 등을 저장한다. 그리고 메소드가 작업을 마치면 해당 메모리 공간은 반환되어 비워진다.

하나의 메소드가 다른 메소드를 호출하고, 그 메소드가 또 다른 메소드를 호출하면 각 메소드에 대한 메모리공간은 서로 구별되어 차례대로 층을 쌓는다.

자바에서는 main 메소드에서 작업이 시작되므로 호출스택의 맨 아래의 공간에 main 메소드의 공간이 할당되고, 그 안에서 다른 메소드를 호출하면 바로 위에 두번째로 호출된 메소드를 위한 공간이 마련된다.

두번째 메소드가 호출되면 첫번째 메소드는 수행을 멈추고, 두번째 메소드가 수행되기 시작한다. 두번째 메소드가 수행을 마치고 나면, 두번째 메소드를 위한 공간이 반환되면서 첫번째 메소드는 다시 수행을 이어간다. 

# 25/02/05 업데이트

`main()` 메소드는 단 하나의 예외로 호출스택에 쌓이지 않고, 정적 메모리에 미리 자리를 잡아두고 시작한다. 이는 자바 공식 문서인 [**JLS(Java Language Specification)**](https://docs.oracle.com/javase/specs/jls/se8/html/jls-12.html#jls-12.1.4)에 명시되어 있다. 

호출스택에 할당된다는 것은 잘못된 사실이다.

자바에서 제공하는 쓰레드는 독립적으로 수행되기 위해 각각의 스택을 할당받는다. 다시 말해, 쓰레드 1개당 독립적 스택 공간이 1개씩 존재하게 된다. 이 또한 쓰레드가 끝나는 즉시 반환된다.