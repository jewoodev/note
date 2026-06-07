JVM Serial GC의 Mark-Copy와 Mark-Sweep-Compact
Mark-Copy (Young Generation)
Young Generation(Eden + Survivor 영역)에서 사용되는 방식입니다.
1. Mark 단계
   GC Root(스택 변수, static 변수, JNI 레퍼런스 등)에서 시작해 참조 그래프를 탐색하며 살아있는 객체를 마킹합니다.
2. Copy 단계
   마킹된(살아있는) 객체만 다른 Survivor 영역으로 복사합니다. 복사하면서 자연스럽게 메모리가 연속적으로 배치되므로 별도의 Compaction이 필요 없습니다. 복사가 끝나면 기존 Eden과 이전 Survivor 영역은 통째로 비워버립니다.
   핵심 특징은 "살아있는 객체만 복사"하는 것이기 때문에, Young Generation처럼 대부분의 객체가 금방 죽는(단명하는) 영역에서 효율적입니다. 살아남는 객체가 소수이므로 복사 비용이 적고, sweep 과정 자체가 불필요합니다.

Mark-Sweep-Compact (Old Generation)
Old Generation에서 사용되는 방식이며, 세 단계로 나뉩니다.
1. Mark 단계
   동일하게 GC Root부터 참조 체인을 따라가며 살아있는 객체를 마킹합니다.
2. Sweep 단계
   마킹되지 않은(죽은) 객체가 차지하는 메모리를 해제합니다. 이 단계 후에는 메모리 곳곳에 빈 공간(fragmentation)이 생깁니다.
3. Compact 단계
   살아있는 객체들을 메모리 한쪽으로 밀어서 연속된 공간으로 재배치합니다. 이를 통해 단편화를 제거하고, 이후 새 객체 할당 시 bump-the-pointer 방식으로 빠르게 할당할 수 있게 됩니다.
   Old Generation은 살아있는 객체 비율이 높기 때문에 Copy 방식은 비효율적입니다. 복사할 객체가 너무 많고, 동일 크기의 여분 공간이 필요하기 때문입니다. 대신 제자리에서 sweep 후 compact하는 방식이 적합합니다.

비교 요약
Mark-CopyMark-Sweep-Compact적용 영역Young GenOld Gen단편화 해결복사 시 자연 해결Compact 단계에서 해결장점빠름 (죽은 객체 무시)별도 복사 공간 불필요단점Survivor 여분 공간 필요Compact의 이동 비용전제대부분 죽는 객체 (약한 세대 가설)대부분 살아있는 객체
두 방식 모두 Serial GC에서는 Stop-The-World 상태에서 단일 스레드로 수행됩니다.