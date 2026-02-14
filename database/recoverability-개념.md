# unrecoverable schedule
'schedule 내에서 commit된 transaction'이 'rollback된 transaction이 write 했었던 데이터'를 read한 경우를 말한다.

이런 경우는 rollback을 해도 이전 상태로 회복하는게 불가능할 수 있기 때문에 DBMS가 허용해서는 안 된다.

# recoverable schedule
schedule 내에 그 어떤 transaction도 '자신이 읽은 데이터를 write한 transaction'이 먼저 commit/rollback 하기 전까지 commit하지 않는 경우를 말한다.

이런 경우는 rollback을 하면 이전 상태로 온전히 회복할 수 있기 때문에 DBMS는 이런 schedule만 허용해야 한다.

# cascading rollback
하나의 transaction이 rollback되면 그 transaction에 의존성이 있는 다른 transaction도 rollback되어야 한다.

그런데 cascading rollback은 여러 개의 transaction이 연쇄적으로 일어날 때, 연쇄적으로 일어난 트랜잭션 각각을 이전 상태로 회복시키려면 처리하는 비용이 많이 든다. 이 비용 문제를 어떻게 해결할 수 있을지 고민하다 보니 다음과 같은 결론에 다다르게 됐다.

"데이터를 write한 transaction이 먼저 commit/rollback 한 뒤에 데이터를 읽는 schedule만 허용하자."

# cacadeless schedule
schedule 내에 어떤 transaction도 'commit 되지 않은 transaction들이 write한 데이터'는 읽지 않는 schedule 

# strict schedule
schedule 내에 어떤 transaction도 'commit 되지 않은 transaction들이 write한 데이터'는 읽지도 쓰지도 않는 schedule

이 schedule은 rollback 할 때 recovery가 쉽다. Transaction 이전 상태로 돌려놓기만 하면 된다.
