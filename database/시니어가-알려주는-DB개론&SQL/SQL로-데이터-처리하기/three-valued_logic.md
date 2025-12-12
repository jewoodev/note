# SQL에서 NULL의 의미
- unknown
  - "알려지지 않았다.", 누군가의 생일 정보가 NULL로 처리되어 있다면 분명 그 사람의 생일은 있을 건데 생일이 아직 알려지지 않았다는 의미를 가질 수 있음.
- unavilable or withheld
  - 생일 정보를 공개하지 않은 것. 여러 이유로 그랬을 수 있다. -> "공개하지 않았다."
- not applicable
  - 최근엔 휴대폰이 너무 대중화가 되어 있어 집전화를 설치하지 않는 경우가 많다. 이렇게 집전화 정보를 저장하고 싶은데 집에 집전화가 없으면 해당 사항이 아예 없는 것이다. -> "적용할 수 없다."

SQL에서는 위와 같은 여러 의미들을 NULL 하나로 표현한다. NULL의 의미가 위와 같기 때문에 NULL과 비교를 할 땐 `=`, `!=` 연산자가 성립할 수 없다. 업데이트가 안되거나 공개를 하지 않았을 뿐 같을 수도, 다를 수도 있다. 그래서 SQL에서 NULL과 비교를 할땐 같다, 다르다 라고 단정지을 수가 없다. 그래서 `=` 나 `!=` 비교연산자를 사용하면 안된다. 만약 birth_date가 NULL 인 레코드를 가져오려면 `IS` 를 사용해야 한다.

## NULL과 Three-Valued Logic
NULL과 비교연산을 하게 됐을 때 그 결과를 어떻게 처리하게 되는지 살펴보자.

```sql
SELECT * FROM employee WHERE birth_date = '1990-03-09';
```

employee 테이블

| id | name | birth_date | sex | position | salary | dept_id |
|----|------|------------|-----|----------|--------|---------|
| 1  | ...  | ...        | ... | ...      | ...    | ...     |
| 2  | ...  | NULL       | ... | ...      | ...    | ...     |
| 3  | ...  | NULL       | ... | ...      | ...    | ...     |

위와 같이 테이블이 형성되어 있다면 id가 2, 3 인 레코드의 비교 연산의 결과가 무엇을 리턴할 것 같은가? FALSE를 리턴할 것 같지 않은가? 

하지만 앞서 살펴봤던 것과 같은 의미를 NULL이 갖기 때문에 **FALSE가 아닌 UNKNOWN을 리턴**한다.

- UNKNOWN은 "TRUE 일수도 FALSE 일수도 있다." 라는 의미이다.
- three-valued logic: 비교/논리 연산의 결과로 TRUE, FALSE, UNKNOWN을 가진다.

### UNKWOWN의 논리 연산 결과
논리 연산을 수행할 때 UNKNOWN이 포함되면 어떤 결과가 나오는지 유념해야 한다.

| AND     | TRUE    | FALSE | UNKNOWN |
|---------|---------|-------|---------|
| TRUE    | TRUE    | FALSE | UNKNOWN |
| FALSE   | FALSE   | FALSE | FALSE   |
| UNKNOWN | UNKNOWN | FALSE | UNKNOWN |

| OR      | TRUE | FALSE   | UNKNOWN |
|---------|------|---------|---------|
| TRUE    | TRUE | TRUE    | TRUE    |
| FALSE   | TRUE | FALSE   | UNKNOWN |
| UNKNOWN | TRUE | UNKNOWN | UNKNOWN |

| NOT     |         |
|---------|---------|
| TRUE    | FALSE   |
| FALSE   | TRUE    |
| UNKNOWN | UNKNOWN |

이걸 왜 유념해야 이유는 다음과 같다. 

- WHERE절을 수행하면 WHERE절의 condition(s)의 결과가 TRUE인 tuple(s)만 선택된다. 
- 즉, 결과가 FALSE이거나 UNKNOWN이면 tuple은 선택되지 않는다.

### NOT IN 사용 시 주의사항
`v NOT IN(v1, v2, v3)`는 아래와 같은 의미다.
- v != v1 AND v != v2 AND v != v3

그런데 만약 v1, v2, v3 중 하나가 NULL이라면 어떻게 될까?

| NOT IN 예제             | 결과      |
|-----------------------|---------|
| 3 not in (1, 2, 4)    | TRUE    |
| 3 not in (1, 2, 3)    | FALSE   |
| 3 not in (1, 3, NULL) | FALSE   |
| 3 not in (1, 2, NULL) | UNKNOWN |

three-valued logic에 의해 마지막 예제의 결과가 UNKNOWN이 된다. 