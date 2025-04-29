설명을 건너뛰고 코드로 사용하는 방법을 살퍼보자

```java
@RequiredArgsConstructor
@Service
public class SentimentService {
    private final WebClient googleLangClient;
    
    @Value("${google.cloud.project-id}")
    private String projectId;
    
    @Value("${google.cloud.api-key}")
    private String apiKey;

    private static final String GOOGLE_NLP_API_URL = "/v1/documents:analyzeSentiment";

    public Mono<Double> analyzeSentiment(String text) {
        return Mono.defer(() -> {
            log.debug("Starting sentiment analysis for text: {}", text);
            Map<String, Object> requestBody = Map.of(
                "document", Map.of(
                    "type", "PLAIN_TEXT",
                    "content", text
                )
            );
            
            return googleLangClient.post()
                    .uri(uriBuilder -> uriBuilder
                        .path(GOOGLE_NLP_API_URL)
                        .queryParam("key", apiKey)
                        .build())
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .timeout(Duration.ofSeconds(5)) // 타임아웃 설정
                    .subscribeOn(Schedulers.boundedElastic()) // I/O 작업을 위한 전용 스케줄러
                    .map(response -> {
                        JsonNode documentSentiment = response.get("documentSentiment");
                        double score = documentSentiment.get("score").asDouble();
                        double magnitude = documentSentiment.get("magnitude").asDouble();
                        
                        log.debug("Sentiment analysis completed. Score: {}", score);
                        return score;
                    });
        })
        .onErrorResume(e -> {
            log.error("감정 분석 API 호출 중 오류 발생: ", e);
            return Mono.just(0.0); // 오류 발생 시 중립 점수 반환
        });
    }
}
```

여기에는 다음의 빈이 필요하다.

```java
@Bean
public WebClient googleLangClient() {
    return WebClient.builder()
            .baseUrl("https://language.googleapis.com")
            .build();
}
```

Google Cloud Natural Language API를 사용하기 위해서는 다음 단계가 필요하다.

1. Google Cloud 계정 생성
2. Natural Language API 활성화
3. API Key 생성
4. 환경 변수 설정:
    - `GOOGLE_CLOUD_PROJECT_ID`: Google Cloud 프로젝트 ID
    - `GOOGLE_CLOUD_API_KEY`: 발급받은 API Key

Google Cloud Natural Language API의 주요 특징:

1. **감정 점수** (Score) 값
    - -1.0 (매우 부정적) ~ 1.0 (매우 긍정적)
    - 0.0은 중립
2. **감정 강도** (Magnitude) 값
    - 0.0 ~ 무한대
    - 감정의 강도를 나타냄
    - 높을수록 더 강한 감정 표현
3. **추가 기능**
    - 엔티티 인식
    - 구문 분석
    - 콘텐츠 분류
    - 감정 분석

이 API를 사용하면 영어 텍스트에 대한 매우 정확한 감정 분석이 가능하다. 필요하다면 magnitude 값도 활용하여 감정의 강도까지 고려한 분석이 가능하다.

