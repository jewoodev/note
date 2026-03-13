# Collection
코틀린은 앞에 Mutable이 붙은 컬렉션 인터페이스를 추가로 가지고 있다. 코틀린에서 `List`, `Set`, `Map`은 Collection을 만들자 마자 `Collections.unmodifableList()` 등을 붙여준 것이라고 생각하면 된다. 코틀린은 불변/가변을 지정해주어야 한다는 점을 꼭 기억하자.

불변 컬렉션이라고 하더라도 Referece Type인 Element의 필드는 바꿀 수 있다.