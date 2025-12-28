백엔드 개발에서 VO와 DTO는 데이터를 담는 객체다. 둘은 목적과 특성에서 차이를 보인다.

## DTO (Data Transfer Object)
DTO는 **계층 간 데이터 전송**을 위한 객체이다. 주로 클라이언트-서버 간, 또는 애플리케이션의 서로 다른 레이어 간에 데이터를 주고받을 때 사용한다.

- **주요 특징:**
  - 순수하게 데이터를 운반하는 역할만 수행 (로직 없음)
  - getter/setter를 가짐
  - 가변(mutable) 객체
  - 필요에 따라 여러 엔티티의 데이터를 조합할 수 있음

```java
public class UserDTO {
private Long id;
private String username;
private String email;

    *// getter, setter*
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    *// ...*
}
```
- **사용 예시:**
  - API 요청/응답 데이터
  - 컨트롤러에서 서비스로 데이터 전달
  - 엔티티를 그대로 노출하지 않고 필요한 필드만 전송

## VO (Value Object)
VO는 **값 그 자체를 표현**하는 불변 객체다. 도메인에서 특정 값을 의미 있게 표현할 때 사용한다.

- **주요 특징:**
  - 불변(immutable) 객체 - 한번 생성되면 변경 불가
  - 값이 같으면 동일한 객체로 취급 (equals/hashCode 오버라이드 필수)
  - setter가 없고 생성자로만 값 설정
  - 도메인 로직을 포함할 수 있음

```java
public class Money {
private final BigDecimal amount;
private final String currency;

    public Money(BigDecimal amount, String currency) {
        this.amount = amount;
        this.currency = currency;
    }
    
    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("통화가 다릅니다");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Money money = (Money) o;
        return Objects.equals(amount, money.amount) && 
               Objects.equals(currency, money.currency);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(amount, currency);
    }
}
```
- **사용 예시:**
  - 주소, 금액, 좌표, 날짜 범위 등
  - 도메인 모델에서 개념적으로 하나의 값을 나타낼 때

## 정리

| 구분     | DTO       | VO           |
|--------|-----------|--------------|
| 목적     | 데이터 전송    | 값 표현         |
| 가변성    | mutable   | immutable    |
| 동등성    | (주로)참조 비교 | 값 비교(equals) |
| 로직     | 없음        | 도메인 로직 포함 가능 |
| Setter | 있음        | 없음           |


실무에서 Spring을 사용할 때는 API 요청/응답에 DTO를 사용하고, 도메인 모델 내부에서 의미 있는 값 표현이 필요할 때 VO를 사용하는 게 일반적이다.