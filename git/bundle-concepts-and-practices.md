# Git bundle의 개념과 안전한 활용

Git bundle은 선택한 Git 참조와 객체를 파일 하나로 보관하는 형식이다. 브랜치를 정리하면서 실험 이력을 남기거나, 네트워크 연결 없이 다른 저장소로 작업을 전달할 때 유용하다.

## 1. 무엇을 보관하는가

브랜치는 특정 커밋을 가리키는 이름인 **참조(ref)**다. 커밋은 부모 커밋과 파일 트리로 연결된다. Bundle은 지정한 참조와 복원에 필요한 객체를 묶는다. 파일을 받아 `clone`하거나 기존 저장소에서 `fetch`할 수 있지만, bundle에 직접 `push`할 수는 없다.

| 선택 | 의미 |
| --- | --- |
| `feature/search` | 해당 브랜치에서 도달하는 이력 보관 |
| `--all` | 로컬 저장소의 모든 참조를 대상으로 보관 |
| `backup-base..main` | 기준 이후 변경만 보관하는 증분 방식 |

증분 bundle은 대상 저장소에 선행 커밋이 있어야 한다. 브랜치 정리용 독립 백업에는 제외 범위 없는 방식을 권장한다. `--all`도 미커밋 파일, 인덱스 상태, 저장소 설정, hooks, reflog 전체를 보존하는 디렉터리 백업은 아니다. stash 전체 복원도 이에 의존하지 않는다. [Git bundle 공식 문서](https://git-scm.com/docs/git-bundle)

## 2. 목적에 맞는 수단 선택

| 목적 | 권장 수단 |
| --- | --- |
| 실험 브랜치를 삭제하면서 이력 보존 | 검증한 bundle |
| 팀과 계속 협업 | 접근 권한이 있는 원격 브랜치 |
| 특정 버전의 파일만 배포 | `git archive` |
| 작업 디렉터리·로컬 설정까지 보존 | 별도 파일 백업과 Git 이력 백업 병행 |

`git archive`는 지정한 트리의 파일을 아카이브로 만든다. 커밋 이력을 이어서 개발할 목적이면 bundle을 선택한다. [Git archive 공식 문서](https://git-scm.com/docs/git-archive)

## 3. 브랜치 삭제 전 권장 절차

다음 예시는 `feature/search`를 정리하는 상황이다. 경로·브랜치명은 실제 대상에 맞게 바꾼다. `/secure-backups`는 쓰기 권한과 접근 통제가 준비된 장기 보관 위치를 뜻하는 예시다.

```bash
git status --short
git worktree list
git rev-parse feature/search
git bundle create /secure-backups/search-2026-10-05.bundle feature/search
git bundle list-heads /secure-backups/search-2026-10-05.bundle
git bundle verify /secure-backups/search-2026-10-05.bundle
```

`list-heads`로 대상 이름과 커밋을 확인한다. `verify`는 bundle 형식과 현재 저장소에서 필요한 선행 이력을 확인한다. 성공했다고 백업 범위가 의도와 같은지까지 보장하지는 않는다. [Git bundle의 검증 명령](https://git-scm.com/docs/git-bundle#Documentation/git-bundle.txt-verify)

실무에서는 다음 순서를 권장한다.

1. 미커밋 변경을 확인한다. 보존할 코드는 비밀정보가 없는지 검토한 뒤 명시한 파일만 WIP 커밋하거나 별도로 백업한다.
2. 보관할 브랜치와 끝 커밋을 기록하고 bundle을 만든다.
3. 빈 위치에 복원해 원래 끝 커밋과 일치하는지 확인한다.
4. 장기 보관 위치의 사본까지 확인한 뒤 브랜치를 삭제한다.

브랜치를 삭제할 때에는 다른 worktree에서 사용 중인지도 확인한다. Squash merge는 원래 커밋들을 그대로 조상으로 포함하지 않을 수 있으므로, 단순히 `git branch --merged` 결과만으로 판단하지 않는다. PR의 실제 머지 여부와 최종 변경 내용을 함께 검토한다.

## 4. 복원과 검증

### 별도 저장소에 복원

```bash
git clone --branch feature/search \
  /secure-backups/search-2026-10-05.bundle \
  /private/tmp/git/search-restore-check
git -C /private/tmp/git/search-restore-check rev-parse HEAD
git -C /private/tmp/git/search-restore-check fsck --full
```

대상 디렉터리는 새 경로를 사용한다. `--branch`는 복원 후 선택할 브랜치를 명시한다. 복원된 저장소의 `origin`은 bundle 파일을 가리키므로, 실제 협업 저장소에 연결하려면 원격 URL을 별도로 설정해야 한다. [Git clone 공식 문서](https://git-scm.com/docs/git-clone)

`fsck --full`은 복원된 객체의 유효성과 연결 관계를 검사한다. 이는 파일 이력이 복원됐다는 검증이며, 프로그램의 빌드 성공이나 외부 의존성 확보를 대신하지 않는다. [Git fsck 공식 문서](https://git-scm.com/docs/git-fsck)

### 기존 저장소에 새 이름으로 가져오기

```bash
git fetch /secure-backups/search-2026-10-05.bundle \
  refs/heads/feature/search:refs/heads/recovered/search
git log --oneline recovered/search -5
```

콜론 왼쪽은 bundle 안의 참조, 오른쪽은 만들 로컬 참조다. 기존 작업을 덮어쓰지 않도록 새 이름을 사용하고, 확인 후 필요한 커밋을 선택한다. [Git bundle의 참조 매핑 예시](https://git-scm.com/docs/git-bundle#_examples)

## 5. 증분 백업의 사용 기준

```bash
git bundle create /secure-backups/main-increment.bundle backup-base..main
```

`backup-base`는 이전에 백업한 기준 커밋을 가리키는 태그라는 가정이다. 증분은 작은 파일로 전달할 수 있지만 기준 백업을 잃으면 복원이 막힐 수 있다. 주기적인 전체 백업을 유지하고, 기준 커밋·적용 순서·필요 파일을 함께 기록한다. 단발성 WIP 보존이라면 관리가 단순한 독립 bundle을 우선한다. [Git bundle의 선행 객체 설명](https://git-scm.com/docs/git-bundle#_object_prerequisites)

## 6. 보관·공유 베스트 프랙티스

다음은 이 문서에서 권장하는 운영 기준이다.

- **임시 경로를 장기 백업으로 취급하지 않는다.** `/tmp`와 `/private/tmp`는 검증·임시 전달용으로 사용하고, 보존이 필요한 파일은 접근 통제된 저장소로 복사한다.
- **파일명과 설명서를 함께 관리한다.** 저장소명, 작성일, 보관 이유, 참조 이름, 전체 커밋 ID, 전체·증분 여부, 복원 명령을 기록한다.
- **이력 전체의 공개 범위를 검토한다.** 현재 파일에서 지운 정보도 과거 커밋에 남아 있을 수 있다. Bundle을 공유하는 행위는 포함된 과거 소스도 공유하는 행위로 취급한다.
- **암호화와 접근 제어를 별도로 적용한다.** 압축 파일이라는 이유로 내용을 보호한다고 생각하지 않는다. 조직의 승인된 보관·전송 수단을 사용한다.
- **전송 후 파일 해시와 복원 결과를 확인한다.** macOS에서는 `shasum -a 256 파일.bundle`로 체크섬을 기록할 수 있다. 같은 경로에 둔 체크섬만으로 발신자 신뢰까지 증명되지는 않는다.
- **외부 자산의 복원 계획을 분리한다.** Git LFS 실제 데이터, submodule 저장소, 런타임 Secret·DB·빌드 의존성은 bundle 하나만으로 복구된다고 가정하지 않는다.
- **실행 중인 저장소 폴더를 동기화하는 방식에 의존하지 않는다.** Git은 저장소 전체에 대한 동기화 도구의 원자성을 보장하지 않는다. 이력 전달은 Git 명령으로 수행하고 만들어진 백업 파일을 보관한다. [Git FAQ의 저장소 전송 안내](https://git-scm.com/docs/gitfaq#_transfers)

## 7. 이번 프로젝트에서의 사용 사례

2026-10-05 브랜치 정리에서는 이전 조건 추출 실험의 WIP를 보존했다. 최종 실시간 조회 기능은 main에 반영됐지만 WIP에는 별도 개발 기록도 있어, 브랜치 삭제와 이력 폐기를 분리했다.

| 항목 | 값 |
| --- | --- |
| 보존 브랜치 | `fix/match-structured-waiting-vehicle-conditions` |
| 끝 커밋 | `806445f6b47715d6ddf177ea0c3af439b420143f` |
| 임시 bundle | `/private/tmp/git/waiting-conditions-wip-806445f.bundle` |
| 생성 범위 | 해당 브랜치, 이력 제외 조건 없음 |

기존 프로젝트에서 다른 이름으로 복원하려면 다음 명령을 사용한다.

```bash
git fetch /private/tmp/git/waiting-conditions-wip-806445f.bundle \
  refs/heads/fix/match-structured-waiting-vehicle-conditions:refs/heads/recovered/waiting-conditions
```

이 파일은 임시 보관본이다. 문서 작성 자체가 장기 보관 위치로 이전했다는 뜻은 아니다. 현재 미커밋 `.gitignore` 변경도 이 WIP bundle의 보존 대상이 아니다.

문서 작성 시 별도 디렉터리에 `clone --branch`로 복원한 뒤 `HEAD`가 위 커밋과 일치하고 `git fsck --full`이 성공하는 것을 확인했다. 검증 로그는 `/private/tmp/logs/waiting-bundle-documentation-restore.log`에 남겼다.
