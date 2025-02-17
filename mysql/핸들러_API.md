# 핸들러 API
MySQL 엔진이 쿼리를 처리하다가 데이터 I/O를 해야할 때는 스토리지 엔진에 요청하는데, 이런 요청을 핸들러(Handler) 요청이라고 하고, 이 요청에 쓰이는 API를 핸들러 API라고 한다.

핸들러 API를 통해 얼마나 많은 I/O 작업이 있었는지는 `SHOW GLOBAL STATUS LIKE 'Handler&';` 명령으로 확인할 수 있다.

<img src="https://github.com/jewoodev/blog_img/blob/main/mysql/%ED%95%B8%EB%93%A4%EB%9F%AC_API/Handler_STATUS_%EC%A1%B0%ED%9A%8C_%EA%B2%B0%EA%B3%BC.png?raw=true">