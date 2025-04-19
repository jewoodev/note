현재 Cursor는 공식적으로 설정과 확장 프로그램을 export/import하는 기능을 제공하지 않는 것으로 파악했다. 

하지만 다음과 같은 방법으로 수동으로 이전할 수 있다.


## 1. 설정 파일 이전

- Windows의 경우 설정 파일은 보통 `%APPDATA%\Cursor` 디렉토리에 있다.
- 이 디렉토리의 내용을 다른 PC의 동일한 위치에 복사하면 됩니다.

## 2. 확장 프로그램

- Cursor의 확장 프로그램은 VS Code와 호환되므로, VS Code의 확장 프로그램 목록을 export/import하는 방법을 사용할 수 있습니다.
- VS Code에서 다음 명령어를 실행하여 확장 프로그램 목록을 export할 수 있다.
    ```bash
    code --list-extensions > extensions.txt
    ```
- 그리고 다른 PC에서 다음 명령어로 import할 수 있다.
    ```bash
    cat extensions.txt | xargs -L 1 code --install-extension
    ```

## 3. 수동 백업

설정 파일과 확장 프로그램을 수동으로 백업하고 복원하는 것이 가장 안전한 방법이다.

Windows의 경우 `%APPDATA%\Cursor `디렉토리를 전체 백업하면 됩니다.

Cursor가 앞으로 이러한 기능을 공식적으로 지원할 가능성이 있지만, 현재는 위의 방법들을 사용해야 합니다.

## 그냥 Extension list 를 관리하는 게 제일 깔끔?

그냥 Extension list를 작성하고, 이를 참고해서 자기가 사용하는 모든 Cursor 에 동일하게 설치하거나 삭제하면 된다.

1. Extension Pack for Java
2. Dev Containvers - ms-vscode-remote
3. Live Server
4. Git Extension Pack
5. Git History
6. gitignore
7. GitLens
8. Gradle for Java
9. IntelliCode
10. IntelliCode API Usage Examples
11. IntelliJ IDEA Keybindings
12. Markdown All in
13. Material Icon Theme
14. Open in Github, Bitbucket, GitLab, ...
15. Project Manager
16. Pylance
17. Python
18. Python Debugger
19. Spring Boot Dashboard
20. Spring Boot Extension Pack
21. Spring Initializer Java Support
22. WSL