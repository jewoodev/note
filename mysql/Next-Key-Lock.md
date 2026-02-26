Next-Key Lock은 InnoDB의 기본 잠금 방식으로, Record Lock + Gap Lock의 조합이다.

# 핵심 개념
InnoDB가 인덱스를 스캔할 때, 단순히 해당 레코드만 잠그는 게 아니라 **레코드 + 그 앞의 갭**(gap)까지 함께 잠근다. 이걸 통해 Phantom Read를 방지하는 게 목적이다.

예를 들어 인덱스에 값 10, 13, 20이 있다면, Next-Key Lock이 걸릴 수 있는 범위는:
```
(-∞, 10]
(10, 13]
(13, 20]
(20, +∞)
```

`(10, 13]`이라 하면 10 초과 ~ 13 이하 구간 전체를 잠그는 것이다.

# 구성 요소
- **Record Lock** — 인덱스 레코드 자체에 거는 잠금. PK나 유니크 인덱스로 정확히 한 행을 찾는 경우 이것만 걸린다.
- **Gap Lock** — 인덱스 레코드 사이의 "빈 공간"에 거는 잠금. 해당 갭에 새로운 INSERT가 들어오는 걸 막는다. Gap Lock끼리는 서로 충돌하지 않는다(공유 가능).
- **Next-Key Lock** — 위 둘의 결합. `SELECT ... WHERE age >= 13 AND age <= 20 FOR UPDATE` 같은 범위 조건에서 InnoDB는 해당 범위의 레코드와 갭을 모두 잠근다.

# 동작이 달라지는 케이스
- **유니크 인덱스 + 등가 조건(=)으로 존재하는 행 조회**: Record Lock만 걸린다 (Gap Lock 불필요)
- **유니크 인덱스 + 등가 조건인데 행이 없는 경우**: Gap Lock이 걸린다
- **비유니크 인덱스 또는 범위 조건**: Next-Key Lock이 걸린다
- **격리 수준이 READ COMMITTED**: Gap Lock이 비활성화되어 Record Lock만 사용 → Phantom Read 방지 안 됨

# 실무에서 주의할 점
Next-Key Lock은 의도보다 넓은 범위를 잠글 수 있다. 범위 쿼리에서 실제 매칭되는 행이 적더라도, 인덱스 구조상 다음 레코드까지 잠금이 확장되기 때문에 동시성 문제(데드락, 대기)가 예상보다 심해질 수 있다. 인덱스 설계와 쿼리 조건을 정밀하게 가져가는 게 중요하다.

# 다른 RDBMS와의 비교
- **PostgreSQL** — Next-Key Lock 개념이 없다. 대신 MVCC(SSI: Serializable Snapshot Isolation)를 활용해서 Phantom Read를 방지한다. 갭을 잠그는 게 아니라 트랜잭션 간 읽기/쓰기 의존성을 추적하다가 직렬화 위반이 감지되면 트랜잭션을 롤백시키는 방식이다. 그래서 잠금으로 인한 동시성 저하가 InnoDB보다 적은 대신, serialization failure로 인한 재시도 로직이 필요하다.
- **Oracle** — 마찬가지로 Gap Lock이 없다. MVCC 기반이고, 기본 격리 수준이 READ COMMITTED라서 Phantom Read 방지를 아예 기본으로 제공하지 않는다. SERIALIZABLE로 올려도 잠금이 아닌 스냅샷 기반으로 동작해서 ORA-08177 (can't serialize access) 에러를 던지는 식이다.
- **SQL Server** — Key-Range Lock이라는 유사한 메커니즘이 있다. SERIALIZABLE 격리 수준에서 인덱스 키 범위를 잠가서 Phantom Read를 방지한다. 개념적으로 InnoDB의 Next-Key Lock과 가장 비슷하다.

정리하면, 갭 잠금 방식(비관적)은 InnoDB와 SQL Server, MVCC/스냅샷 기반(낙관적)은 PostgreSQL과 Oracle로 나뉜다. InnoDB는 REPEATABLE READ에서 기본으로 Phantom Read를 막아주지만, 그 대가로 잠금 범위가 넓어질 수 있다는 트레이드오프가 있다.