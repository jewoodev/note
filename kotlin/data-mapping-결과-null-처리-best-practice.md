# 이론적 접근
Kotlin에서는 null 처리를 위해 Optional보다 언어 자체의 nullable 타입 시스템을 사용하는 것이 best practice 이다.

## Nullable 타입 반환 (가장 권장)
```kotlin
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): User?  // Optional<User> 대신
}


// 사용
val user = userRepository.findByEmail("test@example.com")
if (user != null) {
    // user는 자동으로 non-null로 스마트 캐스팅됨
    println(user.name)
}

// 또는 safe call 연산자
val userName = userRepository.findByEmail("test@example.com")?.name

// 엘비스 연산자로 기본값 제공
val user = userRepository.findByEmail("test@example.com")
    ?: throw UserNotFoundException()
```

## Result 타입 활용 (Kotlin 1.5+)
```kotlin
fun findUserByEmail(email: String): Result<User> {
return runCatching {
    userRepository.findByEmail(email)
        ?: throw UserNotFoundException("User not found: $email")
    }
}

// 사용
findUserByEmail("test@example.com")
    .onSuccess { user -> println(user.name) }
    .onFailure { error -> logger.error("Failed", error) }
```

3. Service Layer에서의 패턴
```kotlin
@Service
class UserService(
private val userRepository: UserRepository
) {
    // 1. nullable 반환 - 조회만 하는 경우
    fun getUserByEmail(email: String): User? {
    return userRepository.findByEmail(email)
}

// 2. 예외 발생 - 반드시 있어야 하는 경우
fun getRequiredUser(email: String): User {
    return userRepository.findByEmail(email)
        ?: throw UserNotFoundException("User not found: $email")
}

// 3. sealed class 활용 - 상세한 결과 표현
fun findUser(email: String): UserResult {
    return userRepository.findByEmail(email)
        ?.let { UserResult.Success(it) }
        ?: UserResult.NotFound
    }
}

sealed interface UserResult {
    data class Success(val user: User) : UserResult
    object NotFound : UserResult
    data class Error(val message: String) : UserResult
}
```

## Spring Data JPA에서 Kotlin 설정
```
// build.gradle.kts
plugins {
kotlin("plugin.jpa") version "1.9.0"
kotlin("plugin.spring") version "1.9.0"
}

dependencies {
implementation("org.jetbrains.kotlin:kotlin-reflect")
}
```

```kotlin
// Repository에서 자동으로 nullable 처리
interface UserRepository : JpaRepository<User, Long> {
fun findByEmail(email: String): User?
fun findAllByStatus(status: String): List<User>  // 빈 리스트 반환
}
```
## let, run, also 등 스코프 함수 활용
```kotlin
// let - null이 아닐 때만 실행
userRepository.findByEmail(email)?.let { user ->
    logger.info("Found user: ${user.name}")
    sendWelcomeEmail(user)
}

// 체이닝
userRepository.findByEmail(email)
    ?.takeIf { it.isActive }
    ?.also { logger.info("Active user found") }
    ?.let { processUser(it) }
    ?: logger.warn("No active user found")
```

## 핵심 포인트
- **Optional 대신 nullable을 사용하는 이유**:
  - Kotlin의 null safety가 컴파일 타임에 체크됨 
  - 더 간결하고 읽기 쉬운 코드 
  - 불필요한 wrapping/unwrapping 제거 
  - 스마트 캐스팅 활용 가능
- **상황별 선택**:
  - 단순 조회: User? 반환 
  - 필수 데이터: 예외 발생 또는 User (non-null) 반환 
  - 복잡한 결과: sealed class나 Result 타입 사용

- [관련 LLM 논의](https://claude.ai/chat/637ef4c9-1314-4447-87ec-0224f97918d7)