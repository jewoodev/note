# Kotlin·Spring 프로젝트의 Gradle 컴파일 설정 이해하기

작성 기준: 2026-10-15

Kotlin으로 Spring 서버를 개발할 때 빌드 파일에는 Kotlin 버전, Java toolchain, JVM target, Spring 컴파일러 플러그인 같은 설정이 함께 등장한다. 각각은 코드의 문법 검사, 바이트코드 생성, 프레임워크 연동 등 서로 다른 문제를 다룬다.

이 문서는 특정 업무나 저장소 구조를 몰라도 읽을 수 있도록 각 도구의 역할부터 설명한다. Kotlin 1.9.25에서 2.4.21로 전환하면서 Java 17과 Spring Boot 3.5.16을 유지하는 사례를 사용한다.

## 1. 소스 코드가 서버에서 실행되기까지

Kotlin 소스 파일은 JVM이 바로 실행하는 파일이 아니다. 컴파일러가 `.kt` 소스를 JVM 바이트코드가 담긴 `.class` 파일로 바꾼다. 클래스와 필요한 라이브러리를 JAR로 묶고 JVM에서 실행할 수 있다.

```text
Kotlin 소스(.kt)
    ↓ Kotlin 컴파일러
JVM 바이트코드(.class)
    ↓ 패키징
애플리케이션 JAR + 필요한 라이브러리
    ↓ JVM
실행 중인 서버
```

여기에서 사용하는 용어를 구분하면 설정을 읽기 쉬워진다.

| 용어 | 역할 |
| --- | --- |
| JVM | 바이트코드를 실행하는 가상 머신 |
| JDK | JVM과 Java 개발 도구를 포함하는 개발 환경 |
| Kotlin 컴파일러 | Kotlin 소스를 분석하고 대상 플랫폼의 코드로 변환하는 도구 |
| Gradle | 의존성 해석·컴파일·테스트·패키징 작업을 연결하는 빌드 도구 |
| Gradle 플러그인 | Gradle에 특정 언어나 프레임워크의 빌드 기능을 추가하는 구성 요소 |
| Spring Framework | 객체 관리·웹 요청 처리·트랜잭션 같은 서버 기능을 제공하는 프레임워크 |
| Spring Boot | Spring 애플리케이션의 구성·실행·패키징을 돕는 도구와 라이브러리 |

Gradle은 빌드 전체를 조율하고, 실제 Kotlin 문법과 타입 검사는 Kotlin 컴파일러가 수행한다. Spring Boot 플러그인은 실행 가능한 JAR을 만드는 등의 작업을 추가한다.

## 2. `build.gradle.kts`와 Kotlin 플러그인의 관계

`build.gradle.kts`는 Kotlin 문법으로 작성하는 Gradle 설정 파일이다. 여기에서 사용하는 설정용 문법을 Gradle Kotlin DSL이라고 부른다. DSL은 특정 목적에 맞춘 언어 또는 API를 뜻한다.

빌드 설정 파일이 Kotlin 문법이라는 사실과, 애플리케이션을 Kotlin으로 컴파일한다는 사실은 구분해야 한다.

```kotlin
plugins {
    kotlin("jvm") version "2.4.21"
}
```

이 선언은 애플리케이션의 Kotlin/JVM 빌드를 위한 플러그인을 적용한다. Gradle 자체가 빌드 스크립트를 처리하는 데 사용하는 내장 Kotlin 버전까지 같은 값으로 바꾸는 선언은 아니다.

## 3. 두 Kotlin 플러그인은 무엇이 다른가?

다음과 같은 플러그인 구성을 보자.

```kotlin
plugins {
    kotlin("jvm") version "2.4.21"
    kotlin("plugin.spring") version "2.4.21"
    id("org.springframework.boot") version "3.5.16"
    id("io.spring.dependency-management") version "1.1.7"
}
```

`kotlin("jvm")`은 Kotlin 코드를 JVM 대상으로 컴파일하는 기능을 추가한다. 일반 애플리케이션 코드와 테스트 코드를 컴파일하는 태스크가 이 구성에 연결된다.

`kotlin("plugin.spring")`은 Spring과 함께 사용하기 위한 Kotlin 컴파일러 플러그인이다. 두 Kotlin 플러그인의 버전을 같이 맞추면 컴파일러와 컴파일러 확장이 같은 릴리스를 사용하게 된다.

### Kotlin의 `final`과 Spring 프록시

Kotlin 클래스와 메서드는 기본적으로 상속·재정의가 제한된다. 일반 클래스의 경우 `open`을 사용해 이를 허용할 수 있다.

Spring은 원래 객체 앞에 부가 동작을 수행하는 객체인 **프록시**를 두기도 한다. 예를 들어 외부 호출을 받아 트랜잭션을 시작한 다음 실제 서비스 메서드를 호출하고, 결과에 따라 커밋하거나 롤백할 수 있다.

```text
호출자 → Spring 프록시 → 서비스 메서드
             │
             └─ 트랜잭션 등 부가 동작
```

인터페이스 기반 프록시도 있지만, 클래스를 상속하는 방식의 프록시는 대상 클래스와 메서드의 `final` 제한에 영향을 받는다. `kotlin-spring`은 Spring 관련 어노테이션이 붙은 대상에 all-open 처리를 적용해 이 마찰을 줄인다. `@Service`처럼 `@Component`를 바탕으로 한 어노테이션도 대상이 될 수 있다.

아래 코드는 별도 프로젝트에서 개념을 설명하기 위한 예시다.

```kotlin
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class BookingService {
    @Transactional
    fun confirm() {
        // 예약 상태를 변경하는 업무 처리
    }
}
```

관련 의존성과 Spring 구성이 있는 환경에서는 Spring 플러그인이 필요한 대상의 상속·재정의를 허용하도록 컴파일을 돕는다. 애플리케이션의 모든 클래스를 무조건 공개하거나 Spring 객체로 등록하는 기능은 아니다.

또한 플러그인 적용만으로 트랜잭션의 실제 작동을 증명할 수는 없다. 프록시를 거치지 않는 자기 호출 등에는 별도의 제약이 있으므로 실제 호출 경로를 검증해야 한다. [Kotlin all-open·Spring 플러그인](https://kotlinlang.org/docs/all-open-plugin.html), [Spring 프록시 동작과 제약](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html)

## 4. `kotlinOptions`를 `compilerOptions`로 옮기는 이유

이전 빌드 설정은 컴파일 태스크를 찾아 옵션을 지정하는 형태였다.

```kotlin
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        freeCompilerArgs += "-Xjsr305=strict"
        javaParameters = true
        jvmTarget = "17"
    }
}
```

`tasks`는 Gradle 작업들의 집합이다. `withType<KotlinCompile>()`은 그중 Kotlin 컴파일 작업을 선택하고, `configureEach`는 선택된 작업에 설정을 적용한다. 애플리케이션 컴파일과 테스트 컴파일에 공통 옵션을 주는 데 사용할 수 있다.

새 설정은 프로젝트의 Kotlin 확장에 공통 옵션을 둔다.

```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

kotlin {
    jvmToolchain(17)
    compilerOptions {
        freeCompilerArgs.add("-Xjsr305=strict")
        javaParameters.set(true)
        jvmTarget.set(JvmTarget.JVM_17)
    }
}
```

Kotlin 공식 문서는 Kotlin 2.0부터 deprecated된 `kotlinOptions` 대신 타입이 있는 `compilerOptions` 사용을 안내한다. 이 사례는 설정 API를 전환하면서 기존 옵션의 의도를 보존한다. [컴파일 옵션 전환 가이드](https://kotlinlang.org/docs/gradle-compiler-options.html#migrate-from-kotlinoptions-to-compileroptions)

### 공통 기본값과 태스크별 설정의 차이

프로젝트 수준의 `compilerOptions`는 하위 컴파일 설정의 기본값이 된다. 특정 태스크에서 다른 값을 지정하면 더 구체적인 설정이 우선할 수 있다.

따라서 기존에 태스크별 재정의가 있는 프로젝트에서는 블록을 옮기는 것만으로 최종 옵션이 같다고 단정하면 안 된다. 애플리케이션·테스트·추가 source set의 컴파일 설정을 함께 확인한다. [설정 수준과 우선순위](https://kotlinlang.org/docs/gradle-compiler-options.html#how-to-define-options)

### `.set()`과 `.add()`를 사용하는 이유

Gradle의 설정 값은 단순 변수뿐 아니라 값을 나중에 계산하거나 연결할 수 있는 Property API로 표현된다. `javaParameters.set(true)`는 단일 값을 설정하고, `freeCompilerArgs.add(...)`는 옵션 목록에 항목을 추가한다.

이 API는 설정 시점과 실제 값 사용 시점을 분리하는 Gradle의 지연 구성 방식과 연결된다. 여기서 `.set()`을 사용했다고 해서 업무 코드의 실행이 비동기 작업으로 바뀌는 것은 아니다. [Gradle의 지연 구성](https://docs.gradle.org/current/userguide/lazy_configuration.html)

## 5. Kotlin 버전·JDK·JVM target은 서로 다른 축이다

다음 세 설정은 모두 다른 질문에 답한다.

| 설정 | 답하는 질문 | 예시 |
| --- | --- | --- |
| Kotlin 플러그인 버전 | 어떤 Kotlin 컴파일러·빌드 통합을 사용하는가? | `2.4.21` |
| Java toolchain | 빌드 작업에 어떤 JDK를 사용하는가? | `jvmToolchain(17)` |
| JVM target | 어떤 버전의 JVM 바이트코드를 생성하는가? | `JvmTarget.JVM_17` |

새 Kotlin 컴파일러를 사용해 Java 17 대상 바이트코드를 만들 수 있다. 따라서 Kotlin 2.4.21 전환과 JDK 25 전환을 별도 단계로 진행하는 구성이 가능하다.

```text
Kotlin 컴파일러 2.4.21
        +
Java toolchain 17
        +
JVM target 17
        ↓
Java 17 대상 애플리케이션 클래스
```

### Gradle을 실행하는 Java와 toolchain도 구분한다

Gradle 자체를 실행하는 JVM은 `JAVA_HOME` 등 실행 환경의 영향을 받는다. toolchain은 컴파일·테스트 등 해당 기능을 지원하는 작업에 사용할 JDK를 고르는 설정이다. 두 값이 항상 같은 것은 아니다.

Kotlin의 `jvmToolchain`은 관련 Java 컴파일·테스트 작업의 toolchain 설정에도 연결된다. 다만 모든 사용자 정의 실행 작업의 JVM까지 일괄적으로 바뀐다고 가정하지 말고 실제 작업 설정을 확인한다. [Kotlin toolchain 지원](https://kotlinlang.org/docs/gradle-configure-project.html#gradle-java-toolchains-support), [Gradle Java toolchain](https://docs.gradle.org/current/userguide/toolchains.html)

### JVM target만 낮춘다고 모든 호환성이 확보되는가?

바이트코드 형식과 사용 가능한 JDK API는 다른 문제다. 높은 JDK에서만 제공하는 API를 사용하면서 바이트코드 target만 낮추면 실행 환경과 맞지 않을 수 있다. 라이브러리 자체의 최소 Java 버전도 확인해야 한다.

toolchain과 target을 같은 버전으로 맞추는 것은 이런 혼동을 줄이는 출발점이다. 더 높은 JDK로 낮은 Java 버전을 대상으로 빌드할 때는 Java의 `--release`나 Kotlin의 관련 API 제한 옵션도 검토한다. [Gradle의 교차 컴파일 설명](https://docs.gradle.org/current/userguide/toolchains.html#sec:java_cross_compilation)

## 6. `-Xjsr305=strict`: Java와 Kotlin 사이의 null 계약

Kotlin은 `String`과 `String?`로 null 가능성을 구분한다. Java API는 어노테이션으로 null 가능성을 알리기도 한다. 이 정보가 부족하면 Kotlin에서 Java 타입을 다룰 때 컴파일 시점의 안전성에 한계가 생긴다.

`-Xjsr305=strict`는 JSR-305 계열 어노테이션을 바탕으로 한 null 계약 위반을 엄격하게 진단하도록 지정한다. 예를 들어 반환값을 nullable로 해석하는 API에서는 다음처럼 null 처리가 필요하다.

```kotlin
// Java API의 반환값이 Kotlin에서 String?로 해석된다고 가정한다.
val customerName: String? = javaDirectory.findName()

// customerName.length: nullable 값을 바로 사용하므로 컴파일 오류
val displayName = customerName ?: "이름 없음"
```

이 옵션은 모든 Java 어노테이션에 동일하게 적용되는 스위치가 아니다. JSpecify 등 다른 어노테이션 체계는 별도 규칙과 옵션을 가질 수 있다. 외부 라이브러리가 계약을 어기거나 강제 null 단언을 사용하면 실행 중 오류가 생길 수 있다.

또한 HTTP 요청의 필수값을 검사하는 `@NotNull` 같은 Bean Validation과는 역할이 다르다. 컴파일 시점의 타입 계약 검사와 실행 시점의 외부 입력 검증을 구분한다. [Java 상호 운용과 null 계약](https://kotlinlang.org/docs/java-interop.html#jsr-305-support)

## 7. `javaParameters`: 리플렉션에서 매개변수 이름 읽기

리플렉션은 실행 중 클래스·메서드·매개변수 정보를 살펴보는 기능이다. 예를 들어 다음 메서드에는 `customerId`라는 이름이 있다.

```kotlin
fun findBooking(customerId: Long) {
    // 조회 처리
}
```

Java 리플렉션으로 읽을 수 있는 매개변수 이름 메타데이터가 없으면 실제 이름 대신 `arg0` 같은 값이 보일 수 있다. `javaParameters.set(true)`는 이 이름 정보를 생성하도록 한다. 프레임워크의 이름 기반 처리에서 활용할 수 있다.

이 옵션은 Kotlin 고유 메타데이터나 `kotlin-reflect` 라이브러리와 동일한 기능이 아니다. 매개변수 이름을 저장한다고 모든 프레임워크의 바인딩 문제를 해결하는 것도 아니다. Spring Boot 플러그인도 Kotlin 컴파일에 Java 매개변수 이름 생성 설정을 적용하지만, 이 사례에서는 기존 명시적 설정을 유지했다. [Kotlin JVM 컴파일 옵션 API](https://kotlinlang.org/api/kotlin-gradle-plugin/kotlin-gradle-plugin-api/org.jetbrains.kotlin.gradle.dsl/-kotlin-jvm-compiler-options/), [Boot의 Kotlin 플러그인 연동](https://docs.spring.io/spring-boot/3.5/gradle-plugin/reacting.html#reacting-to-the-kotlin-plugin)

## 8. `"17"` 대신 `JvmTarget.JVM_17`을 사용하는 이유

이전 API는 JVM target을 문자열로 받았다.

```kotlin
jvmTarget = "17"
```

새 API에서는 대상 버전을 표현하는 타입을 사용한다.

```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

jvmTarget.set(JvmTarget.JVM_17)
```

숫자의 의미는 그대로 Java 17 대상이다. 타입이 있는 값은 지원되는 선택지를 코드로 표현하고 IDE 자동 완성과 설정 오류 진단을 돕는다. 같은 이유로 이전 설정에서 사용하던 `KotlinCompile` import를 제거하고 새 설정에 필요한 `JvmTarget`을 가져온다. [Kotlin JVM 컴파일 옵션 API](https://kotlinlang.org/api/kotlin-gradle-plugin/kotlin-gradle-plugin-api/org.jetbrains.kotlin.gradle.dsl/-kotlin-jvm-compiler-options/)

## 9. 컴파일러와 실행 라이브러리의 버전 정렬

컴파일러는 빌드 시점에 쓰고, 표준 라이브러리는 애플리케이션 실행 시점에도 필요하다. `kotlin-reflect`는 Kotlin 고유 구조를 리플렉션으로 다루는 기능을 제공한다. [Kotlin 리플렉션](https://kotlinlang.org/docs/reflection.html)

| 구성 요소 | 주된 역할 |
| --- | --- |
| Kotlin Gradle 플러그인·컴파일러 | 소스 분석·컴파일과 Gradle 작업 통합 |
| Kotlin Spring 컴파일러 플러그인 | 컴파일 과정에서 Spring 연동을 위한 all-open 처리 |
| `kotlin-stdlib` | 실행 코드가 사용하는 Kotlin 표준 기능 |
| `kotlin-reflect` | Kotlin 선언과 타입 구조를 실행 중 조사하는 기능 |

플러그인 버전만 변경하고 실제 의존성을 보지 않으면 이전 라이브러리가 선택되었는지 놓칠 수 있다. Spring Boot 3.5 플러그인은 Kotlin 플러그인 버전을 감지해 의존성 관리의 `kotlin.version`을 정렬한다. 다른 BOM·직접 지정 버전·제약 조건이 있다면 최종 해석 결과까지 확인한다. [Boot의 버전 정렬 동작](https://docs.spring.io/spring-boot/3.5/gradle-plugin/reacting.html#reacting-to-the-kotlin-plugin)

각 라이브러리에 버전을 중복해서 쓰기 전에 플러그인·의존성 관리가 제공하는 정렬 방식을 확인한다. 마지막 판단 근거는 해석된 의존성과 실제 배포 산출물이다.

## 10. 전환을 검증하는 방법

설정 문법이 맞다는 것과 애플리케이션이 같은 동작을 유지한다는 것은 별도로 검증한다.

| 검증 경계 | 확인할 내용 |
| --- | --- |
| 컴파일 | 애플리케이션·테스트 코드가 새 컴파일러에서 컴파일되는가? |
| 기존 테스트 | 실행 대상·테스트 수·실패·건너뜀에 예상하지 못한 변화가 없는가? |
| 의존성 | stdlib·reflection의 최종 선택 버전은 무엇인가? |
| JAR | 실제 포함 라이브러리와 애플리케이션 클래스 버전이 의도와 맞는가? |
| 실행 환경 | 서버·컨테이너·CI가 필요한 Java 버전으로 실행되는가? |

일반적인 프로젝트에서는 다음과 같이 의존성 선택 근거를 확인할 수 있다. 명령은 해당 Gradle 프로젝트 디렉터리에서 실행한다.

```bash
./gradlew dependencyInsight --configuration runtimeClasspath --dependency kotlin-stdlib
./gradlew dependencyInsight --configuration runtimeClasspath --dependency kotlin-reflect
```

컴파일한 클래스와 JAR은 JDK 도구로 살펴볼 수 있다.

```bash
javap -verbose path/to/SomeClass.class
jar tf build/libs/application.jar
```

`javap`의 major version 61은 Java 17, 69는 Java 25에 해당한다. [JVM 클래스 파일 버전 표](https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-4.html#jvms-4.1)

JAR 파일명·클래스 경로는 각 프로젝트에 맞춰 바꾼다. Spring Boot 실행 JAR에서는 애플리케이션 클래스가 `BOOT-INF/classes`, 실행 라이브러리가 `BOOT-INF/lib` 아래에 들어갈 수 있다. [Boot의 실행 JAR 구성](https://docs.spring.io/spring-boot/3.5/gradle-plugin/reacting.html#reacting-to-the-java-plugin)

### 사례에서 확인한 결과와 한계

이 문서의 출발점이 된 전환에서는 Kotlin JVM·Spring 플러그인을 1.9.25에서 2.4.21로 변경하고, 기존 컴파일 옵션을 새 DSL로 옮겼다. JDK 17·Gradle 8.14.5·Boot 3.5.16을 유지한 상태에서 기존 테스트 864개와 JAR 빌드가 통과했다.

생성된 JAR의 stdlib·jdk7·jdk8·reflection 라이브러리는 모두 2.4.21이었다. 애플리케이션 클래스 major version은 61이었다. 일부 기존 코드에 대한 새 컴파일 경고는 기록했으며, 경고를 숨기거나 테스트를 제외하는 설정을 추가하지 않았다.

이는 해당 시점의 로컬 검증 기록이다. 이 문서 작성 과정에서 테스트를 다시 실행한 결과나, 이후 JDK 25·Boot 4 전환 및 운영 배포의 성공 증거로 해석하지 않는다.

## 11. 다른 프로젝트에 적용할 때의 확인 질문

1. Kotlin 컴파일러와 Spring 컴파일러 플러그인의 버전이 맞는가?
2. Gradle 실행 JVM·toolchain·바이트코드 target을 각각 설명할 수 있는가?
3. 설정 DSL을 바꾸면서 null 검사·매개변수 메타데이터 같은 기존 옵션을 보존했는가?
4. 공통 기본값을 덮어쓰는 태스크별 옵션이 있는가?
5. 실행에 포함되는 stdlib·reflection의 실제 버전을 확인했는가?
6. 기존 테스트의 범위를 유지했고, 동작 변화와 새 경고를 구분했는가?
7. 컴파일 성공 외에 최종 JAR과 실제 실행 환경도 확인했는가?

## 참고 자료

- [Kotlin Gradle 프로젝트 설정](https://kotlinlang.org/docs/gradle-configure-project.html)
- [Kotlin 컴파일 옵션과 전환 방법](https://kotlinlang.org/docs/gradle-compiler-options.html)
- [Kotlin all-open·Spring 컴파일러 플러그인](https://kotlinlang.org/docs/all-open-plugin.html)
- [Kotlin과 Java의 null 계약](https://kotlinlang.org/docs/java-interop.html)
- [Spring 프록시 동작](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html)
- [Spring Boot 3.5 Gradle 플러그인의 Kotlin 연동](https://docs.spring.io/spring-boot/3.5/gradle-plugin/reacting.html)
- [Gradle Java toolchain](https://docs.gradle.org/current/userguide/toolchains.html)
- [Gradle의 지연 구성](https://docs.gradle.org/current/userguide/lazy_configuration.html)
