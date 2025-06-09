FastAPI는 `Annotated`를 쿼리 파라미터와 경로 파라미터를 검증하는 데에 활용한다. 이게 무엇인지 알아보자.

## Annotated의 기본 개념
는 Python 3.9부터 도입된 특별한 타입 힌트로, **타입 정보에 추가 메타데이터를 첨부**하는 역할을 한다. 
``` python
from typing import Annotated

# 기본 구조
Annotated[타입, 메타데이터1, 메타데이터2, ...]
```
## 기존 방식 vs Annotated 방식 비교
### 기존 방식의 문제점
``` python
from fastapi import Query

# 문제: 타입 정보가 불완전하고 혼란스러움
def get_items(q: list = Query(default=[], description="검색 키워드")):
    pass
```
여기서 의 실제 타입은 무엇일까? `q`
- ? (어떤 요소 타입인지 불명확) `list`
- ? (FastAPI 객체인가?) `Query`
- 타입 체커가 혼란스러워함

### Annotated 방식의 해결
``` python
from typing import Annotated
from fastapi import Query

# 명확한 분리: 타입 정보 + 메타데이터
def get_items(q: Annotated[list[str], Query(description="검색 키워드")] = []):
    pass
```
## Annotated가 하는 일들
### 1. 타입과 메타데이터 분리
``` python
from typing import Annotated

# 타입 정보: list[str]
# 메타데이터: Query(description="...", min_length=1)
UserTags = Annotated[list[str], Query(description="사용자 태그", min_length=1)]

def update_user(tags: UserTags = []):
    # 타입 체커는 list[str]로 인식
    # FastAPI는 Query() 메타데이터 활용
    pass
```
### 2. 런타임에서는 원본 타입만 유지
``` python
import inspect
from typing import Annotated, get_origin, get_args

def example(value: Annotated[int, "이것은 메타데이터"]):
    pass

# 런타임에서 확인
sig = inspect.signature(example)
param = sig.parameters['value']

print(param.annotation)  # typing.Annotated[int, '이것은 메타데이터']
print(get_origin(param.annotation))  # typing.Annotated
print(get_args(param.annotation))    # (int, '이것은 메타데이터')

# 실제 타입
actual_type = get_args(param.annotation)[0]
print(actual_type)  # <class 'int'>
```
### 3. 도구별 메타데이터 활용
각 도구들이 자신에게 필요한 메타데이터만 추출해서 사용:
``` python
from typing import Annotated
from fastapi import Query
from pydantic import Field

# 여러 메타데이터를 동시에 지정
UserId = Annotated[
    int,
    Query(description="사용자 ID", ge=1),      # FastAPI가 사용
    Field(description="고유 사용자 식별자"),      # Pydantic이 사용
    "이것은 일반 주석"                          # 다른 도구가 사용 가능
]
```
## FastAPI에서 Annotated 활용 예시
### 복잡한 검증 규칙
``` python
from typing import Annotated
from fastapi import FastAPI, Query, Path
from pydantic import Field

app = FastAPI()

# 재사용 가능한 타입 정의
PageNumber = Annotated[int, Query(description="페이지 번호", ge=1, le=1000)]
PageSize = Annotated[int, Query(description="페이지 크기", ge=10, le=100)]
SearchQuery = Annotated[str, Query(description="검색어", min_length=2, max_length=50)]

@app.get("/search/")
async def search(
    q: SearchQuery,
    page: PageNumber = 1,
    size: PageSize = 20,
    tags: Annotated[list[str], Query(description="필터 태그")] = []
):
    return {
        "query": q,
        "page": page,
        "size": size,
        "tags": tags
    }
```
### Path 매개변수와 함께
``` python
@app.get("/users/{user_id}/posts/{post_id}")
async def get_post(
    user_id: Annotated[int, Path(description="사용자 ID", ge=1)],
    post_id: Annotated[int, Path(description="게시글 ID", ge=1)],
    include_comments: Annotated[bool, Query(description="댓글 포함 여부")] = False
):
    return {"user_id": user_id, "post_id": post_id, "include_comments": include_comments}
```
## 타입 체커 관점에서의 Annotated
### mypy에서의 처리
``` python
from typing import Annotated

def process_data(data: Annotated[list[str], "검증된 데이터"]) -> str:
    # mypy는 data를 list[str]로 인식
    return ", ".join(data)  # ✅ 타입 체크 통과

def wrong_usage(data: Annotated[list[str], "검증된 데이터"]) -> str:
    return data + 5  # ❌ mypy 에러: list[str] + int는 불가능
```
### IDE 자동완성
``` python
from typing import Annotated

def example(items: Annotated[list[str], "항목 리스트"]):
    # IDE는 items를 list[str]로 인식하여 자동완성 제공
    items.append("new")     # ✅ list 메서드 자동완성
    items[0].upper()        # ✅ str 메서드 자동완성
```
## 실제 FastAPI 동작 원리
FastAPI가 를 처리하는 과정: `Annotated`
``` python
# FastAPI 내부적으로 이런 식으로 처리
def process_parameter(annotation):
    if hasattr(annotation, '__origin__') and annotation.__origin__ is Annotated:
        args = annotation.__args__
        actual_type = args[0]        # list[str]
        metadata = args[1:]          # (Query(...),)
        
        # 실제 타입으로 파싱/검증
        # 메타데이터로 추가 설정 적용
        return actual_type, metadata
```
## 장점 요약

| 측면 | 장점 |
| --- | --- |
| **타입 안전성** | 완전한 타입 정보 제공 |
| **가독성** | 타입과 설정의 명확한 분리 |
| **재사용성** | 타입 별칭으로 재사용 가능 |
| **도구 호환성** | 다양한 도구가 각자 필요한 메타데이터 활용 |
| **미래 호환성** | Python 표준 방식 |
## 결론
는 단순한 문법적 설탕이 아니라, **타입 시스템과 메타데이터 시스템을 깔끔하게 분리**하면서도 **각 도구가 필요한 정보를 효율적으로 활용**할 수 있게 해주는 강력한 메커니즘이다. FastAPI뿐만 아니라 Pydantic, SQLAlchemy 등 많은 현대적인 Python 라이브러리들이 이 패턴을 채택하고 있다. 
