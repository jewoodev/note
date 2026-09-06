# Terraform CD를 도입했다가 다시 제거하며 배운 점

## 배경

운영 Terraform을 로컬에서 실행하면 작업자 환경과 절차 준수에 의존한다. 이를 개선하기 위해 한때
GitHub Actions에서 Plan과 Apply를 분리하고, GitHub OIDC로 AWS 임시 권한을 발급받아 승인된 saved
plan만 적용하는 Terraform CD를 도입했다.

방향 자체는 틀리지 않았다. 그러나 현재 팀 규모, GitHub 플랜, 인프라 변경 빈도와 운영 방식에서는
자동화가 줄여주는 위험보다 자동화를 유지하기 위해 생기는 권한·bootstrap·디버깅 복잡성이 더 컸다.
결국 Terraform CD를 제거하고, `vfm-admin` IAM Identity Center profile을 사용하는 로컬 실행을
결정론적인 스크립트로 통제하는 구조로 전환했다.

이 문서는 “Terraform CD는 나쁘다”는 결론이 아니라, 어떤 자동화가 현재 조직에 맞는지 판단하며 배운
내용을 정리한다.

## 처음 Terraform CD가 매력적으로 보였던 이유

GitHub Actions로 Terraform을 실행하면 다음 장점을 기대할 수 있다.

- 실행 환경과 Terraform 버전을 일정하게 유지할 수 있다.
- 누가 어떤 commit을 대상으로 plan과 apply를 실행했는지 GitHub에 기록된다.
- 장기 access key 없이 GitHub OIDC로 짧게 유효한 AWS 권한을 받을 수 있다.
- Plan과 Apply를 분리하면 검토한 binary plan만 적용할 수 있다.
- 로컬 컴퓨터의 상태와 관계없이 같은 절차를 반복할 수 있다.

특히 `main`에 병합된 exact commit, saved plan checksum, state version과 승인 입력값을 연결하면
감사 가능한 운영 흐름을 만들 수 있다. 충분한 조직 규모와 인프라 변경 빈도가 있다면 여전히 좋은
방향이다.

## 실제로 복잡해진 지점

### 1. Terraform plan은 단순한 읽기 작업이 아니다

Terraform plan은 구성 파일만 비교하지 않는다. provider가 실제 AWS 자원을 조회하고 remote state를
refresh해야 한다. 따라서 Plan 역할에도 생각보다 많은 AWS 조회 권한이 필요하다.

서비스마다 조회 API가 다르고 일부 API는 일반적인 ReadOnly 정책만으로 충분하지 않았다. `aws`와
`awscc` provider가 함께 있으면 필요한 권한 집합과 오류 형태도 달라진다. 결국 workflow를 실행해
실패한 API를 확인한 뒤 권한을 하나씩 추가하는 순환이 반복됐다.

여기서 얻은 교훈은 다음과 같다.

- “plan 전용 역할이므로 읽기 권한 몇 개면 된다”라고 가정하면 안 된다.
- provider와 resource 전체가 refresh 때 호출하는 API를 먼저 조사해야 한다.
- 관리형 정책과 실제 provider 호출 범위 사이에는 차이가 있을 수 있다.
- 권한 설계가 안정되지 않은 상태에서 원격 실행만 반복하면 GitHub commit과 실패 run이 불필요하게
  늘어난다.

### 2. 자동화를 만드는 자원도 누군가 먼저 만들어야 한다

Terraform CD에는 OIDC trust policy, Plan 역할, Apply 역할, saved plan 버킷과 관련 정책이 필요했다.
그런데 이 자원들 자체도 Terraform이 관리한다.

즉 다음과 같은 bootstrap 문제가 생긴다.

1. Terraform CD를 실행하려면 AWS 역할과 버킷이 필요하다.
2. 그 역할과 버킷을 Terraform으로 만들려면 먼저 Terraform을 적용해야 한다.
3. CD 역할의 권한을 수정하는 변경이 실패하면 다시 로컬 권한으로 복구해야 한다.

완전한 모순은 아니며 최초 한 번 로컬 bootstrap을 수행하면 해결할 수 있다. 하지만 현재 프로젝트에서는
Terraform CD를 유지하기 위해 계속 로컬 비상 경로를 보존해야 했고, 결과적으로 실행 경로가 두 개가
되었다. 실행 경로가 둘이면 어느 쪽이 표준인지와 drift를 어떻게 다룰지에 대한 운영 규칙도 늘어난다.

### 3. GitHub 플랜의 승인 기능과 우리가 원하는 경계가 달랐다

원하는 구조는 Plan 결과를 사람이 검토한 뒤 별도 승인을 거쳐 Apply하는 것이었다. 그러나 당시 사용
중인 GitHub 조직 플랜에서는 비공개 저장소 Environment의 required reviewer를 원하는 형태로 사용할
수 없었다.

이를 보완하기 위해 Plan workflow와 Apply workflow를 분리하고 plan ID와 확인 문자열을 다시 입력하는
방식을 만들었다. 기술적으로는 승인 경계를 만들 수 있었지만, workflow·OIDC trust condition·artifact
전달·유효기간·checksum 검증 코드가 크게 늘었다.

Enterprise 기능이 없어서 모든 문제가 생긴 것은 아니다. 다만 플랫폼이 제공하는 승인 기능을 쓰지
못하면 같은 안전성을 애플리케이션 코드와 운영 규칙으로 직접 구현해야 하므로 비용이 커진다.

### 4. 원격 workflow는 피드백 주기가 길었다

로컬 스크립트는 즉시 수정하고 fake 기반 테스트를 반복할 수 있다. 반면 OIDC subject, GitHub
permission, AWS trust policy처럼 원격에서만 완전히 검증되는 문제는 다음 순환을 요구했다.

1. 코드 수정
2. commit과 push
3. workflow 실행
4. AWS 또는 GitHub 오류 확인
5. 다시 수정

작은 권한 누락도 이 전체 주기를 거쳤다. 인프라 변경이 드문 소규모 팀에서는 이 운영 비용이 자동화의
효익보다 커질 수 있다.

## Git과 Terraform state는 서로 대체할 수 없다

Terraform 구성은 Git에 있으므로 state도 없어도 된다고 생각하기 쉽다. 하지만 둘은 다른 정보를
담는다.

- Git: 어떤 인프라를 원한다고 선언했는지 기록한다.
- Terraform state: 실제 원격 자원과 Terraform resource address가 어떻게 연결되어 있는지 기록한다.
- Saved plan: 특정 구성, provider, 변수와 특정 state 시점에서 계산된 일회성 실행 계획이다.

Git의 과거 commit만으로는 resource ID, import 관계, provider가 기록한 속성과 현재 원격 자원 매핑을
완전히 복원할 수 없다. state를 잃으면 Git을 checkout하는 것만으로 안전한 rollback이 되지 않는다.

따라서 CD를 제거해도 remote state는 제거하지 않았다. 전용 S3 버킷에 두고 다음 보호 장치를 유지했다.

- versioning
- public access block
- 암호화와 ownership control
- state locking
- current state 비만료
- 제한된 noncurrent version 보존

핵심은 **실행 자동화와 state 보존은 별개의 결정**이라는 점이다.

## 최종적으로 선택한 책임 경계

현재 구조는 자동화를 모두 포기한 것이 아니다. 자동화할 대상을 결정론적인 검증과 반복 작업으로
한정하고, 실제 변경 승인은 사람에게 남겼다.

### GitHub Actions가 담당하는 것

- Terraform format 검증
- Terraform configuration validation
- 운영 스크립트의 fake 기반 회귀 테스트
- AWS 변경 권한이 필요 없는 PR CI

### 로컬 스크립트가 담당하는 것

- 최신 `main`과 `origin/main` 일치 확인
- clean worktree 확인
- `vfm-admin` profile과 대상 AWS 계정 확인
- default workspace 확인
- remote state versioning과 현재 version ID 확인
- binary saved plan 생성
- plan과 함께 검증 metadata 생성
- exact saved plan 적용
- 적용 후 새 state version과 `No changes` 수렴 확인
- 사용된 plan과 metadata 폐기

### 사람이 담당하는 것

- plan의 생성·변경·삭제 자원 검토
- 비용과 운영 영향 판단
- exact plan에 대한 명시적 승인
- 실패했을 때 자동 우회나 자동 rollback을 하지 않고 상황 판단

이 경계에서는 사람이 자유 형식 명령을 기억해서 실행하지 않는다. 사람은 판단을 하고, 스크립트가
판단 전후의 기계적인 조건을 검증한다.

## 결정론적 로컬 실행을 위해 고정한 조건

Saved plan을 적용할 때 다음 값이 plan 생성 시점과 모두 같아야 한다.

- source commit
- `origin/main`과 일치하는 현재 `main`
- remote state version ID
- binary plan SHA-256
- Terraform 버전
- backend 설정 hash
- `terraform.tfvars` hash
- dependency lock file hash
- AWS account ID와 profile
- Terraform workspace

하나라도 달라지면 plan을 적용하지 않고 폐기한다. 적용이 시작된 plan도 성공 여부와 관계없이 다시
사용하지 않는다. apply가 성공한 뒤에는 새 state version이 만들어졌고 후속 plan이 `No changes`인지
확인한다.

또한 `TF_VAR_*`, `TF_CLI_ARGS*`, `TF_WORKSPACE`와 장기 AWS credential 환경변수를 거부한다. 눈에
보이지 않는 환경변수가 검토한 입력을 바꾸거나 `vfm-admin`보다 우선하는 일을 막기 위해서다.

## Terraform CD 제거 자체에서 배운 점

CD workflow 파일만 삭제하면 전환이 끝나는 것이 아니다. 제거 범위를 다음처럼 나누어 확인해야 한다.

1. GitHub Actions workflow와 보조 스크립트 제거
2. OIDC Plan·Apply IAM 역할과 정책 제거
3. saved plan 전달용 S3 버킷 제거
4. 더 이상 참조되지 않는 GitHub variable과 secret 제거
5. production state 버킷과 애플리케이션 배포 역할이 삭제 대상에 포함되지 않았는지 확인
6. 적용 후 Terraform `No changes` 확인

실제 제거 plan은 CD 전용 AWS 자원 14개만 삭제하는지 검토한 뒤 적용했다. 적용 후에는 새 state
version 생성, 사후 `No changes`, IAM 역할과 plan 버킷의 실제 부재, GitHub 설정 제거를 각각 확인했다.

## 다시 Terraform CD를 고려할 조건

다음 조건이 충족되면 원격 Terraform 실행을 다시 검토할 가치가 있다.

- 여러 명이 정기적으로 인프라를 변경한다.
- 로컬 실행 환경 차이 때문에 실제 장애가 반복된다.
- GitHub Environment 승인과 보호 규칙을 충분히 사용할 수 있다.
- provider refresh에 필요한 권한 집합을 사전에 테스트할 수 있다.
- OIDC 역할과 workflow를 관리할 담당자가 있다.
- plan 검토, 정책 검사와 비용 검사 결과를 중앙에서 보존해야 한다.
- 로컬 비상 경로와 원격 표준 경로의 책임을 명확히 나눌 수 있다.

그때도 `main` push 즉시 무승인 apply보다는 다음 흐름이 안전하다.

```text
PR CI
  -> 현재 main의 saved plan 생성
  -> 정책·비용·변경 내용 검토
  -> 보호된 승인
  -> exact plan apply
  -> 새 state version 확인
  -> post-apply No changes 확인
```

## 최종 교훈

자동화의 양이 많다고 항상 더 안전한 것은 아니다. 안전성은 다음 세 가지가 명확할 때 높아진다.

1. 무엇을 기계가 결정할 수 있는가
2. 무엇을 사람이 판단해야 하는가
3. 실패했을 때 어느 지점에서 멈추는가

현재 프로젝트에서는 Terraform apply 빈도가 낮고 운영 담당자가 제한적이므로, GitHub에 변경 권한을
넓게 위임하기보다 로컬 SSO와 fail-closed 스크립트를 결합하는 편이 단순하고 검증 가능했다. 중요한
것은 “로컬인가 CD인가” 자체가 아니라, 검토한 입력과 실제 적용 대상이 같고 state가 복구 가능하며
실패 시 자동으로 위험한 우회를 하지 않는 구조를 만드는 것이다.
