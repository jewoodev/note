MYSQL을 DB로 사용하면서 JPA를 사용할 때 bulk insert가 필요하다면, 어떻게 하는게 Best practice일까? 

## 1. JPA를 사용해 bulk insert하면 어떨까?

먼저 `JpaRepository`의 `saveAll()`의 작동 방식을 살펴봐보자.
```java
@Override
@Transactional
public <S extends T> List<S> saveAll(Iterable<S> entities) {

    Assert.notNull(entities, ENTITIES_MUST_NOT_BE_NULL);

    List<S> result = new ArrayList<>();

    for (S entity : entities) {
       result.add(save(entity));
    }

    return result;
}
```

`save()`의 구현도 살펴보자.
```java
@Override
@Transactional
public <S extends T> S save(S entity) {

    Assert.notNull(entity, ENTITY_MUST_NOT_BE_NULL);

    if (entityInformation.isNew(entity)) {
       entityManager.persist(entity);
       return entity;
    } else {
       return entityManager.merge(entity);
    }
}
```

코드에서 알 수 있듯 파라미터로 넘겨준 `Iterable`(엔티티가 담긴)를 하나씩 반복하며 `persist()`를 수행한다.

### 1.1 `persist()`
`EntityManager`에서 제공하는 메소드이다.
이 메서드는 '비영속 엔티티', 즉 영속성 컨텍스트가 관리하지 않는 '일반 객체'를 영속성 컨텍스트에 의해 관리되는 **영속 상태로 만든다**.  
해당 엔티티는 insert 대상이 된 것이다.

이후 ID 생성 전략에 따라 동작이 다르다.

#### IDENTITY 전략을 사용하는 경우
PK를 받아와 객체에 할당해야 하기 때문에 persist() 호출 시 바로 insert 쿼리를 날린다.

#### 그 외 전략을 사용하는 경우
persist 이벤트를 모아두고(쓰기 지연), 트랜잭션 종료 전 flush 시점에 한 번에 처리한다.

### 1.2 성능 테스트 결과

다음의 코드로 `saveAll()`의 성능을 테스트 해보았다.
```java
@Transactional
public void batchInsert() {
    List<Employee> employees = new ArrayList<>();
    for (int i = 1; i <= 200; i++) {
        Department department = new Department("department" + i);
        Employee employee = new Employee("name" + i, department);
        employees.add(employee);
    }
    employeeRepository.saveAll(employees);
}
```

다음은 MySQL 서버 로그이다. 다음과 같이 쿼리가 전달된다.
![jpa_saveall_test_result.png](../../blog_img/spring-db/jpa_saveall_test_result.png)

Employee를 저장할 때 cascade 설정으로 Department도 함께 저장되게 되어있기에 Employee persist() 한 싸이클에 Department와 Employee 2개의 insert 쿼리가 전송되어 위와 같이 쿼리가 전송되었다.

배치 사이즈 설정을 하지 않았으니 기본적으로 모든 insert문은 각각 DB 서버에 전송된다.

### 1.3 개별 전송의 문제점
