Python의 user site는 Python이 사용자별로 설치된 패키지들을 저장하는 디렉토리 경로이다. 이 경로는 다음과 같은 특징을 갖는다.

1. **의미**
   - 이 경로는 현재 사용자에게만 적용되는 'Python 패키지들이 설치되는 위치'이다.
   - 시스템 전체에 영향을 주지 않고 개인적으로 패키지를 설치할 때 사용된다.
   - `pip install --user` 명령어로 설치한 패키지들이 이 경로에 저장된다.
2. **수정 방법**
   - `PYTHONUSERBASE` 환경변수를 설정해 변경할 수 있다.
   - CLI를 통해서는 다음과 같이 수정할 수 있다. 이는 일시적으로 설정되는 환경변수이다.
     - Windows: `set PYTHONUSERBASE=C:\원하는경로`
     - Linux/Mac: `export PYTHONUSERBASE=/원하는경로`
   - **영구적**으로는 다음의 방법으로 변경할 수 있다.
     - Windows: 시스템 환경 변수 설정에서 `PYTHONUSERBASE` 변수를 추가
     - Linux/Mac: `~/.bashrc` 또는 `~/.zshrc` 파일에 export 명령어 추가

pipenv를 설치할 때 기본적으로 해당 경로가 사용되는 것으로 확인된다. 