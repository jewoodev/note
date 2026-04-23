코틀린은 자바와 다르게 모든 예외를 Unchecked Exception으로 간주한다.

# try-with-resources
코틀린에서는 try-with-resources 구문이 제공되지 않고, use 블록을 사용하여 자원을 안전하게 관리할 수 있다.

```kotlin
fun main() {
    BuffredReader(InputStreamReader(System.`in`)).use { br ->
        println(br.readLine())
    }
}
```