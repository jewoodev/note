# Full Outer Join
MySQL은 풀 아우터 조인은 지원하고 있지 않다. 레프트 조인과 라이트 조인을 UNION 연산하여 처리하자.

# Cross Join
Cartesian 곱 이라고도 부르는 이것은 각 레코드끼리 결합되는 모든 경우의 수를 만들어내는 연산이다.  
이는 다음과 같이 해낼 수 있다.

```sql
SELECT *
FROM table1
CROSS JOIN table2;

-- 동일한 결과
SELECT *
FROM table1, table2;
```

# Left Join
MySQL이 조인 연산할 때 메모리에서 행을 어떻게 처리하는지 알아보자. 이를 이해하면 집계 쿼리의 결과가 잘못 측정될 수 있는 원인을 이해할 수 있다. 

## Nested Loop Join
데이터베이스 엔진이 메모리에서 행을 읽고 비교하는 패턴.  
마치 이중 루프를 사용하는 것처럼 동작한다. 

```
FOR EACH row_left IN left_table:
    matched = false

    FOR EACH row_right IN right_table:
        IF match_function(row_left, row_right) IS TRUE:
            OUTPUT (row_left + row_right)
            matched = true
        
        IF matched = false:
            OUTPUT (row_left + NULL)
```
위와 같은 수도 코드처럼 알고리즘이 동작한다.  
세 가지 핵심 루프가 있어 이를 외부 루프, 내부 루프, Matched Flag라고 불러보자.

외부 루프는 왼쪽 테이블을 순차적으로 스캔한다. 즉, 처음부터 끝까지 모두 읽는다. 여기서 왼쪽 테이블에서 스캔한 로우들을 Driving row라고 부른다. 이 조인 연산을 주제적으로 이끌고 가는 주체적인 row 들이라는 뜻을 갖고 있다.

내부 루프는 Driving row 하나당 오른쪽 테이블 전체를 스캔한다. 마지막으로 Matched Flag는 불리언 변수로 스택 메모리에 저장된다. 

이 연산의 중요 포인트는 비교 연산 횟수가 (왼쪽 테이블 레코드 갯수 * 오른쪽 테이블 레코드 갯수) 라는 것이다. 연산 결과의 로우 수는 그보다 작을 수 있지만 말이다.

## Index Nested Loop Join
내부 루프를 선형 탐색하지 않고 Index 탐색한다. 따라서 시간 복잡도가 O(n * log m)이 된다.

## Block Nested Loop Join
완쪽 테이블을 블록 단위로 메모리에 캐시한다. 이를 통해 디스크 I/O를 줄인다. 

## Hash Join
8.x 버전부터 지원되는 조인으로 ON 절이 `=` 조건이라면 해시 테이블을 사용해 시간 복잡도를 줄인다.  
하지만 이런 최적화 조인들도 내부 동작이 Nested Loop Join과 동일하다.

## Match Function
Left Join에서 ON 절을 Match Function이라고 부른다.

ON 절은 필터라고 여겨지지만 실상은 함수에 가깝다. Match Function은 ON 절에 작성된 불리언 표현식을 평가하는 함수다.  
필터라면 매칭에 실패하면 Driving row가 사라져야 할텐데, 불리언 표현식을 평가하기만 하는 함수이기에 사라지지 않는다.

데이터베이스는 매치 펑션을 처리할 때 구문 분석, 바인딩, 타입, 조건 검사를 수행한다. 이를 위해 매번 이터레이션을 호출한다. 이는 비용을 증가시킬 것 같지만, 내부적으로 inline 함수라는 패턴이 적용되어 최적화되어 있어 함수를 호출하는 오버헤드는 거의 없다.

다만 앞에서 살펴보았듯 연산 횟수 자체는 (왼쪽 테이블 로우 수 * 오른쪽 테이블 로우 수) 가 되어 무시할 수 없는 시간 복잡도를 가진다.

## NULL 처리와 WHERE vs ON 조건의 실행계획
WHERE절과 ON절의 실행계획은 완전히 다르다. 레프트 조인에서 더 중요해지는 이유는 NULL 처리에 있다. ON절은 NULL Padding 이전에 평가하지만 WHERE절은 NULL Padding 후에 평가한다.

NULL Padding 후에 WHERE 절의 조건 평가가 진행되면 NULL 값 비교가 일어날 수 있게 된다. NULL값과의 비교는 SQL의 Three-Valued Logic에 따라 UNKNOWN으로 반환되고 WHERE 절에서 UNKNOWN은 FALSE로 평가된다.
