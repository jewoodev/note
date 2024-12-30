# String 검증 기능

스프링에서 제공하는 프로퍼티 검증 기능 중 String에 `@NotBlank`, `@NotNull`, `@NotEmpty` 가 있는데 각각이 같은 것인지 헷갈린다. 따라서 아래에 차이점을 정리하겠다.

- `@NotNull`: "", "   " (Null은 걸러내는데 빈 문자열과 공백을 걸러내지 못한다.)
- `@NotEmpty`: "    " (공백을 걸러내지 못한다.)
- `@NotBlank`: 공백까지 걸러낸다.

설명이 단소화되었지만, 위에서 아래로 갈 수록 걸러내는 것이 추가되는 것으로 이해하면 된다.