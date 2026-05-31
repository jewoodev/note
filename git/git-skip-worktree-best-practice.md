# Git: 트래킹된 파일을 로컬에서만 다르게 유지하기

## 유스케이스

OSS fork에서 작업할 때 upstream에 트래킹되는 환경 설정 파일(`.sdkmanrc`, `.envrc`, 일부 `.editorconfig` 등)을 **로컬에서만 다르게 유지**하고 싶은 경우.

예: upstream의 `.sdkmanrc`는 Java 17을 가리키는데 로컬에선 Java 21을 쓰고 싶음. 파일을 삭제하거나 `.gitignore`에 넣을 수는 없다 (이미 tracked 상태).

## 명령

```bash
git update-index --skip-worktree <file>
```

지금 working tree의 변경 내용이 그대로 로컬 버전으로 고정되고, `git status`에서 더 이상 안 보인다.

## `--skip-worktree` vs `--assume-unchanged`

| | `--skip-worktree` | `--assume-unchanged` |
|---|---|---|
| 의미 | "이 파일은 **내가 로컬에서 관리한다**" | "이 파일은 변하지 않는다고 가정해 (성능 최적화)" |
| 사용자 수정 의도 | 의도된 로컬 수정 | 변경 안 한다고 약속하는 것 |
| upstream에서 변경 시 | merge로 처리 시도, 안전 | 동작 미정·덮어쓰기 위험 |

**환경 설정 파일을 로컬에서만 다르게 쓰려는 의도에는 `--skip-worktree`가 정확한 도구.** `--assume-unchanged`는 성능 목적이라 의도가 다르고 위험.

## 되돌리기

```bash
git update-index --no-skip-worktree <file>
```

## 상태 확인

```bash
git ls-files -v | grep '^S'
```

소문자 `s` = assume-unchanged, 대문자 `S` = skip-worktree.

## 주의사항

1. **`.git/info`에 저장됨** → 새로 clone 받으면 다시 설정 필요. 메인 머신·서브 머신 모두 각각 설정.
2. **upstream에서 같은 파일이 바뀌면 pull 시 충돌 가능**. 그때만 일시 해제(`--no-skip-worktree`) → pull → 자기 버전으로 다시 수정 → 다시 `--skip-worktree`.
3. **로컬 변경을 진짜 upstream에 반영하고 싶어지면** 일시 해제 후 정상 커밋, 다시 켜기.
