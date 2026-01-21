# Spring boot가 자동으로 등록해주는 DataSource와 TransactionManager

데이터 접근 로직에 사용되는 기능들을 추상화함으로써 확장성과 유지보수성을 높이기 위해 만든 DataSource와 TransactionManager 인터페이스를 Spring boot가 있기 전엔 개발자가 매번 만들어야 했다.

과거에 반복적으로 구현체를 만들던 개발자들의 고민을 해결하기 위해 Spring boot가 자동으로 설정값을 읽어 스프링 빈으로 등록한다.

Spring boot는 application.properties 에 있는 설정값을 읽기 때문에 아래와 같은 속성값을 기입해야 한다.

```
spring.datasource.url=
spring.datasource.username=
spring.datasource.password=
```

# 참고 자료
- [김영한님의 스프링 DB 1편](https://www.inflearn.com/course/%EC%8A%A4%ED%94%84%EB%A7%81-db-1/dashboard)