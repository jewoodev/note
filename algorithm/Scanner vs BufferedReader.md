![post-thumbnail](https://velog.velcdn.com/images/mooh2jj/post/6dacfdf4-7972-44c7-b00f-3b222c63693f/image.jpg)

오늘은 Scanner 그리고 split 대신 `BufferedReader`, `StringTokenizer`을 사용하는 이유를 살펴볼려고 합니다.

### Scanner vs BufferedReader

자바의 입력 class에서는 대표적으로 `Scanner` 을 많이 봤을 것입니다.

결론적으로 Scanner 보다 `BufferedReader`을 사용하면 속도가 빨라집니다.

문자열에 최적화 된 BufferedReader에 비해 Scanner는 다양한 기능을 지원해서 무겁기 때문입니다.

같은 문제를 풀었을 때, Scanner와 BufferedReader를 사용했을 때의 처리속도차이
BufferedReader를 사용했을시, 거의 절반까지 (ex. 112MS -> 92MS)로 처리속도 단축되는 것이 확인이 됩니다.
출처 : https://wkimdev.github.io/java/2018/04/06/java-io-bufferedreader/

예시를 들어보겠습니다.

```java
//Scanner를 사용했을시 입력 형태.
Scanner sc = new Scanner(System.in);

int n = sc.nextInt(); // int
long l = sc.nextLong(); // int
String s = sc.next(); // String
String s = sc.nextLine(); // String
// 1 2 3 4 5 6 7 8 9 10 11 12 // 한줄 입력

for(int i=0;i<12;i++) {
sc.nextInt();
}
```

#### BufferedReader를 사용시

```java
// 1 2 3 4 5 6 7 8 9 10 11 12 // 한줄 입력

BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
String[] s = br.readLine().split(" "); // 문자열로 받고 split메소드를 이용해서 공백을 기준으로 잘라서 활용.

// s[0] = "1"; Integer.parseInt(s[0]) => 1
// s[1] = "2";
// s[2] = "3";
// .....
```

### split VS StringTokenizer의 nextToken

- StringTokenizer는 공백이 있다면 뒤에 문자열이 공백 자리를 땡겨 채우도록 한다.
- StringTokenizer가 BufferedReader보다 빠르게 사용될 수 있다.
- 문자열을 자르게 위해 split을 사용할땐, split은 정규식을 기반으로 자르는 로직으로서 내부는 복잡하다. 그에 비해 StringTokenizer의 nextToken()메소드는 단순히 공백 자리를 땡겨 채우는 것이다. `정규식 처리가 딱히 필요한게 아닌 경우 StringTokenizer가 효율적`이다.
- 정규식이나 인덱스 접근과 같은 처리가 필요없다면 StringTokenizer를 사용하는 것이 효율적이다.

#### StringTokenizer 사용법

- 자바에서는 String을 token단위로 끊어주는 StringTokenizer 클래스를 제공한다.
- 예를들어 “this is my string” 이라는 스트링을 this, is, my, string 4개의 스트링으로 끊어주는 기능을 제공한다.
- 그리고 공백말고도 다른 구획문자(delimiter)를 사용할수도 있다. 예를들어 this%is%my%string을 delimiter에 %를 넣어 StringTokenizer를 사용하면 마찬가지로 this, is, my, string으로 읽어준다.
- thismy%string^일때 구획문자를 “$%^”라고 설정해주면 this, is, my, string 으로 끊어준다.

```java
BufferedReader br = new BufferedReader(new InputStreamReader(System.in);
StringTokenizer st = new StringTokenizer(br.readLine());

// AB CDD EFFF GH 입력

st.nextToken() // AB
st.nextToken() // CDD
st.nextToken() // EFFF
st.nextToken() // GH
    String str = "this%%is%%my%%string"; 
    StringTokenizer st = new StringTokenizer(str,"%%"); 

    while(st.hasMoreTokens()) { 
        System.out.println(st.nextToken()); 
    }
```

### 실제 문제풀이

https://velog.io/@mooh2jj/코딩테스트-구간-합-구하기4-백준

```java
// 구간 합 구하기4
//예제 입력 1 
//5 3
//5 4 3 2 1
//1 3
//2 4
//5 5
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.StringTokenizer;

public class Main {

    public static void main(String[] args) throws IOException {

        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st = new StringTokenizer(br.readLine());
        int n = Integer.parseInt(st.nextToken());
        int m = Integer.parseInt(st.nextToken());
        int num[] = new int[n];
        int sum[] = new int[n + 1];

        st = new StringTokenizer(br.readLine());
        for (int i = 0; i < n; i++) {
            num[i] = Integer.parseInt(st.nextToken());
        }

        sum[1] = num[0];        // 첫번째 합은 num[0]로 설정
        for (int i = 2; i < n + 1; i++) {
            sum[i] = sum[i - 1] + num[i - 1];
        }

        for (int i = 0; i < m; i++) {
            st = new StringTokenizer(br.readLine());
            int s = Integer.parseInt(st.nextToken());
            int e = Integer.parseInt(st.nextToken());
            System.out.println(sum[e] - sum[s - 1]);
        }

    }

}
```

------

### 출처

https://joont92.github.io/java/Scanner-BufferedReader-StringTokenizer/
https://wkimdev.github.io/java/2018/04/06/java-io-bufferedreader/