네트워크 서적에서 `클라이언트와 서버가 비지속적인(non-persistent) HTTP를 사용한다면, 모든 요청/응답마다 새로운 TCP 연결이 생성되고 종료될 것이다. 그리고 그러한 이유로 요청/응답 때마다 매번 새로운 소켓이 생성되고 종료될 것이다.` 라는 내용을 만나게 되었는데 소켓은 서버가 할당받고 나면 생성되어서 서버가 종료될 때까지 그 소켓으로 통신이 이루어지는 거라 생각했기 때문에 의아함을 가지게 되었다.

그런데 아마 서적의 내용은 클라이언트 소켓에 해당하는 설명인 것 같다.

## 서버 소켓 vs 클라이언트 소켓
### 1. **서버 소켓 (Listening Socket)**
``` java
ServerSocket serverSocket = new ServerSocket(8080); // 서버 시작시 생성
```
- 서버가 시작될 때 생성되어 **서버 종료까지 유지**
- 특정 포트(예: 8080)에서 **연결 요청을 대기**
- 실제 데이터 통신은 하지 않음

### 2. **클라이언트 소켓 (Connection Socket)**
``` java
while (true) {
    Socket clientSocket = serverSocket.accept(); // 각 연결마다 새로 생성
    // 요청 처리
    clientSocket.close(); // 응답 후 소켓 종료
}
```
- **각 클라이언트 연결마다 새로 생성**
- 실제 HTTP 요청/응답 데이터 통신 담당
- 비지속적 연결에서는 응답 후 즉시 소켓 종료

## 비지속적 HTTP 연결의 실제 동작
``` java
// 서버 측 (의사코드)
ServerSocket serverSocket = new ServerSocket(8080); // 서버 시작시 한 번만 생성

while (true) {
    Socket clientSocket = serverSocket.accept();     // 새 연결마다 생성
    
    // HTTP 요청 읽기
    BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
    String request = in.readLine();
    
    // HTTP 응답 전송
    PrintWriter out = new PrintWriter(clientSocket.getOutputStream());
    out.println("HTTP/1.1 200 OK\r\n\r\nHello World");
    
    clientSocket.close(); // 응답 후 즉시 종료 (비지속적)
}
```
## 정리
- **서버 소켓**: 서버 생존 기간 동안 유지 (포트 바인딩용)
- **클라이언트 소켓**: 각 HTTP 요청/응답마다 생성/종료
- 비지속적 연결에서 "매번 새로운 소켓"이라는 것은 **클라이언트 소켓**을 의미한다.

서버 소켓은 계속 유지되지만, 실제 통신을 담당하는 클라이언트 소켓은 매번 새로 생성된다.
