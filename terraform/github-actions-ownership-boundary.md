# Terraform과 GitHub Actions의 배포 소유권 경계

## 배경

이 문서는 ECS task definition을 Terraform과 GitHub Actions가 함께 다루는 과정에서 얻은 설계 원칙을 정리한다.

사례가 된 변경은 다음 커밋이다.

```text
7342a2e1d4a46376db3221ae117e11013f8ae98c
refactor: separate ECS task definition ownership (#159)
```

핵심 결론은 다음과 같다.

> Terraform은 실행 환경의 정적 구성 기준을 관리하고, GitHub Actions는 실제 애플리케이션 배포 revision을 관리한다.

## 왜 경계가 필요한가

ECS task definition에는 서로 수명 주기가 다른 정보가 함께 들어간다.

- CPU와 메모리
- 환경변수와 secret 참조
- IAM role
- 로그 설정
- 컨테이너 image URI와 tag

CPU, IAM, 로그 설정은 인프라 변경에 가깝다. 반면 image tag는 애플리케이션을 배포할 때마다 바뀐다.

Terraform과 GitHub Actions가 같은 task definition revision을 각각 최신 상태로 만들려고 하면 두 자동화 주체가 하나의 값을 놓고 경쟁하게 된다.

```text
Terraform이 기억하는 image: commit A
GitHub Actions가 배포한 image: commit B

Terraform apply
  └─ 운영 revision을 다시 commit A 기준으로 만들 가능성

GitHub Actions deploy
  └─ 다시 commit B 또는 commit C revision 생성
```

이 구조에서는 다음 문제가 생긴다.

- 일반 Terraform plan에 애플리케이션 revision 차이가 반복해서 나타난다.
- Terraform apply가 운영 애플리케이션을 과거 image로 되돌릴 위험이 생긴다.
- 어느 도구가 운영 revision의 최종 소유자인지 불분명해진다.
- 인프라 변경과 애플리케이션 배포를 독립적으로 실행하기 어렵다.

## 선택한 소유권 구조

### Terraform의 책임

Terraform은 task definition의 정적 설정 기준 revision을 관리한다.

- ECS cluster와 service의 기본 구성
- task definition family 이름
- CPU와 메모리
- 컨테이너 이름과 실행 방식
- 환경변수와 secret 참조
- IAM role
- 네트워크와 로그 설정
- health check
- 최초 배포와 기준 revision 생성을 위한 고정 baseline image

Terraform이 만든 revision은 다음 GitHub Actions 배포가 복제할 설정 기준이다. 반드시 현재 운영 중인 revision일 필요는 없다.

### GitHub Actions의 책임

GitHub Actions는 실제 애플리케이션 runtime revision을 관리한다.

- 소스 검증과 애플리케이션 build
- immutable image tag 생성
- ECR push
- 최신 Terraform 기준 revision 조회
- 기준 revision의 image를 배포 SHA로 교체
- 새 task definition revision 등록
- ECS service를 새 revision으로 갱신
- rollout 확인과 실패 시 rollback

```text
Terraform baseline revision
  └─ 정적 설정의 원본
       └─ GitHub Actions가 복제
            └─ image만 배포 SHA로 교체
                 └─ runtime revision 등록
                      └─ ECS service 갱신
```

## 기준 revision과 runtime revision

두 revision은 같은 task definition family에 속하지만 역할이 다르다.

| 구분 | 기준 revision | runtime revision |
|---|---|---|
| 생성 주체 | Terraform | GitHub Actions |
| 변경 시점 | 인프라 설정 변경 | 애플리케이션 배포 |
| image 의미 | 초기화와 복제를 위한 안정적인 기준 | 실제 운영할 commit SHA |
| ECS service 실행 대상 | 일반적으로 아님 | 맞음 |
| 식별 방법 예시 | `ManagedBy=Terraform` | `ManagedBy=GitHubActions` |

Terraform은 자신이 생성한 기준 revision을 state로 추적한다. GitHub Actions가 만든 runtime revision까지 Terraform state에 편입할 필요는 없다.

## `ignore_changes`만으로 충분하지 않은 이유

ECS service의 `task_definition`에 다음 설정을 두면 GitHub Actions가 service revision을 바꾸더라도 Terraform이 되돌리지 않는다.

```hcl
resource "aws_ecs_service" "backend" {
  # ...

  lifecycle {
    ignore_changes = [task_definition]
  }
}
```

하지만 이것만으로 소유권 분리가 완성되지는 않는다.

- Terraform task definition이 매번 배포 SHA를 입력받는다면 Terraform plan은 계속 기준 revision 교체를 요구할 수 있다.
- 다른 Terraform 리소스가 현재 runtime revision을 data source로 읽으면 Terraform의 결과가 애플리케이션 배포 시점에 종속된다.
- IAM policy가 특정 Terraform resource revision을 통해 family를 계산하면 불필요한 의존성이 생길 수 있다.

따라서 다음 조치도 필요하다.

1. 애플리케이션 배포 SHA를 Terraform의 일상 입력값에서 제거한다.
2. Terraform baseline image tag는 안정적인 값으로 유지한다.
3. runtime revision을 읽는 data source를 기준 구성에서 제거한다.
4. family 이름처럼 revision과 무관한 값은 별도의 local로 정의한다.
5. GitHub Actions IAM 권한은 해당 family의 revision 범위를 대상으로 한다.

## 서로 다른 image 수명 주기 분리

하나의 `deployment_image_tag`를 backend와 database utility task가 공유하면 서로 다른 배포 주기가 결합된다.

```text
backend image
  └─ 애플리케이션 배포마다 변경

database utility image
  └─ bootstrap 또는 recovery 도구가 변경될 때만 변경
```

따라서 다음처럼 변수를 분리하는 편이 자연스럽다.

```hcl
variable "backend_baseline_image_tag" {
  description = "Terraform 기준 task definition에 사용하는 backend image tag"
}

variable "database_utility_image_tag" {
  description = "Database bootstrap과 recovery task에 사용하는 image tag"
}
```

변수를 분리하면 backend를 배포했다는 이유만으로 database utility task definition이 교체되는 일을 막을 수 있다.

## 일회성 관리 task의 처리

사용자 관리와 같은 일회성 task가 backend image 안의 CLI를 사용한다면 두 가지 요구가 생긴다.

- Terraform은 task의 CPU, IAM, secret과 로그 구성을 관리해야 한다.
- 실제 실행은 현재 검증된 운영 backend image를 사용해야 한다.

이 경우 Terraform 기준 task는 정적 구성의 원본으로만 사용하고, 실행 스크립트가 현재 운영 backend image를 주입한 임시 revision을 만들 수 있다. 실행이 끝난 임시 revision은 정리한다.

이렇게 하면 Terraform 구성을 runtime image에 종속시키지 않으면서도 일회성 작업은 최신 운영 코드로 실행할 수 있다.

## 적용 순서

### 애플리케이션을 배포할 때

1. GitHub Actions가 테스트와 build를 수행한다.
2. commit SHA로 image를 ECR에 push한다.
3. 같은 family에서 가장 최근의 Terraform 관리 기준 revision을 찾는다.
4. 기준 revision의 컨테이너 image만 새 SHA로 교체한다.
5. GitHub Actions 관리 태그와 source commit을 붙여 새 revision을 등록한다.
6. ECS service를 새 revision으로 갱신한다.
7. rollout과 health check를 확인한다.
8. 실패하면 직전 정상 runtime revision으로 rollback한다.

### 인프라 구성을 변경할 때

1. Terraform 코드를 수정한다.
2. plan에서 기준 task definition 변경과 다른 인프라 변경을 검토한다.
3. Terraform state를 백업한다.
4. 검토한 saved plan을 적용한다.
5. 새 Terraform 기준 revision이 만들어졌는지 확인한다.
6. 운영 ECS service가 기존 runtime revision을 유지하는지 확인한다.
7. 일반 Terraform plan이 무변경인지 확인한다.
8. 다음 애플리케이션 배포가 새 기준 revision을 복제하는지 검증한다.

## 완료 기준

소유권 분리가 제대로 되었는지는 다음 조건으로 판단할 수 있다.

- 애플리케이션 배포 후 일반 Terraform plan이 `No changes`다.
- Terraform apply 후 ECS service가 기존 runtime revision을 유지한다.
- 인프라 설정을 바꾸면 Terraform 기준 revision만 새로 생성된다.
- 다음 GitHub Actions 배포가 가장 최근 Terraform 기준 revision의 설정을 계승한다.
- GitHub Actions가 만든 revision에는 source commit과 관리 주체를 식별할 태그가 있다.
- rollback이 Terraform apply가 아니라 애플리케이션 배포 절차에서 수행된다.
- database utility와 같은 별도 수명 주기의 image가 backend 배포에 따라 교체되지 않는다.

## 운영상 주의점

### 기준 image의 ECR 보존

Terraform 기준 revision의 image tag가 ECR lifecycle에 의해 삭제될 수 있다. 기준 revision을 직접 실행할 가능성이 있다면 다음 중 하나를 선택해야 한다.

- 기준 image를 ECR lifecycle 삭제 대상에서 보호한다.
- 실행 전에 항상 검증된 runtime image로 교체한다.
- 기준 revision은 절대 직접 실행하지 않는다는 정책을 명시하고 자동화로 강제한다.

단순히 “기준이라 실행하지 않는다”고 가정하는 것보다 실패 가능성을 자동화와 테스트로 막는 편이 안전하다.

### 하나의 실제 값을 두 주체가 관리하지 않기

Terraform과 GitHub Actions가 모두 ECS를 다룬다는 사실 자체가 문제는 아니다. 문제는 동일한 실제 값의 최종 상태를 두 주체가 동시에 결정하는 것이다.

```text
좋은 분리
  Terraform      → 정적 설정 기준
  GitHub Actions → runtime image와 service revision

나쁜 분리
  Terraform      → 최신 runtime image를 유지하려 함
  GitHub Actions → 최신 runtime image를 유지하려 함
```

### `No changes`를 설계 검증으로 사용하기

애플리케이션 CD 직후 Terraform plan의 `No changes`는 단순히 깔끔한 출력이 아니다. 두 자동화 주체의 경계가 예상대로 작동한다는 중요한 회귀 검증이다.

반대로 애플리케이션 배포만 했는데 Terraform plan에 task definition 교체가 나타난다면 다음을 의심해야 한다.

- 배포 SHA가 Terraform 변수에 다시 들어갔는가
- runtime revision을 읽는 data source가 생겼는가
- service의 runtime revision을 Terraform이 다시 소유하고 있는가
- 서로 다른 수명 주기의 image tag가 다시 결합되었는가

## 일반화한 원칙

1. 하나의 실제 값에는 하나의 최종 소유자만 둔다.
2. 인프라 구성과 애플리케이션 artifact의 수명 주기를 분리한다.
3. Terraform은 선언적 기준 상태를, CD는 빈번한 runtime 전환을 담당한다.
4. 두 도구가 공유해야 하는 것은 현재 runtime revision이 아니라 안정적인 계약이다.
5. 관리 주체를 태그와 문서로 명시한다.
6. 각 경계는 plan, rollout, rollback 회귀 테스트로 검증한다.
7. 예외적인 일회성 task도 동일한 소유권 원칙 안에서 설계한다.

