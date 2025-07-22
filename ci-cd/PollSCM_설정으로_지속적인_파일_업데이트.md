# PollSCM 설정으로 지속적인 파일 업데이트

PollSCM을 쓰면 커밋에 대한 내용이 있을 경우에만 빌드를 다시 하도록 설정할 수 있다. 이 방법도 크론을 쓰는데, 몇 분마다 커밋이 있는지 확인하고 새로 제출된 커밋이 있으면 빌드를 한다.

PollSCM을 설정하는 방법은 아래와 같다.

1. Git Repository URL을 설정한다. ![img_3.png](https://github.com/jewoodev/blog_img/blob/main/CI_and_CD/PollSCM_%EC%84%A4%EC%A0%95%EC%9C%BC%EB%A1%9C_%EC%A7%80%EC%86%8D%EC%A0%81%EC%9D%B8_%ED%8C%8C%EC%9D%BC_%EC%97%85%EB%8D%B0%EC%9D%B4%ED%8A%B8/Git_URL_%EC%84%A4%EC%A0%95%ED%95%98%EB%8A%94_%ED%99%94%EB%A9%B4.png?raw=true)
2. Build Triggers에서 Poll SCM을 선택한다.
   1. Schedule에 크론을 설정한다. 예를 들어, `H/5 * * * *`은 5분마다 빌드를 한다는 뜻이다.
3. Apply > Save 순으로 진행해서 저장한다.

이렇게 설정하면 커밋이 있을 때마다 배포가 진행된다. 그런데 실제 운영에서는 테스트 코드가 failed되었을 때는 배포가 진행되지 않도록 해야 한다. 그래서 추가적으로 어느 선까지는 사용자가 개입을 하고 어느 선까지는 자동화를 하고, 이런 부분들에 대한 설정을 해줘야 할 필요가 있다.