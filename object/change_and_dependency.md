# 변경과 의존성

절차적으로 작성된 코드에서 데이터를 수정하면 항상 하나 이상의 코드를 수정해야 하는 이유는, 의존하고 있는 관계에서 온다. 절차 지향적인 설계에서 프로세스는 현실 세계의 논리를 구현하기 위해 다수의 데이터에 의존하게 된다. 

예를 들어 E-commerce 서비스에서 상품을 구입하는데 드는 비용을 결정하는 논리를 구현하기 위해서 상품들의 정보, 할인이 적용될 수 있는 정책(종류, 할인 금액 or 할인율), 배송지 위치와 같은 데이터가 필요하다. E-commerce의 서비스에는 각 데이터들이 필요한 논리들이 비용을 결정하는 것 외에도 여러가지 있을 수 있다. 그리고 관계는 E-commerce 서비스가 상품들의 정보, 할인 정책 등의 데이터들에 의존하고 있는 관계이다.

그런데 의존성의 방향과 변경의 방향은 반대로, 데이터가 변경되면 데이터에 의존하고 있는 서비스의 논리마다 변경할 필요가 생기는 것이다. 이렇듯 변경의 파급효과는 의존성으로 부터 온다.

절차지향적 설계에서는 위에서 살펴본 이유로 변경에 취약하다. 이 문제를 해결하려면 의존성을 줄여야 할 것이다. 의존성을 줄이려면 데이터의 의존성이 서비스에 흘러들어오지 않게, 데이터를 사용하는 프로세스를 해당 데이터 안에 위치시키면 가능하지 않을까? 이런 지향점에서 **객체지향의 바탕**을 이루는 가장 기본적인 개념이 만들어졌다.

# 참고자료

- [조영호님의 오브젝트 기초편](https://www.inflearn.com/course/%EC%98%A4%EB%B8%8C%EC%A0%9D%ED%8A%B8-%EA%B8%B0%EC%B4%88%ED%8E%B8-%EA%B0%9D%EC%B2%B4%EC%A7%80%ED%96%A5/dashboard)