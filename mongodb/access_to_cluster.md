[mongo db 공식 문서 - 클러스터에 연결](https://www.mongodb.com/ko-kr/docs/atlas/tutorial/connect-to-your-cluster/) 과 [mongosh 공식 문서 - 배포서버에 연결하기](https://www.mongodb.com/ko-kr/docs/mongodb-shell/connect/) 의 내용이 참고되었다.

클러스터에 연결하는 방법은 여러가지가 있다.

1. [MongoDB Shell](https://www.mongodb.com/ko-kr/docs/mongodb-shell/)은 MongoDB 에 대한 대화형 Command-Line 인터페이스이다. `mongosh`를 사용해 Atlas 클러스터에 데이터를 삽입하고 데이터와 상호 작용할 수 있다.
2. ...
3. ...

이 중에서 MongoDB 셸을 사용해서 연결하는 방법을 알아보자. 

## 전제 조건

MongoDB Shell 을 사용하려면 연결할 배포서버가 필요하다. 그리고 MongoDB의 버전 4.2 이상 부터 지원한다.

## 연결하는 법

[데이터베이스 사용자를 생성](https://www.mongodb.com/ko-kr/docs/atlas/tutorial/create-mongodb-user-for-cluster/) 하지 않았다면 사용자 이름과 비밀번호를 설정해야 한다. Atlas에 연결하려면 Atlas 연결 문자열과 함께 사용자 이름을 전달하고 연결 명령을 실행하면 셸에서 비밀번호를 입력하라는 메시지가 표시된다.

연결을 설정하려면 연결 문자열 및 연결 설정 옵션을 포함하여 mongosh 명령을 실행한다. 연결 문자열에는 다음 요소가 포함된다. 

1. 클러스터 이름
2. 해시
3. API 버전에 대한 플래그
4. 연결에 사용할 사용자 이름에 대한 플래그

다음의 예시를 참고하자.

`mongosh "mongodb+srv://YOUR_CLUSTER_NAME.YOUR_HASH.mongodb.net/" --apiVersion YOUR_API_VERSION --username YOUR_USERNAME`

> 다른 연결 보안 옵션을 사용하여 mongosh를 통해 Atlas에 연결할 수 있다.  
> 
> 피어링 또는 비공개 엔드포인트 연결 방식으로 비공개 IP에 연결하는 방법에 대한 정보는 mongosh를 통한 Atlas 연결 문서를 참조하길 바란다..

## 원격 호스트로 배포서버 연결하는 법

