코틀린은 null이 될 수 있는 타입을 완전한 별도의 타입으로 취급한다.

# Safe call
- `?.`은 수신 객체(좌항)가 null이 아닐 때만 멤버에 접근(우항 실행)한다.
  - null이 가능한 타입만을 위한 기능이다.
  - `str?.length` 처럼 null이 될 수 있는 변수에 `?`를 붙이면 사용되는 기능이다.
  - null이면 즉시 null을 반환하여 NPE를 방지

# Elvis 연산자
- null이 될 수 있는 변수에 `?:`를 붙이면 사용되는 기능이다.
  - null이면 실행하지 않고 `str ?: "default"` 코드를 null로 대체한다.
  - null이 아니면 `str`을 그대로 사용한다.
  - null이면 `"default"`를 사용한다.

# 널 아님 단언!! (Not-Null Assertion)
- null이 아님을 단언해야 할 때 사용하는 기능이다.
  - `str!!.length` 처럼 null이 될 수 없는 변수에 `!!`를 붙이면 된다.
  - 혹시 null이 오면 NPE가 발생하므로 정말 null이 올 수 없을 때만 사용해야 한다.