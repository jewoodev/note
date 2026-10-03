# .zprofile과 .zshrc의 차이와 SDKMAN 초기화 문제 해결

작성·검증일: 2026-10-02

터미널에서는 Java를 찾는데 자동 실행 도구에서는 `Unable to locate a Java Runtime`으로 실패하는 일이 있었다. Java 설치 여부만으로는 설명되지 않는 문제였다. 셸이 어떤 시작 파일을 읽고, 부모 프로세스로부터 어떤 환경을 전달받는지도 확인해야 했다.

이 문서는 zsh의 시작 파일 역할과 실제 관찰 결과, SDKMAN 초기화 설정 변경 및 검증 범위를 정리한다. 여기서 프로젝트 루트는 저장소의 최상위 디렉터리이며, 관리자 계정인 `root`와는 관계없다.

## 1. 로그인 셸과 대화형 셸은 서로 다른 구분이다

**로그인 셸**은 로그인 모드로 시작한 셸이다. **대화형 셸**은 사용자가 명령을 입력하는 대화형 모드로 실행되는 셸이다. 두 속성은 독립적이다. 자동 실행 명령도 `zsh -lc '명령'`처럼 로그인 모드이면서 비대화형으로 실행할 수 있다.

zsh는 로그인 여부에 따라 `.zprofile`을, 대화형 여부에 따라 `.zshrc`를 읽는다. 두 조건을 모두 만족하면 `.zprofile` 다음 `.zshrc` 순서로 읽는다. 일반적인 시작 파일 설정을 기준으로 한 동작이다. [zsh 공식 문서: Startup/Shutdown Files](https://zsh.sourceforge.io/Doc/Release/Files.html)

| 실행 방식 | 로그인 | 대화형 | `.zprofile` | `.zshrc` |
|---|---|---|---|---|
| `zsh -lic '명령'` | 예 | 예 | 읽음 | 읽음 |
| `zsh -lc '명령'` | 예 | 아니요 | 읽음 | 읽지 않음 |
| `zsh -ic '명령'` | 아니요 | 예 | 읽지 않음 | 읽음 |
| `zsh -c '명령'` | 아니요 | 아니요 | 읽지 않음 | 읽지 않음 |

이 표는 두 파일만 비교한다. 실제로는 `.zshenv`, 시스템 설정 파일, 로그인 셸의 `.zlogin` 등도 관련된다. 사용자 설정 위치는 `ZDOTDIR`을 따르며, 미설정이면 홈 디렉터리다. `RCS` 옵션 등으로 시작 파일 읽기를 변경할 수도 있다. [zsh 공식 문서](https://zsh.sourceforge.io/Doc/Release/Files.html)

### .zprofile

로그인 모드에서 필요한 환경 초기화를 배치할 수 있다. 대화형 여부와 무관하게 로그인 셸에서 실행되므로 자동화 도구가 로그인 셸로 시작하는 경우에도 적용된다.

### .zshrc

프롬프트, 별칭, 자동 완성, 대화형 도구 등 대화형 세션의 설정을 배치한다. SDKMAN 초기화를 이 파일에만 넣으면 비대화형 로그인 셸에서는 해당 초기화가 실행되지 않는다.

파일을 읽지 않아도 `JAVA_HOME`이 존재할 수는 있다. 부모 프로세스가 `export`한 환경변수를 자식 프로세스가 물려받을 수 있기 때문이다. 따라서 `echo "$JAVA_HOME"` 결과만으로 어떤 시작 파일이 실행됐는지를 판정하면 안 된다.

## 2. 당시 SDKMAN 설정과 증상

SDKMAN은 `sdkman-init.sh`를 현재 셸에서 `source`하여 초기화한다. 설치된 Java를 사용하는 환경과 `sdk` 명령도 이 초기화와 관련된다. [SDKMAN 공식 설치 안내](https://sdkman.io/install/)

변경 전 설정은 다음과 같았다.

| 파일 | 당시 설정 |
|---|---|
| `~/.zshrc` | `SDKMAN_DIR` 지정 및 `sdkman-init.sh` 실행 |
| `~/.bash_profile` | 같은 SDKMAN 경로의 초기화 스크립트 실행 |
| `~/.zprofile` | SDKMAN 초기화 없음 |

`.bash_profile`은 bash용 설정이고 `.zshrc`는 zsh용 설정이다. 확인한 사용자 설정에는 두 파일이 서로를 불러오는 구문이 없었다. 같은 초기화 코드가 두 파일에 있다는 사실만으로 하나의 zsh에서 두 번 실행된다고 볼 수는 없다.

관찰 결과는 다음과 같았다.

| 실행 환경 | 확인된 결과 |
|---|---|
| 사용자 터미널 | `JAVA_HOME`이 설정되어 있었음 |
| 도구의 기본 프로젝트 디렉터리에서 시작한 실행 | `JAVA_HOME`이 `~/.sdkman/candidates/java/current`를 가리킴 |
| 도구에 `workdir=backend`를 지정해 시작한 실행 | `JAVA_HOME`이 비어 있고 `java`가 `/usr/bin/java`로 해석됨 |
| 기본 프로젝트 디렉터리에서 시작한 뒤 `cd backend` | 기존 환경을 유지하여 Gradle 테스트 성공 |

실패 메시지는 다음과 같았다.

```text
The operation couldn’t be completed. Unable to locate a Java Runtime.
```

`JAVA_HOME`을 명령 앞에 직접 지정하면 테스트는 실행됐다. 하지만 이것은 개별 명령에 환경을 제공하는 우회였으며, 새 셸의 SDKMAN 초기화 문제를 해결한 것은 아니었다.

### backend 디렉터리가 JAVA_HOME을 지운 것은 아니다

사용자가 같은 디렉터리에서 Java를 정상 인식한다는 사실과 도구 실행의 실패는 모순되지 않는다. 사용자의 기존 셸에서 이동하는 것과 도구가 지정된 작업 디렉터리에서 새 실행 환경을 만드는 것은 다른 과정이다.

추가로 다음 로컬 설정을 확인했다.

- `~/.sdkman/candidates/java/current`는 `17.0.19-amzn`을 가리키는 심볼릭 링크였다.
- `backend/.sdkmanrc`에는 `java=17.0.19-amzn`이 지정되어 있었다.
- `~/.sdkman/etc/config`에는 `sdkman_auto_env=true`가 설정되어 있었다.
- 수정 후 `backend`에서 새 셸을 시작하면 `Using java version 17.0.19-amzn in this shell.` 메시지와 구체적인 버전의 `JAVA_HOME` 경로가 확인됐다.

이 설정은 사용자가 `backend`에서 `current` 대신 특정 버전 경로를 본 현상과도 부합한다. 다만 실패 당시 실행 도구가 환경을 상속하거나 초기화하는 내부 과정은 추적하지 않았다. **작업 디렉터리 지정 방식에 따른 환경 차이는 관찰 사실이고, 도구 내부에서 그 차이를 만든 정확한 원인은 미확정이다.**

## 3. 적용한 해결 방법

`~/.zprofile`에 SDKMAN 초기화를 추가하고, 기존 `~/.zshrc`의 초기화도 아래와 같은 조건부 구문으로 변경했다. `.bash_profile`은 변경하지 않았다.

```zsh
export SDKMAN_DIR="$HOME/.sdkman"
if (( ! $+functions[sdk] )) && [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
```

각 부분의 역할은 다음과 같다.

- `SDKMAN_DIR`: SDKMAN 설치 경로를 지정한다.
- `$+functions[sdk]`: 현재 zsh에 `sdk` 함수가 정의되어 있으면 1, 없으면 0이다. 부정 조건을 사용해 함수가 없을 때 초기화한다.
- `-s`: 초기화 스크립트가 존재하고 비어 있지 않은지 확인한다.
- `source`: 별도 프로세스가 아니라 현재 셸에 초기화를 적용한다.

이 구성은 두 진입점을 지원한다.

| 셸 종류 | 초기화 동작 |
|---|---|
| 비대화형 로그인 zsh | `.zprofile`에서 초기화 |
| 대화형 비로그인 zsh | `.zshrc`에서 초기화 |
| 대화형 로그인 zsh | `.zprofile`에서 초기화한 뒤 `.zshrc`에서는 이미 존재하는 함수를 확인하고 생략 |

`JAVA_HOME`의 존재를 검사하는 대신 함수를 검사한 이유는 환경변수만 전달받은 새 zsh에는 `sdk` 함수가 없을 수 있기 때문이다. 여기서는 `sdk`라는 함수명을 SDKMAN이 사용한다는 전제다.

`.zshrc`의 초기화를 통째로 `.zprofile`로 옮기지 않은 이유도 있다. 그렇게 하면 로그인 모드가 아닌 대화형 zsh가 SDKMAN을 초기화할 경로를 잃는다.

## 4. 검증 결과

설정 변경 후, 이전에 실패했던 것과 같이 도구의 작업 디렉터리를 `backend`로 지정해 새 셸을 시작했다. 명령 앞에 `JAVA_HOME`을 별도로 지정하지 않았다.

```text
JAVA_HOME=/Users/jewoo/.sdkman/candidates/java/17.0.19-amzn
/Users/jewoo/.sdkman/candidates/java/17.0.19-amzn/bin/java
openjdk version "17.0.19" 2026-04-21 LTS
sdk: function
```

같은 Gradle 테스트 명령도 성공했다.

```zsh
# backend 디렉터리에서 실행
DOCKER_AUTH_CONFIG='{"auths":{}}' ./gradlew test \
  --tests '*ClaudeWaitingToolTest' \
  --tests '*WaitingToolGatewayTest' \
  --tests '*AnthropicAiGatewayTest' \
  --tests '*S3WaitingVehicleReaderTest' \
  > /private/tmp/logs/issue-42-sdkman-profile-test.log 2>&1
```

```text
> Task :test UP-TO-DATE
BUILD SUCCESSFUL in 315ms
6 actionable tasks: 6 up-to-date
```

이는 **Java를 찾지 못해 Gradle 시작 전에 실패하던 문제의 해결을 확인한 결과**다. 이 실행에서는 테스트 본문을 다시 수행하지 않았으며, 기존 통과 결과를 재사용했다. 앞선 실행에서는 관련 테스트 68개가 통과했다.

로컬 검증 자료는 다음 위치에 있다. 임시 파일이므로 다른 컴퓨터나 향후 시점에 남아 있다고 보장하지 않는다.

- 실패 로그: `/private/tmp/logs/issue-42-diagnostics-without-java-home-test.log`
- 변경 전 루트 셸에서 이동해 성공한 로그: `/private/tmp/logs/issue-42-diagnostics-root-shell-test.log`
- 설정 적용 후 성공 로그: `/private/tmp/logs/issue-42-sdkman-profile-test.log`
- 변경 전 설정 백업: `/private/tmp/sdkman-shell-backup-20261002-145315/`

## 5. 적용 범위와 다시 확인할 때 사용할 명령

이번 변경은 로그인 또는 대화형 zsh의 초기화 경로를 보완한다. **비로그인·비대화형 `zsh -c`까지 두 파일을 읽게 만드는 변경은 아니다.** 그런 실행은 부모 환경을 전달받거나 필요한 초기화를 명시해야 한다. 이미 실행 중인 셸도 파일 변경만으로 즉시 다시 초기화되지는 않는다.

환경이 다르게 보이면 실패한 실행 방식에서 직접 다음을 확인한다.

```zsh
pwd
printf 'login=%s interactive=%s\n' "$options[login]" "$options[interactive]"
printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
command -v java
java -version
whence -w sdk
```

사용자 터미널의 성공과 자동 실행 도구의 성공은 각각 검증해야 한다. 작업 디렉터리만 비교하지 말고 셸 모드, 시작 파일, 환경 상속을 함께 비교한다. SDKMAN 초기화는 자동 환경 전환 메시지를 출력할 수도 있으므로, 표준 출력을 데이터로 해석하는 자동화에서는 이 점도 구분해야 한다.
