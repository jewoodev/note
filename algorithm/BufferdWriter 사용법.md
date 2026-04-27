# BufferdWriter 사용법

```java
BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(System.out));   //할당된 버퍼에 값 넣어주기 
String s = "abcdefg";   //출력할 문자열 
bw.write(s+"\n");   //버퍼에 있는 값 전부 출력 
bw.flush();   //남아있는 데이터를 모두 출력시킴 
bw.close();   //스트림을 닫음
```

BufferedWriter 의 경우 버퍼를 잡아 놓았기 때문에 반드시 flush() / close() 를 반드시 호출해 주어 뒤처리를 해주어야 한다.

그리고 bw.write에는 System.out.println();과 같이 자동개행기능이 없기때문에 개행을 해주어야할 경우에는 `\n`를 통해 따로 처리해주어야 한다.