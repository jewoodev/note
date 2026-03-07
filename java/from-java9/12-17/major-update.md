# String class API
- `indent()`
- `formatted()`
- 21에 preview feature로 문자열 템플릿 기능이 추가됨

# Files class API
- `mismatch()`: 서로 다른 파일의 내용물을 비교함
  - 다르면 다른 부분의 인덱스를 반환, 같으면 -1 반환

# Collectors와 Stream API
- `teeing(컬렉터1, 컬렉터2, ByFunction)`
  - 한 번의 Stream 연산으로 두 컬렉터의 결과를 구해 ByFunction을 수행한다. 생각보다 코드가 복잡해져서 비추.
- `mapMulti()`
  - `flapMap()`을 조금 더 효율적으로 사용하면서, 동시에 필터와 맵 연산까지 할 수 있음.
  - 