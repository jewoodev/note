## 1. 맞춤법 검사(Spell)로 인한 빨간줄 끄기

LazyVim은 마크다운(`.md`)이나 텍스트 파일 등에서 기본적으로 맞춤법 검사(`spell = true`)를 활성화한다. 이를 전역적으로 해제하려면 `lua/config/autocmds.lua` 에 아래 설정을 추가하면 된다.

```lua
-- LazyVim의 기본 텍스트 파일 맞춤법 자동 활성화 기능을 제거
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
```

그게 아니라 현재 버퍼에서 일시적으로 끄려고 한다면 명령어 창에 입력한다.

```lua
:set nospell
```

## 2. LSP / 린터(Linter) 진단 에러로 인한 빨간줄 끄기

코드 내에 한글을 주석이나 문자열로 쓸 때, 언어 서버(LSP)나 린터가 이를 문법 오류로 인식해 빨간 밑줄(`underline`)을 표시하는 경우도 있다.

이 경우로 생기는 빨간줄을 감추기만 하려면 `lua/config/options.lua` 또는 플루긴 설정에 아래 코드를 추가한다.

```lua
vim.diagnostic.config({
  underline = false, -- 빨간 밑줄 제거
})
```

진단 기능 자체를 끄고 싶다면 LazyVim 단축키인 `<leader>ud`를 눌러 **Diagnostics를 토글**할 수 있다.

