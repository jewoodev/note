이 글의 내용은 `https://netxhack.com/dns/` 포스팅의 내용을 정리한 것으로 전적으로 모든 저작권이 해당 블로그의 저자에게 있음을 알린다.

## 1. DNS의 중요성

과거에는 DNS까지 신경쓸 필요가 없었다. 날이 갈수록 보안성을 갖춘 DNS 서비스는 인터넷의 안정성과 보안성을 유지하는 데 있어 매우 중요한 역할을 갖게 된다. 특히 한국처럼 검열 국가에 속하는 지역에서는 ISP에 나의 활동 내역이 저장되는 것이 부담스러워지고, 나날이 발전하는 사이버 범죄로 인해 나의 네트워크 계층을 좀 더 안전하고 탄탄하게 보호하고 싶은 사람들도 많아지고 있다.

요즘은 DNS 중에는 DNS 자체에 광고 차단, 멀웨어 및 피싱 사이트 차단 같은 기능도 포함하고 있어 ISP(인터넷 서비스 제공자 - 통신사)에서 제공하는 국내 DNS를 사용하는 것이 자신의 use case에 정답이 아닐 수 있다. 하지만 속도가 좀 느려지고, 아주 가끔 호환성 문제가 생기는 부작용도 생기곤 한다.

DoT, DoH 같은 암호화 DNS도 생기기 시작했다. 평문으로 전송되는 일반 DNS가 전자라면 DNS over HTTPS (DoH), DNS over TLS (DoT), DNSCrypt 등은 후자에 속한다. 더 안전하게 인터넷을 할 수 있도록 보완한 DNS 인 것이다. - [Doh,DoT란?](https://netxhack.com/network/dns-doh-dot/)

"HTTPS로 접속하면 다 암호화되는 것 아니야?"라는 생각을 들 수 있디. DoH 같은 것이 따로 생긴 이유는 HTTPS 접속 시에 DNS는 함께 암호화되지 않기 때문이다. 반대로 검열해야 하는 입장에서는 이런 DNS 암호화 기술이 달갑지 않다. 구축해놓은 통제 시스템을 우회하기 때문이다. 이런 기술이 최근에 갑자기 생긴 건 아니며 각각 2016년과 2018susdp IETF (Internet Engineering Task Force)을 통해 표준 기술이 되었다. - [DNS 쉬운 기술](https://netxhack.com/dns/about-dns/)

## 2. 미리 알아두면 도움되는 정보

- KT, SK브로드밴드, LG 유플러스 등 국내 통신사 ISP DNS는 DoH, DoT 지원이 모두 안된다. 아마도 검열 때문인 것으로 보인다.
- 국내 ISP DNS 주소 (수동으로 DNS 주소를 바꿨다면 다시 기본 DNS로 바꿀 때 필요해서 미리 적어둠)
    - **KT** : 168.126.63.1 / 168.126.63.2
    - **SK Broadband** : 210.220.163.82 / 219.250.36.130
    - **LG U+** : 164.124.101.2 / 203.248.252.2
- DNS 주소는 ‘주(메인)DNS’와 ‘보조DNS’ 두개로 이루어져 있다. 서버 점검, 일시적 오류 등으로 메인DNS가 잠시 먹통이 되는 경우엔 보조DNS를 사용하게 된다. 다른 이름으로는 Primary DNS (preferred DNS) 그리고 Secondary DNS (alternate DNS)라고 부른다.
- 각 서비스 별로 멀웨어 차단, 자녀를 위한 성인사이트 차단 등 기능성 DNS 주소도 있다. (사용하시는 분들이 현실적으로 극소수인듯..)
    - 다만 이런 기능들은 부가적인 요소이지 전문 앱 만큼의 보호 기능은 없다.
- 아래 많은 종류 중 고민하실 필요는 없다.
    - 본인만의 특별한 목적이 없다면 1.1.1.1 을 통신사 DNS 대체용으로 쓰자.
    - 기업은 믿지 못하겠다면 비영리 재단에서 운영하는 Quad9
- 보안 DNS 주소를 사용한다고 해서 '익명'이 되는 것이 아님에 유의하자. 본인의 IP 주소는 그대로 사용된다.

## 3. 대략적인 DNS 속도 비교

![sketchy_DNS_speed_comparison.png](https://github.com/jewoodev/blog_img/blob/main/network/DNS_%EB%B9%84%EA%B5%90/sketchy_DNS_speed_comparison.png?raw=true)

녹색 바를 보시면 된다. Cloudflare > Quad9 > Cisco Umbrella > Google 순서로 성능이 비교되는 것이 확인된다. [1.1.1.1 vs 8.8.8.8 비교](https://netxhack.com/dns/1-1-1-1_vs_8-8-8-8/) 글을 읽어보시면 당시 측정했던 속도와 비슷합니다. Ping 기준으로 1.1.1.1이 20중반해서 40중반 정도이고 구글은 그 2배정도. (Test 시간대에 따라서 결과값이 다르긴 하지만 속도 순위는 큰 차이 없음)

평균적으로 KT 인터넷 기준으로 유명한 DNS Ping 값을 보면

1. Cloudflare
2. NextDNS
3. OpenDNS
4. Google
5. Adguard DNS
6. Quad9
7. Mullvad DNS

순서인 것 같다.

클라우드플레어 기준으로 사용량이 적은 시간대에는 5~6ms 수준으로 통신사 DNS와 거의 비슷하게 나온다.

![sketchy_DNS_speed_comparison2.png](https://github.com/jewoodev/blog_img/blob/main/network/DNS_%EB%B9%84%EA%B5%90/sketchy_DNS_speed_comparison2.png?raw=true)

시간대별로 꽤 다른 결과치가 나오기도 하지만 대체적으로는 저 순서로 빠른게 맞다.

## 4. 무료 DNS 서비스 종류

주소 뒤 ( ) 안에 포함된 복잡한 주소는 IPv6 주소다. 보통은 사용하실 일이 없지만 혹시나 필요하신 분들을 위해 같이 정리해두었다.

### 4.1 CloudFlare – 1.1.1.1

한국 뿐 아니라 전세계적으로도 이 회사의 DNS 성능이 가장 좋다. 디도스 방어, CDN(콘텐츠를 가장 가까운 서버에서 사용자에게 보내주는 서비스) 등의 분야에서 가장 유명하고 독보적인 위치에 있는 회사다. 00티비 같은 불법 서비스들이 클라우드플레어 CDN 네트워크를 이용해 우회 서비스를 하면서 당국과의 마찰도 있었다.

한국에서 무료 검열 우회 앱으로 유명한 유니콘HTTPS도 클라우드플레어 1.1.1.1을 기본 DNS로 사용하고 있다. 이런 종류의 앱들은 DNS 변경을 쉽게 해주는게 기능의 대부분이라고 봐도 무방하다. 2018년에 시작한 것으로 기억하는데 훨씬 빠른 속도를 무기로 구글 DNS의 자리를 대체했다.

미국의 대기업이라 Log 정책, 수사 협조 등이 궁금하시면 제가 작성한 [Cloudflare 관련글](https://netxhack.com/network/cloudflare-investigation/)을 읽어보자. 

개인 정보 보호 정책도 걱정하실 부분은 보이지 않는다. 마케팅, 광고를 위해 사용자의 Query를 이용하지 않을 것이고, IP 주소 등 log는 디스크에 저장되지 않으며, 기록되는 일부 Log는 24시간 이내에 삭제된다. 이런 정책은 대규모 회계, 감사 회사인 KPMG 등을 통해 이 부분의 감사를 진행하고 개개인의 정보를 팔아서 이익을 취하지 않아도 이미 돈을 잘 버는 큰 회사이기 때문에 큰 걱정없이 사용해도 된다.

#### 4.1.1 주소

- 기본 서버    - 
    - 1.1.1.1 (2606:4700:4700::1111)
    - 1.0.0.1 (2606:4700:4700::1001)
    - DoH : https://cloudflare-dns.com/dns-query- 
    - DoT
        - tls://one.one.one.one
        - tls://1dot1dot1dot1.cloudflare-dns.com
- 멀웨어 차단
    - 1.1.1.2 (2606:4700:4700::1112)
    - 1.0.0.2 (2606:4700:4700::1002)
    - DoH : https://security.cloudflare-dns.com/dns-query
    - DoT : tls://security.cloudflare-dns.com

```
Ping 1.1.1.1 32바이트 데이터 사용:
1.1.1.1의 응답: 바이트=32 시간=6ms TTL=56
1.1.1.1의 응답: 바이트=32 시간=6ms TTL=56
1.1.1.1의 응답: 바이트=32 시간=6ms TTL=56
1.1.1.1의 응답: 바이트=32 시간=6ms TTL=56

1.1.1.1에 대한 Ping 통계:
    패킷: 보냄 = 4, 받음 = 4, 손실 = 0 (0% 손실),
왕복 시간(밀리초):
    최소 = 6ms, 최대 = 6ms, 평균 = 6ms
```

속도에서 이미 다른 DNS는 따라올수가 없다. 느려도 20ms대는 나온다. 인프라 자체의 차이가 너무 크기 때문이라고 생각한다. Cloudflare는 태생 자체가 각국에 콘텐츠를 가장 빠른 속도로 전달해야하는 서비스를 하는 기업이고 그 일을 전 세계에서 가장 잘하고 있다. 지금까지 오랜기간 구축해온 인프라와 경험, 거기다 탄탄한 자금력까지 다른 기업이 쉽게 따라오진 못할거라고 생각한다.

DNS를 쉽게 토글 버튼으로 바꾸고 싶으신 분은 1.1.1.1 Warp 앱을 사용하면 된다.

### 4.2 Google Public DNS – 8.8.8.8

우리가 아는 그 구글에서 운영하는 퍼블릭 DNS 서버다. 2009년에 출시되어 당시에는 가장 쉬운 주소와 구글이라는 회사가 제공하는 무료로 제공하는 서비스라 사용하는 사람들이 지금보다는 더 많았던 것 같다. 사실상 지금은 더 쉬운 주소와 다양하고 빠른 서버를 제공하는 클라우드플레어에게 밀렸다.

- 8.8.8.8 (2001:4860:4860::8888)
- 8.8.4.4 (2001:4860:4860::8844)
- DoT : tls://dns.google
- DoH : https://dns.google/dns-query

홈페이지 : Google Public DNS 그리고 네트워크 설정 페이지를 보시면 윈도우, MacOS, 리눅스 등 구체적인 설정 방법들이 나온다. 여기서 DNS 서버 주소만 다른 것으로 교체하면 된다.

8.8.8.8 속도는 시간대별로 편차가 좀 크다.

속도 좋을때는 꽤 쓸만하다.

```
Ping 8.8.8.8 32바이트 데이터 사용:
8.8.8.8의 응답: 바이트=32 시간=27ms TTL=116
8.8.8.8의 응답: 바이트=32 시간=27ms TTL=116
8.8.8.8의 응답: 바이트=32 시간=27ms TTL=116
8.8.8.8의 응답: 바이트=32 시간=27ms TTL=116

8.8.8.8에 대한 Ping 통계:
    패킷: 보냄 = 4, 받음 = 4, 손실 = 0 (0% 손실),
왕복 시간(밀리초):
    최소 = 27ms, 최대 = 27ms, 평균 = 27ms
```

이러다 느릴 때는 40~80ms 정도도 나온다.

#### 4.2.1 구글 퍼블릭 DNS Log 기록 - 영구 DNS 기록

영구 로그는 IP 주소가 삭제되고 도시 또는 리전 수준 위치로 대체되는 임시 로그의 샘플이다. 따라서 영구 로그에는 사용자의 개인 정보가 포함되지 않는다. 다음 정보는 영구 로그에 기록된다. 개인 정보 보호 | Public DNS 여기에서 자세히 볼 수 있다.

- **임시 DNS 로그** : 임시 로그는 IP 주소와 DNS 쿼리를 모두 저장하는 유일한 로그입니다. 로그는 24~48시간 이내에 삭제되며 Google DNS 서비스 개선 및 유지관리, 수정 그리고 악의적인 보안 위협 및 활동, 갱니 식별이 불가능한 집계 DNS 사용 요약을 위해 쓰입니다.
    - DNS 쿼리를 보내는 기기의 IP 주소
    - 영구 로그를 위해 수집되는 기술 정보 (아래 참고)
    - DNS-over-HTTPS (DoH): Content-Type 및 Accept HTTP 헤더
- 영구 DNS 로그
    - 요청된 도메인 이름
    - 요청 유형 (A, AAAA, NS, MX, TXT 등)
    - 요청 크기    - 
    - 전송 프로토콜 (TCP, UDP, TLS 또는 HTTPS)
    - 클라이언트의 자율 시스템 번호
    - 사용자의 위치정보: 국가, 지역, 도시 (사용자 1km2 및 1,000명 이하)    - 
    - DNS 응답 코드
    - Google DNS 서버 정보
    - 타임스탬프
    - 처리 시각
    - 응답 DNS 플래그 (AD, CD, DO, RD, TC 포함)
    - 응답 크기
    - EDNS 버전
    - EDNS 옵션
    - EDNS 클라이언트 서브넷 (ECS) (IP 프로토콜 및 프리픽스 길이 – 클라이언트 IP 주소 제외)
    - EDNS 클라이언트 서브넷 (ECS) (IP 프로토콜 및 프리픽스 길이 – 클라이언트 IP 주소 제외)
    - DNS-over-HTTPS (DoH):
        - HTTP 경로 (/dns-query 또는 /resolve)에 해당하는 버전 문자열입니다.
        - 응답 HTTP 인코딩(예: application/dns-message 또는 json)

