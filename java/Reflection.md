# 리플렉션이란?
구체적인 클래스 타입을 알지 못해도, 그 클래스의 메소드, 타입, 변수들에 접근할 수 있도록 해주는 자바 API.

# 리플렉션과 기본 생성자
> Almost all frameworks require a default(no-argument) constructor in your class because these frameworks use reflection to create objects by invoking the default constructor.

[Deserialize json with Java parameterized constructor](https://blogs.jsbisht.com/blogs/2016/09/12/deserialize-json-with-java-parameterized-constructor)에서 언급되는 표현이다. 리플렉션은 기본 생성자를 반드시 필요로 한다는 이야기인데, 그 이유는 뭘까?

자바에서 제공하는 리플렉션(Reflection)은 C, C++과 같은 언어를 비롯한 다른 언어에서는 볼 수 없는 기능이다. 이미 로딩이 완료된 클래스에서 또 다른 클래스를 동적으로 로딩(Dynamic Loading)하여 생성자(Constructor), 멤버 필드(Member Variables) 그리고 멤버 메서드(Member Method) 등을 사용할 수 있도록 한다. 그런데 리플렉션이 가져올 수 없는 정보 중 하나가 바로 생성자의 인자 정보들이다. 즉, 기본 생성자 없이 파라미터가 있는 생성자만 존재한다면 java Reflection이 객체를 생성할 수 없게 되는 것이다.
