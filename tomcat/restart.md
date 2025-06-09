Tomcat의 클린 스타트를 위한 일반적인 방법을 살펴보자.

tomcat 버전은 8.5.70, CentOS Linux release 7.8.2003 (Core) 환경을 전제로 하겠다.
```
# Tomcat 중지
/usr/local/lib/apache-tomcat-8.5.70/bin/shutdown.sh

# work 디렉토리 정리
rm -rf /usr/local/lib/apache-tomcat-8.5.70/work/*

# temp 디렉토리 정리
rm -rf /usr/local/lib/apache-tomcat-8.5.70/temp/*

# Tomcat 시작
/usr/local/lib/apache-tomcat-8.5.70/bin/startup.sh
```

