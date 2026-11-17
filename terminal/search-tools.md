# fd, ripgrep(PCRE2), fzf로 터미널에서 검색하기

파일을 찾는 작업은 이름이나 경로를 찾는 단계, 파일 안의 내용을 찾는 단계, 후보 중 하나를 고르는 단계로 나눌 수 있다. 세 도구를 이 역할에 맞춰 사용하면 긴 경로를 직접 입력하거나 많은 검색 결과를 스크롤하는 일을 줄일 수 있다.

이 문서는 macOS의 Homebrew와 zsh를 기준으로 한다. 특정 프로젝트나 Neovim, LazyVim이 없어도 사용할 수 있다.

## 1. 도구별 역할

| 도구 | 실행 명령 | 주요 역할 | 사용 예 |
| --- | --- | --- | --- |
| fd | `fd` | 파일·디렉토리 이름 또는 경로 검색 | 이름에 `invoice`가 들어가는 파일 찾기 |
| ripgrep | `rg` | 파일 내용 검색 | `PaymentService`를 참조하는 코드 찾기 |
| PCRE2 | 보통 `rg -P`로 사용 | 추가 정규식 기능을 제공하는 라이브러리 | 앞뒤 문맥 조건이나 역참조로 검색 |
| fzf | `fzf` | 입력받은 목록에서 대화형으로 선택 | 파일 후보를 몇 글자로 좁혀 선택 |

예를 들어 `fd`로 파일 목록을 만들고 `fzf`로 하나를 고르거나, `rg`로 특정 문자열이 있는 파일만 추린 뒤 `fzf`로 선택할 수 있다. PCRE2는 이 과정에 별도 단계를 추가하는 도구가 아니라 `rg`가 선택적으로 사용하는 검색 엔진이다.

공식 설명: [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep), [fzf](https://github.com/junegunn/fzf).

## 2. 설치와 확인

Homebrew로 세 명령을 관리할 수 있다.

```sh
brew install fd ripgrep fzf

fd --version
rg --version
fzf --version
```

패키지 이름은 `ripgrep`이고 실제 명령은 `rg`다. 업데이트할 때는 다음과 같이 실행한다.

```sh
brew upgrade fd ripgrep fzf
```

PCRE2 사용 가능 여부는 `rg --version`의 PCRE2 관련 출력으로 확인한다. 빌드 방식에 따라 지원 여부가 다르므로, 모든 환경에서 `rg -P`가 가능하다고 가정하지 않는다. PCRE2가 Homebrew 의존성으로 설치돼 있다면 `ripgrep`을 유지하는 동안 임의로 제거하지 않는다.

설치와 빌드별 기능은 [fd 설치 안내](https://github.com/sharkdp/fd#installation), [ripgrep 설치 안내](https://github.com/BurntSushi/ripgrep#installation), [fzf 설치 안내](https://github.com/junegunn/fzf#installation)를 참고한다.

## 3. fd: 이름과 경로로 찾기

기본 형식은 `fd [옵션] [패턴] [검색 경로]`다. 검색 경로를 생략하면 현재 디렉토리 아래를 검색한다.

```sh
# 이름에 invoice가 포함된 항목
fd invoice

# src 안에서 이름에 Payment가 포함된 파일만 검색
fd --type f Payment src

# 확장자가 kt인 파일
fd --type f --extension kt . src

# 이름이 test 또는 tests인 디렉토리
fd --type d '^tests?$'

# glob으로 *Service.kt와 일치하는 파일
fd --type f --glob '*Service.kt' src

# 파일 이름이 아닌 전체 경로를 정규식으로 검색
fd --type f --full-path 'src/.*/test/'
```

`src`는 실제로 존재하는 검색 경로로 바꾼다. `.` 패턴은 모든 이름에 일치하도록 사용했다. 패턴이 없는 목록 조회는 `fd --type f`처럼 쓸 수도 있다.

기본 패턴은 정규식이며, 기본적으로 마지막 이름 부분을 대상으로 한다. 경로 전체를 검색하려면 `--full-path`를 사용한다. `--glob`은 셸에서 익숙한 `*`, `?` 패턴을 쓰고 싶을 때 사용한다. glob을 따옴표로 감싸야 셸이 먼저 파일 목록으로 확장하지 않는다.

### 숨김 파일과 제외 규칙

```sh
# 숨김 파일 포함, 기존 ignore 규칙은 유지
fd --hidden --type f config

# ignore 규칙도 해제하되 .git 디렉토리는 제외
fd --hidden --no-ignore --exclude .git --type f config
```

기본적으로 숨김 항목과 ignore 규칙에 걸린 항목은 제외된다. Git 저장소 안에서는 `.gitignore`도 검색 범위에 영향을 준다. `--hidden`만으로 ignore 규칙까지 해제되지는 않는다. 심볼릭 링크 디렉토리 내부를 따라갈 필요가 있을 때만 `--follow`를 추가한다.

옵션의 정확한 범위: [fd 매뉴얼](https://github.com/sharkdp/fd/blob/master/doc/fd.1).

## 4. ripgrep: 파일 안의 내용 찾기

기본 형식은 `rg [옵션] 패턴 [파일 또는 디렉토리]`다. 디렉토리를 지정하면 하위 파일을 재귀적으로 검색한다.

```sh
# src 안에서 문자열이 등장하는 줄과 줄 번호 출력
rg -n 'PaymentService' src

# 정규식 해석 없이 문자열 그대로 검색
rg -n -F 'customer.email' src

# 대소문자를 무시하고 단어 단위로 검색
rg -n -i -w 'timeout' src

# Kotlin 파일만 검색하고 build 경로는 제외
rg -n -g '*.kt' -g '!**/build/**' 'TODO|FIXME' .

# 일치하는 내용을 담은 파일 이름만 출력
rg -l 'PaymentService' src

# 오류가 나온 줄의 앞뒤 3줄까지 출력
rg -n -C 3 'ERROR|Exception' application.log

# 파일 내용을 검색하지 않고 검색 대상 파일 목록만 출력
rg --files -g '*.tf'
```

`-F`는 점이나 괄호가 들어간 텍스트를 그대로 찾을 때 편하다. 기본 정규식에서 `.`은 임의의 문자이므로, `customer.email`과 문자 그대로 일치시키려면 `-F` 또는 이스케이프가 필요하다.

`rg --files`는 예외적으로 내용 대신 파일 목록을 출력한다. 파일 이름 검색은 `fd`, 내용 검색은 `rg`를 먼저 떠올리면 일상적인 사용이 단순해진다.

### 검색되지 않는 파일이 있을 때

```sh
# 숨김 파일 포함, .git 제외
rg --hidden -g '!.git/**' -n 'TODO' .

# ignore 규칙도 해제하되 생성물은 명시적으로 제외
rg --hidden --no-ignore -g '!.git/**' -g '!**/node_modules/**' -n 'TODO' .
```

기본 검색은 숨김 파일·ignore 대상·바이너리 파일 등을 걸러낸다. 검색 결과가 없다고 파일이나 문자열이 없다고 단정하기 전에 검색 경로와 필터를 확인한다. 바이너리로 감지된 파일을 텍스트로 읽으려면 `--text`가 필요하지만, 일반 소스 검색에 상시 적용할 필요는 없다.

`rg`의 종료 코드는 보통 일치 결과가 있으면 `0`, 없으면 `1`, 오류가 나면 `2`다. 스크립트에서는 검색 결과 없음과 명령 실행 오류를 구분한다.

기본 검색·필터 설명: [ripgrep 사용자 가이드](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md).

## 5. PCRE2: 일반 정규식으로 표현하기 어려울 때

일반적인 문자열·선택 패턴·반복 검색에는 `rg` 기본 엔진으로 충분하다. 기본 엔진은 look-around와 역참조를 지원하지 않으며, 필요할 때 `-P` 또는 `--pcre2`로 PCRE2를 선택한다.

```sh
# customer. 바로 뒤에 있는 email만 추출: 뒤쪽이 아닌 앞쪽 문맥을 검사하는 look-behind
rg -n -o -P '(?<=customer\.)email' src

# 공백을 사이에 두고 같은 단어가 두 번 연속 등장하는 줄
rg -n -P '\b(\w+)\s+\1\b' notes.txt
```

첫 번째 패턴의 `(?<=...)`는 앞쪽 문맥을 조건으로 검사하지만 그 문맥을 일치 결과에는 포함하지 않는다. 두 번째 패턴의 `(\w+)`는 단어를 캡처하고, `\1`은 캡처한 내용과 같은 문자열을 다시 요구한다. 예를 들어 `very very`가 일치한다.

PCRE2는 표현력이 넓지만 모든 패턴에서 기본 엔진보다 빠르다는 의미는 아니다. 우선 단순한 검색을 사용하고 필요한 기능이 있을 때만 선택한다. 위 예제는 각 줄 안의 검색이며, 여러 줄에 걸친 검색은 별도로 `--multiline`과 패턴을 검토해야 한다.

지원 기능과 엔진 선택: [ripgrep 공식 설명](https://github.com/BurntSushi/ripgrep#why-should-i-use-ripgrep).

## 6. fzf: 후보 목록에서 대화형으로 고르기

`fzf`는 입력 목록을 필터링한다. 파일 내용 검색 자체를 대체하지 않으며, 직접 실행할 때는 내장 파일 탐색 기능으로 후보를 만들 수도 있다. 다른 도구의 결과를 파이프로 넘기면 후보를 어디서 가져왔는지 명확해진다.

```sh
# 파일 목록에서 선택
fd --type f | fzf

# PaymentService를 포함하는 파일 중 선택
rg -l 'PaymentService' src | fzf

# 최근 커밋 목록에서 선택
git log --oneline -50 | fzf
```

화면이 열리면 이름 일부를 입력해 후보를 좁히고 방향키로 이동한다. `Enter`로 선택하면 항목이 표준 출력으로 나오며 `Esc` 또는 `Ctrl+C`로 취소한다. 선택만으로 파일을 열거나 커밋을 변경하지는 않는다.

퍼지 검색은 입력한 문자가 연속하지 않아도 순서대로 포함되는 후보를 찾는 방식이다. 파일 이름 전체를 기억하지 못할 때 유용하다. 다음 예제는 대화형 화면 없이 필터 결과를 출력한다.

```sh
fd --type f | fzf --filter 'payment'
```

파일명에 줄바꿈이 있으면 줄 단위 파이프는 경계를 구분하지 못한다. 이런 경로까지 다뤄야 한다면 NUL로 구분한다.

```sh
fd --type f --print0 | fzf --read0 --print0
```

이 출력 역시 NUL 구분이므로, 다음 명령도 이를 지원해야 한다. 일반적인 파일명에 공백이 있는 것과 파일명에 줄바꿈이 있는 것은 다른 문제다. `fzf` 출력을 따옴표 없이 명령 인수로 확장하지 않는다.

검색·선택·NUL 옵션: [fzf 매뉴얼](https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1).

## 7. zsh에서 명령 기록과 파일 선택에 연결하기

설치만 해도 `fzf` 명령은 사용할 수 있다. 키 바인딩과 자동완성까지 쓰려면 `~/.zshrc`에 셸 연동을 추가한다. `.zprofile`은 로그인 셸용이고, 키 입력 기능은 대화형 셸용 `.zshrc`에 두는 것이 적절하다.

```sh
# ~/.zshrc: fzf가 PATH에 들어온 뒤 초기화
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
```

기존 파일 전체를 덮어쓰지 말고 이미 같은 초기화가 있는지 확인한 뒤 한 번만 추가한다. 새 터미널을 열면 적용된다.

| 키 | 기능 |
| --- | --- |
| `Ctrl+R` | 명령 기록에서 찾아 현재 명령줄에 가져오기 |
| `Ctrl+T` | 파일·디렉토리를 찾아 현재 명령줄에 삽입 |
| `Alt+C` | 디렉토리를 찾아 이동 |

단축키는 다른 셸 플러그인이나 터미널 키 설정과 충돌할 수 있다. macOS에서 `Alt+C`는 터미널의 Option 키 전송 설정에 따라 별도 조정이 필요할 수 있다. 명령 기록에서 가져온 명령은 실행 전에 내용을 확인한다.

기본 파일 후보 생성에 `fd`를 쓰고 싶으면 위 초기화 앞에 다음 설정을 추가한다.

```sh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
```

이 예제의 `Ctrl+T`는 파일만 선택하도록 바뀐다. 숨김 파일은 포함하지만 ignore 규칙은 유지한다. 변수는 서로 다른 사용처를 제어하므로 `FZF_DEFAULT_COMMAND` 하나만 설정해 모든 단축키가 같은 후보를 사용한다고 가정하지 않는다. 이미 파이프로 후보를 전달한 명령에는 그 입력 목록이 사용된다.

연동 방식과 설정 예제: [fzf 셸 연동](https://github.com/junegunn/fzf#setting-up-shell-integration), [fzf와 fd 조합](https://github.com/junegunn/fzf#respecting-gitignore).

## 8. 상황별로 선택하기

| 하고 싶은 일 | 먼저 사용할 명령 |
| --- | --- |
| 이름에 invoice가 있는 파일 찾기 | `fd --type f invoice` |
| 특정 설정 문자열의 사용처 찾기 | `rg -n -F 'feature.enabled' .` |
| 오류가 난 위치와 주변 로그 읽기 | `rg -n -C 3 'ERROR' application.log` |
| 조건에 맞는 파일에서 하나 선택하기 | `rg -l 'PaymentService' src \| fzf` |
| 예전에 실행한 명령 다시 찾기 | 셸 연동 후 `Ctrl+R` |
| 같은 단어의 반복 같은 패턴 검색 | `rg -P '\b(\w+)\s+\1\b' notes.txt` |

처음에는 `fd`, `rg -n`, `rg -l`, `fzf`만 익혀도 충분하다. 검색 범위를 먼저 줄이고, 정규식 기능이나 셸 설정은 실제 필요가 생길 때 추가한다. `find`, `grep`도 환경에 따라 유용하므로 기존 명령을 무조건 alias로 대체할 필요는 없다.
