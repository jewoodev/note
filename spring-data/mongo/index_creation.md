Spring Data MongoDB 3.0 버전부터 컬렉션 라이프 사이클 및 성능에 미치는 원치 않는 방지하기 위해 인덱스 생성을 명시적으로 활성화해야 하도록 설정하는 방식이 변경되었다.

따라서 다음과 같은 방법을 사용하자.

```java
// Example 1. Programmatic Index Creation for a single Domain Type
class MyListener {

  @EventListener(ContextRefreshedEvent.class)
  public void initIndicesAfterStartup() {

    MappingContext<? extends MongoPersistentEntity<?>, MongoPersistentProperty> mappingContext = mongoTemplate
                .getConverter().getMappingContext();

    IndexResolver resolver = new MongoPersistentEntityIndexResolver(mappingContext);

    IndexOperations indexOps = mongoTemplate.indexOps(DomainType.class);
    resolver.resolveIndexFor(DomainType.class).forEach(indexOps::ensureIndex);
  }
}
```

```java
// Example 2. Programmatic Index Creation for all Initial Entities
class MyListener{

  @EventListener(ContextRefreshedEvent.class)
  public void initIndicesAfterStartup() {

    MappingContext<? extends MongoPersistentEntity<?>, MongoPersistentProperty> mappingContext = mongoTemplate
        .getConverter().getMappingContext();

    // consider only entities that are annotated with @Document
    mappingContext.getPersistentEntities()
                            .stream()
                            .filter(it -> it.isAnnotationPresent(Document.class))
                            .forEach(it -> {

    IndexOperations indexOps = mongoTemplate.indexOps(it.getType());
    resolver.resolveIndexFor(it.getType()).forEach(indexOps::ensureIndex);
    });
  }
}
```

EventListener를 활용한 예시는 좋은 예시이다.

만약 프로젝트가 리액티브 프로젝트라면 다음의 예시를 참고하자.

```java
@Slf4j
@RequiredArgsConstructor
@Configuration
public class ContextRefreshListener {

    private final ReactiveMongoTemplate mongoTemplate;

    @EventListener(ContextRefreshedEvent.class)
    public void initIndicesAfterStartup() {
        MappingContext<? extends MongoPersistentEntity<?>, MongoPersistentProperty> mappingContext = 
            mongoTemplate.getConverter().getMappingContext();
        IndexResolver resolver = new MongoPersistentEntityIndexResolver(mappingContext);

        mappingContext.getPersistentEntities()
                .stream()
                .filter(it -> it.isAnnotationPresent(Document.class))
                .forEach(it -> {
                    ReactiveIndexOperations indexOps = mongoTemplate.indexOps(it.getType());
                    resolver.resolveIndexFor(it.getType())
                            .forEach(indexDefinition ->
                                indexOps.ensureIndex(indexDefinition)
                                    .doOnSuccess(index -> log.info("Created index {} for collection {}", 
                                        index.toString(), it.getType().getSimpleName()))
                                    .doOnError(error -> log.error("Failed to create index for collection {}: {}", 
                                        it.getType().getSimpleName(), error.getMessage()))
                                    .subscribe()
                            );
                });
    }
}
```