# Optical network terminator

**Optical Network Terminator**(ONT)는 광섬유 네트워크에서 가입자(사용자) 측에 위치하는 장비로, 인터넷 서비스 제공업체(ISP)로부터 오는 광 신호를 전기 신호로 변환하고, 사용자의 네트워크 장비(예: 라우터, PC)와 연결하는 역할을 합니다.

## 🔹 ONT (Optical Network Terminator)의 역할

1. 광 신호(Optical Signal) ↔ 전기 신호(Electrical Signal) 변환 
   - ISP에서 송출한 광 신호를 전기 신호로 변환하여 사용자(가입자)의 네트워크 장치(PC, 라우터, Wi-Fi 공유기 등)로 전달합니다. 
   - 반대로, 사용자 측의 데이터를 전기 신호에서 광 신호로 변환하여 ISP로 보냅니다.
2. 가입자 네트워크 접속 (Customer Premises Equipment, CPE)
   - ONT는 가입자 댁내 장비(CPE, Customer Premises Equipment)의 일부로, 사용자의 집이나 사무실에 설치됩니다. 
   - 이더넷 포트, 전화 포트(VoIP 지원 시), Wi-Fi 기능(일부 모델) 등을 포함할 수 있습니다.
3. PON(Passive Optical Network) 환경에서 사용 
   - ONT는 Passive Optical Network(PON)에서 OLT(Optical Line Terminal)와 연결됩니다. 
   - OLT는 ISP의 데이터센터에 위치하며, 다수의 ONT를 관리하면서 네트워크 트래픽을 조정합니다.
4. QoS(Quality of Service) 및 트래픽 관리 
   - ONT는 트래픽 우선순위를 지정하고, 서비스 품질(QoS)을 유지하는 역할을 합니다.
   - ISP에서 제공하는 대역폭을 적절하게 분배하여 사용자 경험을 최적화합니다.

## 🔹 ONT vs ONU (Optical Network Unit)

종종 **ONT와 ONU**(Optical Network Unit)가 혼용되지만, 기술적으로 약간의 차이가 있습니다.

| 항목 | ONT (Optical Network Terminator) | ONU (Optical Network Unit) |
| -- | --- | --- |
| **설치 위치** | 사용자의 집이나 사무실 (가입자 댁내 장비) | 아파트, 빌딩, 국지적인 중간 지점 |
| **연결 방식** | 직접 OLT와 연결 | ONU를 거쳐 여러 사용자가 공유 |
| **사용 환경** | FTTH(Fiber-to-the-Home) | FTTB(Fiber-to-the-Building), FTTC(Fiber-to-the-Curb) |
| **트래픽 관리** | 개별 가입자 단위 관리 | 여러 가입자의 트래픽을 집계하여 OLT로 전달 |

즉, **ONT는 개별 가정/기업에 직접 설치되는 장비**, **ONU는 여러 사용자가 공유하는 중간 지점 장비**라고 볼 수 있습니다.