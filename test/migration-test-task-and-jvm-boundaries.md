# 마이그레이션 테스트 분리에서 배운 실행 경계와 검증 범위 설계

**테스트의 책임을 나누는 것과 실행 자원의 수명을 나누는 것은 서로 다른 설계다.** 테스트 클래스와 데이터베이스를 구분했더라도 같은 JVM에서 실행하면 프로세스 안의 상태와 자원 수명은 계속 묶일 수 있다. 실행 목적이 다른 테스트는 분류, 프로세스, 실행 순서, 전체 검증 포함 여부를 각각 명시해야 한다.

이 글은 Kotlin·Spring Boot·Gradle 기반 업무 시스템에서 마이그레이션 테스트를 별도 실행 태스크로 분리한 PR #316을 정리한다. 특정 업무 기능을 몰라도 이해할 수 있도록 문제와 설정의 의미, 확인해야 할 증거를 설명한다.

## 1. 배경: 두 종류의 통합 테스트가 같은 실행 태스크에 있었다

이 시스템에는 실제 애플리케이션과 DB의 연결을 검증하는 일반 통합 테스트와, 과거 DB를 새 구조로 바꾸는 마이그레이션 테스트가 있었다.

| 종류 | 검증하려는 질문 | 테스트 준비 방식 |
| --- | --- | --- |
| 일반 통합 테스트 | 서비스와 저장소, 세션 등이 연결됐을 때 기대대로 동작하는가? | 애플리케이션 구성과 필요한 저장소를 연결 |
| 마이그레이션 테스트 | 이전 스키마와 데이터가 새 구조로 올바르게 바뀌는가? | 이전 버전의 DB 구성 → 기존 데이터 입력 → 변경 적용 |

마이그레이션은 테이블·컬럼·제약 조건과 기존 데이터를 변경하는 작업이다. 이 사례에서는 Flyway가 버전별 SQL을 적용하고, Testcontainers가 테스트용 MySQL을 실행했다.

변경 전에는 이름이 `IT`로 끝나는 테스트를 모두 `integrationTest`라는 Gradle 태스크에서 실행했다. 마이그레이션 테스트도 그 안에 포함됐다. 별도의 테스트 기반 클래스와 MySQL 컨테이너는 이미 있었지만, 일반 통합 테스트와 실행 JVM은 분리되지 않았다.

따라서 이번 변경을 “DB를 처음 분리했다”거나 “마이그레이션 검증을 새로 만들었다”라고 읽으면 부정확하다. 변경의 중심은 **이미 있던 테스트의 실행 단위를 분리한 것**이다.

## 2. 태그, 태스크, JVM, 컨테이너는 서로 다른 경계다

| 경계 | 이 사례에서의 역할 |
| --- | --- |
| 테스트 클래스 | 관련 시나리오와 검증 코드의 묶음 |
| JUnit 태그 | 실행할 테스트를 선택하기 위한 분류 정보 |
| Gradle `Test` 태스크 | 어떤 테스트를 어떤 설정으로 실행할지 정의하는 단위 |
| 테스트 JVM | Java·Kotlin 테스트가 실행되는 프로세스 |
| MySQL 컨테이너 | 테스트 JVM 밖에서 실행되는 DB 서버 |

`@Tag("migration")`만 붙인다고 프로세스가 나뉘지는 않는다. 별도 `Test` 태스크를 정의하고 서로 다른 필터를 적용해야 실행 경계가 생긴다.

Gradle은 테스트를 빌드 프로세스와 분리된 JVM에서 실행한다. 이번 변경에서는 일반 통합 테스트와 마이그레이션 테스트를 각각의 `Test` 태스크로 실행하도록 구성했다. 같은 테스트 클래스 출력과 런타임 클래스패스를 사용하면서도 테스트 프로세스를 분리할 수 있다. [Gradle JVM 테스트 문서](https://docs.gradle.org/current/userguide/java_testing.html)

이 방식은 테스트 소스 디렉터리나 의존성 구성을 새로 나누지 않고 실행 경계부터 바꿀 수 있게 한다. 별도 소스 세트가 반드시 필요한 것은 아니다.

## 3. 공통 기반 클래스에 분류 규칙을 연결한다

마이그레이션 테스트는 이미 `MigrationITBase`를 상속하고 있었다. 이번 변경은 이 기반 클래스에 태그를 추가했다.

```kotlin
@Tag("migration")
abstract class MigrationITBase {
    // 공통 MySQL 컨테이너, Flyway 초기화와 마이그레이션 실행 지원
}
```

그 결과 기반 클래스를 상속하는 테스트들이 같은 실행 분류를 사용한다. 당시에는 8개 클래스가 이 기반을 직접 상속하고 있었다.

이 접근은 개별 클래스마다 태그를 반복해서 붙이는 부담을 줄인다. 새 마이그레이션 테스트를 작성할 때 공통 DB 준비 코드와 실행 분류를 함께 얻는다.

다만 상속 규칙을 따르지 않고 새 클래스를 만들면 태그가 빠질 수 있다. 따라서 기반 클래스와 이름 규칙을 문서화하고 실제 선택 결과도 확인해야 한다. 공통화는 실수를 줄이는 장치이지, 모든 누락을 자동으로 막는 장치는 아니다.

## 4. 포함과 제외를 한 쌍으로 설계한다

별도 태스크를 추가하는 것만으로는 충분하지 않다. 기존 태스크에도 같은 테스트가 남으면 전체 검증에서 두 번 실행된다. 반대로 기존 태스크에서 제외만 하고 전체 검증에 새 태스크를 연결하지 않으면 실행되지 않는다.

당시 설정은 다음과 같이 나눴다.

| 태스크 | 클래스 이름 조건 | 태그 조건 |
| --- | --- | --- |
| `test` | `*IT.class` 제외 | 별도 migration 필터 없음 |
| `integrationTest` | `*IT.class` 포함 | `migration` 제외 |
| `migrationTest` | `*IT.class` 포함 | `migration` 포함 |

핵심 설정을 발췌하면 다음과 같다.

```kotlin
val integrationTest by tasks.registering(Test::class) {
    testClassesDirs = sourceSets["test"].output.classesDirs
    classpath = sourceSets["test"].runtimeClasspath
    include("**/*IT.class")
    useJUnitPlatform { excludeTags("migration") }
    systemProperty("user.timezone", "UTC")
    mustRunAfter(tasks.named("test"))
}

val migrationTest by tasks.registering(Test::class) {
    testClassesDirs = sourceSets["test"].output.classesDirs
    classpath = sourceSets["test"].runtimeClasspath
    include("**/*IT.class")
    useJUnitPlatform { includeTags("migration") }
    systemProperty("user.timezone", "UTC")
    mustRunAfter(tasks.named("test"), integrationTest)
}
```

여기서는 **클래스 이름 조건과 태그 조건을 모두 충족해야 한다.** 태그만 붙인 `SomethingMigrationTest`는 새 태스크의 `*IT` 조건에 맞지 않는다. 반대로 `SomethingMigrationIT`라도 태그가 없으면 일반 통합 테스트 쪽으로 들어간다.

이 사례에서 도출할 수 있는 검증 원칙은 다음과 같다.

```text
일반 통합 테스트와 마이그레이션 테스트의 교집합 = 없음
두 그룹의 합집합 = 분리 전 실행하던 IT 전체
```

단순히 태스크가 성공했는지보다 실제 테스트 목록이 이 조건을 만족하는지 확인하는 편이 중요하다.

## 5. 실행 참여와 실행 순서를 구분한다

이번 변경의 중요한 선택은 `dependsOn`과 `mustRunAfter`를 다른 목적에 사용한 것이다.

| 설정 | 의미 | 이번 사용 위치 |
| --- | --- | --- |
| `dependsOn` | 이 작업에 필요한 다른 작업도 실행 그래프에 포함 | `check`에 두 통합 테스트 태스크 연결 |
| `mustRunAfter` | 두 작업이 모두 실행 대상일 때 순서를 강제 | `test → integrationTest → migrationTest` |
| `shouldRunAfter` | 순서에 대한 더 약한 규칙 | 기존 일반 통합 테스트 설정을 `mustRunAfter`로 변경 |

`mustRunAfter`는 앞선 태스크를 자동으로 실행시키는 의존 관계가 아니다. 그래서 `migrationTest`만 요청하면 일반 통합 테스트까지 함께 실행할 필요가 없다. 물론 테스트 클래스 컴파일 같은 필요한 준비 작업은 실행될 수 있다. [Gradle 태스크 실행 순서 문서](https://docs.gradle.org/current/userguide/controlling_task_execution.html)

전체 검증에는 다음 설정을 추가했다.

```kotlin
tasks.named("check") {
    dependsOn(integrationTest, migrationTest)
}
```

기존 `check`의 기본 테스트 연결에 두 태스크를 더하고, 순서는 별도 규칙으로 강제한다.

```text
개별 검증
  integrationTest만 선택 → 일반 통합 테스트
  migrationTest만 선택   → 마이그레이션 테스트

전체 검증
  check → test → integrationTest → migrationTest
```

이 구조는 빠른 개별 피드백과 전체 검증의 완전성을 동시에 제공한다. 만약 `migrationTest.dependsOn(integrationTest)`로 연결했다면 마이그레이션만 확인하려고 해도 일반 통합 테스트를 함께 실행하게 된다.

## 6. CI 진입점까지 이어져야 분리가 완성된다

로컬에서 새 태스크가 동작해도 CI가 실행하지 않으면 배포 전 검증에서 빠질 수 있다.

당시 CodeBuild 설정은 Gradle의 `clean build`를 호출했다. `build`가 `check`를 거치므로 새 `migrationTest`도 전체 검증에 포함되는 구조였다. PR #316은 CI YAML을 수정하는 대신 Gradle 검증 그래프를 확장했다.

이 판단은 “CI 설정을 바꾸지 않았으므로 CI에는 영향이 없다”가 틀릴 수 있음을 보여 준다. CI가 호출하는 상위 태스크와 그 의존 작업까지 따라가야 실제 실행 범위를 알 수 있다.

동시에 실행 그래프에 포함된다는 것과 매번 실제 테스트 프로세스가 시작된다는 것도 구분해야 한다. 증분 실행 등으로 태스크가 생략될 수 있으므로, 실행 증거를 수집할 때는 태스크 결과 상태와 테스트 보고서를 함께 읽어야 한다.

## 7. 순차 실행과 JVM 하나는 병렬성의 모든 층을 통제하지 않는다

기존 공통 설정은 다음과 같았고, 새 태스크에도 적용됐다.

```kotlin
tasks.withType<Test>().configureEach {
    useJUnitPlatform()
    maxParallelForks = 1
}
```

`maxParallelForks`는 각 태스크가 동시에 실행할 테스트 프로세스 수를 제한한다. 세 태스크 사이의 순서는 `mustRunAfter`가 맡는다. 서로 다른 설정이 서로 다른 층의 동시성을 다룬다. [Gradle Test 설정](https://docs.gradle.org/current/dsl/org.gradle.api.tasks.testing.Test.html)

여기에 JUnit 내부의 클래스·메서드 병렬 실행이나 서로 다른 CI 작업의 동시 실행까지 자동으로 제한된다고 해석하면 안 된다.

마이그레이션 기반 클래스는 공유 MySQL DB를 매 테스트 전에 Flyway로 초기화한다. 같은 DB를 대상으로 두 테스트가 동시에 실행되면 한 테스트가 다른 테스트의 스키마를 지울 수 있다. JVM을 분리했어도 **마이그레이션 태스크 내부의 상태 격리 전제**는 여전히 확인해야 한다.

## 8. 프로세스 격리와 성능 개선을 같은 결론으로 묶지 않는다

별도 JVM은 일반 통합 테스트의 프로세스 내부 상태와 마이그레이션 테스트의 상태를 분리한다. 그러나 그것만으로 실행 시간이 단축되거나 최대 메모리가 줄었다고 단정할 수는 없다.

새 JVM을 시작하는 비용이 있고, 외부 MySQL 컨테이너의 자원 사용량도 별도로 존재한다. 전체 자원 사용은 JVM뿐 아니라 Gradle, Docker, DB와 정리 시점의 영향을 받는다. `mustRunAfter`는 태스크 실행 순서를 정할 뿐 외부 자원의 종료 시점을 직접 정의하지 않는다.

실제로 PR 본문은 **CodeBuild 실행 시간과 메모리 개선을 아직 검증하지 않았다**고 명시했다. 이 구분은 유지해야 한다.

확인된 결과는 테스트 그룹과 JVM 실행 경계를 나눴고, 순차 실행과 기존 검증의 포함 여부를 확인했다는 것이다. 성능 효과를 판단하려면 같은 환경에서 전체 시간, 단계별 시간, 메모리와 컨테이너 수명을 별도로 측정해야 한다.

## 9. 실행 구조 리팩토링은 목록·순서·결과를 함께 검증한다

당시 PR의 검증 기록은 다음과 같다.

| 검증 항목 | 기록된 결과 |
| --- | --- |
| 기본 테스트 | 401개 통과 |
| 일반 통합 테스트 | 136개 통과 |
| 마이그레이션 테스트 | 10개 통과 |
| 마이그레이션 클래스 분류 | 8개 클래스의 누락·중복 없음 |
| 전체 실행 순서 | `test → integrationTest → migrationTest` 확인 |

8개는 클래스 수이고 10개는 테스트 수다. 서로 다른 단위를 비교해 누락으로 판단하지 않도록 구분해야 한다.

유사 작업에서는 다음을 함께 확인하면 좋다.

1. 분리 전 실행 대상 목록을 확보한다.
2. 새 태스크의 포함·제외 규칙으로 각 테스트의 소속을 확인한다.
3. 두 태스크에 같은 테스트가 들어가거나 어디에도 들어가지 않는 경우를 점검한다.
4. 개별 실행과 전체 실행이 의도한 범위를 선택하는지 확인한다.
5. 실제 테스트 결과와 태스크 순서를 확인한다.
6. 실행 방법과 새 테스트 작성 규칙을 문서에 반영한다.

이번 변경은 `backend/README.md`에 개별·전체 실행 방법을, `backend/AGENTS.md`에 기반 클래스의 태그 상속과 실행 경계를 기록했다. 테스트 설정만 바꾸면 다음 작성자가 기존 이름·상속 규칙을 놓칠 수 있기 때문이다.

## 10. 근거와 적용 범위

이 글의 기준은 2026년 9월 9일 병합된 PR #316과 커밋 `e150feeb4f9d58f295f67943d7d5fb634dae1d31`이다. 변경 파일은 Gradle 설정, 마이그레이션 기반 클래스의 태그, 실행 방법과 규칙 문서의 4개다. 테스트 시나리오나 운영 마이그레이션 SQL을 변경한 PR은 아니다.

이번 문서 작성에서는 병합 당시 코드와 PR 기록을 확인했다. 위 통과 수치와 순서 검증은 당시 PR의 기록이며, 테스트를 이번에 다시 실행한 결과는 아니다. 운영 배포나 CodeBuild 성능 개선까지 확인한 것으로 해석하지 않는다.

| 근거 | 확인할 내용 |
| --- | --- |
| [PR #316](https://github.com/icar-mobility/icar-erp/pull/316) | 변경 목적, 테스트 수, 누락·중복과 순서 검증, 성능 미검증 범위 |
| [병합 커밋](https://github.com/icar-mobility/icar-erp/commit/e150feeb4f9d58f295f67943d7d5fb634dae1d31) | 실제 변경한 4개 파일 |
| [당시 Gradle 설정](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/backend/build.gradle.kts) | 태그 필터, 별도 태스크, 순서와 전체 검증 연결 |
| [MigrationITBase](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/backend/src/test/kotlin/com/icar/erp/testsupport/MigrationITBase.kt) | 태그와 공유 MySQL·Flyway 초기화 구조 |
| [MySqlITBase](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/backend/src/test/kotlin/com/icar/erp/testsupport/MySqlITBase.kt) | 기존 일반 통합 테스트의 별도 DB 구성 |
| [CodeBuild 설정](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/infra/codebuild/backend-production.yml) | CI에서 `clean build`를 호출하는 진입점 |
| [백엔드 실행 문서](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/backend/README.md) | 개별 실행과 전체 검증 방법 |
| [테스트 작성 규칙](https://github.com/icar-mobility/icar-erp/blob/e150feeb4f9d58f295f67943d7d5fb634dae1d31/backend/AGENTS.md) | 마이그레이션 테스트의 이름·태그·실행 경계 |

코드 링크는 당시 커밋에 고정했다. Gradle 공식 문서 링크는 설정의 일반적인 의미를 설명하기 위한 참고 자료이며, 이 PR의 테스트 통과나 성능을 입증하는 자료는 아니다.
