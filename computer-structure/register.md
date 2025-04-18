# 레지스터

프로그램의 명령어와 데이터는 실행 전후로 반드시 레지스터에 저장된다. 그리고 이런 레지스터는 다양한 종류로써 CPU 안에서 각기 다른 역할을 수행한다. 

이 문서에서는 모든 레지스터는 아니지만, 여러 전공 서적에서 중요하게 다루고 많은 CPU가 공통으로 포함하고 있는 여덟 개의 레지스터를 살펴본다. 

1. 프로그램 카운터
2. 명령어 레지스터
3. 메모리 주소 레지스터
4. 메모리 버퍼 레지스터
5. 플래그 레지스터
6. 범용 레지스터
7. 스택 포인터
8. 베이스 레지스터

## 1. 프로그램 카운터

프로그램 카운터는 메모리에서 가져올 명령어의 주소가 저장되는 곳이다. 이를 명령어 포인터라 부르기도 한다.

## 2. 명령어 레지스터

명령어 레지스터는 명령어 실행을 하기 위해 메모리에서 읽어들인 명령어를 저장하는 레지스터이다.  
제어장치는 명령어 레지스터에 저장된 명령어를 받아들이고 해석한 뒤 제어 신호를 내보낸다.

## 3. 메모리 주소 레지스터

메모리 주소 레지스터는 CPU가 읽어 들이고자 하는 주소 값을 주소 버스로 보낼 때 거치게 되는 레지스터로, 메모리의 주소를 저장하는 곳이다.

## 4. 메모리 버퍼 레지스터

이 레지스터는 메모리와 주고받을 값(데이터와 명령어)을 저장하는 레지스터이다. 즉, 메모리에 쓰고 싶은 값이나 메모리부터 읽어들인 값은 메모리 버퍼 레지스터를 거친다.   
CPU가 주소 버스로 내보낼 값이 메모리 주소 레지스터를 거친다면, 데이터 버스로 주고받을 값은 메모리 버퍼 레지스터를 거친다.

