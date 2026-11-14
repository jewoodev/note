## 암기노트

1. S3 객체 잠금은 버전 관리가 활성화된 상태에서만 사용 가능하다.
2. EBS Elastic Volumes 기능을 사용해 볼륨 크기를 늘릴 수 있다.
3. 파일 게이트웨이는 NFS, SMB 프로토콜을 사용해서 S3에 파일을 업로드하는 방식이다.
4. CloudFront는 HTTP 기반 콘텐츠 전송에 특화되어 있으며 TCP 가속에는 Global Accelerator가 더 적합하다.
5. Aurora Serverless v2: 데이터베이스 용량을 워크로드에 맞춰 1초 단위로 자동 조정한다.
6. SNS는 메세지 지속성, SQS는 데이터 손실을 방지하는 메세지 처리
7. Lambda 함수 URL: Lambda 함수에 전용 HTTP(S) 엔드포인트를 제공하는 기능으로 API Gateway 없이도 함수를 직접 호출할 수 있어 비용효율적이고 구성이 간단하다.
8. RDS 자동 백업의 최대 보존 기간은 35일이다.
9. DynamoDB의 PITR (Point-in-Time Recovery) 는 최대 35일까지만 데이터를 복구할 수 있는 기능이다.
10. SQS는 메세지 보존기간을 최대 14일까지 설정할 수 있다.
11. PrivateLink는 VPC와 AWS 서비스 또는 타사의 SaaS 애플리케이션 간의 통로 역할, 인터페이스 VPC 엔드포인트는 VPC 서브넷 안에 생성되어 프라이빗 IP를 할당받는 실제 진입점이다.
12. 게이트웨이 VPC 엔드포인트는 비용이 무료다.
13. 인터페이스 VPC 엔드포인트는 NAT Gateway에 비해 비용이 저렴하다.
14. CloudTrail은 특정 계정이 AWS의 어떤 API를 호출했는 지 기록하는 서비스다.
15. AWS 보안 그룹은 '허용(Allow)' 규칙만 설정할 수 있으며, '거부(Deny)'규칙을 지원하지 않는다. 특정 트래픽을 명시적으로 차단하려면 반드시 네트워크 ACL을 사용해야 한다.
16. S3는 보안 그룹을 사용하지 않는다. 버킷 정책이나 ACL로 접근을 제어한다. 버킷 정책은 WAF ARN을 주체(Principal)로 직접 지정하여 트래픽을 제어하는 방식을 지원하지 않는다. S3에 직접 WAF를 붙일 수 없다.
17. WAF 포워딩은 서비스 앞단에서 검사하는 구조다.
18. 네트워크 ACL은 규칙 수에 제한(일반적으로 20~40개 권장)이 있다.
19. WAF IP 필터: 소셜 IdP의 IP를 화이트리스팅하는 것은 불가능하다(IP가 수시로 변경됨). 

## S3 

1. b
2. b
3. c
4. d
5. a, c
6. a
7. b
8. c
9. e
10. b
11. b
12. c
13. c

## Storage

1. c
2. b
3. d
4. c
5. c
6. c
7. c
8. c
9. a

## Data transfer

1. c
2. b,e
3. c
4. b
5. a
6. b

## Database

1. b
2. a
3. c
4. c
5. c
6. d
7. a
8. b
9. a
10. b,c
11. d
12. d
13. a
14. a
15. d
16. c
17. a
18. b
19. c
20. a
21. b
22. b
23. b
24. c

## Computing 1

1. a
2. c,e
3. a,d
4. a
5. c
6. c
7. a
8. a,b
9. a
10. b
11. a

## Computing 2

1. b
2. c
3. b
4. a
5. d
6. c
7. a
8. c
9. b
10. a

## Computing 3

1. a
2. b
3. a
4. d
5. d
6. b
7. c
8. a
9. c
10. a
11. d
12. b
13. c
14. c
15. a
16. a (x)
17. c
18. b
19. d
20. b
21. c
22. b

## Network 1

1. c (x)
2. c (x)
3. b,c (x) 
4. a
5. a
6. c
7. c
8. a (x)
9. c
10. d
11. d
12. b
13. c
14. d
15. b
16. b

## Network 2

1. b
2. b
3. c
4. b

## Data analysis

1. b
2. d (x)
3. a
4. a

## Security 1

1. c
2. a `(x)`
3. d
4. d `(x)`
5. a
6. c
7. a

## Security 2

1. b
2. d
3. c
4. b
5. a
6. d
7. a
8. b
9. b
10. d `(x)`
11. c
12. b

## Security 3

1. b
2. b
3. a
4. d
5. b
6. d
7. b,e
8. c
9. a
10. d
11. a,c
12. c `(x)`
13. b,c `(x)`
14. d `(x)`
15. a
16. c,e `(x)`

## Cost management

1. c
2. a
3. c
4. a,c
5. d
6. b
7. a,b `(x)`
8. a,b
9. c

