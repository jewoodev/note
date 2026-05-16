# Unreachable
JVM의 GC는 unreachable 객체를 메모리에서 제거한다. 그리고 GC root로부터 객체를 탐색하기 시작해서 unreachable 객체를 찾아낸다.

## GC root 종류

| GC root                | reachable한 객체들                                                                     |
|------------------------|------------------------------------------------------------------------------------|
| thread stack(지역 변수)    | 모든 active thread들의 stack에 있는 지역변수(매개변수 포함)가 참조하는 객체들.                              |
| thread 객체(ThreadLocal) | active thread 객체(java.lang.Thread)에서 참조하는 객체들. 대표적으로 ThreadLocal과 Runnable 객체가 있음. |
| ClassLoader(정적 변수)     | 클래스로더가 로딩한 클래스들이 참조하는 객체들. 대표적으로 정적 변수가 있음.                                        |
| JNI 참조                 | 네이티브 코드에서 참조하고 있는 객체들                                                              |
| Monitor                | 동기화(e.g. synchronized, wait())에 사용 중인 모니터(monitor) 객체들.                            |

- GC root는 live(reachable) 객체를 찾기 위한 출발점. 
  - live 객체가 아니면 garbage로 판단함.
- garbage 공간은 재사용 가능.

# Generation GC
> 해당 내용은 serial GC 기준

Generation GC는 heap이 차면 GC root로부터 모든 live 객체들을 탐색. 

그런데 성능을 높이기 위한 고민을 해보면 모든 GC마다 모든 live 객체들을 방문해야 하는 걸까?

개발자들은 이런 의문을 가지고 객체의 생명 주기를 관찰해보았다. 그 결과 대부분의 객체는 태어나서 금방 죽었다. 오래된 객체는 계속 살아남을 가능성이 컸다.

태어나서 금방 죽는다? 그래서 young 객체만 탐색하자는 전략을 떠올리게 되었다.

> - age는 gc를 경험한 횟수
> - age는 객체의 헤더에 있음
> - age가 특정 threshold를 넘으면 old 객체가 됨

바로 old 객체를 만나면 더 이상 탐색하지 않고 다음 young 객체만 탐색하는 전략이다. 이는 성능을 높이는 전략은 맞았으나, old 객체가 참조하는, 즉 reachable한 객체가 garbage로 판단되는 문제가 생겨났다.

그래서 young generation과 old generation을 나누고 young generation만 collection하는 전략을 고안했다. 이는 각 세대의 주소 공간을 나누기 때문에 콜렉터가 객체 주소만 봐도 어떤 세대인지 알 수 있다.

이는 곧 Generation GC라는 이름을 갖게 되고, 다음과 같은 특성으로 설명될 수 있다.

- 객체의 나이에 따라 young generation와 old generation으로 나눈다.
- young generation이 다 차면 young live 객체만 탐색해서 young generation만 collection한다. (minor GC || young GC)
- minor GC 후에도 살아남은 young 객체는 나이가 1씩 증가한다.
- age가 임계치(threshold)를 넘으면 old generation으로 이동한다. (promotion)

## Generation GC의 문제점
만약 young 객체를 참조하는 old 객체가 생기게 되면 애플리케이션에서 사용되고 있는 객체인데 garbage가 되어버리는 문제가 있다. 하지만 경험적으로 "더 오래된 객체가 더 젊은 객체를 참조하는 경우는 거의 없다." 라는 걸 확인하게 되었다. 그래서 개발자들은 "드문 케이스이니까 old 객체가 참조하는 young 객체를 리스트 형태로 관리하면 되지 않을까?" 라는 생각을 하게 된다. 그래서 등장하게 된 개념이 remembered set이다. 

## Remembered set
이론적 & 논리적 개념인데 old 객체이면서 young 객체를 참조하고 있는 객체의 주소의 집합이다. minor GC가 일어날 때 이 집합을 young generation 다음으로 collection 한다.

## Free 공간을 확보하는 방법
- mark-sweep
  - live 객체들을 마킹하고 나서 마킹되지 않은 공간을 free 영역으로 등록한다.
  - 메모리 공간 파편화 문제를 갖는다.
- mark-sweep-compact
  - live object 탐색을 통해 free 공간 확인
  - live object를 compact 했을 때의 새로운 주소(forwarding address)를 객체의 헤더에 임시로 저장(linear scan)
  - 참조 주소를 새 주소로 업데이트 (GC root, linear scan)
  - 실제로 객체를 복사(linear scan)
  - 성능: **heap 크기와 전체 객체 수에 비례**
- mark-copy
  - **빈 공간**이 핵심
  - 빈 공간에 GC root로부터 탐색되는 live 객체들을 복사시킨 후, 빈 공간 외의 young generation을 free 영역으로 등록한다.
  - 성능: **live 객체 수에 비례**
  - 이 방법은 다음의 공간들이 필요
    - 살아남은 young 객체를 담을 공간 + 새 객체가 생성될 공간 + copy를 위한 빈 공간
  - 그래서 mark-copy가 끝난 후의 young 영역을 다음과 같이 나눔
    - 살아남은 young 객체를 담을 공간: eden
    - 새 객체가 생성될 공간: survivor0
    - copy를 위한 빈 공간: survivor1
  - 이 후 eden 영역이 다 차면 young generation을 collection한다. (minor GC)
  - 순서
    - GC root로부터 탐색된 live 객체를 eden 영역에 복사한 후 원래의 객체의 헤더에 forwarding address를 남김
      - 처음 탐색된 live 객체부터 차례대로 복사, 복사시킨 객체의 참조 관계가 유지되도록 참조값 수정(이때는 GC root의 참조값은 수정 x) 
    - live 객체를 모두 복수한 후에 다시 GC root부터 탐색해서 객체의 헤더에 forwarding address가 남아있으면, 해당 root의 참조 주소를 그 forwarding address로 업데이트
  - remembered set 관리
    - mark-copy를 통해 remembered set이 더이상 young 객체를 참조하고 있지 않게 되면?
    - 다음 mark-copy가 일어날 때 remembered set이 young 객체를 참조하지 않고 있다는 걸 확인하고 remembered set에서 제거함

### 정리
- **객체의 나이**에 따라 **young generation**와 **old generation**으로 나눈다.
- 새로운 객체는 **eden**에 생성된다.
- **eden**에 새 객체를 할당할 공간이 부족하면 **young live 객체**만 탐색해서 **young generation만 collection**한다. (**minor GC** || **young GC**)
- minor GC 후에도 살아남은 young 객체는 나이가 1씩 증가한다. (=**aging**)
- minor GC에서 young live 객체는 **survivor** 영역 중 하나로 모두 복사되고, 그 외의 young generation 전체는 비어지게 된다. (**mark-copy**)
- 단, age가 임계치(threshold)에 도달한 young live 객체는 survivor이 아닌 old generation으로 올라간다. (**promotion**)
- **remembered set**(card table)을 통해 young 객체를 참조하는 old 객체를 관리하며, minor GC 중에는 GC root 처럼 활용된다.

## major GC
앞서 살펴본 것처럼 GC 메모리 공간을 관리하다가 old generation 공간이 부족해지면 major GC가 발생한다. major GC는 old generation만 대상으로 collection 할까? 과거에는 그랬지만 최근의 방식은 generation 구분 없이 전체를 대상으로 한다.

- heap 전체를 collection
- **full GC**라고도 불림
- **mark-sweep-compact** 방식으로 동작(full GC가 minor GC보다 더 오래걸리는 이유)
- young generation 에서 살아남은 객체들도 **모두 old generation 으로 복사** (old generation 을 compact 한 후에)
- remembered set 은 major gc 에서는 사용되지 않음

## generation 비율
- (default) young generation : old generation = 1:2
- (default) eden : survivor0 : survivor1 = 8:1:1

## 언제 full GC가 트리거되나?
- young GC 직전에 old generation의 여유 공간이 부족하다고 예측되면
- young GC 도중에, 프로모션하기에는 old generation 공간이 부족하면
- 너무 큰 객체는 old generation으로 바로 생성되는데, 공간이 부족할 때

# 정리
- minor GC가 full GC보다 더 자주 일어난다.
- mark-sweep-compact는 mark-compact라고도 부른다.
- weak generation hypothesis
  - 대부분의 객체는 태어나서 금방 죽는다.
  - 더 오래된 객체에서 더 젋은 객체를 참조하는 경우는 거의 없다.
