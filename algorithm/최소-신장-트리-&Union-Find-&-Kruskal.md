LeetCode의 'Min Cost to Connect All Points' 문제를 통해 최소 신장 트리를 공부한 내용을 기록해둔다.

# Min Cost to Connect All Points - 학습 기록

## 문제

배열 `points`가 주어지고, `points[i] = [xi, yi]`는 2D 평면 위의 좌표를 나타낸다.  
두 점 `[xi, yi]`와 `[xj, yj]`를 연결하는 비용은 맨해튼 거리: `|xi - xj| + |yi - yj|`이다.  
**모든 점을 연결하는 최소 비용**을 구하라. (임의의 두 점 사이에 정확히 하나의 경로만 존재해야 한다)

**제약 조건:**
- `1 <= points.length <= 1000`
- `-10^6 <= xi, yi <= 10^6`
- 모든 `(xi, yi)` 쌍은 서로 다르다.

---

## 풀이 접근 과정

### 1단계: 문제를 그래프로 변환

- 모든 점을 연결해야 한다 → 노드를 모두 포함
- 간선 가중치(맨해튼 거리)의 합을 최소화해야 한다
- 임의의 두 점 사이 경로가 정확히 하나 → **트리 구조** (사이클 없는 연결 그래프)

→ 이 세 조건을 합치면: **MST(Minimum Spanning Tree, 최소 신장 트리)** 문제

### 2단계: MST란?

- **신장 트리(Spanning Tree)**: 그래프의 모든 노드를 연결하면서 사이클이 없는 부분 그래프. N개 노드를 N-1개 간선으로 사이클 없이 연결한 구조.
- **최소 신장 트리**: 그중에서 간선 가중치 합이 가장 작은 것.

### 3단계: Kruskal 알고리즘

**핵심 아이디어:**

1. 모든 간선을 가중치 기준으로 오름차순 정렬한다
2. 가장 작은 간선부터 하나씩 꺼내서, **사이클이 생기지 않으면** 추가한다
3. N-1개 간선을 추가하면 끝

**이 문제에 적용:**
- 점이 N개이면 가능한 간선은 모든 점 쌍의 조합: **N*(N-1)/2**개
- N=1000이면 약 50만 개 → 정렬/처리 충분히 가능

### 4단계: Union-Find (서로소 집합)

"이 두 원소가 같은 그룹에 속해 있는가?"를 빠르게 판별하는 자료구조.

**연산 두 가지:**
- **Find(x)**: x가 속한 그룹의 대표(루트)를 찾는다. `parent[x] == x`인 지점까지 따라간다.
- **Union(x, y)**: x의 그룹과 y의 그룹을 하나로 합친다.

**예시:**

```
초기: parent = [0, 1, 2, 3, 4]  → {0} {1} {2} {3} {4}

Union(0, 1) → parent = [0, 0, 2, 3, 4]  → {0,1} {2} {3} {4}
Union(2, 3) → parent = [0, 0, 2, 2, 4]  → {0,1} {2,3} {4}
Union(1, 3) → Find(1)=0, Find(3)=2 → parent[2]=0  → {0,1,2,3} {4}
```

**Kruskal에서의 활용:**
- 간선을 꺼낼 때 양쪽 노드를 Find → 루트가 같으면 **스킵(사이클 방지)**, 다르면 **Union하고 간선 채택**

---

## 왜 이게 최적인가? (Greedy 원리)

- N개 점을 연결하려면 반드시 N-1개 간선이 필요
- 가장 싼 간선부터 골라가되, 사이클이 생기는 것만 피하면 불필요하게 비싼 간선을 쓸 일이 없다
- 사이클을 피하는 이유: 이미 연결된 점끼리 또 연결하면 비용만 늘고 새로운 점 연결에 기여하지 못함

**예시:**

```
가능한 간선들 (정렬 후):
A-B: 1, B-C: 2, A-C: 3, C-D: 4, A-D: 5, B-D: 6

A-B(1) → 다른 그룹 → 채택! cost=1
B-C(2) → 다른 그룹 → 채택! cost=3
A-C(3) → 같은 그룹 → 스킵! (사이클)
C-D(4) → 다른 그룹 → 채택! cost=7 → 완성!
```

---

## 최종 코드

```java
class MinCostToConnectAllPoints { // https://leetcode.com/problems/min-cost-to-connect-all-points/description/
    public int minCostConnectPoints(int[][] points) {
        int[] parent = new int[points.length];
        for (int i = 0; i < points.length; i++) {
            parent[i] = i;
        }

        var q = new PriorityQueue<Edge>((e1, e2) -> e1.cost - e2.cost);
        for (int i = 0; i < points.length; i++) {
            for (int j = i + 1; j < points.length; j++) {
                int point = Math.abs(points[i][0] - points[j][0]) + Math.abs(points[i][1] - points[j][1]);
                q.offer(new Edge(i, j, point));
            }
        }

        int cost = 0;
        while (!q.isEmpty()) {
            var cur = q.poll();
            if (find(parent, cur.from) != find(parent, cur.to)) {
                union(parent, cur.from, cur.to);
                cost += cur.cost;
            }
        }

        return cost;
    }

    private int find(int[] parent, int x) {
        while (x != parent[x]) {
            x = parent[x];
        }
        return x;
    }

    private void union(int[] parent, int x, int y) {
        parent[find(parent, x)] = find(parent, y);
    }

    private static class Edge {
        int from, to, cost;
        private Edge(int from, int to, int cost) {
            this.from = from;
            this.to = to;
            this.cost = cost;
        }
    }
}
```

---

## 학습한 개념 정리

| 개념             | 설명                                         |
|----------------|--------------------------------------------|
| MST (최소 신장 트리) | 모든 노드를 최소 비용으로 연결하는 트리                     |
| Kruskal 알고리즘   | 간선을 가중치 오름차순으로 정렬 후, 사이클 없이 채택하는 Greedy 방식 |
| Union-Find     | 두 원소가 같은 그룹인지 판별하고 그룹을 합치는 자료구조            |
| Greedy         | 매 순간 최선의 선택(가장 싼 간선)이 전체 최적해를 보장           |
