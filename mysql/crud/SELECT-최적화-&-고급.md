# 검색 쿼리
일반적인 인덱스 구조에서는 검색 쿼리가 큰 효과를 내지 못한다. 큰 효과를 내기 위해서는 역 인덱스 구조를 사용할 수 있어야 한다. 역 인덱스를 사용하려면 ElasticSearch가 가장 대표적으로 사용할 수 있는 검색 엔진 옵션이다. MySQL도 비슷한 효과를 낼 수 있지만 역 인덱스에 비해 유동적이지 못하고 효과적이지 못한다. 검색 엔진까지는 필요하지 않고 시간이 없다면 MySQL의 Full Text Search로 해결하는 것이 좋지만, 형태소 분석과 더불어 더 자세하고 유연한 설정을 통해 검색 기능을 구현하고 싶다면 역 인덱스 구조를 가지고 있는 ElasticSearch를 사용하는 것이 좋다.

다음으로 MySQL의 검색 쿼리 최적화 방법을 알아보자.

```sql
-- 전문 검색 인덱스 활용 (가장 효율적, Full Text Index 필요)
SELECT post_id, title, content
FROM post
WHERE MATCH(title, content) AGAINST('의자' IN NATURAL LANGUAGE MODE);

-- 접두사 선택 (인덱스 활용 가능)
SELECT member_id, username
FROM member
WHERE username LIKE 'jewoo%';

-- 복합 검색 조건
SELECT post_id, title
FROM post
WHERE status = 'PUBLISHED'
  AND (
      title LIKE '%책상%'
       OR content LIKE '%가성비%'
    ) 
ORDER BY created_at DESC
```

- `IN NATURAL LANGUAGE MODE` : 
  - 자연어 처리 방식으로 분석하며 단어 빈도나 문서 길이 등에 따라 row를 정렬.
  - 엔진이 판단했을 때 가장 적합도가 높은 순서대로 결과를 노출.
- 접두가 선택 쿼리:
  - 일반적인 문자열 `LIKE` 쿼리에서는 대소문자에 대한 고려가 필요.

## 리스트 데이터
리스트 데이터를 노출하는 쿼리는 기본적으로 페이징이 필요하다. 

- 과거부터 지금까지 사용되어져 왔으며 보편적인 **오프셋 방식**으로는 
  - 페이지에 몇 개의 원소를 포함시킬 것인지,
  - 건너뛸 원소의 개수는 몇 개로 지정할 것인지
- 를 지정해서 페이징을 구현한다.

이런 페이징 구현 방식은 일반적으로는 문제 없이 동작하지만 데이터가 너무 많아지게 된다면 다른 방식에 비해 성능이 나쁘다는 단점이 있다.  

그럴 땐 '커서 기반' 페이징을 사용하자.  
데이터베이스의 쿼리가 실행되는 순서는 `SELECT` -> `FROM` -> `WHERE` 순서로, 먼저 조건을 통해 다루어야 하는 데이터의 갯수를 줄여 작업 효율을 높인다.    
커서 기반 페이징이 성능을 높이는 원리는 바로 이 `WHERE` 의 효능을 이용해 더 적은 데이터를 대상으로 잡아 효율을 높이는 것이다. 

커서 기반 페이징의 쿼리는 다음과 같은 쿼리가 된다.

```sql
-- 첫 번째 페이지
SELECT post_id, title, content
FROM post
ORDER BY created_at DESC
LIMIT 10;

-- 두 번째 페이지
SELECT post_id, title, content
FROM post
WHERE post_id < 12345
ORDER BY created_at DESC
LIMIT 10;
```

커서 기반 페이징에서 다음 페이지 대상의 범위를 좁히는 조건은 '순차적으로 증가하며 UNIQUE 값'을 대상으로 해야 한다.

위의 예시에서는 기본 키를 대상으로 했는데, 이는 실무에서 자주 사용하는 대상은 아니다. 기본 키는 통상적으로 AUTO_INCREMENT로 설정되어있어도 AUTO_INCREMENT는 따로 관리가 되기 때문에 순차적이지 않기 때문이다. ROW를 기준으로 순차적인게 아니라 AUTO_INCREMENT를 관리하는 필드를 기준으로 순차적이다. AUTO_INCREMENT를 사용할 땐 해당 조건이 순차적인지, 그 값에 누락이 없는지 고려하면서 사용해야 한다. AUTO_INCREMENT를 대신해 보통 ULID를 사용한다.

> 왜 순차적이어야 하는지에 대한 자세한 내용: [링크에서 확인하기](https://www.inflearn.com/community/questions/1772445/%EC%BB%A4%EC%84%9C-%EA%B8%B0%EB%B0%98-%ED%8E%98%EC%9D%B4%EC%A7%95-%EC%A1%B0%EA%B1%B4-%EB%8C%80%EC%83%81%EC%9C%BC%EB%A1%9C-auto-increment-vs-ulid)

# 윈도우 함수
쿼리가 너무 길어져서 가독성이 낮아지고 복잡해지는 경우 사용된다. 이는 현재 행과 관련된 다른 행을 참조하면서 계산하는 함수이다.  
이는 `GROUP BY` 같이 값을 특정 키로 묶어주는 작업 없이도 원하는 그룹별로 분석하는 데에 많이 사용한다.

```sql
-- 사용 되는 형태
SELECT 
    기본컬럼들,
    윈도우함수() OVER (PARTITION BY 그룹컬럼 ORDER BY 정렬컬럼) AS 결과 컬럼
FROM 테이블;
```
위와 같은 쿼리 형태로 사용되며 활용 예시는 아래와 같다.

```sql
SELECT
    post_id,
    title,
    view_count,
    
    -- 순차적인 순위 (1,2,3,4,...)
    ROW_NUMBER() OVER (ORDER BY view_count DESC) AS 전체순위,

    -- 동점자 고려한 순위(1,2,2,4,...)
    RANK() OVER (ORDER BY view_count DESC) AS 랭킹,

FROM post
WHERE status = 'PUBLISHED'
ORDER BY view_count DESC;

SELECT 
    user_id,
    post_id,
    title,
    view_count,
    
    -- 각 사용자 마다의 순위
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY view_count DESC) AS 사용자별순위,
FROM post
WHERE status = 'PUBLISHED'
ORDER BY user_id, 사용자별순위;

SELECT 
    post_id,
    title,
    view_count,
    
    LAG(post_id, 1) OVER (ORDER BY view_count DESC) AS 상위순위글식별자,
    LAG(post_id, 1) OVER (ORDER BY view_count) AS 하위순위글식별자,
FROM post
WHERE status = 'PUBLISHED';
```

# CTE(Common Table Expressions)
복잡한 분석을 해야하는 경우 엄청난 쿼리를 전송하는 경우도 있고, 플랫폼에서 다양한 데이터를 가져와야 하는데 각 데이터가 정규화되어 쪼개져 있어 쿼리가 너무 길어지는 경우가 있다. 때로는 우리가 상상할 수 없을 만큼 복잡한 쿼리를 보내는 경우도 있다. 이런 쿼리는 유지보수하기가 매우 어렵다. 이럴 때 CTE를 활용하면 복잡한 쿼리를 빌더 패턴처럼 단계별로 나누어서 작성함으로써 그러한 어려움을 줄일 수 있다.

기본적인 문법은 다음과 같은 형태다.
```sql
WITH 임시테이블명 AS ( 
    SELECT ... -- 1단계 계산
)
SELECT ...
    FROM 임시테이블명;
```

# EXISTS
값을 존재하는지 여부만을 체크하기 때문에 매우 성능이 우수하다.

```sql
SELECT 
    user_id,
    usename
FROM member m 
WHERE status = 'ACTIVE'
    AND EXISTS(
        SELECT 1
        from post p
        WHERE p.user_id = m.user_id
            AND p.created_at >= DATE_SUB(NOW(), INTERVAL 3 MONTH)
)
```