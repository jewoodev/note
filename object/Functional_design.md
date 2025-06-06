# 절차적인 설계

프로그램은 일반적으로 데이터와 데이터를 사용하는 프로세스의 조합으로 정의된다. 

그리고 프로그램을 절차적으로 구현하는 방식은 프로그램을 구성하는 데이터와 프로세스를 개별적인 모듈로 분리해서 구현하는 걸 의미한다. 데이터와 프로세스를 구현하는 순서는 데이터 정의 &rarr; 프로세스 설계이다. 

절차적으로 작성된 코드가 갖는 특징이 있는데, 객체의 타입을 판별하고 그 결과에 따라 어떤 작업을 해야 하는지를 해당 객체의 내부가 아닌 외부에서 결정한다는 점이다.

그리고 데이터 접근 객체와 데이터를 저장하고 있는 객체 등의 모든 실행 흐름이, 프로세스를 구현한 객체 안으로 집중되는 방식, 즉 중앙 집중식 제어 스타일을 띈다는 점도 있다.

두번째 언급한 특징은 응집도와 결합도 측면에서 코드를 수정할 때 많은 문제를 야기한다. 

# 참고자료

- [조영호님의 오브젝트 기초편](https://www.inflearn.com/course/%EC%98%A4%EB%B8%8C%EC%A0%9D%ED%8A%B8-%EA%B8%B0%EC%B4%88%ED%8E%B8-%EA%B0%9D%EC%B2%B4%EC%A7%80%ED%96%A5/dashboard)