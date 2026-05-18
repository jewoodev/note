# for each 
```kotlin
for (item in items) {
    // do something
}

for (i in 1..10) {
    // do something
}

for (i in 10 downTo 1) {
    // do something
}
```
코틀린에서는 `:` 대신 `in`을 사용한다. `in` 뒤에는 자바와 동일하게 Iterable이 구현된 객체라면 모두 올 수 있다.

```
for (int i = 0; i < 10; i += 2) {
}
```
이거는 

```kotlin
for (i in 0..9 step 2) {
    // do something
}
```
로 치환된다.

# Progression과 Range
위에서 보여진 `1..10`은 IntRange라는 실제 클래스를 통해 생성된다. 그리고 이건 IntProgression이라는 걸 상속받는다. IntProgression을 직역하면 등차수열이다.

그러니까 사실 `10 downTo 1` 등등의 코드는 등차수열을 만드는 코드다. `downTo`와 `step`은 (중위 호출 )함수다.