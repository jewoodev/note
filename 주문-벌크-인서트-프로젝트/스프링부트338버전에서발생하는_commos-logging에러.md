build.gradle에 
```groovy
configurations {
    all {
        exclude group: 'commons-logging', module: 'commons-logging'
    }
}
```

를 추가해 해당 라이브러리를 제거한다는 것을 명시적으로 선언하면 제거된다.