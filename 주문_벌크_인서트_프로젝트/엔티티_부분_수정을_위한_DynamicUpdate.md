# 엔티티 부분 수정을 위한 DynamicUpdate
Patch 메소드가 적용되어 특정 컬럼만 update 하는 쿼리가 나가게 하려면 해당 엔티티에 `@DynamicUpdate` 애노테이션을 붙여줘야 한다.