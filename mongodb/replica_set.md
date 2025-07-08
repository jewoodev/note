# 레플리카 셋은 홀수 개의 노드로 구성하는 것이 좋다?
## 홀수 개 노드 구성의 장점
### 1. **Split-brain 문제 방지**
- 네트워크 파티션이 발생했을 때, 홀수 개의 노드가 있으면 과반수(majority)를 명확하게 결정할 수 있다
- 예: 3개 노드 중 2개가 연결되어 있으면 과반수를 유지하여 계속 운영 가능

### 2. **선거(Election) 과정의 효율성**
- Primary 노드가 다운되었을 때, 새로운 Primary를 선출하는 과정에서 과반수 투표가 필요하다
- 홀수 개 노드는 동점 상황을 방지하여 빠른 선거 결과를 보장한다

### 3. **Write Concern의 안정성**
- `majority` write concern 사용 시, 과반수 노드에 데이터가 복제되어야 확인된다
- 홀수 개 구성에서 과반수 계산이 명확하다

## 일반적인 구성 예시
### **3-멤버 레플리카 셋 (권장)**
```javascript
// 기본 3-멤버 구성
{
  "_id": "myReplicaSet",
  "members": [
    { "_id": 0, "host": "mongodb0.example.net:27017" },
    { "_id": 1, "host": "mongodb1.example.net:27017" },
    { "_id": 2, "host": "mongodb2.example.net:27017" }
  ]
}
```
### **5-멤버 레플리카 셋 (고가용성)**
- 더 많은 읽기 처리 능력
- 더 높은 장애 허용성 (2개 노드까지 실패 허용)

## 예외 상황: Arbiter 사용
만약 비용상의 이유로 짝수 개의 데이터 노드만 운영해야 한다면:
```javascript
// 2개 데이터 노드 + 1개 Arbiter
{
  "_id": "myReplicaSet",
  "members": [
    { "_id": 0, "host": "mongodb0.example.net:27017" },
    { "_id": 1, "host": "mongodb1.example.net:27017" },
    { "_id": 2, "host": "mongodb2.example.net:27017", "arbiterOnly": true }
  ]
}
```
Arbiter는 투표만 참여하고 데이터는 저장하지 않아 리소스를 절약할 수 있다.

## 결론
홀수 개 노드 구성은 MongoDB 레플리카 셋의 **고가용성**과 **데이터 일관성**을 보장하는 핵심 설계 원칙이다. 특히 네트워크 분할 상황에서 서비스 연속성을 유지하는 데 매우 중요하다.
