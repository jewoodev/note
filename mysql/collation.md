# collation
특정 문자 집합(character set)에 대해 문자들을 비교하고 정렬하는 방법을 정의하는 규칙을 의미한다.

## 1. 개념
같은 문자 집합이라도 대소문자를 구분할지, 특정 언어별 정렬 규칙을 적용할지에 따라 여러 개의 정렬방식이 존재한다.

###  1-1. `utf8mb4`
- `utf8mb4_general_ci` : 대소문자 구분 안 함(Case-Insensitive, `ci`)
- `utf8mb4_bin` : 바이너리 정렬(대소문자 구분, `bin`)
- `utf8mb4_unicode_ci` : 유니코드 표준 정렬(대소문자 구분 안함)

## 2. 주요 속성
- `ci (Case Insensitive)` : 대소문자를 구분하지 않음
- `cs (Case Sensitive)` : 대소문자를 구분함
- `bin (Binary)` : 바이너리 코드값을 기준으로 비교

## 3. 설정 방법
- 데이터베이스 단위  
  ```sql
  CREATE DATABASE mydb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  ```
- 테이블 단위  
  ```sql
  CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) COLLATE utf8mb4_unicode_ci
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  ```
- 컬럼 단위  
  ```sql
  ALTER TABLE users MODIFY name VARCHAR(255) COLLATE utf8mb4_bin;
  ```
- 정렬된 검색 시 사용  
  ```sql
  SELECT * FROM users ORDER BY name COLLATE utf8mb4_unicode_ci;
  ```
  
## 4. collation 선택 가이드
- 대소문자 구분 필요 없음 → utf8mb4_general_ci 또는 utf8mb4_unicode_ci 
- 대소문자 구분 필요 → utf8mb4_general_cs 
- 완전한 유니코드 정렬 지원 → utf8mb4_unicode_ci 
- 빠른 성능 우선 → utf8mb4_general_ci 
- 바이너리 비교 필요 → utf8mb4_bin

---

## 5. 대소문자를 구분하는 Collation 사용하기
필자가 글을 적는 시점에서 MySQL 버전은 8.0.40 대를 이어가고 있는데, 이 때는 utf8mb4_general_* 같은 collation이 deprecated 된 것 같다.([공식문서](https://dev.mysql.com/doc/refman/8.4/en/charset-mysql.html))

이후 버전 대에서는 선택할 수 있는 Collation이 다음과 같다.
- `utf8mb4_0900_as_cs` : Accent Sensitive, 대소문자를 구분하는 것에 더해 악센트를 구분하는 collation이다. 예를 들어. `é`와 `e`를 다르게 취급한다.
- `utf8mb4_0900_ai_cs` : Accent Insensitive, 악센트를 구분하지 않는다. é와 e를 동일하게 취급한다.

이 두 Collation은 유니코드 9.0을 기반으로 한다. 
