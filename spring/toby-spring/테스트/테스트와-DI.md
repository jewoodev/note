BigDecimal을 비교할 때 `isEqaulTo()`를 사용하는 것은 굉장히 위험하다. 이는 `eqauls()` 메소드를 사용해 동일 여부를 반환하는데, BigDecimal은 값의 숫자뿐만 아니라 유효 자릿수까지 따지는 클래스이기 때문이다. A는 소수점 이하 둘째 자리까지만 유효하게 만들었고, B는 여섯째 자리까지 유효하게 만들었다고 가정하자. 그러면 둘의 값이 똑같으면 `true`를 반환해야 하는데 `eqauls()`는 false를 반환하기 때문에 `isEqualByComparingTo()`를 사용해야 한다.

> `isEqualByComparingTo()` asserj에서 사용하는 것으로, 내부적으로 `comparingTo()`를 사용함

`isEqualByComparingTo()`에 대해서는 참고자료를 참고하자.