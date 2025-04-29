HTTPS나 WSS 같은 프로토콜을 사용하기 위해서는 SSL 인증서를 설정해야 한다.

## 1. SSL 인증서 생성하기

```bash
keytool -genkey -alias {your_alias} -storetype PKCS12 -keyalg RSA -keysize 2048 -keystore keystore.p12 -validity 3650
```

이 명령어를 실행하면 다음과 같은 정보를 입력하라는 프롬프트가 나온다.

1. keystore 비밀번호
2. 이름과 성
3. 조직 단위
4. 조직 이름
5. 도시 또는 지역
6. 시/도
7. 국가 코드

## 2. 생성된 keystore.p12 파일을 프로젝트에 추가

- 생성된 `keystore.p12` 파일을 `src/main/resources` 디렉토리에 복사한다.
- `application.yml`에서 설정한 비밀번호를 실제 keystore 비밀번호로 변경한다.

## 3. Spring 설정 파일에 SSL 인증서를 설정하는 부분 추가

```application.yml
server:
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: your-password
    key-store-type: PKCS12
    key-alias: tomcat
  port: 8443
```

