자바에서 문자열을 자르는데 사용하는 대표적인 클래스가 String 클래스의 split 메서드와 StringTokenizer 클래스가 있다. 

이번 시간에는 이 둘의 사용 문법을 알아보고, 둘이 어떠한 차이점이 있는지, 어떨때 어느 것을 사용해야 하는지 알아보자.

## String 클래스의 split 메서드
String 클래스에서 제공되는 split 메서드는 매개변수 갯수가 다른 2개로 오버로딩 되어 있다.  

자바의 split 메서드의 가장 큰 특징은 구분자를 문자로 받는게 아니라 정규식으로 받는다는 점이다.  
정규식이 난이도가 있는 부분이긴 하지만 덕분에 다채롭고 섬세하게 문자열을 자를 수 있다는 특징이 있다.  

```java
public String[] split(String regex);
// 반환을 String 배열로 받는다.
// 구분 기호를 문자열이 아닌 정규표현식으로 받는다. (중요)

public String[] split(String regex, int limit);
// 문자열을 정규식에 맞춰서 분리하는데 limit만큼 문자열을 자른다.
```
> _Tip!_
> 만일 split의 문자열 자르기 동작이 실패하면 PatternSyntaxException 예외(정규식 패턴 오류)를 발생시킨다. 

### 구분자로 문자열 분리하기

```java
String str = "inpa@tistory@com@super@power";
String[] splitter = str.split("@");

for (int i=0; i < splitter.length; i++) {
    System.out.printf("%d위치 : %s\n", i, splitter[i]);
}

String str = "inpa@tistory@com@super@power";
// 문자열을 자르되, 딱 3번 까지만 자르고 말아라
String[] splitter = str.split("@", 3); // limit 사용

for (int i=0; i < splitter.length; i++) {
        System.out.printf("%d위치 : %s\n", i, splitter[i]);
}
```

### 여러개 구분자로 문자열 분리하기
정규식 or를 의미하는 대괄호로 감싸서 구분자로 사용할 특수문자를 적어주면 된다.
```java
String str = "hello-world%inpa@tistory#com";
String[] splitter = str.split("[%-@#]");

for (int i=0; i < splitter.length; i++) {
    System.out.printf("%d위치 : %s\n", i, splitter[i]);
}
```

### 구분자에 사용할 특정 기호 주의점
split 메소드는 정규표현식을 매개변수로 받기 때문에, 정규식으로 이미 지정된 약속 기호를 아무 생각없이 써버리면 안된다.

예를 들어 | 기호는 정규식에서 or을 의미하는데 무턱대고 사용하면 다음과 같은 결과가 나타나게 된다.

```java
String str = "inpa|tistory|com|super|power";
String[] splitter = str.split("|");

for (int i=0; i < splitter.length; i++) {
    System.out.printf("%d위치 : %s\n", i, splitter[i]);
}
```
따라서 \\ 로 이스케이프 처리해서 인자로 전달 해야 한다.

```java
String str = "inpa|tistory|com|super|power";
String[] splitter = str.split("\\|"); // 문자 | 로 자르기

for (int i=0; i < splitter.length; i++) {
    System.out.printf("%d위치 : %s\n", i, splitter[i]);
}

System.out.println("\n---------------------------------\n");

String str2 = "inpa.tistory.com.super.power";
String[] splitter2 = str2.split("\\."); // 문자 . 로 자르기

for (int i=0; i < splitter2.length; i++) {
    System.out.printf("%d위치 : %s\n", i, splitter2[i]);
}
```

## StringTokenizer 클래스
StringTokenizer 클래스는 문자열을 구분자(delimiter)를 기준으로 토큰(token)이라는 여러 개의 문자열로 잘라내는데 사용한다.

만일 구분자를 넘겨주지 않을 경우 기본으로 공백으로 설정되어 문자열을 자르게 된다.

```java
// 문자열을 공백 문자를 구분자로 자르기
new StringTokenizer(String str)


// 문자열을 매개변수로 지정된 구분자(delim)로 자르기
// 이때 구분자는 토큰으로 간주되지 않음
new StringTokenizer(String st, String delim)


// 문자열을 매개변수로 지정된 구분자(delim)로 자르기
// returnDelims 의 값을 true로하면 구분자도 토큰으로 간주
new StringTokenizer(String str, String delim, boolean returnDelims)
```

위의 과정으로 만들어진 결과물은 배열이 아닌, 구분자에 따라 나누어진 문자열의 토큰을 갖고 있게 된다.

개발자는 이러한 토큰을 꺼내와서 StringTokenizer에서 지원하는 메소드로 원하는 방식으로 문자열을 가공해야 하기에 split 과는 사용방법에 차이가 있다.

| StringTokenizer 메서드                                  | 설명                |
|------------------------------------------------------|-------------------|
| int countTokens()                                    | 전체 토큰 수를 반환       |
| boolean hasMoreTokens() && boolean hasMoreElements() | 토큰이 남아 있는지 여부를 반환 |
| String nextToken()                                   | 다음 토큰을 반환         |

### 구분자로 문자열 분리하기

```java
// 1. delim을 default로 설정.
String str1 = "Wellcome to The Java HelloWorld";
StringTokenizer st = new StringTokenizer(str1);

System.out.println("- str1의 토큰 개수 : " + st.countTokens());
while (st.hasMoreTokens()) {
    System.out.println(st.nextToken());
}

// 2. delim을 '%'로 설정.
String str2 = "Wellcome%to%The%Java%HelloWorld";
StringTokenizer st = new StringTokenizer(str2, "%");

System.out.println("- str2의 토큰 개수 : " + st.countTokens());
while (st.hasMoreTokens()) {
    System.out.println(st.nextToken());
}
```

### 구분자도 토큰으로 포함시켜 분리하기
구분자를 문자열 자르는데에 사용되는 것 뿐만 아니라 토큰으로도 지정할 수도 있다.

```java
String str4 = "Wellcome%to%The%Java%HelloWorld";
// %를 구분자로서 역할 뿐만 아니라 출력되도록 설정
StringTokenizer st = new StringTokenizer(str4, "%", true); // 3번째 인자를 true로

System.out.println("- str4의 토큰 개수 : " + st.countTokens());
while (st.hasMoreTokens()) {
    System.out.println(st.nextToken());
}
```

### 구분자 중간에 재설정하기
StringTokenizer의 가장 큰 특징은 중간에 구분자를 새로 설정 할수 있다는 점이다.

```java
// 4. delim을 '%'으로 설정하여 출력하다가, delim을 '&'로 재설정하고 출력.
String str4 = "Wellcome%%to%&The&Java&HelloWorld";
StringTokenizer st = new StringTokenizer(str4, "%");

System.out.println("- str4의 토큰 개수 (delim : '%') : " + st.countTokens());
System.out.println(st.nextToken());
System.out.println(st.nextToken());

System.out.println(st.nextToken("&")); // 구분자 재설정

System.out.println("- str4의 토큰 개수 (delim : '&') : " + st.countTokens());
System.out.println(st.nextToken());
System.out.println(st.nextToken());
System.out.println(st.nextToken());
```

## Split vs StringTokenizer 차이점
- 먼저 split 메소드는 String클래스에 속해있는 메소드이고, StringTokenizer는 java.util에 포함되어 있는 클래스이다. 
- 구분자를 split는 **정규 표현식**으로 구분하고, StringTokenizer는 **문자**로 받는다. 
- split는 결과 값이 문자열 **배열**이지만, StringTokenizer는 **객체**이다. 
- split는 빈문자열을 토큰으로 인식하는 반면, StringTokenizer는 빈 문자열을 토큰으로 인식하지 않는다. (뒤에 코드 예제)
- **성능은 split 보다 StringTokenizer 가 좋다**.  
   split은 데이터를 토큰으로 잘라낸 결과를 배열에 담아서 반환하기 때문에 StringTokenizer보다 성능이 떨어진다.그러나 데이터의 양이 많은 경우가 아니라면 별 문제가 되지 않는다.

다음은 구분자를 `,` 로 하는 문자열 데이터를 String 클래스의 `split()` 과 `StringTokenizer` 로 잘라낸 결과를 비교하는 예제이다.

`split()` 은 빈 문자열도 토큰으로 인식하는 반면, `StringTokenizer`는 빈 문자열을 토큰으로 인식하지 않기 때문에 토큰 개수에 차이가 있는 것을 확인할 수 있다.

```java
String data = "100,,,200,300";

// split은 빈문자 까지 토큰으로 인식하여 저장한다.
String[] result = data.split(",");
for (int i = 0; i < result.length; i++) {
    System.out.print(result[i] + "|"); // 빈문자를 구분하기 위해 | 문자를 출력
}
System.out.printf("%nsplit()의 개수 : " + result.length + "%n%n");


// StringTokenizer 빈문자는 토큰으로 인식하지 않는다.
StringTokenizer st = new StringTokenizer(data, ",");
int countTokens = st.countTokens(); // 전체 토큰의 수를 반환
for (int j = 0; st.hasMoreElements(); j++) {
    System.out.print(st.nextToken() + "|"); // 빈문자를 구분하기 위해 | 문자를 출력
}
System.out.printf("%nStringTokenizer개수 : " + countTokens);
```

## 출처
- [Inpa Dev 👨‍💻](https://inpa.tistory.com/entry/JAVA-☕-Split-StringTokenizer-문자열-자르기-비교하기) 