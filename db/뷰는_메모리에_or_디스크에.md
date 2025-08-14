DB의 '뷰'는 메모리에 적재되는 걸까, 디스크에 적재되는 걸까?

뷰는 실제 데이터를 memory나 disk에 **저장하지 않고** 실행되는 시점에 **저장된 쿼리를 실행**시킨다. 즉, "뷰는 쿼리를 저장하고 있다."는 표현이 맞다. ["Views are stored queries that when invoked produce a result set."](https://dev.mysql.com/doc/refman/8.0/en/views.html)을 참고하라.

그렇다고 메모리를 이용하지 않는 건 아니다. 정확한 내부 동작은 잘 모르지만 일반적닌 select와 유사할 것이라고 판단되며 특정 조건이나 limit을 주지 않으면 용량이 큰 뷰가 메모리에 올라가는 문제가 발생할 수 있다. 대용량 데이터가 저장된 table을 where나 limit없이 select 하지 않는 이유와 같다고 볼 수 있다.

# Reference
- [커리어리 답변](https://careerly.co.kr/qnas/2941)