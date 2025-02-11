# Jenkins

## Jenkins Pipeline

![img.png](https://github.com/jewoodev/blog_img/blob/main/CI_and_CD/Jenkins/Jenkins%ED%8C%8C%EC%9D%B4%ED%94%84%EB%9D%BC%EC%9D%B8.png?raw=true)

시스템 개발은 개발팀에 의해 코드 개발이 완료가 되면 VCM에 코드를 저장한 다음 코드를 빌드하고 테스트 하는 단계로 이루어진다. 그렇게 통합 테스트에 이르기까지 각 단계가 다 끝나야지만 고객이 테스트할 수 있는 UAT(User Acceptance Test) 단계로 넘어갈 수 있다. 그리고 UAT 환경에서의 작업이 마무리되야 그 다음 단계에 속하는 프로덕션 작업으로 넘어간다. 

CI/CD 작업 도구를 쓸 땐 위의 단계들을 자동으로 처리해서 넘어갈 수 있게끔 구성해서 사용한다. 그런 도구들 중 오픈소스이며 가장 많은 플러그인을 제공하는 Jenkins를 사용할 것이다. 

Jenkins에서는 작업의 단위를 아이템이라는 이름으로 부르는데 각각의 단계를 하나의 아이템으로 구성해서 실행할 수 있고, 아이템들을 묶어서 Jenkins Pipeline을 구성해서 실행할 수도 있다. Jenkins Pipeline은 CI/CD 작업에 있어서 필요한 파이프라인을 지원하는 플러그인 이름이다. 

우리는 Jenkins만의 고유한 문법 체계인 DSL을 이용해서 파이프라인 스크립트를 만들 수 있다. 그리고 이 스크립트는 Jenkinsfile이라는 파일명을 갖게끔 되어 있다. Jenkinsfile은 크게 두가지 형태로 만들 수 있는데, Declarative Pipeline과 Scripted Pipeline이 있다.

> DSL(Domain Specific Language): 특정 도메인에 특화된 언어를 말한다. Dockerfile이나 Jenkinsfile같은 것에 DSL이 사용되고 있다.

## Jenkins 세팅

도커를 사용해서 Jenkins를 설치하고 실행할 것이다. 

```yml
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk11
    container_name: jenkins-server
    ports:
      - "8088:8080"
      - "50000:50000"
    volumes:
      - ./volumes/jenkins_home:/var/jenkins_home
    restart: on-failure
```

위와 같이 docker-compose.yml 파일을 만들어서 docker-compose up -d 명령어를 실행하면 Jenkins가 실행된다. 젠킨스가 처음 실행될 때는 초기 비밀번호를 입력해야 하는데, 이 비밀번호는 volumes/jenkins_home/secrets/initialAdminPassword 파일에 저장되어 있다. 아니면 `docker log jenkins-server` 명령어를 통해서도 확인할 수 있다.

![img_1.png](https://github.com/jewoodev/blog_img/blob/main/CI_and_CD/Jenkins/Jenkins_initialAdminPassword.png?raw=true)

이제 8088 포트로 접속해서 Jenkins에 접속한 후에 패스워드를 입력하자.

![img_2.png](https://github.com/jewoodev/blog_img/blob/main/CI_and_CD/Jenkins/%EC%B2%AB_%EB%B9%84%EB%B0%80%EB%B2%88%ED%98%B8_%EC%9E%85%EB%A0%A5%ED%95%98%EB%8A%94_%ED%99%94%EB%A9%B4.png?raw=true)

입력하고 통과되면 suggested plugins을 모두 설치할 건지 아니면 골라서 그것만 설치할 건지 선택지가 주어지는데 여기서는 suggested plugins을 설치하자.

설치가 끝나고 나면 관리자 계정을 만들라는 화면이 나오는데, 여기서 관리자 계정을 만들어주자.

## 첫 작업 만들기

Docker로 세팅했기 때문에 JDK 등의 설치없이 바로 작업을 만드는 것이 가능하다. 왼쪽 내비게이션에 있는 New Item 버튼을 눌러서 새로운 작업을 만들어보자.

작업 이름은 원하는대로 정하면 되는데 필자는 First-Job이라고 지었다. 그리고 템플릿을 선택하면 되는데 이후에 플러그인 추가할게 있어서 Freestyle project를 선택했다.

그 다음 화면에서 소스코드를 어디서 가져온다던가 빌드 방법 등을 설정할 수 있는데 다른 건 건들지 말고 Build Steps에 Shell script를 추가하자.

```shell
echo "Hello, Jenkins!"
java -version
```

그리고 저장해서 작업을 실행시켜보면 해당 작업을 클릭했을 때 Console Output에 위의 스크립트가 실행되는 것을 확인할 수 있다.
