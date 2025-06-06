## 회선 교환(Circuit Switching)의 개념

- 통신을 시작하기 전에 송신자와 수신자 사이에 전용 통신 경로를 설정하는 방식이다. 통신이 시작되면 해당 경로는 통신이 종료될 때까지 다른 사용자가 사용할 수 없다.
- 전화 네트워크에서 가장 일반적으로 사용되는 방식이다.

### 시분할 다중화(TDM, Time Division Multiplexing)의 특징

- 하나의 전송 매체를 시간적으로 분할하여 여러 사용자가 공유할 수 있게 하는 기술이다.
- 각 사용자에게 고정된 시간 슬롯을 할당한다.
- 동기식 TDM과 비동기식 TDM으로 구분된다.

### 동기식 TDM의 작동 방식

- 시간 프레임을 고정된 크기의 슬롯으로 나눈다.
- 각 슬롯은 특정 사용자에게 할당된다.
- 사용자가 데이터를 전송하지 않더라도 슬롯은 계속 할당된다.
- 프레임의 시작을 알리는 동기화 비트가 필요하다.

### 비동기식 TDM의 특징

- 동적 TDM이라고도 한다.
- 데이터가 있는 사용자에게만 슬롯을 할당한다.
- 각 슬롯에 사용자 식별 정보가 포함된다.
- 대역폭을 더 효율적으로 사용할 수 있다.

### TDM의 장점

- 간단하고 예측 가능한 지연 시간
- 실시간 통신에 적합
- 하드웨어 구현이 비교적 간단

### TDM의 단점

- 사용자가 데이터를 전송하지 않을 때도 대역폭이 낭비될 수 있다.
- 고정된 대역폭 할당으로 인한 비효율성
- 사용자 수가 증가하면 각 사용자의 대역폭이 감소

### 실제 적용 사례

- 전화 네트워크의 T1/E1 회선
- ISDN (Integrated Services Digital Network)
- SONET/SDH 광통신 네트워크

### 최신 동향

- 패킷 교환 네트워크의 발전으로 전통적인 TDM의 사용이 감소
- 소프트웨어 정의 네트워킹(SDN)과 가상화 기술의 등장
- 5G 네트워크에서의 새로운 형태의 TDM 활용

이러한 회선 교환과 TDM은 여전히 특정 분야에서 중요한 역할을 하고 있으며, 특히 실시간 통신이 필요한 환경에서 그 가치를 인정받고 있다.

## TDM의 슬롯과 프레임, 그리고 전송률

### 슬롯(Slot)과 프레임(Frame)의 개념

- 슬롯: 데이터 전송의 기본 단위 시간 구간
- 프레임: 여러 슬롯이 모여서 구성되는 하나의 완전한 전송 단위

### 전송률과 슬롯의 관계

- 전송률(Transmission Rate) = 슬롯 수 × 슬롯당 전송률
- 예시:
  - 1초에 8000개의 프레임을 전송
  - 각 프레임이 24개의 슬롯으로 구성
  - 전송률 = 8000 × 24 × 8 = 1.544 Mbps (T1 회선)

### 프레임과 슬롯 할당 예시

```text
프레임 구조:
[동기화 비트][슬롯1][슬롯2][슬롯3]...[슬롯N]
```

### 사용자별 슬롯 할당 이해

- 고정 할당 방식:
  - 예: 1초에 8000개의 프레임
  - 각 프레임이 24개의 슬롯으로 구성
  - 사용자 A에게는 매 프레임의 1번 슬롯 할당
  - 사용자 B에게는 매 프레임의 2번 슬롯 할당

### 구체적인 예시 계산

```text
조건:
- 프레임 전송률: 8000 프레임/초
- 프레임당 슬롯 수: 24개
- 사용자 수: 24명

각 사용자의 전송 기회:
- 1초당 8000번의 프레임 전송
- 각 프레임에서 1개의 슬롯 할당
- 따라서 각 사용자는 1초에 8000번의 전송 기회
- 각 슬롯당 8비트 전송 시, 사용자당 전송률 = 8000 × 8 = 64 Kbps
```

### 슬롯 할당의 특징

- 고정 할당:
  - 각 사용자에게 프레임마다 동일한 위치의 슬롯이 할당
  - 예측 가능한 전송 지연
  - 대역폭 낭비 가능성
- 동적 할당:
  - 사용자가 데이터를 전송할 때만 슬롯 할당
  - 슬롯에 사용자 식별 정보 포함
  - 대역폭 효율적 사용

### 실제 적용 예시 (T1 회선)

```text
- 프레임 전송률: 8000 프레임/초
- 프레임당 슬롯 수: 24개
- 슬롯당 비트 수: 8비트
- 프레임당 추가 비트: 1비트 (동기화용)
- 총 전송률: (24 × 8 + 1) × 8000 = 1.544 Mbps
```

이러한 구조를 통해 TDM은 여러 사용자가 하나의 전송 매체를 효율적으로 공유할 수 있게 됩니다. 각 사용자는 자신에게 할당된 슬롯에서만 데이터를 전송하며, 프레임의 반복 주기만큼 정기적인 전송 기회를 가지게 됩니다.
