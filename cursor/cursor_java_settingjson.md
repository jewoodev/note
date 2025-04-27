```json
{
    "window.commandCenter": true,
    "workbench.colorTheme": "Cursor Dark Midnight",
    "workbench.iconTheme": "material-icon-theme",
    "extensions.ignoreRecommendations": true,
    "terminal.integrated.defaultProfile.windows": "Command Prompt",
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-17",
            "path": "C:\\jdk\\jdk-17.0.12",
            "default": true
        }
    ],
    "java.jdt.ls.java.home": "C:\\jdk\\jdk-21.0.7",
    "files.autoSave": "afterDelay",
    "workbench.editor.showTabs": "none",
    "java.saveActions.organizeImports": true,
    "java.completion.importOrder": [
        "java",
        "javax",
        "org",
        "com"
    ],
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.configuration.maven.userSettings": ".mvn/settings.xml",
    "java.signatureHelp.enabled": true,
    "java.completion.enabled": true,
    "java.compile.nullAnalysis.mode": "automatic",
    "java.completion.favoriteStaticMembers": [
        "org.junit.Assert.*",
        "org.junit.Assume.*",
        "org.junit.jupiter.api.Assertions.*",
        "org.assertj.core.api.Assertions.*",
        "org.mockito.Mockito.*",
        "org.mockito.ArgumentMatchers.*",
        "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
        "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*"
    ],
    "java.debug.settings.hotCodeReplace": "auto",
    "java.debug.settings.forceBuildBeforeLaunch": true,
    "java.debug.settings.console": "integratedTerminal",
    "[java]": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": "explicit"
        },
    },
    "cursor.cpp.disabledLanguages": [
        "plaintext"
    ],
    "java.import.gradle.java.home": "C:\\jdk\\jdk-17.0.12"
}
```

1. 코드 포맷팅 관련:
    - `java.format.enabled`: 자동 코드 포맷팅 활성화
    - `java.format.settings.profile`: Google Java Style 가이드 사용
    - `java.saveActions.organizeImports`: 저장 시 자동으로 import 정리
2. 코드 완성 및 편의성:
    - `java.completion.enabled`: 코드 완성 기능 활성화
    - `java.signatureHelp.enabled`: 메서드 시그니처 도움말 활성화
    - `java.semanticHighlighting.enabled`: 시맨틱 하이라이팅 활성화
3. 디버깅 관련:
    - `java.debug.settings.hotCodeReplace`: 실행 중 코드 변경 지원
    - `java.debug.settings.forceBuildBeforeLaunch`: 실행 전 자동 빌드
    - `java.debug.settings.console`: 통합 터미널에서 디버그 콘솔 사용
4. Spring Boot 관련:
    - `spring-boot.ls.trace.server`: Spring Boot Language Server 추적 활성화
    - `spring-boot.ls.java.home`: Spring Boot Language Server용 JDK 경로 설정
5. 테스트 관련:
    - `java.completion.favoriteStaticMembers`: JUnit, Mockito 등의 테스트 관련 정적 멤버 자동 완성 설정

이러한 설정들은 Java와 Spring 개발 시 다음과 같은 이점을 제공합니다:
- 일관된 코드 스타일 유지
- 향상된 코드 완성 및 리팩토링 지원
- 효율적인 디버깅 환경
- Spring Boot 개발을 위한 특화된 지원
- 테스트 코드 작성의 편의성 향상