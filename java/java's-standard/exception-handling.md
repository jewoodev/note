# 1. 예외 처리
## 1.9 자동 자원 반환 - try-with-resources문
JDK 1.7부터 try-with-resources문이라는 try-catch문의 변형이 새로 추가되었다. 이 구문은 주로 '입출력'과 관련된 클래스를 사용할 때 유용하다.

이 걸 사용하면 finally 블럭 안에서 `close()`를 처리하지 않아도 되기 때문이다. finally 블럭 안에서 처리하게 되면, `close()` 수행 중에서도 예외가 발생할 수 있기 때문에 finally 블럭 안에서 또 다른 try 문을 만들고 결과적으로 코드 가독성이 나빠진다. 더 큰 문제는 try 블럭과 finally 블럭 모두에서 예외가 발생하면, **try 블럭의 예외는 무시된다**는 점이 있다. 

이런 문제점을 개선하기 위해 try-with-resources문이 추가되었다. 

try-with-resources문의 괄호() 안에 객체를 생성하는 문장을 넣으면, 그 객체는 따로 `close()`룰 호출하지 않아도 try 블럭을 벗어나는 순간 자동적으로 `close()`가 호출된다. 