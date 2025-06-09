하나의 서버에서 여러 개의 어플리케이션을 deploying 하다보면 여러 버전의 java를 세팅하게 될 수 있다.

그럴 때 특정 버전에서만 정상작동하는 레거시 애플리케이션이 있는데 os에 세팅된 java가 호환되지 않는 버전으로 설정될 수 있고, 그러면 tomcat server startup 에 실패한다.

그렇게 실패했을 때의 로그 내용은 아래와 같다.
```
[:: MainServlet.forwardErrorScreen :javax/xml/bind/DatatypeConverter ::]
09-Jun-2025 10:17:27.635 INFO [main] org.apache.catalina.core.StandardServer.await A valid shutdown command was received via the shutdown port. Stopping the Server instance.
09-Jun-2025 10:17:27.635 INFO [main] org.apache.coyote.AbstractProtocol.pause Pausing ProtocolHandler ["http-nio-80"]
09-Jun-2025 10:17:27.641 INFO [main] org.apache.catalina.core.StandardService.stopInternal Stopping service [Catalina]
09-Jun-2025 10:17:27.657 WARNING [localhost-startStop-2] org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesJdbc The web application [ROOT] registered the JDBC driver [org.apache.commons.dbcp.PoolingDriver] but failed to unregister it when the web application was stopped. To prevent a memory leak, the JDBC Driver has been forcibly unregistered.
09-Jun-2025 10:17:27.657 WARNING [localhost-startStop-2] org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesJdbc The web application [ROOT] registered the JDBC driver [com.mysql.jdbc.Driver] but failed to unregister it when the web application was stopped. To prevent a memory leak, the JDBC Driver has been forcibly unregistered.
09-Jun-2025 10:17:27.658 WARNING [localhost-startStop-2] org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesThreads The web application [ROOT] appears to have started a thread named [Timer-0] but has failed to stop it. This is very likely to create a memory leak. Stack trace of thread:
 java.base@17.0.12/java.lang.Object.wait(Native Method)
 java.base@17.0.12/java.lang.Object.wait(Object.java:338)
 java.base@17.0.12/java.util.TimerThread.mainLoop(Timer.java:537)
 java.base@17.0.12/java.util.TimerThread.run(Timer.java:516)
09-Jun-2025 10:17:27.658 WARNING [localhost-startStop-2] org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesThreads The web application [ROOT] appears to have started a thread named [Abandoned connection cleanup thread] but has failed to stop it. This is very likely to create a memory leak. Stack trace of thread:
 java.base@17.0.12/java.lang.Object.wait(Native Method)
 java.base@17.0.12/java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:155)
 com.mysql.jdbc.AbandonedConnectionCleanupThread.run(AbandonedConnectionCleanupThread.java:41)
09-Jun-2025 10:17:27.659 WARNING [localhost-startStop-2] org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesObjectStreamClassCaches Failed to clear soft references from ObjectStreamClass$Caches for web application [ROOT]
        java.lang.ClassCastException: class java.io.ObjectStreamClass$Caches$1 cannot be cast to class java.util.Map (java.io.ObjectStreamClass$Caches$1 and java.util.Map are in module java.base of loader 'bootstrap')
                at org.apache.catalina.loader.WebappClassLoaderBase.clearCache(WebappClassLoaderBase.java:2331)
                at org.apache.catalina.loader.WebappClassLoaderBase.clearReferencesObjectStreamClassCaches(WebappClassLoaderBase.java:2306)
                at org.apache.catalina.loader.WebappClassLoaderBase.clearReferences(WebappClassLoaderBase.java:1675)
                at org.apache.catalina.loader.WebappClassLoaderBase.stop(WebappClassLoaderBase.java:1605)
                at org.apache.catalina.loader.WebappLoader.stopInternal(WebappLoader.java:455)
                at org.apache.catalina.util.LifecycleBase.stop(LifecycleBase.java:257)
                at org.apache.catalina.core.StandardContext.stopInternal(StandardContext.java:5505)
                at org.apache.catalina.util.LifecycleBase.stop(LifecycleBase.java:257)
                at org.apache.catalina.core.ContainerBase$StopChild.call(ContainerBase.java:1443)
                at org.apache.catalina.core.ContainerBase$StopChild.call(ContainerBase.java:1432)
                at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
                at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
                at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
                at java.base/java.lang.Thread.run(Thread.java:842)
09-Jun-2025 10:17:27.666 INFO [main] org.apache.coyote.AbstractProtocol.stop Stopping ProtocolHandler ["http-nio-80"]
09-Jun-2025 10:17:27.669 INFO [main] org.apache.coyote.AbstractProtocol.destroy Destroying ProtocolHandler ["http-nio-80"]
NOTE: Picked up JDK_JAVA_OPTIONS:  --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED
09-Jun-2025 10:17:54.881 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version name:   Apache Tomcat/8.5.70
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server built:          Aug 9 2021 16:17:14 UTC
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version number: 8.5.70.0
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Name:               Linux
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Version:            3.10.0-1127.19.1.el7.x86_64
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Architecture:          amd64
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Java Home:             /usr/lib/jvm/jdk-17.0.12-oracle-x64
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Version:           17.0.12+8-LTS-286
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Vendor:            Oracle Corporation
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_BASE:         /usr/local/lib/apache-tomcat-8.5.70
09-Jun-2025 10:17:54.884 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_HOME:         /usr/local/lib/apache-tomcat-8.5.70
09-Jun-2025 10:17:54.886 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.lang=ALL-UNNAMED
09-Jun-2025 10:17:54.890 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.io=ALL-UNNAMED
09-Jun-2025 10:17:54.890 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.util=ALL-UNNAMED
09-Jun-2025 10:17:54.890 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.base/java.util.concurrent=ALL-UNNAMED
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.config.file=/usr/local/lib/apache-tomcat-8.5.70/conf/logging.properties
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djdk.tls.ephemeralDHKeySize=2048
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.protocol.handler.pkgs=org.apache.catalina.webresources
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dorg.apache.catalina.security.SecurityListener.UMASK=0027
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dignore.endorsed.dirs=
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.base=/usr/local/lib/apache-tomcat-8.5.70
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.home=/usr/local/lib/apache-tomcat-8.5.70
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.io.tmpdir=/usr/local/lib/apache-tomcat-8.5.70/temp
09-Jun-2025 10:17:54.891 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent The Apache Tomcat Native library which allows using OpenSSL was not found on the java.library.path: [/usr/java/packages/lib:/usr/lib64:/lib64:/lib:/usr/lib]
09-Jun-2025 10:17:54.924 INFO [main] org.apache.coyote.AbstractProtocol.init Initializing ProtocolHandler ["http-nio-80"]
09-Jun-2025 10:17:54.946 INFO [main] org.apache.tomcat.util.net.NioSelectorPool.getSharedSelector Using a shared selector for servlet write/read
09-Jun-2025 10:17:54.969 INFO [main] org.apache.catalina.startup.Catalina.load Initialization processed in 628 ms
09-Jun-2025 10:17:55.000 INFO [main] org.apache.catalina.core.StandardService.startInternal Starting service [Catalina]
09-Jun-2025 10:17:55.001 INFO [main] org.apache.catalina.core.StandardEngine.startInternal Starting Servlet engine: [Apache Tomcat/8.5.70]
09-Jun-2025 10:17:56.822 INFO [localhost-startStop-1] org.apache.jasper.servlet.TldScanner.scanJars At least one JAR was scanned for TLDs yet contained no TLDs. Enable debug logging for this logger for a complete list of JARs that were scanned but no TLDs were found in them. Skipping unneeded JARs during scanning can improve startup time and JSP compilation time.
log4j: Threshold ="null".
log4j: Level value for root is  [debug].
log4j: root level set to DEBUG
log4j: Class name: [org.apache.log4j.DailyRollingFileAppender]
log4j: Setting property [file] to [D:/Project/Heribio_MTicketSettle/logs/Heribio_MTicketSettle.log].
log4j: Setting property [datePattern] to ['.'yyyy-MM-dd].
log4j: Parsing layout of class: "org.apache.log4j.PatternLayout"
log4j: Setting property [conversionPattern] to [%d{yyyy-MM-dd HH:mm:ss} [%p] %c{1} : %m%n].
log4j: setFile called: D:/Project/Heribio_MTicketSettle/logs/Heribio_MTicketSettle.log, true
log4j: setFile ended
log4j: Appender [fileAppender] to be rolled at midnight.
log4j: Adding appender named [fileAppender] to category [root].
log4j: Class name: [org.apache.log4j.ConsoleAppender]
log4j: Setting property [threshold] to [TRACE].
log4j: Parsing layout of class: "org.apache.log4j.PatternLayout"
log4j: Setting property [conversionPattern] to [%d{yyyy-MM-dd HH:mm:ss} [%p] [%C.%M():%L] %m%n].
log4j:WARN No such property [fatalErrorColor] in org.apache.log4j.PatternLayout.
log4j:WARN No such property [errorColor] in org.apache.log4j.PatternLayout.
log4j:WARN No such property [warnColor] in org.apache.log4j.PatternLayout.
log4j:WARN No such property [infoColor] in org.apache.log4j.PatternLayout.
log4j:WARN No such property [debugColor] in org.apache.log4j.PatternLayout.
log4j: Adding appender named [CONSOLE] to category [root].
2025-06-09 10:17:56 [INFO] [kr.co.ekooniz.lib.util.LogManager.log():186]
CommonConfig(www)[
Read default config file : /home/heribio/config/www.config
]
-------------------------------------------------------------------------------
2025-06-09 10:17:56 [INFO] [kr.co.ekooniz.lib.util.LogManager.log():186]
CommonConfig.setOtherProperties[
Config �����珥�린������듬���
]
-------------------------------------------------------------------------------
2025-06-09 10:17:56 [INFO] [kr.co.ekooniz.lib.util.LogManager.log():186]
CommonConfig.setOtherProperties[
Config �����珥�린������듬���
]
-------------------------------------------------------------------------------
2025-06-09 10:17:56 [INFO] [kr.co.ekooniz.lib.util.LogManager.log():186]
CommonConfig(www)[
Config files have been initialized.
]
-------------------------------------------------------------------------------
[:: Framework Start ::]
09-Jun-2025 10:17:57.004 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-nio-80"]
09-Jun-2025 10:17:57.013 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 2043 ms
2025-06-09 10:18:29 [DEBUG] [kr.co.ekooniz.lib.util.LogManager.log():144]
[
[parameter name]/[value]
                [command]/[point_list]
                [_authkey]/[???]
                [admin_id]/[dev01@heribio.com]

]
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
=============== reloanding ===================
[:: MainServlet.forwardScreen :javax/xml/bind/DatatypeConverter ::]
2025-06-09 10:18:29 [ERROR] [kr.co.ekooniz.lib.util.LogManager.exceptionLog():103]
[오류번호][null]
[오류제목][null]
[오류내용][
kr.co.ekooniz.lib.web.URLMapping.URLManager.getURLEntity() : Line Number -> 148
        kr.co.ekooniz.lib.web.URLMapping.URLManager.getURL() : Line Number -> 84
                kr.co.ekooniz.lib.web.action.ScreenFlowManager.getURLMapping() : Line Number -> 31
null]
[오류처치법][null]
[
URL : admin_report.do URLEntity媛�議댁���� ������.
]
-------------------------------------------------------------------------------
[:: MainServlet.forwardErrorScreen :javax/xml/bind/DatatypeConverter ::]
```

로그에서도 Java 버전과 Tomcat 버전의 호환성 문제가 보인다.
- Java 17.0.12를 사용 중
- Tomcat 8.5.70 (2021년 8월 버전)
- `javax.xml.bind.DatatypeConverter` 관련 오류는 Java 9+ 버전에서 자주 발생하는 문제

## CentOS 서버 Java 버전 변경

```
[root@heri2go-op-web-pay001 apache-tomcat-8.5.70]# alternatives --config java

There are 2 programs which provide 'java'.

  Selection    Command
-----------------------------------------------
 + 1           java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el7_9.x86_64/jre/bin/java)
*  2           /usr/lib/jvm/jdk-17.0.12-oracle-x64/bin/java

Enter to keep the current selection[+], or type selection number:
```

`alternatives --config java` 명령어를 사용하면 설치된 jdk 리스트를 확인할 수 있다. 그리고 원하는 버전의 selection number를 입력해서 설정할 수 있다.