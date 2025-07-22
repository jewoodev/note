# Jenkins - Git과 Maven 설정

Jenkins를 처음 실행할 때 Suggested Plugins를 설치하면 Git과 Maven 플러그인이 설치된다. 문제 없이 설치됐는지 확인해보자.

Manage Jenkins > Manage Plugins > Installed 플러그인에서 Git과 Maven 플러그인이 설치되어 있는지 확인한다.

그 후에 Manage Jenkins > Global Tool Configuration에서 Git Installation을 추가적으로 설정해줄건데, Name은 Default로 그대로 두고 Path to Git executable에는 git이라고 적어주자. 컨테이너에 접속해 git 명령어를 사용할 수 있는지 확인해보고 하는 것을 권장한다.

그 다음 Maven을 세팅해줄 건데 먼저 `Maven Integration`이라는 플러그인을 설치해준다. 그 후에 Manage Jenkins > Global Tool Configuration에서 Maven Installation을 추가적으로 설정해줄건데, Name은 원하는 대로 지어주고 version도 원하는 것을 선택하자. 필자는 3.8.5 버전을 선택했다. 그 후 apply, save 해준다.

## Maven 프로젝트 생성

new item을 클릭하고 적당한 이름을 적고 템플릿으로 Maven project를 선택해준다. 그 후에 소스 코드 관리에서 Git을 선택하고 Repository URL에는 본인의 깃 주소를 적어주자. 

그리고 Build 란에 Root POM에 해당 프로젝트의 pom.xml 파일을 지정해주자. Goals and options에는 clean compile package를 적어주자. 그 후에 apply, save 해준다. 그리고 Build Now를 눌러 빌드를 해보자.

# Jenkins - Tomcat 서버 연동

Manage Jenkins > Manage Plugins > Available에서 `Deploy to container Plugin`을 설치해준다.

그리고 Maven Project를 만들어서 소스 코드 관리에서 Git을 선택하고 Repository URL에는 본인의 깃 주소를 적어주자. 그리고 Build 란에 Root POM에 해당 프로젝트의 pom.xml 파일을 지정해주자. Goals and options에는 clean compile package를 적어주자. 

그 후 Post-build Actions에서 빌드 후 어떤 조치를 할지 설정할 건데, Deploy war/ear to a container를 선택해서 war 파일을 배포할 수 있게 해주자. WAR/EAR files에는 **/*.war를 적어주고 Add Container에서 Tomcat 9버전 대를 선택한다. 

그 후 Credentials를 추가할건데 Username과 Password를 입력해주자. 그리고 Tomcat URL에는 본인의 Tomcat 서버 주소를 적어주자. 그 후 apply, save 해준다. 그리고 Build Now를 눌러 빌드를 해보자.

> Username과 Password는 Tomcat 서버에 설정된 계정값을 적어야 한다.
 
톰캣도 도커로 띄울 것이다. 그런데 톰캣 기본 이미지는 관리 앱이 빠진 경우가 있다. 그런데 Jenkins에서 배포할 때는 관리 앱이 필요하므로 관리 앱이 포함된 이미지를 사용하거나 직접 설치해주자. 직접 설치하려면 아래의 명령어들을 사용하자. 참고로 직접 설치하는 것보다는 Tomcat Dockerfile로 설치를 자동화하는 것이 더 좋다.

```bash
docker exec -it tomcat-server bash
apt-get update && apt-get install -y curl
cd /usr/local/tomcat/webapps
curl -O https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz
tar -xzvf apache-tomcat-9.0.85.tar.gz
cp -r apache-tomcat-9.0.85/webapps/manager /usr/local/tomcat/webapps/
cp -r apache-tomcat-9.0.85/webapps/host-manager /usr/local/tomcat/webapps/
exit
docker restart tomcat-server
```

그리고 톰캣 계정이 manager-script 권한을 가지고 있어야 한다. Jenkins가 text API를 사용하기 때문이다. 그러기 위해서는 tomcat-users.xml 파일을 수정해주어야 한다.

```xml
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<user username="admin" password="admin123" roles="manager-gui,manager-script"/>
```

위의 내용을 tomcat-users.xml 파일에 추가해주고 톰캣을 재시작해주자.

