# SOLID

컴퓨터 프로그래밍에서 SOLID라는 단어는 로버트 C.마틴이 2000년대 초반에 명명한 객체 지향 프로그래밍 설계의 다섯 가지 원칙을 마이클 페더스가 두문자어 기억술로 소개한 것이다. 프로그래머가 시간이 지나도 유지 보수와 확장이 쉬운 시스템을 만들고자 할 때 이 원칙들을 함께 적용할 수 있다. 

| 두문자 | 약어  | 개념                                                                                                                                                                                                                    |
|-----|-----|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| S   | SRP | [단일 책임 원칙(Single responsibility principle)](https://ko.wikipedia.org/wiki/%EB%8B%A8%EC%9D%BC_%EC%B1%85%EC%9E%84_%EC%9B%90%EC%B9%99)<br/>한 클래스는 하나의 책임만 가져야 한다.                                                        |
| O   | OCP | [개방-폐쇄 원칙 ((Open/closed principle)](https://ko.wikipedia.org/wiki/%EA%B0%9C%EB%B0%A9-%ED%8F%90%EC%87%84_%EC%9B%90%EC%B9%99)<br/>"소프트웨어 요소는 확장에는 열려 있으나 변경에는 닫혀 있어야 한다."                                               |
| L   | LSP | [리스코프 치환 원칙 (Liskov substitution principle)](https://ko.wikipedia.org/wiki/%EB%A6%AC%EC%8A%A4%EC%BD%94%ED%94%84_%EC%B9%98%ED%99%98_%EC%9B%90%EC%B9%99)<br/>"프로그램의 객체는 프로그램의 정확성을 깨뜨리지 않으면서 하위 타입의 인스턴스로 바꿀 수 있어야 한다." |
| I   | ISP | [인터페이스 분리 원칙(Interface segregation principle)](https://ko.wikipedia.org/wiki/%EC%9D%B8%ED%84%B0%ED%8E%98%EC%9D%B4%EC%8A%A4_%EB%B6%84%EB%A6%AC_%EC%9B%90%EC%B9%99)<br/>"특정 클라이언트를 위한 인터페이스 여러 개가 범용 인터페이스 하나보다 낫다."    |
| D   | DIP | [의존관계 역전 원칙 (Dependency inversion principle)](https://ko.wikipedia.org/wiki/%EC%9D%98%EC%A1%B4%EA%B4%80%EA%B3%84_%EC%97%AD%EC%A0%84_%EC%9B%90%EC%B9%99)<br/>프로그래머는 "추상화에 의존해야지, 구체화에 의존하면 안된다."                                                                                                                               |

# 참고자료

[위키백과](https://ko.wikipedia.org/wiki/SOLID_(%EA%B0%9D%EC%B2%B4_%EC%A7%80%ED%96%A5_%EC%84%A4%EA%B3%84))