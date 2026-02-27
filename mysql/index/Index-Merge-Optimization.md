Index Merge는 MySQL이 하나의 테이블에 대해 여러 인덱스를 동시에 사용하여 결과를 합치는 최적화 기법.  
보통 하나의 쿼리에는 하나의 인덱스만 사용되지만, 특정 조건에서는 여러 인덱스를 각각 스캔한 뒤 결과를 병합하는 게 더 효율적일 수 있다.

# 동작 방식
쿼리의 WHERE 절에 서로 다른 인덱스를 사용하는 조건이 OR 또는 AND로 결합되어 있을 때 옵티마이저가 각 인덱스를 개별 스캔하고, 그 결과를 합치거나 교차시켜 최종 결과를 만든다.    
EXPLAIN 실행 시 type 컬럼에 **index_merge**가 표시되고, Extra 컬럼에 구체적인 알고리즘이 나타난다.

# 세 가지 알고리즘
## Index Merge Intersection (Using intersect(...))  
AND 조건에서 사용된다. 이때, 각 인덱스 스캔 결과의 교집합을 구한다. 
```sql 
-- idx_a(a), idx_b(b) 각각 존재할 때
SELECT * FROM t WHERE a = 1 AND b = 2;
```

각 인덱스에서 조건에 맞는 row id를 가져온 뒤 교집합을 구하고, 해당 row만 테이블에서 읽는다. 복합 인덱스 (a, b)가 있다면 그쪽이 더 효율적이므로 Index Merge 대신 그걸 사용하게 된다.

## Index Merge Union (Using union(...))  
OR 조건에서 사용된다. 이때, 각 인덱스 스캔 결과의 합집합을 구한다.
```sql
SELECT * FROM t WHERE a = 1 OR b = 2;
```

이 경우 복합 인덱스로는 해결이 안 되기 때문에 Index Merge가 유용한 대표적인 케이스이다. OR 조건이 없으면 보통 full table scan이 될 수 있는 상황을 인덱스 활용으로 개선해준다.

## Index Merge Sort-Union (Using sort_union(...))
Union과 비슷하지만, 범위 조건이 포함되어 있어서 각 인덱스 스캔 결과가 정렬되지 않은 경우 사용된다. 결과를 먼저 정렬한 뒤 합집합을 구한다.
```sql
SELECT * FROM t WHERE a < 10 OR b BETWEEN 5 AND 20;
```
Union은 동등 비교(=)에서 이미 정렬된 결과를 바로 병합할 수 있지만, 범위 조건은 정렬이 보장되지 않아서 Sort-Union이 필요하다.

# 주의할 점
Index Merge가 항상 좋은 건 아니다. EXPLAIN에서 index_merge가 보이면 오히려 적절한 복합 인덱스가 빠져있다는 신호일 수 있다. 특히 Intersection의 경우 복합 인덱스 하나로 대체하는 게 거의 항상 더 낫다.

Union의 경우는 OR 조건 특성상 복합 인덱스로 커버가 안 되므로, Index Merge가 정당한 최적화인 경우가 많다.

옵티마이저 스위치로 개별 제어가 가능하다.:

```sql
-- 특정 알고리즘 비활성화
SET optimizer_switch = 'index_merge_intersection=off';
SET optimizer_switch = 'index_merge_union=off';
SET optimizer_switch = 'index_merge_sort_union=off';
```

# 실무에서 권장되는 사고 체계

| 상황                 | 권장 대응                                 |
|--------------------|---------------------------------------|
| `intersect` 발견     | 복합 인덱스 추가 검토                          |
| `union` 발견 (OR 조건) | 대체로 정상적인 최적화, 쿼리 분리(`UNION ALL`) 도 고려 |
| `sort_union` 발견    | 범위 조건 최적화 또는 쿼리 구조 개선 검토              |

