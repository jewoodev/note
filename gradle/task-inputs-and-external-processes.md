# Gradle 작업의 입력 추적과 외부 프로그램 실행

Gradle에서 Python 스크립트 같은 외부 프로그램을 실행할 때는 두 가지를 따로 생각해야 한다.

1. **프로그램 실행:** 어떤 명령을 실행하고 어떤 파일을 전달할지 정한다.
2. **작업 입력 추적:** 스크립트나 설정 파일처럼 결과에 영향을 주는 파일과 값을 Gradle에 알려, 변경이 생겼을 때 작업을 다시 실행해야 하는지 판단할 수 있게 한다.

입력 파일을 등록하는 설정은 해당 파일을 실행하지 않는다. 반대로 실행 명령을 작성했다고 해서 Gradle이 그 프로그램이 참조하는 모든 파일을 자동으로 추적하는 것은 아니다.

## Gradle 작업과 입력·출력

Gradle **작업(task)**은 빌드에서 수행할 작업 단위다. 예를 들어 소스 파일을 컴파일하거나 테스트를 실행하고, 결과 파일을 만드는 작업이 있다.

작업의 **입력**은 결과에 영향을 주는 파일이나 값이다. **출력**은 작업이 만들어 내는 파일이나 디렉터리다. 소스 파일을 읽어 결과 파일을 만드는 경우, 소스가 입력이고 결과 파일이 출력이다.

Gradle은 선언된 입력과 출력을 이전 실행과 비교해 다시 실행할 필요가 없다고 판단하면 작업을 `UP-TO-DATE`로 건너뛸 수 있다. 이 판단이 가능한지는 작업의 입력·출력 선언과 작업의 실행 조건에 달려 있다. [Gradle 증분 빌드 문서](https://docs.gradle.org/current/userguide/incremental_build.html)

예를 들어 Python 코드가 작업 결과에 영향을 주지만 입력으로 등록되지 않은 상황을 생각해 보자.

1. Gradle이 작업을 성공적으로 실행한다.
2. Python 스크립트만 수정한다.
3. Gradle이 등록된 입력과 출력에 변화가 없다고 판단한다.
4. 작업을 건너뛰면 수정된 Python 코드가 실행되지 않는다.

이는 항상 건너뛴다는 뜻은 아니다. 다른 입력이 변경됐거나 작업이 항상 실행되도록 설정된 경우에는 다시 실행될 수 있다. 문제는 **Python 변경만으로 결과가 달라질 수 있는데, Gradle이 그 변경을 판단에 반영하지 못한다는 것**이다.

## 실행과 추적을 함께 구성하는 예제

아래 예제는 외부 Python 프로그램이 텍스트를 읽어 결과 파일을 만드는 간단한 Gradle 프로젝트다. 사전에 JDK, Gradle, `python3`가 설치돼 있고 명령행에서 실행 가능하다고 가정한다.

프로젝트 구조는 다음과 같다.

```text
example/
├── settings.gradle.kts
├── build.gradle.kts
├── config/
│   └── prefix.txt
└── scripts/
    └── make_message.py
```

`settings.gradle.kts`:

```kotlin
rootProject.name = "external-process-example"
```

`config/prefix.txt`:

```text
Hello
```

`scripts/make_message.py`:

```python
from pathlib import Path
import sys

prefix_file = Path(sys.argv[1])
output_file = Path(sys.argv[2])

prefix = prefix_file.read_text(encoding="utf-8").strip()
output_file.parent.mkdir(parents=True, exist_ok=True)
output_file.write_text(f"{prefix}, Gradle!\n", encoding="utf-8")
```

`build.gradle.kts`:

```kotlin
tasks.register<Exec>("makeMessage") {
    val script = layout.projectDirectory.file("scripts/make_message.py")
    val prefix = layout.projectDirectory.file("config/prefix.txt")
    val result = layout.buildDirectory.file("generated/message.txt")

    // 변경 여부 판단에 사용할 입력과 출력
    inputs.file(script).withPropertyName("messageScript")
    inputs.file(prefix).withPropertyName("messagePrefix")
    outputs.file(result)

    // 실제로 실행할 프로그램과 인수
    workingDir = project.projectDir
    commandLine("python3", script.asFile, prefix.asFile, result.get().asFile)
}
```

이 설정에서 `commandLine(...)`이 Python 실행을 지정하고, `inputs.file(...)`은 스크립트와 설정 파일의 변경을 Gradle에 알린다. `outputs.file(...)`은 생성 결과를 선언한다.

프로젝트 디렉터리에서 다음처럼 관찰할 수 있다.

```sh
gradle makeMessage
gradle makeMessage
```

첫 실행이 성공하면 `build/generated/message.txt`가 생성된다. 입력과 출력에 변화가 없다면 두 번째 실행은 `UP-TO-DATE`로 표시될 수 있다. 이후 `config/prefix.txt`의 내용을 변경하고 다시 실행하면 Gradle이 입력 변경을 감지해 결과를 다시 만든다. `scripts/make_message.py`의 내용을 바꾸는 경우도 마찬가지다.

예를 들어 `inputs.file(script)`만 제거하면 Python 자체는 계속 실행할 수 있다. 하지만 스크립트 내용만 변경했을 때 Gradle의 최신 상태 판단에 그 변경이 포함되지 않아, 이전 출력을 그대로 사용할 가능성이 생긴다.

위 예제는 개념 설명을 위해 단순화했다. Python 인터프리터 버전이나 실행 환경도 결과에 영향을 준다면, 실제 빌드에서는 그것도 입력으로 모델링하거나 항상 실행하는 방식을 검토해야 한다.

## 테스트 작업에 적용하기

JVM 테스트가 `ProcessBuilder`로 외부 프로그램을 실행하는 경우에도 원리는 같다. 아래는 **기존 `integrationTest` 작업이 정의돼 있다는 전제**의 예시다.

```kotlin
import org.gradle.api.tasks.PathSensitivity

tasks.named<Test>("integrationTest") {
    inputs.files(fileTree("../python-worker") {
        include("src/**/*.py", "tests/**/*.py")
    })
        .withPropertyName("workerPythonSources")
        .withPathSensitivity(PathSensitivity.RELATIVE)

    inputs.files("../python-worker/pyproject.toml", "../python-worker/uv.lock")
        .withPropertyName("workerPythonDependencies")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}
```

이 설정은 Python 소스와 의존성 설정 파일을 **테스트 결과에 영향을 주는 입력**으로 등록한다. `withPropertyName(...)`은 Gradle이 입력을 구분할 이름이고, `PathSensitivity.RELATIVE`는 파일 위치를 비교할 때 상대 경로를 고려하도록 한다. 같은 파일 이름이 서로 다른 하위 디렉터리에 있는 경우를 구분하면서, 체크아웃의 절대 경로 차이는 줄이는 데 쓸 수 있다. [Gradle 작업 입력 권장 사항](https://docs.gradle.org/current/userguide/best_practices_tasks.html)

이 선언은 외부 명령 실행을 대신하지 않는다. 예를 들어 JVM 테스트 안에서 다음처럼 별도로 프로세스를 시작해야 한다.

```kotlin
val process = ProcessBuilder("python3", "../python-worker/scripts/check.py")
    .directory(projectDirectory)
    .inheritIO()
    .start()

check(process.waitFor() == 0) { "Python process failed" }
```

`projectDirectory`는 호출자가 제공하는 `java.io.File`이며, 상대 경로는 그 작업 디렉터리를 기준으로 해석된다. 이 예제는 실행 방식의 차이를 보여주기 위한 코드다. 실제 테스트에서는 제한 시간, 종료 코드, 출력·오류 로그와 프로세스 정리도 설계해야 한다.

## `UP-TO-DATE`와 빌드 캐시의 차이

두 기능 모두 작업 입력을 사용하지만 결과를 재사용하는 방식이 다르다.

| 상태 | 의미 |
| --- | --- |
| `UP-TO-DATE` | 현재 작업 디렉터리의 기존 출력과 이전 실행 정보를 바탕으로 작업 실행을 건너뜀 |
| `FROM-CACHE` | 활성화된 빌드 캐시에서 입력에 대응하는 작업 출력을 복원해 실행을 건너뜀 |

입력 등록은 두 판단에 영향을 줄 수 있지만, **등록만으로 모든 작업의 빌드 캐시가 활성화되는 것은 아니다.** 빌드 캐시 사용 여부와 해당 작업의 캐시 가능 여부는 별도로 결정된다. [Gradle 빌드 캐시 문서](https://docs.gradle.org/current/userguide/build_cache.html)

## 입력을 선언할 때 확인할 점

- **결과에 영향을 주는 파일을 포함한다.** 스크립트뿐 아니라 가져오는 모듈, 설정 파일, 테스트 코드, 필요한 lockfile도 살핀다. lockfile은 의존성 해석의 입력이지만 실제 설치 상태나 인터프리터 버전 전체를 대표하지는 않는다.
- **결과에 영향을 주지 않는 파일은 되도록 제외한다.** 너무 넓게 등록하면 무관한 변경마다 작업이 다시 실행된다.
- **파일 외의 입력을 살핀다.** 명령 옵션, 환경변수, 인터프리터 버전과 외부 서비스 상태에 따라 결과가 달라질 수 있다. 예를 들어 실행 여부를 결정하는 환경변수는 `inputs.property("externalTestEnabled", providers.environmentVariable("EXTERNAL_TEST_ENABLED").orElse(""))`처럼 값으로 등록할 수 있다.
- **외부 상태가 바뀌는 시험을 주의한다.** 네트워크 서비스나 DB 상태처럼 입력을 완전히 표현하기 어려운 경우, 이전 성공 결과를 재사용해도 되는지 검토한다. 필요하면 해당 작업의 최신 상태 판단이나 캐시 사용을 제한한다.
- **실행 환경을 별도로 준비한다.** 입력 선언은 Python을 설치하거나, 의존성을 설치하거나, 작업 디렉터리를 맞춰 주지 않는다.

입력 추적은 작업 결과를 재사용해도 되는지 판단하는 근거다. 실행에 필요한 구성과 함께 관리해야 최신 코드가 실제 검증에 반영된다.

## 참고 자료

- [Gradle: Incremental Build](https://docs.gradle.org/current/userguide/incremental_build.html)
- [Gradle: Build Cache](https://docs.gradle.org/current/userguide/build_cache.html)
- [Gradle: Best Practices for Tasks](https://docs.gradle.org/current/userguide/best_practices_tasks.html)
