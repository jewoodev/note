# AWS Cloud Control Terraform Provider (`awscc`)

## 한 문장으로 이해하기

`awscc`는 Terraform 구성을 AWS Cloud Control API 호출로 변환하는 HashiCorp provider다.

기존 `aws` provider를 대체하는 것이 아니라, 기존 provider가 아직 지원하지 않거나 Cloud Control API를 통해 먼저 제공되는 AWS 리소스를 관리할 때 함께 사용한다.

```text
Terraform 구성
  ├─ hashicorp/aws
  │    └─ AWS 서비스별 API
  │
  └─ hashicorp/awscc
       └─ AWS Cloud Control API
            └─ 실제 AWS 서비스 리소스
```

## Terraform provider란

Terraform 자체는 AWS, GCP 또는 GitHub의 API를 직접 이해하지 않는다. provider가 Terraform 리소스 선언을 외부 시스템의 API 요청으로 번역한다.

예를 들어 다음 두 리소스는 서로 다른 provider가 관리한다.

```hcl
resource "aws_cloudwatch_log_group" "example" {
  name = "/example/access"
}

resource "awscc_logs_delivery_source" "example" {
  name         = "example-access"
  log_type     = "ALB_ACCESS_LOGS"
  resource_arn = aws_lb.example.arn
}
```

- `aws_*`: 기존 AWS provider가 관리
- `awscc_*`: AWS Cloud Control provider가 관리

두 provider의 리소스는 같은 Terraform 구성 안에서 서로의 값을 참조할 수 있다.

## AWS Cloud Control API란

AWS 서비스는 각각 서로 다른 API를 제공한다. Cloud Control API는 여러 AWS 리소스를 공통된 형식으로 생성, 조회, 수정, 삭제, 목록 조회할 수 있게 만든 API 계층이다.

Cloud Control API는 AWS CloudFormation 계열의 리소스 타입 스키마를 사용한다. 이 스키마에는 다음 정보가 들어 있다.

- 리소스가 제공하는 속성
- 필수 속성과 자료형
- 값 제약
- 지원하는 생성·조회·수정·삭제 동작
- 동작에 필요한 AWS 권한

`awscc` provider는 이 표준 스키마를 활용하여 Terraform 리소스를 비교적 빠르게 제공할 수 있다.

## 기존 `aws` provider와의 차이

| 구분 | `hashicorp/aws` | `hashicorp/awscc` |
|---|---|---|
| 접근 방식 | AWS 서비스별 API에 맞춘 구현 | Cloud Control API의 공통 인터페이스 사용 |
| 리소스 접두사 | `aws_` | `awscc_` |
| 강점 | 성숙한 리소스, Terraform에 맞춘 인터페이스 | 새로운 AWS 리소스 타입을 빠르게 지원할 수 있음 |
| 일반적인 사용 | 기본 선택 | 기존 provider에 필요한 리소스가 없을 때 보완 |
| 함께 사용 | 가능 | 가능 |

모든 리소스를 `awscc`로 통일할 필요는 없다. 기존 `aws` provider가 충분히 지원하는 리소스는 그대로 유지하고, 필요한 리소스에만 `awscc`를 사용하는 편이 단순하다.

## ALB 액세스 로그 구성 예시

ALB 액세스 로그를 CloudWatch Logs로 직접 전달하는 구성에서는 다음과 같이 책임을 나눌 수 있다.

```text
aws provider
  ├─ ALB
  ├─ CloudWatch Logs 로그 그룹
  └─ 로그 전달 서비스가 쓸 수 있는 리소스 정책

awscc provider
  ├─ 로그 전달 원본: ALB
  ├─ 로그 전달 목적지: CloudWatch Logs
  └─ 원본과 목적지의 전달 연결
```

```hcl
resource "awscc_logs_delivery_source" "alb_access" {
  name         = "production-alb-access"
  log_type     = "ALB_ACCESS_LOGS"
  resource_arn = aws_lb.backend.arn
}

resource "awscc_logs_delivery_destination" "alb_access" {
  name                     = "production-alb-access"
  destination_resource_arn = aws_cloudwatch_log_group.alb_access.arn
  output_format            = "json"
}

resource "awscc_logs_delivery" "alb_access" {
  delivery_source_name     = awscc_logs_delivery_source.alb_access.name
  delivery_destination_arn = awscc_logs_delivery_destination.alb_access.arn
}
```

`awscc` 자체가 로그 저장소인 것은 아니다. Terraform이 AWS 로그 전달 리소스를 관리하기 위해 사용하는 API 연결 방식이다.

## CloudFormation과의 관계

`awscc`가 CloudFormation 계열의 리소스 스키마를 사용한다고 해서 CloudFormation stack을 생성하는 것은 아니다.

- CloudFormation은 여러 리소스를 stack이라는 단위로 관리한다.
- Cloud Control API는 개별 리소스의 공통 CRUD 인터페이스를 제공한다.
- `awscc`는 Cloud Control API를 호출하고 그 리소스를 Terraform state로 관리한다.

따라서 리소스의 최종 관리 주체는 여전히 Terraform이다.

## 의존성 잠금 파일

`awscc`를 도입하고 `terraform init`을 실행하면 `.terraform.lock.hcl`에 다음 정보가 추가된다.

- 선택된 `awscc` provider 버전
- 설정에서 허용한 버전 범위
- provider 배포 파일의 무결성 검증 해시

이 파일에는 AWS 비밀번호, access key 또는 Terraform state가 들어 있지 않다. 개발 환경과 CI가 동일하고 검증된 provider를 사용하게 하기 위한 의존성 잠금 정보이므로 일반적으로 코드와 함께 커밋한다.

## 도입 판단 기준

다음 순서로 판단하면 된다.

1. 기존 `hashicorp/aws` provider가 필요한 리소스를 지원하는지 확인한다.
2. 지원한다면 기존 provider를 우선 사용한다.
3. 지원하지 않거나 필요한 기능이 Cloud Control 리소스로만 제공되면 `awscc` 지원 여부를 확인한다.
4. `awscc` 리소스의 생성·조회·수정·삭제 지원 범위와 스키마를 확인한다.
5. 별도 provider 의존성과 버전 관리 비용보다 기능 도입 가치가 큰지 판단한다.

## 실무상 주의점

- provider가 하나 늘어나므로 초기화와 버전 관리 대상도 늘어난다.
- `aws`와 `awscc`에서 비슷한 리소스를 동시에 관리하지 않는다. 하나의 실제 리소스에는 하나의 Terraform 소유자만 둔다.
- Cloud Control 리소스가 지원하는 동작은 리소스 타입마다 다를 수 있으므로 스키마를 확인한다.
- `terraform plan`과 실제 적용 결과를 검증하여 읽기 결과와 갱신 동작이 예상과 일치하는지 확인한다.
- provider 버전 갱신은 일반 초기화와 분리하여 검토한다.

## 참고 자료

- [HashiCorp: Manage new AWS resources with the Cloud Control provider](https://developer.hashicorp.com/terraform/tutorials/aws/aws-cloud-control)
- [AWS: What is AWS Cloud Control API?](https://docs.aws.amazon.com/cloudcontrolapi/latest/userguide/what-is-cloudcontrolapi.html)
- [AWS: How Cloud Control API works](https://docs.aws.amazon.com/cloudcontrolapi/latest/userguide/how-it-works.html)

