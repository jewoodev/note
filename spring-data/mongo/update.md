Spring WebFlux와 Reactive MongoDB를 사용할 때 Document를 업데이트 하는 Best practice가 무엇인지 알아보자.

## 1. `findById()` + `save()` 패턴

```java
repository.findById(id)
    .flatMap(existingDoc -> {
        existingDoc.setField(newValue);
        return repository.save(existingDoc);
    });
```

- 장점
    - 전체 도큐먼트를 한 번에 업데이트할 때 유용
    - 도큐먼트의 현재 상태를 확인하고 업데이트 가능
- 단점
    - 전체 도큐먼트를 다시 저장하므로 불필요한 데이터 전송이 발생할 수 있음
    - 동시성 이슈가 발생할 수 있음

## 2. MongoTemplate를 사용한 부분 업데이트 

```java
@Autowired
private ReactiveMongoTemplate mongoTemplate;

// 부분 업데이트
mongoTemplate.updateFirst(
    Query.query(Criteria.where("_id").is(id)),
    Update.update("field", newValue),
    YourDocument.class
);
```

- 장점
    - 필요한 필드만 업데이트 가능
    - 네트워크 트래픽 최소화
    - 원자적 업데이트 가능
- 단점
    - 추가적인 의존성 필요
    - 코드가 더 복잡해짐

## 3. `@Version`을 사용한 낙관적 락(Optimistic Lock)

```java
@Document
public class YourDocument {
    @Version
    private Long version;
}
```

- 장점
    - 동시성 이슈를 최소화
    - 충돌 방지
- 단점
    - 추가 필드 필요
    - 버전 충돌 시 재시도 로직 필요

## 4. Best Practive

1. 단일 필드 업데이트의 경우
    - MongoTemplate의 `updateFirst()` 또는 `updateMulti()` 사용
    - 네트워크 효율성과 성능이 가장 좋음
2. 여러 필드 동시 업데이트의 경우
    - `findById()` + `save()` 패턴 사용
    - 코드 가독성과 유지보수성이 좋음
3. 동시성 제어가 필요한 경우
    - `@Version`을 사용한 낙관적 락 구현
    - 충돌 해결 로직 추가
4. 대량 업데이트의 경우
    - MongoTemplate의 `updateMulti()` 사용
    - 벌크 연산으로 성능 최적화

## 5. 사용 예시

### 5.1 MongoTemplate의 Update 객체 사용 (권장)

```java
@Service
public class YourService {
    private final ReactiveMongoTemplate mongoTemplate;
    
    public Mono<YourDocument> updateMultipleFields(String id, String field1, String field2, String field3) {
        Update update = new Update()
            .set("field1", field1)
            .set("field2", field2)
            .set("field3", field3);
            
        return mongoTemplate.updateFirst(
            Query.query(Criteria.where("_id").is(id)),
            update,
            YourDocument.class
        ).then(mongoTemplate.findById(id, YourDocument.class));
    }
}
```

장점:
- 필요한 필드만 선택적으로 업데이트
- 네트워크 트래픽 최소화
- 원자적 업데이트 보장
- 성능이 가장 좋음

### 5.2 `findById()` + `save()` 패턴

```java
@Service
@Service
public class YourService {
    private final ReactiveMongoRepository<YourDocument, String> repository;
    
    public Mono<YourDocument> updateMultipleFields(String id, String field1, String field2, String field3) {
        return repository.findById(id)
            .flatMap(doc -> {
                doc.setField1(field1);
                doc.setField2(field2);
                doc.setField3(field3);
                return repository.save(doc);
            });
    }
}
```

장점:
- 코드가 더 직관적이고 읽기 쉬움
- 도큐먼트의 현재 상태를 확인하고 업데이트 가능
- 비즈니스 로직이 복잡한 경우 유리

### 5.3 실제 사용 예시

```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final ReactiveMongoTemplate mongoTemplate;
    
    // DTO를 사용한 업데이트
    public Mono<User> updateUserFields(String userId, UserUpdateDTO updateDTO) {
        Update update = new Update();
        
        if (updateDTO.getName() != null) {
            update.set("name", updateDTO.getName());
        }
        if (updateDTO.getEmail() != null) {
            update.set("email", updateDTO.getEmail());
        }
        if (updateDTO.getPhone() != null) {
            update.set("phone", updateDTO.getPhone());
        }
        
        return mongoTemplate.updateFirst(
            Query.query(Criteria.where("_id").is(userId)),
            update,
            User.class
        ).then(mongoTemplate.findById(userId, User.class));
    }
    
    // Map을 사용한 동적 업데이트
    public Mono<User> updateUserFields(String userId, Map<String, Object> updates) {
        Update update = new Update();
        updates.forEach(update::set);
        
        return mongoTemplate.updateFirst(
            Query.query(Criteria.where("_id").is(userId)),
            update,
            User.class
        ).then(mongoTemplate.findById(userId, User.class));
    }
}

// DTO 예시
@Data
public class UserUpdateDTO {
    private String name;
    private String email;
    private String phone;
}
```

일반적으로 MongoTemplate의 Update 객체를 사용하는 것이 가장 효율적이고 권장되는 방식이다.
