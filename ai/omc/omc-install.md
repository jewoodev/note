# oh-my-claudecode (OMC) 설치 기록

Claude Code에 oh-my-claudecode 플러그인을 설치한 과정과 그에 딸린 HUD/CLI/에이전트 팀/MCP 서버까지 함께 구성한 흐름을 정리한다. 재설치·문제 진단 시 그대로 따라갈 수 있도록 실제 입력한 명령과 선택지, 결과 파일 경로를 함께 남긴다.

- 설치 일자: 2026-05-07
- 설치 모드: **글로벌 + preserve** (`~/.claude` 의 기존 `CLAUDE.md` 보존, OMC는 컴패니언 파일로 분리)
- OMC 버전: `4.13.6`

## 0. 사전 상태

- `~/.claude/CLAUDE.md` 가 이미 존재 (개인 글로벌 규칙). OMC 마커는 없음.
- `~/.claude/settings.json` 에 `permissions`, `enabledPlugins`, `extraKnownMarketplaces`, `effortLevel` 등이 이미 설정돼 있는 상태.
- `gh` CLI 인증 완료, `npm` 사용 가능, `bd`/`br` 같은 외부 태스크 도구 없음.

## 1. 플러그인 마켓플레이스 등록 & 설치

Claude Code 슬래시 커맨드로 진행.

```
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/reload-plugins
```

리로드 결과: `2 plugins · 0 skills · 24 agents · 24 hooks · 1 plugin MCP server · 0 plugin LSP servers`. 이 시점에 OMC가 제공하는 에이전트·훅·브리지 MCP가 모두 활성화된다.

## 2. 셋업 마법사 실행

```
/oh-my-claudecode:omc-setup
```

`~/.claude/.omc-config.json` 의 `setupCompleted` 가 비어 있어 **풀 셋업** 분기로 들어감. 이후 4개 phase 가 순차 진행된다.

### Phase 1 — CLAUDE.md 설치 (preserve 모드)

대화형 질의 2개:

| 질문 | 선택 |
|---|---|
| Where should I configure oh-my-claudecode? | **Global (all projects)** |
| Global setup will change your base CLAUDE.md. Which behavior do you want? | **Keep base, use OMC only via `omc`** |

내부적으로 실행된 스크립트:

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/setup-claude-md.sh" global preserve
```

결과:

- 기존 파일 백업: `~/.claude/CLAUDE.md.backup.2026-05-07_203445`
- 컴패니언 설치: `~/.claude/CLAUDE-omc.md` (`<!-- OMC:START --> … <!-- OMC:END -->` 마커 포함)
- 기존 `~/.claude/CLAUDE.md` 끝에 import 블록 자동 삽입:
  ```markdown
  <!-- OMC:IMPORT:START -->
  @CLAUDE-omc.md
  <!-- OMC:IMPORT:END -->
  ```
- `~/.claude/skills/omc-reference/SKILL.md` 동시 설치
- 레거시 훅 정리

> **preserve 모드의 의미**: 평소처럼 `claude` 로 실행하면 본인 글로벌 규칙 + import된 OMC 규칙이 같이 로드된다. (스크립트가 import 블록을 박아주기 때문에 사실상 두 모드가 합쳐진 상태로 동작한다.) `omc` 런처는 컴패니언을 강제 로드한다.

### Phase 2 — HUD · CLI · 기본 실행 모드

#### 2.1 HUD statusline

`hud` 스킬 위임 → 다음 파일들 설치:

- `~/.claude/hud/omc-hud.mjs` (canonical 템플릿 복사, 실행권한 755)
- `~/.claude/hud/lib/config-dir.mjs`

`~/.claude/settings.json` 에 추가:

```json
"statusLine": {
  "type": "command",
  "command": "node ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hud/omc-hud.mjs"
}
```

`node ~/.claude/hud/omc-hud.mjs` 직접 실행 시 `[OMC] HUD v4.13.6 | preset: focused` 출력으로 동작 검증.

#### 2.2 캐시 / 버전 체크

- 플러그인 캐시: clean
- 설치 버전 = npm 최신 버전 = `4.13.6`

#### 2.3 기본 실행 모드 & OMC CLI

| 질문 | 선택 |
|---|---|
| Default mode for "fast"/"parallel" keywords | **ultrawork (Recommended)** |
| Install OMC CLI globally? | **Yes (Recommended)** |

명령:

```bash
npm install -g oh-my-claude-sisyphus
```

설치 후 `omc --version` → `4.13.6` 확인. PATH 에 `omc` 등록 완료.

#### 2.4 태스크 도구

`bd`(beads)·`br`(beads-rust) 모두 미감지 → 자동으로 **built-in TaskCreate** 사용.

`~/.claude/.omc-config.json` 갱신 결과:

```json
{
  "defaultExecutionMode": "ultrawork",
  "configuredAt": "2026-05-07T11:37:27Z",
  "taskTool": "builtin",
  "taskToolConfig": { "injectInstructions": true, "useMcp": false }
}
```

### Phase 3 — 통합 (MCP + 에이전트 팀)

#### 3.1 에이전트 팀 활성화

| 질문 | 선택 |
|---|---|
| Enable experimental agent teams? | **Yes (Recommended)** |
| Teammate display mode | **Auto (Recommended)** |
| Default team size | **3 agents (Recommended)** |
| Default CLI provider | **claude (Recommended)** |

`~/.claude/settings.json` 에 추가:

```json
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
```

`~/.claude/.omc-config.json` 에 추가:

```json
"team": {
  "ops": {
    "maxAgents": 3,
    "defaultAgentType": "claude",
    "monitorIntervalMs": 30000,
    "shutdownTimeoutMs": 15000
  }
}
```

이번 세션에서 직접 확인된 것은 **(a)** `~/.claude/settings.json` 의 `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 활성화와 **(b)** `~/.claude/.omc-config.json` 의 `team.ops` 저장까지다. 실제 `TeamCreate` / `SendMessage` / `TeamDelete` 도구 노출 여부는 Claude Code 재시작 후 ToolSearch 로 확인이 필요하다.

#### 3.2 MCP 서버 — Context7

| 질문 | 선택 |
|---|---|
| MCP setup type | **Recommended starter setup** |
| Recommended bundle | **Context7 only (Recommended)** |

명령:

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

> **등록 스코프 주의**: `claude mcp add` 의 기본값은 **현재 프로젝트 스코프**다. 이번 설치도 글로벌이 아닌 `/home/jewoo/.claude.json` 의 `projects["/home/jewoo/develp-dir/2026-musinsa-rookie"].mcpServers.context7` 에 기록되었다 (실제 응답: `Added stdio MCP server context7 ... to local config`). Phase 1 의 "글로벌 + preserve" 와는 별개의 범위이며, 다른 레포에서도 쓰려면 그 레포에서 동일 명령을 다시 실행하거나 `claude mcp add --scope user ...` 로 사용자 스코프에 등록해야 한다.

`claude mcp list` 결과 (이번 설치 직후 상태, 이 프로젝트 디렉터리에서 호출):

```
plugin:oh-my-claudecode:t  ✓ Connected   (OMC 브리지 MCP, 플러그인 자동 등록)
pencil                     ✓ Connected
context7                   ✓ Connected   ← 이번에 추가
claude.ai Google Calendar  ! Needs authentication
claude.ai Gmail            ! Needs authentication
claude.ai Google Drive     ! Needs authentication
```

> Exa / Filesystem / GitHub 는 이번 설치에서 건너뜀. 필요해지면 `/oh-my-claudecode:mcp-setup` 재실행 또는 `claude mcp add ...` 직접 호출.

### Phase 4 — 완료 처리

- 2.x 마커(`commands/ralph-loop.md`, `commands/ultrawork.md`) 없음 → fresh install 으로 처리.
- GitHub 스타: **No thanks**.
- `setup-progress.sh complete 4.13.6` 로 마무리. 이후 같은 명령을 재실행하면 "Update CLAUDE.md only" 같은 가벼운 분기로 들어간다.

## 3. 설치 후 최종 상태 요약

생성·수정된 핵심 파일:

| 경로 | 내용 |
|---|---|
| `~/.claude/CLAUDE.md` | 기존 규칙 보존 + 끝에 `@CLAUDE-omc.md` import 블록 |
| `~/.claude/CLAUDE-omc.md` | OMC 본문 (preserve 모드 컴패니언) |
| `~/.claude/CLAUDE.md.backup.2026-05-07_203445` | 설치 직전 백업 |
| `~/.claude/settings.json` | `statusLine`, `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 추가 |
| `~/.claude/.omc-config.json` | `defaultExecutionMode`, `taskTool`, `team.ops`, `setupCompleted`(2026-05-07T20:43:06+09:00), `setupVersion`(4.13.6) |
| `~/.claude/hud/omc-hud.mjs`, `lib/config-dir.mjs` | HUD statusline 스크립트 |
| `~/.claude/skills/omc-reference/SKILL.md` | OMC 레퍼런스 스킬 |
| `/home/jewoo/.claude.json` | 이 프로젝트 항목 아래 `mcpServers.context7` 추가 (프로젝트 스코프 MCP) |

확보된 기능:

- 28+ 에이전트 (executor, planner, architect, debugger, code-reviewer, document-specialist 등)
- 슬래시 스킬: `/oh-my-claudecode:autopilot`, `/oh-my-claudecode:ralph`, `/oh-my-claudecode:ultrawork`, `/oh-my-claudecode:team`, `/oh-my-claudecode:plan`, `/oh-my-claudecode:verify`, `/oh-my-claudecode:debug`, `/oh-my-claudecode:hud` 등
- 매직 키워드: `ralph`, `ralplan`, `ulw`, `plan`, `team`
- 글로벌 CLI: `omc`, `omc hud`, `omc teleport`, `omc team status`
- 실험 기능: 에이전트 팀 env 활성화 + 기본값 저장 (재시작 후 `TeamCreate` / `SendMessage` / `TeamDelete` 노출 여부는 별도 검증 필요)
- MCP 도구: Context7 (라이브러리 문서 조회, **이 프로젝트 스코프 한정**), 기존 pencil + OMC 플러그인 브리지(`plugin:oh-my-claudecode:t`)

## 4. 재현·운영 메모

- **업데이트만 하고 싶을 때**: `/oh-my-claudecode:omc-setup` 재실행 → "Update CLAUDE.md only" 선택. 풀 마법사 다시 안 돌림.
- **글로벌 설정 강제 갱신**: `/oh-my-claudecode:omc-setup --global`
- **현재 프로젝트만 OMC 적용**: `/oh-my-claudecode:omc-setup --local` (이번 세션에서는 사용 안 함)
- **MCP 추가**: `/oh-my-claudecode:mcp-setup` 또는 `claude mcp add <name> -- <command>`. 기본 스코프는 **현재 프로젝트**(`/home/jewoo/.claude.json` 의 해당 project 아래). 모든 레포에서 공유하려면 `claude mcp add --scope user <name> -- <command>` 로 사용자 스코프에 등록.
- **HUD 점검·재설치**: `/oh-my-claudecode:hud setup`
- **상태 점검**: `/oh-my-claudecode:omc-doctor`
- **Statusline / 에이전트 팀 env 적용**: Claude Code 재시작 필요.

## 5. 이번 세션에서 보류한 것

- Exa Web Search MCP (API 키 필요)
- Filesystem MCP
- GitHub MCP
- 프로젝트 로컬 OMC 설정 (`./.claude/CLAUDE.md`) — 본 레포에는 이미 자체 `CLAUDE.md` 가 존재하므로 추가 설치하지 않음.
- 깃허브 저장소 스타.

필요해지면 위 4. 재현·운영 메모의 명령으로 추가하면 된다.
