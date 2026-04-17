컨트롤러 메소드의 인자에 @RequestParam, @RequestBody 애노테이션을 사용할 때 nullable 타입을 사용하면 내부적으로 required가 false로 설정된다.

그걸 의도한 것이라면 괜찮지만 그렇지 않은 경우가 더 많다. 따라서 nullable 타입은 기본적으로 사용하지 않는 쪽으로 컨벤션을 설정하는 것이 좋다.