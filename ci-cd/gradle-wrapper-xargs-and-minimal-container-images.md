# JDK 이미지인데 Gradle이 실행되지 않는 이유: `xargs`와 `findutils`

Java가 설치된 컨테이너에서도 `./gradlew`가 실패할 수 있다. Gradle Wrapper를 시작하는 셸 스크립트가 운영체제 명령을 사용하기 때문이다.

이 문서는 Corretto 25·Amazon Linux 2023 기반 이미지에서 다음 오류를 해결한 사례를 바탕으로, 원인과 해결 방법을 설명한다. 특정 프로젝트의 코드나 업무 구조를 몰라도 읽을 수 있다.

```text
xargs is not available
```

핵심은 **Gradle을 실행하는 빌드 환경에 `xargs`를 제공하는 `findutils` 패키지를 설치하는 것**이다.

## 1. JDK와 Gradle Wrapper는 서로 다른 역할이다

JDK는 Java 프로그램의 컴파일·실행 도구를 제공한다. Gradle은 의존성 해결, 컴파일, 테스트, JAR 생성을 수행하는 빌드 도구다. Gradle Wrapper는 프로젝트가 정한 Gradle 배포판을 준비하고 실행하는 진입점이다.

Wrapper를 사용하는 프로젝트에는 보통 다음 파일이 있다.

| 파일 | 역할 |
| --- | --- |
| `gradlew` | Linux·macOS 등에서 사용하는 셸 실행 스크립트 |
| `gradlew.bat` | Windows 실행 스크립트 |
| `gradle/wrapper/gradle-wrapper.jar` | Gradle 배포판을 준비하고 실행하는 Java 코드 |
| `gradle/wrapper/gradle-wrapper.properties` | 배포 URL·체크섬 등 Wrapper 설정 |

Linux에서 `./gradlew`를 실행하면 먼저 셸 스크립트가 동작한다. 이 스크립트가 Java 명령과 인수를 준비한 뒤 Wrapper JAR를 실행한다. `xargs` 확인은 Java 프로세스를 실행하기 전의 단계에 있다. [Gradle 9.7.1 실행 스크립트](https://github.com/gradle/gradle/blob/v9.7.1/gradlew)

따라서 이 오류는 애플리케이션 소스가 컴파일되거나 테스트가 시작되기 전에 발생할 수 있다.

## 2. Wrapper가 `xargs`를 사용하는 이유

`xargs`는 표준 입력으로 받은 내용을 명령의 인수로 구성하는 도구다. 공백으로 구분된 값뿐 아니라 따옴표로 묶은 값도 해석한다.

다음은 인수 경계를 보여주는 예제다.

```sh
printf '%s\n' '-Xmx512m "-Dapp.label=hello world"' | xargs -n1
```

출력:

```text
-Xmx512m
-Dapp.label=hello world
```

`-n1`은 명령 호출 한 번에 인수를 하나씩 전달한다. 이 예제에서는 실행할 명령을 생략했으므로 기본 명령인 `echo`가 사용된다. 따옴표로 묶인 두 번째 값은 내부에 공백이 있어도 하나의 인수다.

Gradle의 POSIX 실행 스크립트는 `DEFAULT_JVM_OPTS`, `JAVA_OPTS`, `GRADLE_OPTS`에 담긴 옵션을 처리할 때 `xargs -n1`을 사용한다. 이후 `sed`·`tr` 등의 처리를 거쳐 Java에 전달할 인수를 구성한다. Bash 배열에 의존하지 않는 실행 스크립트의 일부다. [Gradle 9.7.1의 인수 처리 구현](https://github.com/gradle/gradle/blob/v9.7.1/gradlew#L198-L228)

Java가 옵션을 해석하기 전에 셸 스크립트가 인수를 준비해야 하므로, JDK만 있다고 전체 실행 조건이 충족되는 것은 아니다.

## 3. 최소 컨테이너 이미지에서 드러나는 숨은 의존성

개발자의 노트북에는 여러 명령이 이미 설치되어 있는 경우가 많다. 같은 스크립트를 작은 컨테이너 이미지에서 실행하면 평소 의식하지 못했던 도구 의존성이 드러날 수 있다.

Amazon Linux 2023 기본 컨테이너의 패키지 목록에는 `findutils`가 포함되어 있지 않다. AWS의 AL2·AL2023 비교 표에서도 차이를 확인할 수 있다. 다만 기본 이미지와 JDK를 추가한 파생 이미지의 구성은 다를 수 있으므로, 실제 사용할 이미지도 확인해야 한다. [AWS 공식 패키지 비교](https://docs.aws.amazon.com/linux/al2023/ug/amzn2-al2023-container.html)

이 사례에서 확인한 환경은 다음과 같다.

| 항목 | 관찰한 값 |
| --- | --- |
| 기반 이미지 | `amazoncorretto:25-al2023` |
| 고정한 이미지 index digest | `sha256:c4348c3d4e9c2219d6e09c2e9e473c9a5bafe0492c4a7038cd60f2f6a473c16b` |
| 검증 플랫폼 | Linux ARM64 |
| Wrapper가 선택한 Gradle | 9.7.1 |
| 누락된 명령 | `xargs` |
| 해결에 사용한 패키지 | `findutils` |

이는 모든 Corretto 이미지나 모든 Gradle 버전이 같은 조건이라는 뜻은 아니다. Wrapper 스크립트와 이미지 digest를 기준으로 실제 실행 조건을 확인한다.

## 4. 해결: 빌드 단계에 `findutils` 설치

이 환경에서 `findutils`는 `find`와 `xargs` 같은 명령을 제공하는 운영체제 패키지다. Gradle의 라이브러리 의존성으로 추가하는 항목이 아니다.

Amazon Linux 2023에서는 `dnf`로 설치한다.

```dockerfile
FROM amazoncorretto:25-al2023 AS build

RUN dnf install -y findutils \
    && dnf clean all

WORKDIR /workspace
COPY . .

RUN ./gradlew --no-daemon bootJar
```

위 예제는 Gradle Wrapper와 Spring Boot의 `bootJar` 태스크가 있는 프로젝트를 전제로 한다. 일반 Java 프로젝트라면 실제 사용하는 빌드 태스크로 바꾼다. 예제의 태그는 읽기 쉽게 줄인 것이며, 실제 사례에서는 앞서 기록한 digest로 이미지를 고정했다.

- `dnf install -y findutils`: 빌드에 필요한 운영체제 도구를 설치한다.
- `dnf clean all`: 패키지 관리자 캐시를 정리한다. 설치한 실행 파일을 제거하는 명령은 아니다.
- 설치를 소스 복사보다 앞에 배치하면 소스만 바뀔 때 패키지 설치 레이어를 재사용하기 좋다.

Debian·Ubuntu 등 다른 배포판은 패키지 관리자와 기본 구성이 다르다. 이미지의 배포판과 해당 명령을 제공하는 패키지를 확인한 뒤 설치 방법을 선택한다.

## 5. 왜 실행 단계가 아니라 빌드 단계에 추가하는가?

멀티 스테이지 빌드에서는 역할별로 여러 `FROM` 단계를 정의한다. 다음 단계로 필요한 산출물만 복사할 수 있다. [Docker 공식 문서: 멀티 스테이지 빌드](https://docs.docker.com/build/building/multi-stage/)

아래 예제는 `bootJar` 결과 파일명이 `build/libs/app.jar`로 설정된 프로젝트를 전제로 한다.

```dockerfile
FROM amazoncorretto:25-al2023 AS build
RUN dnf install -y findutils && dnf clean all
WORKDIR /workspace
COPY . .
RUN ./gradlew --no-daemon bootJar

FROM amazoncorretto:25-al2023 AS runtime
WORKDIR /app
COPY --from=build /workspace/build/libs/app.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

`build`는 `./gradlew`를 실행하므로 `xargs`가 필요하다. `runtime`은 만들어진 JAR를 `java -jar`로 실행한다. 이 실행 경로 자체는 Wrapper를 사용하지 않는다.

`COPY --from=build`는 지정한 JAR를 복사한다. 빌드 단계에서 설치한 모든 패키지를 실행 단계에 전달하는 명령이 아니다. 실행 단계의 다른 스크립트도 `xargs`를 사용하는지는 별도로 판단한다.

## 6. prebuilt 경로만 확인하면 놓칠 수 있다

배포 파이프라인이 컨테이너 밖에서 JAR를 만들고 이미지에는 JAR만 복사하는 경우도 있다. 이런 경로를 `prebuilt`라고 부르기도 한다.

| 경로 | JAR 생성 위치 | 이 문제를 발견할 가능성 |
| --- | --- | --- |
| 일반 컨테이너 빌드 | Dockerfile의 빌드 단계 | Wrapper를 실행하므로 누락된 `xargs`가 드러남 |
| prebuilt 이미지 | 호스트 또는 CI 빌드 환경 | 컨테이너 빌드 단계를 실행하지 않으면 문제를 놓칠 수 있음 |

현대 Docker의 BuildKit은 선택한 target에 필요한 단계만 실행한다. 따라서 JAR를 복사하는 경로가 통과했다고 해서 컨테이너 내부의 Gradle 빌드 경로까지 검증된 것은 아니다. [Docker 공식 문서: 단계 실행 차이](https://docs.docker.com/build/building/multi-stage/#differences-between-legacy-builder-and-buildkit)

일반 빌드와 prebuilt 경로를 둘 다 제공한다면 각각 확인한다. Java 버전·JAR 실행 성공 여부에 더해 빌드 스크립트가 요구하는 도구도 검증 대상이다.

## 7. 같은 오류를 만났을 때 확인할 순서

1. 로그에서 최초 실패한 명령과 Dockerfile 단계를 찾는다. 빌드 태스크가 시작되기 전의 스크립트 오류인지 확인한다.
2. 같은 이미지에서 `java -version`과 `command -v xargs`를 각각 확인한다. 호스트에 명령이 있다는 사실은 컨테이너의 설치 상태를 증명하지 않는다.
3. `gradlew`에서 `xargs`를 검색해 어떤 처리에 필요한지 확인한다.
4. 해당 배포판에서 `xargs`를 제공하는 패키지를 확인하고 Wrapper를 실행하는 단계에 설치한다.
5. 명령 존재 확인에 이어 `./gradlew --version`을 실행하고, 마지막으로 실제 JAR 빌드를 확인한다.

`command -v xargs`의 실패는 PATH에서 명령을 찾을 수 없다는 뜻이다. 패키지가 설치되어 있는데도 찾지 못한다면 PATH도 확인한다.

Wrapper 파일이 존재하는데 실행 권한이 없어 생기는 오류, 잘못된 `JAVA_HOME`, Gradle 배포 파일 다운로드 실패는 각각 다른 원인이다. 오류 메시지와 실패 지점을 기준으로 분리한다.

## 8. 이 사례에서 확인한 결과와 적용 범위

2026-10-15에 Corretto 25 AL2023의 빌드 단계에 `findutils`를 추가한 뒤, Gradle 9.7.1의 실제 JAR 빌드가 성공했다. 로그에서 `findutils` 설치와 `BUILD SUCCESSFUL`을 확인했다.

Linux ARM64의 일반 빌드와 prebuilt 이미지 모두 별도로 검증했다. 두 이미지의 MySQL 연결·health·로그인·세션·복구 CLI도 확인했지만, 이것이 실제 AWS CodeBuild·ECS 배포의 성공을 뜻하지는 않는다. 이 문서 작성 중 해당 빌드·배포 검증을 다시 실행하지는 않았다.

여기서 얻은 교훈은 **Java 도구의 실행 조건에는 JVM 라이브러리뿐 아니라 진입 스크립트가 사용하는 운영체제 명령도 포함된다**는 것이다. 기반 이미지를 바꿀 때는 JDK 버전과 함께 빌드·실행 단계 각각의 도구 의존성을 확인한다.
