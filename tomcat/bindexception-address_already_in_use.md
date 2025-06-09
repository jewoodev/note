톰캣 서버를 재시작할 때

```
SEVERE [main] org.apache.catalina.core.StandardService.initInternal Failed to initialize connector [Connector[HTTP/1.1-80]]
Caused by: java.net.BindException: Address already in use
```

이런 에러가 발생하면 이는 **포트 80이 이미 사용 중**이라는 것을 나타낸다. 이는 다음과 같은 상황들로 인해 발생할 수 있다:
- 다른 Tomcat 인스턴스가 이미 실행 중
- 다른 웹 서버(예: Apache, Nginx 등)가 80 포트를 사용 중
- 이전 Tomcat 프로세스가 제대로 종료되지 않음

톰캣 서버에 설정된 포트가 80번으로 설정되어있을 수도 있다는 것에 유의하자. 레거시 프로젝트의 경우 이러한 사항들이 잘 파악되어있지 않을 수 있다.

이는 `[톰캣 서버 디렉토리]/conf/server.xml`에 설정 정보가 있을 것이다.

일반적으로 Tomcat의 기본 포트들은 다음과 같다:
- 8080: HTTP 연결을 위한 기본 포트
- 8443: HTTPS 연결을 위한 기본 포트
- 8005: shutdown 포트
- 8009: AJP 연결을 위한 포트

80번 포트는 HTTP의 기본 포트이지만, 일반적으로 Apache HTTPd나 Nginx와 같은 웹 서버가 사용한다. Tomcat을 80포트로 실행하려면:
1. root 권한이 필요하다 (Linux에서 1024 미만의 포트는 root 권한 필요)
2. server.xml에서 명시적으로 포트를 80으로 변경해야 한다

보통의 운영 환경에서는 보안과 관리의 용이성을 위해 Apache/Nginx를 프론트엔드로 두고, 그 뒤에 Tomcat을 8080 포트로 실행하는 구성을 많이 사용한다.
