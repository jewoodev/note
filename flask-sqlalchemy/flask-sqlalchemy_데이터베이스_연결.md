# flask-sqlalchemy 데이터베이스 연결

flask 루트 디렉토리에 위치한 app.py 파일이 각종 설정 정보들이 적용되는 곳이다.  

따라서 데이터베이스에 flask 서버가 접속하는데 필요한 정보들도 여기에서 적용해주면 된다. 

예를 들어서 다음과 같이 코드를 작성해서 데이터베이스 설정을 해보자.

```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///db.sqlite3"
app.config["SQLALCHEMY_TRACk_MODIFI

```

# 참고자료
- [유튜브 영상 링크](https://www.youtube.com/watch?v=SYG1jQYIxfQ&t=118s)