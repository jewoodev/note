# JVM vs JRE
JRE는 Java Runtime Environment의 약자로 Java 프로그램이 실행될 수 있는 환경을 의미한다. 크게 Class Loader, Bytecode Verifier, Java Virtual Machine 세 가지 요소로 구성되며, 각각의 역할은 다음과 같다.
- **Class Loader**: 컴파일된 클래스 파일을 메모리에 로딩시키는 역할
- **Bytecode Verifier**: 클래스 파일의 정보가 문제 없는지 검증하는 역할  
- **Java Virtual Machine**: 클래스 파일을 바이트 코드로 변환해 플랫폼에서 실행시키는 역할

이 중 JVM이 각 플랫폼 별로 다른 JVM이 제공되는 구조로 되어있어 멀티플랫폼에서 호환될 수 있다.

# JRE vs JDK
JDK는 Java Development Kit의 약자로 프로그램 개발을 위해 JRE 이상의 것을 제공한다. 그 이상의 것이란 클래스 파일 생성을 가능하게 하는 자바 컴파일러, 디버깅 같은 런타임 지원을 위한 파일들이 포함된다.

## JVM (Java Virtual Machine)
- 자바 바이트코드(.class 파일)를 실행하는 런타임 환경입니다 
- 플랫폼에 독립적인 실행 환경을 제공하여 "Write Once, Run Anywhere"를 가능하게 합니다 
- 메모리 관리, 가비지 컬렉션, 바이트코드 해석/컴파일 등을 담당합니다

## JRE (Java Runtime Environment)
- 자바 애플리케이션을 실행하기 위한 환경입니다 
- JVM + 자바 클래스 라이브러리 + 기타 런타임 지원 파일들로 구성됩니다 
- 개발은 할 수 없고 오직 실행만 가능합니다

## JDK (Java Development Kit)
- 자바 애플리케이션을 개발하고 실행할 수 있는 완전한 개발 환경입니다 
- JRE + 개발 도구들(javac 컴파일러, jar, javadoc, 디버깅 등)이 포함됩니다 
- 개발자가 실제로 설치하는 것은 보통 JDK입니다