# 프로세스로 실행되는 건 jar 파일인가 java 실행 파일인가?
- jar 파일은 실행 파일이 아니고 특수한 형태의 zip(압축) 파일 
- /bin/java는 실행 파일이며, 프로세스로 실행됨
- /bin/java가 실행되면 그것이 곧 JVM으로 동작하기 때문에 `자바 프로세스 = JVM 프로세스`
  - JVM 프로세스가 별도로 있지 않음
- JVM 프로세스는 jav 파일 내부의 .class 파일들에 기술된 바이트코드들을 읽고 해석해서 대신 수행하거나, 자주 사용되는 바이트코드들은 컴파일해서 기계어로 (바로 실행될 수 있게)변환함

# java 실행 파일 실행 후 main 메소드 실행까지의 흐름
1. JDK 소스 코드의 시작점에서 내부적으로 JLI_Launch() 함수를 호출해 리턴을 한다.
2. 그 후의 코드 흐름을 쭉 따라가보면 CallJavaMainInNewThread() 함수를 호출한다.
   1. 이 함수 내부를 보면 pthread_create() 함수를 호출해 그 결과가 0인지 확인하는 if 문이 있다.
      1. pthread_create() 함수는 새로운 스레드를 생성하는 함수이다.
      2. 0이면 새로운 스레드를 생성하는데 성공한 것이다.
      3. 생성에 성공하면 그 스레드에서 ThreadJavaMain() 메소드를 실행한다.
         1. ThreadJavaMain() 메소드는 JavaMain() 메소드를 실행한다.
   2. pthread_create() 함수 결과가 0이 아니면 해당 스레드에서 JavaMain() 메소드를 호출하는 코드가 있다.
3. JavaMain() 메소드는 내부적으로 다음과 같은 함수를 호출한다.
   1. InitializeJVM(): JVM 초기화
      1. Threads:create_vm(): vm에 대한 초기화 작업들을 수행하는 메소드
      2. new JavaThread(): 새로운 JavaThread 객체를 생성하는 메소드
         1. JavaThread는 JVM 안에서 관리하는 자료구조이다.
            1. java.lang.Thread가 아니다.
         2. OS Thread와 매핑시켜서 관리하기 편하게 하기 위한 자료구조다. C++ 안에서 구현되어 있다.
      3. initialize_java_lang_classes(): java.lang.Thread 를 하나 더 만든다.
      4. JavaThread와 java.lang.Thread를 연결한다.
      5. java.lang.Thread 코드를 까보면 JavaThread를 참조하고 있다.
      6. java.lang.Thread : JavaThread : OS Thread = 1 : 1 : 1 매핑 관계다.
         1. 여기서 말하는 java.lang.Thread는 virtual thread가 아니다.
   2. LoadMainClass(): Main 클래스 로드
   3. invokeStaticMainWithoutArgs(): main 메소드 호출

# JVM이 바이트코드를 실행하는 두 가지 흐름
1. 인터프리터 방식: JVM이 한줄 씩 해석해서 대신 실행
   1. java를 실행하면 우선 인터프리터 방식으로 바이트코드를 해석하며 실행됨
   2. 바이트코드를 한줄 씩 해석하면서 '각각의 명령에 대해 어떻게 동작하라고 정의해놓은 내부 코드'를 실행하는 방식
      1. 여기서 말한 내부 코드는 컴파일되어 있는 C++ 코드임
2. JIT Compiler: Just-in-time
   1. 바이트코드들 중에서 자주 호출되는 메서드나 loop 블록은 **최적화**해서 기계어 블락으로 컴파일하고, 그 후부터 컴파일된 곳(code cache)으로 바로 호출

    
- 일단 인터프리터로 동작하다가 자주 호출되는 영역(hotspot)은 JIT Compiler를 통해 기계어로 컴파일해서 그 기계어가 직접 실행되도록 하는 방식의 VM을 hotspot VM이라고 한다.
- hotspot의 JIT Compiler는 동작 방식이 tired compilation 방식이다.
  - level 0 (interpreter) -> level 1 ~ 3 (C1 - client compiler) -> level 4 (C2 - server compiler)
  - level이 높아질수록 더 최적화된다.

# 클래스 파일들은 한 번에 다 RAM에 로딩될까?
- 자바 표준 라이브러리들은 /lib/modules 라는 jimage 포맷의 파일에 모두 포함되어 있다.
- 개발자가 작성한 자바 클래스들은 jar 파일에 있다.
- java 실행 시 클래스로더를 통해 실행에 필요한 최소한의 클래스만 klass 객체로 만들어서 metaspace에 로딩
  - 이때 java.lang.Class 객체도 java heap에 생성
  - 여기서 말하는 최소한의 클래스는 자바 라이브러리 혹은 개발자가 작성한 클래스
- 로딩된 클래스를 바탕으로 바이트코드를 수행
- lazy loading: 바이트코드를 수행하다가 아직 로드되지 않은 클래스를 만나면 클래스로더가 해당 클래스를 로드함
- 클래스로더는 여러 종류가 있다.
  - bootstrapping classloader: 자바 표준 라이브러리를 담당
  - application classloader: 개발자가 작성한 클래스를 담당(from. jar)
  - platform classloader: JDK 확장할 때 사용. java 9 부터 java.xml, java.sql 등의 전신을 표준 라이브러리에 포함시켜서 보통 사용할 일이 없어짐.
- 클래스로더는 로드 이후에 linking과 initialization 과정이 있다.

## JDK 구성 
- /bin: 각종 실행 파일
- /lib:
  - modules: 자바 라이브러리
  - lib*.so: 네이티브 라이브러리
  - /server
    - libjvm.so: JVM 엔진

# JVM 프로세스 메모리 구조
- code(text), data(+bss), heap, stack 영역으로 분리해 메모리 공간을 할당받음
  - 스레드마다 별도의 stack 영역 할당

## code, data, (OS )heap
- **JVM 내부 로직이 사용(C++로 개발된 코드들)**
- 가령 이 heap에는 JavaThread 객체(C++로 정의됨)가 존재함

## (JVM )Stack 영역
- OS Thread마다 할당되는 stack 영역을 Java Thread들이 그대로 사용
- hotspot VM은 java 스택과 native 스택을 합쳐서 사용(JVM 명세에는 JVM stack과 native method stack을 구분)

## Code Cache
- JIT 컴파일러에 의해 최적화되어 기계어로 변환된 코드(주로 메서드 단위)들이 여기에 상주

## native library
- libjvm.so, libnet.so, libjava.so, etc... 
  - 이걸 사용해 시스템 콜을 호출
- 무조건적으로 연속적인 가상 주소 공간을 확보해서 사용하지는 않음

## Metaspace (method area)
- klass 객체: 각종 클래스 메타 정보(필드, 메서드 정보, 상속 관계)
- 메서드 바이트코드
- Runtime constant pool
- 드물게 GC 발생(at fullGC)
- 무조건적으로 연속적인 가상 주소 공간을 확보해서 사용하지는 않음
### JVM spec 문서 vs Hotspot VM Implementation
- JVM spec은 JVM은 어떻게 동작해야 하는지 기술한 스펙이고, 실제로는 항상 이 문서대로(이상적으로) 안 될수도 있고 튜닝이 될 수도 있음
- JVM spec을 기반으로 만들어진 구현체들이 여러 가지 있는데 그 중 하나가 Hotspot VM
- Hotspot VM에서 Metaspace라고 불리는게 JVM spec 무넛에서는 method area라고 불림

## JVM heap
- 위의 heap 영역과는 다름
  - 위의 것은 JVM 프로세스를 위한, JavaThread 같은 객체, C++로 구현된 그런 객체들이 사용하는 공간
- 자바 객체와 배열이 여기에 상주
- java.lang.Thread, java.lang.Class 객체도 여기에
- hotspot JVM의 GC는 주로 이곳에서
- String pool도 여기에서

## kernel space
그리고 당연히 커널 영역이 있겠다.

## native memory
JVM 공식 영문 문서에 나오는 명칭으로 JVM heap을 제외한 모든 영역을 일컫는다. 