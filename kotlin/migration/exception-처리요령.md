예외를 던지는 코드를 하나의 함수로 추출해 코드 양을 줄일 수 있다.

```kotlin
fun clientFault(): Nothin {
    throw IllegalArgumentException("client fault")
}
```

JPA의 조회 메서드를 확장해서 null 처리하는 부분까지 함수로 추출하는 응용도 가능하다.

```kotlin
fun <T, ID> CrudRepository<T, ID>.findByIdOrThrow(id: ID): T {
    return this.findByIdOrNull(id) ?: throw IllegalArgumentException("있을 수 없는 에러가 발생했습니다: while findById($id)")
}
```