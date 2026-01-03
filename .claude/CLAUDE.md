# Blacksmith Workflow

## Directory Structure

```
.claude/              # 로컬 테스트용 (심볼릭 링크)
  commands/           # → plugins/*/commands/
  skills/             # → plugins/*/skills/
plugins/              # 배포용 소스 코드 (원본)
.claude-plugin/       # 마켓플레이스 메타데이터
```

## Symlink Rules (CRITICAL)

`.claude/` 디렉토리는 테스트용이며, `plugins/`의 심볼릭 링크입니다.

### 절대 금지
- `.claude/skills/` 또는 `.claude/commands/` 내 파일을 직접 생성/수정하지 마세요
- 심볼릭 링크를 일반 파일로 대체하지 마세요

### 올바른 수정 방법
1. **항상 `plugins/` 디렉토리의 원본을 수정**하세요
2. 심볼릭 링크가 자동으로 변경사항을 반영합니다

### 새 스킬/커맨드 추가 시
1. `plugins/<plugin>/skills/` 또는 `plugins/<plugin>/commands/`에 생성
2. `.claude/`에 심볼릭 링크 생성:
   ```bash
   ln -s ../../plugins/<plugin>/skills/<name> .claude/skills/<name>
   ln -s ../../plugins/<plugin>/commands/<name>.md .claude/commands/<name>.md
   ```

### 현재 심볼릭 링크 구조
```
.claude/commands/do.md      → plugins/siat/commands/do.md
.claude/skills/clarify      → plugins/clarify/skills/clarify
.claude/skills/forge        → plugins/forge/skills/forge
.claude/skills/format-response → plugins/format-response/skills/format-response
.claude/skills/look-back    → plugins/look-back/skills/look-back
.claude/skills/siat         → plugins/siat/skills/siat
.claude/skills/split        → plugins/split/skills/split
```

---

## Deployment Rules

### Version Bumping (CRITICAL)

When deploying plugin changes, you MUST update versions in BOTH files:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json` - the plugin's own version
2. `.claude-plugin/marketplace.json` - the marketplace registry version

**Checklist before any commit that modifies a plugin:**
- [ ] Update `plugin.json` version for the edited plugin(s)
- [ ] Update corresponding version(s) in `marketplace.json` to match

Both versions must be in sync. Never commit plugin changes without bumping both.
