# Android 알림의 EXTRA_MESSAGES 이해하기

작성일: 2026-10-13

## 무엇을 담는가?

`Notification.EXTRA_MESSAGES`는 **메신저 형태의 알림에 담긴 메시지 목록을 읽기 위한 Android 표준 키**다. 실제 문자열 값은 `"android.messages"`이며 API 24에서 도입됐다. 키 자체가 메시지 배열은 아니고, 알림의 부가 정보에서 배열을 찾을 때 사용하는 이름이다. [Android 공식 정의](https://developer.android.com/reference/android/app/Notification#EXTRA_MESSAGES)

예를 들어 메신저가 알림 하나에 “안녕하세요”와 “사진 부탁드립니다”라는 두 메시지를 표시할 수 있다. 이때 메시지 목록에는 각 메시지의 본문, 발신자, 시각 등을 담을 수 있다. 알림 하나와 메시지 하나가 반드시 일대일로 대응하는 것은 아니다.

## 먼저 알아둘 용어

| 용어 | 의미 |
|---|---|
| `Notification` | 앱이 Android에 게시하는 알림 객체 |
| `extras` | 알림의 부가 정보를 키와 값으로 담는 `Bundle` |
| `Bundle` | 이름을 붙여 여러 값을 보관하고 전달하는 Android 자료형 |
| `MessagingStyle` | 대화의 여러 메시지를 표현하는 알림 스타일 |
| `MessagingStyle.Message` | 본문·시각·발신자 등을 가진 개별 메시지 객체 |

`MessagingStyle`은 앱이 메시지 목록을 구성해 알림으로 표현하도록 지원한다. [MessagingStyle 공식 문서](https://developer.android.com/reference/android/app/Notification.MessagingStyle)

## 알림 안의 구조

다음은 개념을 설명하기 위한 구조다. 개별 Bundle 내부의 실제 키 이름을 그대로 나열한 것은 아니다.

```text
Notification
└─ extras: Bundle
   └─ "android.messages": Parcelable 배열
      ├─ 메시지 A의 Bundle
      │  ├─ 본문
      │  ├─ 발신자
      │  ├─ 메시지 시각
      │  └─ 메시지별 추가 데이터
      └─ 메시지 B의 Bundle
         ├─ 본문
         ├─ 발신자
         ├─ 메시지 시각
         └─ 메시지별 추가 데이터
```

`EXTRA_MESSAGES`에 저장되는 값은 **메시지를 Bundle로 표현한 배열**이다. 바로 `Message[]`가 저장되어 있는 것은 아니다. `Parcelable`은 Android에서 객체를 전달할 수 있게 하는 규약이며, 여기서는 배열의 각 항목이 Bundle이다. [배열 형식 정의](https://developer.android.com/reference/android/app/Notification#EXTRA_MESSAGES)

개별 메시지에는 별도의 `extras`도 있다. 따라서 알림 전체의 `notification.extras`와 개별 메시지의 `message.extras`는 서로 다른 공간이다. [Message.getExtras 공식 문서](https://developer.android.com/reference/android/app/Notification.MessagingStyle.Message#getExtras())

## 읽기와 메시지 객체 복원

배열을 직접 읽는 예시는 다음과 같다.

```kotlin
@Suppress("DEPRECATION")
val bundles = notification.extras
    .getParcelableArray(Notification.EXTRA_MESSAGES)
```

이 코드는 원시 배열을 읽는다. 개별 메시지의 정보를 편리하게 사용하려면 메시지 객체로 복원해야 한다. API 30 이상에서는 다음 공개 메서드를 사용할 수 있다.

```kotlin
val messages = Notification.MessagingStyle.Message
    .getMessagesFromBundleArray(bundles)

for (message in messages) {
    val text = message.text
    val timestamp = message.timestamp
    val extras = message.extras
}
```

`getMessagesFromBundleArray()`는 Bundle 배열에서 메시지 목록을 읽는 API이며 API 30에 추가됐다. 위 코드를 더 낮은 API 수준에서 그대로 호출해서는 안 된다. [메서드 공식 문서](https://developer.android.com/reference/android/app/Notification.MessagingStyle.Message#getMessagesFromBundleArray(android.os.Parcelable%5B%5D))

이 저장소의 Android 알림 파서는 `Notification.Builder.recoverBuilder(context, notification).style`을 통해 `MessagingStyle`을 복원하고 `style.messages`를 읽는다. 원래 배열은 복원 과정에서 항목이 누락됐는지 개수를 비교하는 데 사용한다. 이 경로는 현재 구현에서 API 28 이상에만 적용한다. 이는 이 프로젝트의 구현 선택이며 `EXTRA_MESSAGES` 자체가 API 28부터 제공된다는 의미는 아니다. [현재 파서 구현](../../android-bridge/src/main/kotlin/com/icar/aicounselor/bridge/notification/KakaoNotificationParser.kt)

## 비슷한 필드와의 차이

| 필드 | 담는 정보 |
|---|---|
| `EXTRA_TEXT` | 알림의 본문 텍스트 |
| `EXTRA_MESSAGES` | `MessagingStyle` 알림의 메시지 목록 |
| `EXTRA_HISTORIC_MESSAGES` | 대화 맥락을 보여주기 위해 추가한 과거 메시지 목록 |

단일 본문과 개별 메시지 목록은 구조가 다르다. 메시지별 발신자나 추가 데이터를 확인하려면 개별 메시지를 읽어야 한다. 과거 메시지 목록은 별도의 키 `"android.messages.historic"`를 사용한다. [EXTRA_TEXT](https://developer.android.com/reference/android/app/Notification#EXTRA_TEXT), [EXTRA_HISTORIC_MESSAGES](https://developer.android.com/reference/android/app/Notification#EXTRA_HISTORIC_MESSAGES)

여기서 “메시지 목록”은 앱이 해당 알림에 넣은 데이터다. 채팅방의 전체 대화 기록이나 모든 미확인 메시지를 조회하는 API로 해석해서는 안 된다. `EXTRA_MESSAGES`에 들어 있다는 사실만으로 각 항목을 이번에 새로 도착한 메시지라고 판단해서도 안 된다.

## 카카오톡의 chatLogId와 어떤 관계인가?

이 프로젝트는 Android 알림을 읽고 카카오톡 요청에 답변하는 앱을 개발한다. 현재 파서는 개별 메시지의 추가 데이터에서 `chatLogId`를 읽는다.

```kotlin
val chatLogId = message.extras.get("chatLogId") as? Long
```

두 이름의 소유 주체를 구분해야 한다.

- `EXTRA_MESSAGES`: Android가 정의한 메시지 목록의 표준 키.
- `chatLogId`: 이 프로젝트가 조사한 카카오톡 알림의 개별 메시지 추가 데이터 필드. Android 표준 메시지 ID가 아니다.

현재 구현은 채팅방의 `shortcutId`와 `chatLogId`를 조합해 요청을 식별한다. 본문 수정으로 알림이 갱신되어도 같은 메시지로 판단하기 위한 프로젝트 정책이다. 다른 메신저 앱에도 `chatLogId`가 존재하거나 동일하게 동작한다고 가정할 수 없다. [식별자 추출 구현](../../android-bridge/src/main/kotlin/com/icar/aicounselor/bridge/notification/KakaoNotificationParser.kt)

## 데이터를 처리할 때 확인할 점

현재 파서는 배열이나 필요한 값이 없으면 해당 알림을 건너뛴다. 마지막 메시지가 잘못됐을 때 이전 메시지를 대신 선택하지 않도록 원래 배열과 복원된 목록의 크기를 비교한다. 마지막 항목만 처리하는 것은 이 프로젝트의 정책이며, Android가 모든 앱에 강제하는 처리 방식은 아니다.

조건에 맞지 않는 데이터는 명시적으로 제외하고, 실제 파싱 예외는 호출부에서 원인과 스택 추적을 기록한다. 메시지 목록을 읽을 수 있다는 것과, 그 메시지에 자동으로 응답해도 된다는 판단은 별개다. [파서 테스트](../../android-bridge/src/test/kotlin/com/icar/aicounselor/bridge/notification/KakaoNotificationParserTest.kt), [알림 처리 호출부](../../android-bridge/src/main/kotlin/com/icar/aicounselor/bridge/notification/KakaoNotificationListenerService.kt)
