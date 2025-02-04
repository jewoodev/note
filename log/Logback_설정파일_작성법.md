# Logback 설정 파일 작성법

Logback은 SLF4J(Simple Logging Facade for Java)의 구현체로, 로깅 프레임워크 중 하나이다. 

이것 말고도 Log4j, Log4j2, JUL(Java Util Logging) 등이 있지만, Logback은 Log4j보다 성능이 좋고, Log4j2보다 설정이 간단하다. 그래서 Spring Boot에서 기본 로깅 프레임워크로 사용된다.

Log4j, Log4j2, JUL 모두 SLF4J 인터페이스의 구현체이므로 Logback을 사용하다가 Log4j2로 바꾸더라도 코드를 바꿀 필요가 없다. 이런 설계는 Spring framework에서 중요하게 다뤄지는 PSA(Portable Service Abstraction)의 한 예이다. Transactional Annotation도 PSA의 대표적인 예시이다.

Logback 설정 파일은 XML, Groovy, JSON 등으로 작성할 수 있다. 여기서는 XML로 작성하는 방법을 알아보자.

> resources 디렉토리에 logback.xml 파일을 생성한다. logback.xml 파일은 Logback 설정 파일의 기본 이름이다. 만약 다른 이름으로 설정 파일을 사용하고 싶다면, logback 설정 파일을 지정해주어야 한다.
> 
> 그리고 Logback 설정 파일의 이름 뒤에 스프링 profile을 지정할 수 있다. 예를 들어, logback-dev.xml, logback-prod.xml 등으로 설정 파일을 작성할 수 있다.

```xml
<configuration>
    <property name="LOG_FILE" value="application.log"/>

    <!-- 콘솔 출력 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- 파일 출력 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_FILE}</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>application.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- Logger 설정 -->
    <root level="info">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

위의 설정 파일은 콘솔 출력과 파일 출력을 설정한 것이다. 

- property : 변수를 설정할 때 사용한다. ${LOG_FILE}은 application.log를 의미한다.
- appender : 로그를 출력하는 방법을 설정한다. CONSOLE은 콘솔에 출력하고, FILE은 파일에 출력한다.
- root : 로그 레벨을 설정한다. info 레벨 이상의 로그만 출력한다. 이와 비슷하게 세부적인 패키지를 지정할 수도 있다.

## Appender 활용법

Logback에서는 다양한 Appender를 제공한다. 주로 사용하는 Appender는 다음과 같다.

1. ConsoleAppender : 콘솔에 로그를 출력한다.
   1. encoder : 로그를 출력할 때 어떤 패턴으로 출력할지 설정한다. 패턴을 지정할 수 있는 문법으로 예시에서 사용한 것은 아래와 같다.
      1. %d : 날짜
      2. %-5level : 로그 레벨
      3. %thread : 스레드 이름
      4. %logger{36} : 로거 이름
      5. %msg : 로그 메시지
      6. %n : 줄바꿈
   2. target : 콘솔에 출력할 때 System.out 또는 System.err 중 어디에 출력할지 설정한다.
2. FileAppender : 파일에 로그를 출력한다.
   1. file : 로그 파일의 경로를 설정한다.
   2. append : 로그를 추가할지 덮어쓸지 설정한다.(기본값: true)
3. RollingFileAppender : 파일에 로그를 출력하되, 자동으로 롤링(분할)하여 관리한다.
   1. rollingPolicy : 롤링 정책을 설정한다.
      1. TimeBasedRollingPolicy : 시간 단위로 롤링한다.
         1. fileNamePattern : 롤링 파일의 이름 패턴을 설정한다. `%d{yyyy-MM-dd}`의 형태로 날짜를 지정하면 1일 단위로 롤링한다. 2일 단위로 롤링하고 싶다면 `%d{yyyy-MM-dd-2}`로 설정한다. 분 단위로 설정하고 싶다면 `%d{yyyy-MM-dd-HH-mm}`로 설정한다.
      2. SizeAndTimeBasedRollingPolicy : 파일 크기와 시간 단위로 롤링한다.
         1. fileNamePattern : 롤링 파일의 이름 패턴을 설정한다. 
         2. maxFileSize : 롤링 파일의 최대 크기를 설정한다.
         3. totalSizeCap : 롤링 파일의 최대 크기를 설정한다.
      3. maxHistory : 롤링 파일의 최대 개수를 설정한다.

로그가 너무 많이 쌓이면, 로그 파일이 너무 커지기 때문에 롤링 정책을 설정하여 로그 파일을 관리하는 것이 좋다. 더 나아가서 압축을 하는 방법으로 로그 파일 용량을 줄일 수도 있다.

압축을 시키는 방법으로 보통 활용하는 방법은 gzip 압축을 사용하는 것이다. 이를 위해 logback에서는 `Compress` 클래스를 제공한다.

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>${LOG_FILE}</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>application.%d{yyyy-MM-dd}.log</fileNamePattern>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n</pattern>
    </encoder>
    <compress class="ch.qos.logback.core.rolling.helper.Compression">
        <compressionMode>COMPRESS</compressionMode>
        <fileNamePattern>application.%d{yyyy-MM-dd}.log.gz</fileNamePattern>
    </compress>
</appender>
```

그런데 꼭 Compress 클래스를 사용하지 않아도 gzip 압축을 사용할 수 있다. 다음과 같이 설정하면 된다.

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>${LOG_FILE}</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>application.%d{yyyy-MM-dd}.log.gz</fileNamePattern>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level [%thread] %logger{36} - %msg%n</pattern>
    </encoder>
</appender>
```

## Spring profile를 활용해서 설정 파일 분리하기

Spring profile을 활용하면 설정 파일을 분리할 수 있다. 예를 들어, 개발 환경에서는 로그를 콘솔에 출력하고, 운영 환경에서는 파일에 출력하고 싶다면, 다음과 같이 설정할 수 있다.

1. resources 디렉토리에 logback-dev.xml, logback-prod.xml 파일을 생성한다.
2. application.properties 파일에 `spring.profiles.active`를 설정한다.

```properties
spring.profiles.active=dev
logging.config=classpath:logback-dev.xml
```

logging.config의 classpath는 resources 디렉토리를 기준으로 한다. 그래서 resources 하위에 있는 logback-${spring.profiles.active}.xml 파일을 찾을 수 있다.

운영 환경의 설정 파일도 개발 환경과 같은 방법으로 설정할 수 있다.

```properties
spring.profiles.active=prod
logging.config=classpath:logback-prod.xml
```

spring.profiles.active를 설정하면, 해당 프로필에 맞는 설정 파일을 읽어온다. 깔끔하게 application.properties 파일을 환경별로 분리해서 만들어두고 각 환경에 맞는 설정 파일을 만들어두면, 개발 환경과 운영 환경에서 로그 설정을 쉽게 변경할 수 있다. application-dev.properties, application-prod.properties 파일을 만들고 거기에 logging.config를 설정해두면 된다.