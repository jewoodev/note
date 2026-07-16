# 슬러그(slug)란 무엇인가 — 메모리 시스템의 링크 동작 원리

## 슬러그의 정의

슬러그는 제목 같은 자연어를 기계가 다루기 좋게 정규화한 짧은 식별자다. 블로그 글 "My First Post!"의 URL이 `/my-first-post`가 되는 것처럼, 보통 소문자 + 하이픈(kebab-case)으로 만든다.

Claude 메모리 시스템에서는 각 메모리 파일 frontmatter의 `name:` 값이 슬러그 역할을 한다. 본문에서 다른 메모리를 가리키는 `[[...]]` 링크는 **파일 이름이 아니라 이 `name:` 값으로 연결**된다.

## 이름 공간은 두 개다

| 이름 공간 | 예시 | 어디서 쓰이나 |
|---|---|---|
| 파일 이름 | `feedback_oss_pr_send_decision.md` | `MEMORY.md` 인덱스의 `[제목](파일.md)` 마크다운 링크, Read 도구의 경로 |
| `name:` 슬러그 | `feedback-oss-pr-send-decision` | 메모리 본문 사이의 `[[...]]` 상호 참조 |

둘은 서로 일치할 필요가 없다. 따라서 "파일 이름은 underscore, 슬러그는 kebab-case" 조합은 전혀 문제없이 동작한다. 실제로 현재 메모리 파일 대부분이 그 상태다.

## 동작에 진짜로 중요한 것

표기 스타일이 아니라 **링크 문자열과 대상 파일의 `name:` 값이 글자 그대로 일치하는가**다.

- kebab-case에 기술적인 마법이 있는 게 아니다. 모든 `name:`과 모든 링크가 underscore로 통일돼 있어도 똑같이 동작한다.
- 문제가 되는 건 혼재다. 예: 링크는 `[[feedback-oss-preempted-pr-compete]]`(kebab)인데 대상 파일의 name은 `feedback_oss_preempted_pr_compete`(underscore)면 문자열이 안 맞아 링크가 끊긴다.
- name이 슬러그가 아예 아닌 경우(예: `First open-source contribution` 같은 영어 문장)는 어떤 표기로 링크해도 닿을 수 없다.

## 링크를 해석하는 주체

`[[...]]` 링크를 해석하는 건 별도의 소프트웨어 엔진이 아니라 **미래 세션의 Claude**다. `[[x]]`를 보면 `grep "name: x"` 같은 정확한 문자열 매칭으로 대상을 찾는데, 표기가 어긋나 있으면 검색이 빈손으로 돌아오고 그때부터 추측에 의존하게 된다. 표기 통일의 목적은 이 추측을 없애고 매칭을 결정적(deterministic)으로 만드는 것이다.

## kebab-case로 통일하는 이유

1. Claude의 메모리 작성 규칙이 `name:`을 kebab-case 슬러그로 정의한다.
2. 기존 파일 다수가 이미 kebab-case라 그쪽으로 수렴하는 게 수정량이 가장 적다.
3. 파일 이름은 underscore 그대로 둬도 되므로 파일 rename은 불필요 — `name:` 필드와 본문 링크만 고치면 된다.
