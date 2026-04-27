## 메모리 효율성
`StringBuilder`가 더 유리하다.

- `StringBuilder`는 내부적으로 `char` 배열 하나만 사용하여 문자열을 관리 
- `BufferedWriter`는 내부 버퍼 + 출력 스트림 객체들을 추가로 유지해야 함 
- `StringBuilder`는 필요에 따라 배열 크기를 동적으로 조정하므로 메모리 사용량이 더 예측 가능

## 시간 복잡도
상황에 따라 다르다.

### 문자열 조작이 많은 경우
- `StringBuilder` 승리: O(1) amortized append 연산
- 내부 배열에 직접 문자를 추가하므로 매우 빠름

### 대용량 출력의 경우
- `BufferedWriter` 승리: 시스템 호출 횟수를 최소화
- 내부 버퍼가 가득 찰 때만 실제 I/O 수행
- `StringBuilder`는 마지막에 `toString()` + `System.out.print()`로 한 번에 출력해야 하는데, 이때 추가 문자열 복사 발생

## 실제 사용 권장사항
```java
// 적은~중간 정도의 출력량 (보통의 알고리즘 문제)
StringBuilder sb = new StringBuilder();
sb.append("결과: ").append(answer).append("\n");
System.out.print(sb.toString());

// 대용량 출력이 예상되는 경우
BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(System.out));
bw.write("결과: " + answer + "\n");
bw.flush(); // 또는 bw.close();
```

## 결론
- 일반적인 알고리즘 문제: `StringBuilder` (메모리 효율성 + 코드 간결성)
- 대용량 출력 문제: `BufferedWriter` (I/O 최적화)
- 복잡한 문자열 조작 + 출력: `StringBuilder`로 문자열 구성 후 `BufferedWriter`로 출력

대부분의 코딩테스트 환경에서는 `StringBuilder`가 더 간단하고 효율적이다.