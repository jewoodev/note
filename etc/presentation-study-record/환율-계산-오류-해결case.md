# I. 들어가며
## 1. 소개
해외송금 서비스에서 발생한 환율 계산 불일치(0.01 달러) 문제를 부동소수점 관점에서 해부하고, 해결 과정을 기록한 실전 사례다.

## 2. 부동소수점 문제?
![img.png](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FcYMrGX%2FbtsPqMRX0cf%2FAAAAAAAAAAAAAAAAAAAAAGDcDDKTCin61VIBWuzJUtEpR3odjrQfn9H9iz3BX3t1%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1753973999%26allow_ip%3D%26allow_referer%3D%26signature%3DSfBQ8jCxoM6OOBRQjZ9tS2DonbU%253D)
_미국 국방기술정보센터 내용_

1991년 걸프전에서 패트리어트 미사일이 이라크 스커드 미사일 요격에 실패해 미군 기지에 사상자가 났다. 0.34초 시간 계산 오차 부동소수점 반올림 때문이었다. 수학적으로 보잘것없는 오차가 현실에서는 목숨과 직결될 수 있다는 사실


# II. 문제의 발견
## 1. 문제의 발견
```
환율계산기 API

1. 송금 국가에 금액 입력시 : $5,000  →  6,825,000 KRW
2. 수취 국가에 금액 입력시 : 6,825,000 KRW →  $4,999.99
```
같은 금액을 입력했지만 전자와 후자의 달러 금액이 $5000과 $4999.99 로 다르다.

- 동일 입력·동일 환율인데 왕복 계산이 $0.01(≈13원) 어긋남
- 고객 시점: “내 돈이 사라졌다” 고객 신뢰 문제
- 규제 시점: 금융 데이터 불일치 → 감사·제재 대상 가능성
- 기술 시점: API 호출에 정합성(contract) 붕괴 → 장애로 분류

## 2. 문제의 원인
```
// 목표 : $5000 를 KRW로 → 다시 USD로 역산 (내부 로직 시뮬레이션)
BigDecimal fee   = new BigDecimal("12");            // 송금 수수료
BigDecimal rate  = new BigDecimal("1365.00");       // KRW/USD

// 1. 정방향 (USD→KRW)
BigDecimal net   = new BigDecimal("5000").subtract(fee); // 4988
BigDecimal krw   = net.multiply(rate);                   // 6_808_620 원

// 2. 역방향 (KRW→USD)
BigDecimal usdBeforeFee = krw.divide(rate, 14, RoundingMode.HALF_UP); // 4987.999267...
BigDecimal fromAmount   = usdBeforeFee.add(fee);                      // 4999.999267...

// 3. USD 두 자리 제한
fromAmount.setScale(2, RoundingMode.HALF_UP); // 4999.99 ❌ 0.01 손실 발생
```
역방향 (KRW→USD) 연산에서 divide() 결과가 무한소수지만 USD는 두 자리만 표기 → 잘라내는 순간 오차가 고정된다.  
즉 무한소수 ÷ 두 자리 제한이라는 복합 문제가 발생한다.

# III. 문제의 해결
## 1. MathContext로 정밀도 극대화
```   
// 최고 정밀도(34자리) 설정
private static final MathContext MC  = MathContext.DECIMAL128;
private static final BigDecimal STEP = new BigDecimal("0.01", MC); // USD 최소 단위(센트)
```
- 임의로 setScale(14)만 쓰던 기존 구현은 중간 연산 정밀도에 한계가 있었다.
- 모든 곱·나눗셈·덧뺄셈을 MathContext.DECIMAL128(34‑digit) 로 통일해 무한소수를 최대한 보존한다.

DECIMAL128을 선택 이유는 정밀도, 표준, 성능의 균형  
정밀도 관점 : 환율(소수 5 ~ 6)·금액(억 단위) 곱‧나눗셈 모두 손실 없이 해결이 가능하다
표준성 관점 : IEEE 754 표준  
성능 관점 : JVM 내부 최적화 + JIT 인라이닝  

## 2. 역계산 보정 메서드
±0.03 USD 범위에서 7회 탐색 → 대부분 첫 번째 후보에서 정합성 확보
```java
/**
* @param calculatedFromAmount  역계산으로 얻은 USD 금액(수수료 포함)
* @param originalToAmount    최초 수취 금액
* @param exchangeRateInfo      수취국가통화/USD 환율
* @param fee       송금 수수료
* @return 고객에게 노출할 USD 금액(소수 2자리)
*/
private BigDecimal applyReverseCalculationCorrection(
    BigDecimal calculatedFromAmount,
    BigDecimal originalToAmount,
    ExchangeRateInfo exchangeRateInfo,
    BigDecimal fee) {
    
    // 후보 금액들 (±0.01, ±0.02, ±0.03 범위)
    BigDecimal[] candidates = {
        calculatedFromAmount.add(new BigDecimal("0.01")),
        calculatedFromAmount,
        calculatedFromAmount.subtract(new BigDecimal("0.01")),
        // ... 더 많은 후보들
    };
    
    // 각 후보로 역계산하여 원본값과 비교
    for (BigDecimal candidate : candidates) {
        BigDecimal reverseToAmount = calculateReverse(candidate, exchangeRateInfo, fee);
        if (reverseToAmount.compareTo(originalToAmount) == 0) {
            return candidate.setScale(2, RoundingMode.HALF_EVEN); // 정확한 값 발견!
        }
    }
    // 아래로 실패 처리 이동
    return handleCorrectionFail(calcFrom, origTo, rate);
}
```

## 3.보정 실패 시 안전장치 & 로깅
- Fail‑Safe: 고객 금액은 보정 전 그대로 노출 → 화면 변화 없음 
- 로깅: 모든 실패 케이스는 경고 로그 + 모니터링 대시보드에 기록하여 추후 리포트 가능
```java
private BigDecimal handleCorrectionFail(BigDecimal calcFrom, BigDecimal origTo, BigDecimal rate) {
    log.warn("[FX‑CORR‑FAIL] reverse correction failed : from={} to={} rate={}", calcFrom, origTo, rate);
    // 차후 통계 분석을 위해 메트릭 푸시
    metrics.counter("fx.correction.fail").increment();
    return calcFrom.setScale(2, RoundingMode.HALF_EVEN);
}
```
- HALF_EVEN(Banker’s Rounding)으로 장기 편향 0 보장 
- 실패율 < 0.1 % (551 케이스 기준)

## 4. 검증
- 551 케이스 자동 테스트 (실제 환율·극한·무한소수·스트레스)

1단계: 기본 검증 (4개 케이스)

```java
@Test void basicKRWTests() {
// $5000 → 6,825,000 KRW → $5000.00
// $3000 → 4,095,000 KRW → $3000.00  
// $1000 → 1,365,000 KRW → $1000.00  
// $500 → 682,500 KRW → $500.00
}
```

2단계: 실제 환율 시나리오 (75개 케이스)
```
// 5개국 × 5개 경제 시나리오 × 3개 금액대
countries: KRW, JPY, AUD, CAD, MXN
scenarios: 경기호황, 불황, 금리인상, 지정학적리스크, 안정기
amounts: $1000, $3000, $5000
```

3단계: 극한 시나리오 (16개 케이스)
```
// 역사적 고점/저점, 급변동 상황
KRW: 900~1400 (일 변동률 5-7%)
JPY: 100~160 (급격한 엔저/엔고)
```

4단계: 정밀도 도전 (24개 케이스)
```
// 무한소수, 고정밀도 환율 테스트
repeatingDecimals: 1/3, 2/3, 1/7
highPrecision: 소수점 4-7자리
nearInteger: 999.999, 1000.001
```

5단계: 스트레스 테스트 (432개 연속 계산)
```java
// 메모리 누수, 성능 검증
for(int i = 0; i < 432; i++) {
    testCalculation(randomAmount, randomRate);
}
```

최종 결과

- 총 551개 테스트 케이스 
- 95%+ 케이스에서 완벽한 0.00$ 차이 
- 100% 케이스에서 ±0.03$ 허용 오차 내


# IV. 나가며
1. 부동소수점 = 시한폭탄: 도메인 제약(USD 2자리)과 결합의 문제 
2. 역연산 보존: A → B → A는 항상 원본을 돌려주도록 설계하기 
3. Banker’s Rounding: 금융·회계는 IEEE 754 표준을 고민하자 
4. 테스트는 보험: 극한·실전·스트레스 세트가 필요하다.