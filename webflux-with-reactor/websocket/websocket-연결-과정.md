```text
1. 클라이언트가 HTTP 요청으로 WebSocket 업그레이드를 시도
   GET /ws/chat HTTP/1.1
   Upgrade: websocket
   Connection: Upgrade
   ...

2. 서버가 WebSocket 프로토콜로 업그레이드
   HTTP/1.1 101 Switching Protocols
   Upgrade: websocket
   Connection: Upgrade
   ...
```

