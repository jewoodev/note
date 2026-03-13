# filter & map
```kotlin
// 함수를 인자로 받는 filter 함수를 사용하여 20세 이상인 학생 필터링
val jewoo = students.filter { it.name == "Jewoo" } // students는 Collection

// 필터에서 인덱스가 필요한 경우
val jewooIndex = students.filterIndexed { index, student ->
    println("index: $index")
    student.age >= 20
}

// 필터링한 객체를 무언가로 매핑하고 싶으면
val jewooName = students.filter { it.age >= 20 }.map { it.name }

// 맵에서 인덱스가 필요한 경우
val jewooNameWithIndex = students.filter { it.age >= 20 }.mapIndexed { index, student ->
    println("index: $index")
    student.name
}

// 맵에서 결과가 null이 아닌 것만 가져오고 싶다면
val jewooNameNotNull = students.filter { it.age >= 20 }.mapNotNull { it.name }
```

# 다양한 컬렉션 처리 기능
- all
  - 조건을 모두 만족하면 true / 그렇지 않으면 false
    ```kotlin
    val isAllAdult = students.all { it.age >= 20 }
    ```
- none
  - 조건을 모두 불만족하면 true / 그렇지 않으면 false
    ```kotlin
    val isNoneAdult = students.none { it.age >= 20 }
    ```
- any
  - 조건을 하나라도 만족하면 true / 그렇지 않으면 false
    ```kotlin
    val isAnyAdult = students.any { it.age >= 20 }
    ```
- count
  - 개수를 셈
    ```kotlin
    val countAdult = students.count()
    ```
- sortedBy
  - (오름차순) 정렬
    ```kotlin
    val fruitCount = fruits.sortedBy { it.price }
    ```
- sortedByDescending
  - (내림차순) 정렬
    ```kotlin
    val fruitCount = fruits.sortedByDescending { it.price }
    ```
- distinctBy
  - 변형된 값을 기준으로 중복을 제거
    ```kotlin
    val distinctFruitNames = fruits.distinctBy { it.name }
        .map { it.name }
    ```
- first / firstOrNull
  - 첫 번째 값을 가져옴(무조건 null이 아니어야 함) / 첫 번째 값 또는 null을 가져옴
- last / lastOrNull
  - 마지막 값을 가져옴(무조건 null이 아니어야 함) / 마지막 값 또는 null을 가져옴

# List를 Map으로
```kotlin
// value에 List가 들어가는 경우 groupBy
val studentMap: Map<String, List<Student>> = students.groupBy { it.name }

// value에 단일 객체가 들어가는 경우 associateBy
val studentMap: Map<String, Student> = students.associateBy { it.name }

// {학생 이름 -> 학생 학년} Map이 필요한 경우
val studentAgeMap: Map<String, List<Int>> = students.groupBy({ it.name }, { it.age }) 

// {id -> 학생 학년} Map이 필요한 경우
val studentAgeMap: Map<Int, Int> = students.associateBy({ it.id }, { it.age })

// 다른 기능과 함께 사용하면
val jewooAgeMap: Map<String, List<Int>> = students.groupBy { it.name }
    .filter { (key, value) -> key == "Jewoo" }
```

```kotlin
// 자바의 flatMap도 사용 가능
val studentsInList: List<List<Student>> = listOf(// ...
  listOf(
    // ...
  )
)

val notGraduateStudents = studentsInList.flatMap { list ->
    list.filter { it.grade < 3 }
}
```
위의 중접된 람다 함수는 확장 함수로 리팩터링할 수 있다. 아래를 참고하자.

```kotlin
val notGraduateStudents = studentsInList.flatMap { list -> list.notGraduateFilter }

val List<Student>.notGraduateFilter: List<Student>
get() = this.filter(Student::isNotGraduate)

data class Student(
    val studentId: Long,
    val name: String,
    val grade: Int,
) {
    val isNotGraduate: Boolean
        get() = grade < 3
}
```

- `List<List<Student>>`를 `List<Student>`로 바꿔야 할 때
  ```kotlin
  studentsInList.flatten()
  ```
