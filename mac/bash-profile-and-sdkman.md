# .bash_profile의 역할과 SDKMAN 초기화가 필요한 조건

작성·확인일: 2026-10-02

`.bash_profile`의 SDKMAN 설정은 **로그인 bash에서도 Java 환경과 `sdk` 명령을 준비하기 위한 설정**이다. zsh 설정과 내용이 같아도 서로 다른 셸의 진입점을 지원한다. 다만 zsh만 사용한다면 zsh의 동작을 위해 `.bash_profile`까지 설정할 필요는 없다.

## 1. .bash_profile은 언제 읽는 파일인가

로그인 셸은 로그인 모드로 시작한 셸이고, 대화형 셸은 사용자가 명령을 입력하는 대화형 모드의 셸이다. 두 속성은 독립적이다. 예를 들어 `bash -lc '명령'`은 비대화형 로그인 셸이다.

bash는 로그인 시 `/etc/profile`을 읽은 다음, `~/.bash_profile`, `~/.bash_login`, `~/.profile` 순서로 찾아 **존재하고 읽을 수 있는 첫 파일 하나만** 실행한다. 세 사용자 파일을 모두 읽는 것은 아니다. 대화형 비로그인 bash는 `.bashrc`를 읽는다. 로그인 bash가 `.bashrc`까지 읽으려면 보통 로그인 설정에서 명시적으로 불러온다. [GNU Bash 공식 문서: Bash Startup Files](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)

| 실행 예 | `.bash_profile` 자동 읽기 | `.bashrc` 자동 읽기 |
|---|---|---|
| `bash -lic '명령'` | 예 | 아니요 |
| `bash -lc '명령'` | 예 | 아니요 |
| `bash -ic '명령'` | 아니요 | 예 |
| `bash -c '명령'` 또는 `bash script.sh` | 아니요 | 아니요 |

표는 bash라는 이름으로 실행하고 시작 파일을 억제하는 옵션을 지정하지 않은 일반적인 로컬 실행 기준이다. 비대화형 bash는 `BASH_ENV`로 지정된 파일을 읽을 수 있으며, `sh`로 실행하거나 원격 실행 환경을 사용하는 경우에는 별도 규칙이 있다. [GNU Bash 공식 문서](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)

역할상 `.bash_profile`은 zsh의 `.zprofile`, `.bashrc`는 `.zshrc`와 대응한다. 다만 대화형 로그인 zsh는 `.zprofile` 다음 `.zshrc`를 자동으로 읽는 반면, 로그인 bash는 `.bashrc`를 자동으로 읽지 않는다는 차이가 있다. [zsh 공식 문서](https://zsh.sourceforge.io/Doc/Release/Files.html)

## 2. 여기에 SDKMAN 설정이 있는 이유

확인한 `~/.bash_profile`에는 다음 설정이 있었다.

```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

`SDKMAN_DIR`은 설치 경로이고, `-s`는 스크립트가 존재하며 비어 있지 않은지 검사한다. `source`는 스크립트를 별도 프로세스가 아닌 현재 셸에서 실행한다. SDKMAN도 설치 후 새 터미널을 열거나 초기화 스크립트를 `source`하도록 안내한다. [SDKMAN 공식 설치 안내](https://sdkman.io/install/)

이 코드는 **로그인 bash 자체가 SDKMAN을 사용할 수 있게 하는 진입점**이다. 기본 터미널 셸이 zsh여도 사용자나 프로그램이 `bash -l` 또는 `bash -lc '명령'`을 실행할 수 있다. 이때 bash는 zsh의 `.zprofile`이나 `.zshrc`를 자동으로 읽지 않는다.

같은 SDKMAN 설치 디렉터리를 사용하므로 셸마다 Java를 다시 설치하는 것은 아니다. 각 셸에 필요한 함수와 환경을 준비하는 것이다.

### 환경변수 상속과 함수 초기화는 다르다

부모 셸이 내보낸 `JAVA_HOME`과 `PATH`는 자식 bash가 상속할 수 있다. 따라서 SDKMAN 초기화를 하지 않은 bash에서도 이미 전달받은 환경으로 `java`를 실행할 수 있다.

반면 zsh의 `sdk` 함수가 새 bash에 그대로 전달되는 것은 아니다. bash에서 `sdk use java ...`처럼 SDKMAN 기능을 사용하려면 해당 bash에도 초기화가 필요하다. 부모 환경에 Java 설정이 없는 로그인 bash라면 `.bash_profile`의 초기화가 Java 환경을 준비하는 역할도 한다.

따라서 다음은 서로 다른 확인이다.

```bash
printf 'JAVA_HOME=%s\n' "$JAVA_HOME"
command -v java
java -version
type -t sdk
```

앞의 세 명령은 Java 환경과 실행 경로를 확인한다. 마지막 명령이 `function`을 출력하면 현재 bash에 `sdk` 함수가 정의되어 있음을 의미한다. Java 실행 성공만으로 SDKMAN 초기화 여부를 단정하지 않는다.

## 3. 반드시 설정해야 하는가

| 사용하는 방식 | `.bash_profile`의 SDKMAN 설정 필요성 |
|---|---|
| 로그인 bash에서 SDKMAN으로 Java를 선택하거나 관리함 | 해당 bash의 초기화 경로가 필요함 |
| zsh만 사용하고 로그인 bash를 사용하지 않음 | zsh 동작을 위해서는 필요하지 않음 |
| bash에서는 부모로부터 받은 Java 환경으로 실행만 함 | 환경 상속이 보장되면 Java 실행 자체에는 필수가 아님 |
| `bash script.sh` 형태의 자동화만 사용함 | `.bash_profile`을 읽지 않으므로 여기에 넣는 것만으로 해결되지 않음 |
| 대화형 비로그인 bash에서도 `sdk`를 사용함 | `.bashrc` 등 해당 실행의 초기화 경로도 별도로 필요함 |

“zsh에 설정했으니 bash 쪽은 중복이라 지워도 된다”거나 “Java를 사용하려면 무조건 `.bash_profile`에도 넣어야 한다”고 일반화할 수 없다. 실제 사용하는 셸과 실행 모드에 따라 판단한다.

일반 bash 스크립트에서 SDKMAN이 필요하다면 실행 환경을 명시적으로 구성하거나 필요한 초기화를 직접 수행해야 한다. `.bash_profile`이 있다는 이유만으로 모든 bash 실행이 같은 Java 환경을 갖는 것은 아니다.

## 4. 이번 환경에서의 판단

2026-10-02 로컬 파일 확인 결과는 다음과 같다.

- `.bash_profile`에는 SDKMAN 초기화가 있었다.
- 사용자 `.bashrc` 파일은 없었다.
- 확인한 사용자 설정에서 `.bash_profile`과 `.zshrc`가 서로를 불러오는 구문은 없었다.
- 앞선 Java 인식 문제의 수정 대상은 `.zprofile`과 `.zshrc`였으며, `.bash_profile`은 변경하지 않았다.

앞선 문제는 도구가 `backend`를 작업 디렉터리로 지정해 시작한 zsh 실행에서 `JAVA_HOME`이 비어 있던 현상이었다. `.zprofile`과 `.zshrc`에 중복 방지 조건을 둔 SDKMAN 초기화를 적용한 뒤 같은 실행 방식에서 Java를 인식했다. **이 zsh 문제를 해결하기 위해 `.bash_profile`을 수정할 필요는 없었다.**

`.bash_profile`의 기존 설정은 로그인 bash 지원을 유지하도록 남겨 두었다. 로그인 bash를 사용하는 모든 프로그램을 조사한 것은 아니므로 현재 사용 빈도나 제거 시 영향까지 검증한 것은 아니다. 이 문서 작성에서도 홈 설정 파일을 수정하지 않았다.

## 5. zsh의 중복 방지 코드를 그대로 복사하지 않기

zsh에 적용한 `$+functions[sdk]` 조건은 zsh 전용 문법이다. bash에도 중복 초기화 방지가 필요하다면 bash의 함수 검사 구문을 사용한다.

```bash
export SDKMAN_DIR="$HOME/.sdkman"
if ! declare -F sdk >/dev/null && [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
```

`declare -F sdk`는 현재 bash에 `sdk` 함수가 있는지 검사한다. 함수가 없고 초기화 파일이 있을 때만 실행한다. 이는 `sdk`라는 함수명을 SDKMAN이 사용한다는 전제의 **설명용 예시**이며, 실제 `.bash_profile`에 적용한 변경은 아니다.

로그인 bash와 비로그인 대화형 bash를 모두 지원하려면 초기화를 공통 파일에 두고 각 진입점에서 불러오는 구성도 가능하다. 어느 방식을 선택하든 시작 파일을 읽는 조건과 같은 셸에서 두 번 초기화되는 경로를 함께 확인해야 한다.
