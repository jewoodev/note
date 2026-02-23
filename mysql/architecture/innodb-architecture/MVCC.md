> Multi Version Concurrency Control 의 약자이다.

일반적으로 레코드 레벨의 트랜잭션을 지원하는 DBMS가 제공하는 기능으로, 잠금을 사용하지 않는 일관된 읽기를 하는데에 가장 큰 목적을 두고 있다.  
InnoDB는 언두 로그를 이용해서 이 기능을 구현한다. 어떻게 구현되어 있는지 한 번 알아보자.

만약 `member` 라는 테이블을 생성하고 레코드 하나를 INSERT 했다면, 다음의 그림처럼 바뀔 것이다.

<img src="https://github.com/jewoodev/blog_img/blob/main/mysql/InnoDB_%EC%8A%A4%ED%86%A0%EB%A6%AC%EC%A7%80_%EC%97%94%EC%A7%84/mvcc1.png?raw=true">

그리고 `member` 테이블에 UPDATE 쿼리를 하면 아래처럼 바뀐다.

```sql
UPDATE member SET area="경기" where id=1;
```

<img src="https://github.com/jewoodev/blog_img/blob/main/mysql/InnoDB_%EC%8A%A4%ED%86%A0%EB%A6%AC%EC%A7%80_%EC%97%94%EC%A7%84/mvcc2.png?raw=true">

그림처럼 커밋 여부와 상관없이 버퍼 풀의 레코드는 바로 업데이트 되고 디스크의 데이터 파일의 상태는 시점에 따라 달라질 수 있다.

아직 UPDATE 쿼리를 실행한 세션에서 커밋이나 롤백을 하지 않은 상태에서 다른 세션이 해당 레코드를 조회하면 어디에 있는 걸 조회할까?  
이 질문의 답은 "MySQL 서버의 시스템 변수(transaction_isolation)에 설정된 격리 수준에 따라 달라진다." 이다.

격리 수준이 READ_UNCOMMITTED 이면 버퍼 풀에서 가져오고, READ_COMMITTED 나 그 이상의 격리 수준에서는 언두 로그에서 읽는다.

이렇듯 하나의 레코드에 여러 버전이 유지되며, 필요에 따라 다른 버전을 읽을 수 있는 기능이 MVCC이다.