# Optical line terminator

**Optical Line Terminator (OLT)**는 주로 **수동 광 네트워크(PON, Passive Optical Network)**에서 사용되는 장비로, 광섬유 통신망에서 서비스 제공자(예: 인터넷 서비스 제공업체, ISP) 측에 위치하는 핵심 장비입니다.

## 🔹 OLT (Optical Line Terminator)의 역할

1. 광 신호 송수신 
   - OLT는 인터넷 서비스 제공자의 데이터 센터나 중앙국에서 오는 데이터를 광 신호로 변환하여 광섬유를 통해 전송합니다.
   - 동시에 가입자로부터 올라오는 데이터를 수집하고 다시 전기 신호로 변환하여 상위 네트워크로 전달합니다.
2. 다수의 가입자 관리 
   - OLT는 하나의 광섬유를 통해 여러 가입자(ONT/ONU, Optical Network Terminal/Unit)를 동시에 관리할 수 있습니다.
   - OLT에서 Time-Division Multiplexing (TDM) 또는 Wavelength-Division Multiplexing (WDM) 방식을 이용하여 여러 가입자의 데이터를 효과적으로 전달합니다.
3. 트래픽 제어 및 QoS (Quality of Service) 제공 
   - OLT는 여러 가입자의 데이터 트래픽을 제어하고, 네트워크 대역폭을 효율적으로 분배하는 역할을 합니다.

## 🔹 OLT와 관련된 주요 개념

1. PON (Passive Optical Network)
   - OLT는 PON 네트워크의 핵심 장비이며, 데이터센터와 가입자를 연결하는 광 분배 네트워크를 관리합니다. 
   - PON에는 OLT, 광 분배기(Splitter), ONU/ONT가 포함됩니다.
2. ONU/ONT (Optical Network Unit/Terminal)
   - OLT에서 전송한 광 신호를 가입자 측에서 수신하고, 이를 전기 신호로 변환하여 사용자의 네트워크 장비(예: 라우터, 컴퓨터)와 연결하는 장치입니다.
3. GPON / EPON 
   - GPON(Gigabit Passive Optical Network)과 EPON(Ethernet Passive Optical Network)은 PON 기술의 대표적인 표준입니다.
   - OLT는 GPON 또는 EPON 기술을 이용하여 다수의 가입자를 서비스할 수 있습니다.

## 🔹 OLT의 실제 사용 사례
- FTTH (Fiber To The Home): 가정이나 기업에 광섬유 기반 초고속 인터넷을 제공할 때 OLT가 핵심 역할을 합니다. 
- 통신사(ISP) 네트워크: KT, SKT, LG U+ 같은 통신사가 가입자들에게 광 인터넷을 제공할 때 OLT를 사용합니다. 
- 데이터 센터 및 기업 네트워크: 대규모 광섬유 네트워크를 운영하는 데이터 센터에서 OLT를 통해 고속 인터넷 연결을 지원합니다.

## 🔹 정리

Optical Line Terminator (OLT)는 PON 네트워크에서 ISP 측에 위치하여 여러 가입자(ONU/ONT)와 데이터를 송수신하는 핵심 장비입니다. FTTH 같은 광 인터넷 서비스에서 필수적인 역할을 하며, 여러 가입자의 데이터를 효율적으로 관리하고 배분하는 기능을 수행합니다.