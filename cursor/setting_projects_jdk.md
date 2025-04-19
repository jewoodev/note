Cursor에서 프로젝트의 JDK를 설정하는 방법을 알아보자. 이 예시는 설정하려는 JDK를 JAVA_HOME로 설정한 후 테스트되었다.

`.vscode/settings.json` 파일을 생성/수정해서 Java 버전을 설정한다.

```json
{
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-17",
            "path": "{Path where your JDK placed}",
            "default": true
        }
    ],
    "java.home": "{Path where your JDK placed}",
    "java.jdt.ls.java.home": "{Path where your JDK placed}",
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.import.gradle.java.home": "{Path where your JDK placed}"
}
```

`{Path where your JDK placed}` 를 설정하려는 JDK 파일을 저장한 후 Cursor를 재시작하면 그 JDK로 설정된다.