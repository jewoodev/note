# Spotbugs 세팅 중 발생한 에러
```
> Task :spotbugsMain
M V EI2: new jewoospring.splearn.application.MemberQueryService(MemberRepository) may expose internal representation by storing an externally mutable object into MemberQueryService.memberRepository  At MemberQueryService.java:[line 12]
M V EI2: new jewoospring.splearn.application.MemberModifyService(MemberFinder, MemberRepository, EmailSender, PasswordEncoder) may expose internal representation by storing an externally mutable object into MemberModifyService.memberRepository  At MemberModifyService.java:[line 15]

> Task :spotbugsMain FAILED

> Task :spotbugsTest
M D DLS: Dead store to member1 in jewoospring.splearn.application.provided.MemberRegisterTest.duplicateEmailInFailure()  At MemberRegisterTest.java:[line 36]
H C NP: Null passed for non-null parameter of MemberFixture.createMemberRegisterRequest(String) in jewoospring.splearn.domain.MemberTest.registerNullCheck()  At MemberTest.java:[line 30]
```

## SpotBugs가 이런 에러를 내는 이유
## 1. EI2 (Exposing Internal Representation) 에러
### MemberQueryService와 MemberModifyService의 문제점
``` java
@RequiredArgsConstructor
public class MemberQueryService {
    private final MemberRepository memberRepository; // 문제 지점
}
```
**원인**: SpotBugs는 생성자에서 외부에서 전달받은 mutable 객체를 그대로 저장하는 것을 경고한다. `MemberRepository`는 인터페이스지만, 실제 구현체는 mutable한 상태를 가질 수 있어서 내부 표현이 외부에 노출될 수 있다고 판단한다.

**해결 방법**:
1. **Spring의 의존성 주입을 사용하는 경우 (권장)**: 이 경고는 무시해도 된다. Spring이 관리하는 싱글톤 빈이므로 실제로는 안전하다.
2. **SpotBugs 설정에서 제외**: `@SuppressFBWarnings("EI_EXPOSE_REP2")` 어노테이션 사용
``` java
@Service
@Validated
@RequiredArgsConstructor
@SuppressFBWarnings("EI_EXPOSE_REP2")
public class MemberQueryService implements MemberFinder {
    private final MemberRepository memberRepository;
    // ...
}
```

## 2. DLS (Dead Local Store) 에러
### MemberRegisterTest의 문제점
``` java
@Test
void duplicateEmailInFailure() {
    Member member1 = memberRegister.register(MemberFixture.createMemberRegisterRequest()); // 사용되지 않는 변수
    
    assertThatThrownBy(() -> memberRegister.register(MemberFixture.createMemberRegisterRequest()))
            .isInstanceOf(DuplicateEmailException.class);
}
```
**원인**: `member1` 변수를 선언하고 값을 할당했지만, 그 이후에 사용하지 않는다.

**해결 방법**:
``` java
@Test
void duplicateEmailInFailure() {
    // 변수 없이 직접 호출
    memberRegister.register(MemberFixture.createMemberRegisterRequest());
    
    assertThatThrownBy(() -> memberRegister.register(MemberFixture.createMemberRegisterRequest()))
            .isInstanceOf(DuplicateEmailException.class);
}
```

## 3. NP (Null Pointer) 에러
### MemberTest의 문제점
``` java
@Test
void registerNullCheck() {
    var createRequest = createMemberRegisterRequest(null); // null을 전달
    assertThatThrownBy(() -> Member.register(createRequest, passwordEncoder))
            .isInstanceOf(NullPointerException.class);
}
```
**원인**: `@NonNullApi` 패키지 어노테이션으로 인해 null이 허용되지 않는 파라미터에 null을 전달하고 있다.

**해결 방법**: 이것은 의도적으로 null을 전달해서 예외를 테스트하는 코드이므로, SpotBugs 경고를 억제하거나 다른 방식으로 테스트를 작성할 수 있다.
``` java
@Test
@SuppressFBWarnings("NP_NULL_PARAM_DEREF")
void registerNullCheck() {
    var createRequest = createMemberRegisterRequest(null);
    assertThatThrownBy(() -> Member.register(createRequest, passwordEncoder))
            .isInstanceOf(NullPointerException.class);
}
```

## 요약
- **EI2**: Spring DI 환경에서는 일반적으로 안전하므로 `@SuppressFBWarnings` 사용
- **DLS**: 사용하지 않는 변수 제거
- **NP**: null 테스트의 경우 `@SuppressFBWarnings` 사용하거나 테스트 방식 변경

이러한 SpotBugs 경고들은 대부분 코드 품질 향상을 위한 것이며, Spring 환경에서는 실제 문제가 되지 않는 경우가 많다.


## `@SuppressFBWarning` import가 안 되는 문제
`@SuppressFBWarnings` 어노테이션을 사용하려면 SpotBugs 어노테이션 의존성을 추가해야 한다.

``` kotlin
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    compileOnly("org.projectlombok:lombok")
    compileOnly("com.github.spotbugs:spotbugs-annotations:4.8.6") // 추가
    developmentOnly("org.springframework.boot:spring-boot-docker-compose")
    runtimeOnly("com.h2database:h2")
    runtimeOnly("com.mysql:mysql-connector-j")
    annotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
```
의존성을 추가한 후에는 다음과 같이 사용할 수 있다.

``` java
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;

@Service
@Validated
@RequiredArgsConstructor
@SuppressFBWarnings("EI_EXPOSE_REP2")
public class MemberQueryService implements MemberFinder {
    private final MemberRepository memberRepository;
    // ...
}
```
**참고사항:**
- `compileOnly` 로 추가하는 것이 좋다. 이 어노테이션들은 컴파일 타임에만 필요하고 런타임에는 필요하지 않기 때문이다. 
- SpotBugs 플러그인 버전과 호환되는 어노테이션 버전을 사용하는 것이 중요하다. 위의 4.8.6 버전은 SpotBugs 6.2.1과 호환됩니다.

### 위 세팅법의 Reference
제가 SpotBugs 어노테이션 의존성에 대해 알려드린 내용은 일반적인 SpotBugs 사용 경험과 공식 문서를 기반으로 했다.

1. **SpotBugs 공식 문서** [[1]](https://spotbugs.readthedocs.io/en/stable/migration.html) - SpotBugs 마이그레이션 가이드에서 의존성 사용법을 확인했습니다. `com.github.spotbugs:spotbugs-annotations`
2. **SpotBugs Gradle 플러그인 공식 페이지** [[2]](https://plugins.gradle.org/plugin/com.github.spotbugs) - 플러그인 버전 6.2.1이 최신 버전임을 확인했습니다.
3. **SpotBugs 공식 GitHub 저장소** [[3]](https://github.com/spotbugs/spotbugs-gradle-plugin) - Gradle 플러그인의 사용법과 호환성 정보를 참고했습니다.
4. **Maven Central** [[4]](https://central.sonatype.com/artifact/com.github.spotbugs/spotbugs-annotations) - 아티팩트의 최신 버전 정보를 확인했습니다. `spotbugs-annotations`

**설정의 근거:**
- 스코프: 어노테이션은 컴파일 타임에만 필요하고 런타임에는 불필요하므로 `compileOnly`
- 버전 4.8.6: SpotBugs 6.2.1과 호환되는 안정적인 어노테이션 버전
- : FindBugs에서 SpotBugs로 마이그레이션된 공식 패키지 `com.github.spotbugs:spotbugs-annotations`

이 설정은 SpotBugs 공식 문서에서 권장하는 표준적인 방법이다.

## Spotbugs 구동시 ClassNotFoundException 발생
```
> Task :spotbugsMain
edu.umd.cs.findbugs.ba.AnalysisException: Exception was thrown during analysis
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$3(FindBugs2.java:1117)
        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)
        at edu.umd.cs.findbugs.FindBugs2.analyzeApplication(FindBugs2.java:1110)
        at edu.umd.cs.findbugs.FindBugs2.execute(FindBugs2.java:309)
        at edu.umd.cs.findbugs.FindBugs.runMain(FindBugs.java:390)
        at edu.umd.cs.findbugs.FindBugs2.main(FindBugs2.java:1223)
Caused by: java.util.concurrent.ExecutionException: java.lang.NoClassDefFoundError: edu/umd/cs/findbugs/annotations/SuppressMatchType
        at java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
        at java.base/java.util.concurrent.FutureTask.get(FutureTask.java:191)
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$3(FindBugs2.java:1112)
        ... 5 more
Caused by: java.lang.NoClassDefFoundError: edu/umd/cs/findbugs/annotations/SuppressMatchType
        at edu.umd.cs.findbugs.detect.NoteSuppressedWarnings.visitAnnotation(NoteSuppressedWarnings.java:91)
        at edu.umd.cs.findbugs.visitclass.AnnotationVisitor.visitAnnotation(AnnotationVisitor.java:315)
        at org.apache.bcel.classfile.Annotations.accept(Annotations.java:84)
        at edu.umd.cs.findbugs.visitclass.PreorderVisitor.visitJavaClass(PreorderVisitor.java:409)
        at org.apache.bcel.classfile.JavaClass.accept(JavaClass.java:249)
        at edu.umd.cs.findbugs.detect.NoteSuppressedWarnings.visitClassContext(NoteSuppressedWarnings.java:81)
        at edu.umd.cs.findbugs.DetectorToDetector2Adapter.visitClass(DetectorToDetector2Adapter.java:76)
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$1(FindBugs2.java:1100)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at edu.umd.cs.findbugs.CurrentThreadExecutorService.execute(CurrentThreadExecutorService.java:86)
        at java.base/java.util.concurrent.AbstractExecutorService.invokeAll(AbstractExecutorService.java:247)
        ... 4 more
Caused by: java.lang.ClassNotFoundException: edu.umd.cs.findbugs.annotations.SuppressMatchType
        at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:641)
        at java.base/jdk.internal.loader.ClassLoaders$AppClassLoader.loadClass(ClassLoaders.java:188)
        at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:525)
        ... 15 more

> Task :spotbugsMain FAILED

> Task :spotbugsTest FAILED
edu.umd.cs.findbugs.ba.AnalysisException: Exception was thrown during analysis
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$3(FindBugs2.java:1117)
        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)
        at edu.umd.cs.findbugs.FindBugs2.analyzeApplication(FindBugs2.java:1110)
        at edu.umd.cs.findbugs.FindBugs2.execute(FindBugs2.java:309)
        at edu.umd.cs.findbugs.FindBugs.runMain(FindBugs.java:390)
        at edu.umd.cs.findbugs.FindBugs2.main(FindBugs2.java:1223)
Caused by: java.util.concurrent.ExecutionException: java.lang.NoClassDefFoundError: edu/umd/cs/findbugs/annotations/SuppressMatchType
        at java.base/java.util.concurrent.FutureTask.report(FutureTask.java:122)
        at java.base/java.util.concurrent.FutureTask.get(FutureTask.java:191)
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$3(FindBugs2.java:1112)
        ... 5 more
Caused by: java.lang.NoClassDefFoundError: edu/umd/cs/findbugs/annotations/SuppressMatchType
        at edu.umd.cs.findbugs.detect.NoteSuppressedWarnings.visitAnnotation(NoteSuppressedWarnings.java:91)
        at edu.umd.cs.findbugs.visitclass.AnnotationVisitor.visitAnnotation(AnnotationVisitor.java:315)
        at org.apache.bcel.classfile.Annotations.accept(Annotations.java:84)
        at edu.umd.cs.findbugs.visitclass.PreorderVisitor.doVisitMethod(PreorderVisitor.java:323)
        at edu.umd.cs.findbugs.visitclass.PreorderVisitor.visitJavaClass(PreorderVisitor.java:405)
        at org.apache.bcel.classfile.JavaClass.accept(JavaClass.java:249)
        at edu.umd.cs.findbugs.detect.NoteSuppressedWarnings.visitClassContext(NoteSuppressedWarnings.java:81)
        at edu.umd.cs.findbugs.DetectorToDetector2Adapter.visitClass(DetectorToDetector2Adapter.java:76)
        at edu.umd.cs.findbugs.FindBugs2.lambda$analyzeApplication$1(FindBugs2.java:1100)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at edu.umd.cs.findbugs.CurrentThreadExecutorService.execute(CurrentThreadExecutorService.java:86)
        at java.base/java.util.concurrent.AbstractExecutorService.invokeAll(AbstractExecutorService.java:247)
        ... 4 more
Caused by: java.lang.ClassNotFoundException: edu.umd.cs.findbugs.annotations.SuppressMatchType
        at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:641)
        at java.base/jdk.internal.loader.ClassLoaders$AppClassLoader.loadClass(ClassLoaders.java:188)
        at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:525)
        ... 16 more

FAILURE: Build completed with 2 failures.

1: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':spotbugsMain'.
> A failure occurred while executing com.github.spotbugs.snom.internal.SpotBugsRunnerForHybrid$SpotBugsExecutor
   > Verification failed: SpotBugs ended with exit code 4.

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

2: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':spotbugsTest'.
> A failure occurred while executing com.github.spotbugs.snom.internal.SpotBugsRunnerForHybrid$SpotBugsExecutor
   > Verification failed: SpotBugs ended with exit code 4.

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

BUILD FAILED in 16s
10 actionable tasks: 6 executed, 4 up-to-date
```
이제 그레이들 빌드 결과가 이렇게 나올 수 있다. 이 로그에서 확인되는 게 뭔지 파악해보자.

이 에러는 **SpotBugs 플러그인과 SpotBugs 어노테이션 라이브러리 간의 버전 호환성 문제**인 것 같다.

**핵심 에러**: `java.lang.ClassNotFoundException: edu.umd.cs.findbugs.annotations.SuppressMatchType`  
이 에러는 다음을 의미합니다:  
1. SpotBugs 플러그인(6.2.1)이 실행 중에 `edu.umd.cs.findbugs.annotations.SuppressMatchType` 클래스를 찾으려고 한다.
2. 하지만 현재 추가된 라이브러리에는 이 클래스가 없다. `spotbugs-annotations`
3. 이는 플러그인이 기대하는 어노테이션 버전과 실제 추가된 버전이 다르기 때문인 것 같다.

### 해결 방법
#### 1. SpotBugs 어노테이션 의존성 수정
``` kotlin

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    compileOnly("org.projectlombok:lombok")
    // SpotBugs 플러그인 6.2.1과 호환되는 버전으로 변경
    compileOnly("com.github.spotbugs:spotbugs-annotations:4.8.6")
    // 또는 최신 버전 사용
    // compileOnly("com.github.spotbugs:spotbugs-annotations:4.9.3")
    developmentOnly("org.springframework.boot:spring-boot-docker-compose")
    runtimeOnly("com.h2database:h2")
    runtimeOnly("com.mysql:mysql-connector-j")
    annotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
```

#### 2. 또는 SpotBugs 플러그인 버전 다운그레이드
``` kotlin
plugins {
    java
    id("org.springframework.boot") version "3.5.3"
    id("io.spring.dependency-management") version "1.1.7"
    // 더 안정적인 버전으로 변경
    id("com.github.spotbugs") version "6.0.24"
}
```
#### 3. 임시 해결책: SpotBugs 어노테이션 의존성 제거
만약 당장 `@SuppressFBWarnings` 어노테이션을 사용하지 않는다면, 의존성을 제거하고 코드를 수정해서 SpotBugs 경고를 해결할 수 있다.

``` kotlin
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    compileOnly("org.projectlombok:lombok")
    // SpotBugs 어노테이션 의존성 제거
    developmentOnly("org.springframework.boot:spring-boot-docker-compose")
    runtimeOnly("com.h2database:h2")
    runtimeOnly("com.mysql:mysql-connector-j")
    annotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
```

---

내 생각엔 아무래도 유닉스 운영체제를 쓰는 게 낫다고 본다.