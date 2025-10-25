카프카에서 데이터의 시작점은 프로듀서이다. 프로듀서 애플리케이션은 카프카에 필요한 데이터를 선언하고 브로커의 특정 토픽의 파티션에 전송한다. 프로듀서는 데이터를 전송할 때 리더 파티션을 가지고 있는 카프카 브로커와 직접 통신한다. 프로듀서는 카프카 브로커로 데이터를 전송할 때 내부적으로 파티셔너, 배치 생성 단계를 거친다.

## 프로듀서 내부 구조
<img src="https://github.com/jewoodev/blog-img/blob/main/2024-05-03-%EC%95%84%ED%8C%8C%EC%B9%98_%EC%B9%B4%ED%94%84%EC%B9%B4_%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98_%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D_%EC%9D%B8%EA%B0%95_%EC%A0%95%EB%A6%AC/image-20240505210327064.png?raw=true" alt="image-20240505210327064" style="zoom: 50%;" />

- ProducerRecord : 프로듀서에서 생성하는 레코드. 오프셋은 미포함.
- send() : 레코드를 전송하는 요청 메서드.
- Partitioner : 어느 파티션으로 전송할지 지정하는 역할을 수행한다. 별도로 설정하지 않으면 DefaultPartitioner로 설정된다.
- Accumulator : 배치로 묶어 전송할 데이터를 모으는 버퍼.