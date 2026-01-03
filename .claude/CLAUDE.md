# Blacksmith Plugins

## 이 레포의 목적

이 레포는 **독립적인 Claude Code 플러그인들을 개발하는 공간**입니다.

- 각 플러그인(clarify, forge, split, siat, look-back, format-response)은 **독립적으로 동작**
- 플러그인 간 통합보다 **각각의 완성도**에 집중
- siat가 메인이 아님 - 다른 플러그인들과 동등한 하나의 플러그인일 뿐

---

## Directory Structure

```
.claude/
  commands/           # 심볼릭 링크 → plugins/*/commands/
  skills/             # 심볼릭 링크 → plugins/*/skills/
  siat/               # 이 레포의 siat 워크플로우 설정 (복사본, 커스터마이징됨)
    config.yml
    steps/
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

---

## Siat Plugin: Template vs Project Config

siat 플러그인은 **템플릿**과 **프로젝트 설정**이 분리되어 있습니다.

### 구조

| 경로 | 역할 | 수정 시점 |
|------|------|----------|
| `plugins/siat/steps/` | 기본 템플릿 (hooks 없음) | 새 프로젝트 init 시 복사됨 |
| `plugins/siat/config.yml` | 기본 config 템플릿 | 새 프로젝트 init 시 복사됨 |
| `plugins/siat/agents/` | 공유 에이전트 (gh-issue-creator 등) | 모든 프로젝트에서 사용 |
| `.claude/siat/` | **이 레포**의 워크플로우 설정 | 이 레포에서만 사용 |

### 작업별 수정 위치

| 작업 | 수정 위치 |
|------|----------|
| 공유 에이전트 추가/수정 (gh-*, reporter 등) | `plugins/siat/agents/` |
| 기본 템플릿 수정 (새 프로젝트용) | `plugins/siat/steps/`, `config.yml` |
| **이 레포** 워크플로우 커스터마이징 | `.claude/siat/` |

### 템플릿 변경 시 주의 (IMPORTANT)

`plugins/siat/steps/` 템플릿을 수정해도 `.claude/siat/steps/`에 **자동 반영되지 않습니다**.

필요 시 수동으로 반영:
1. `plugins/siat/steps/`의 변경사항 확인
2. `.claude/siat/steps/`에 필요한 부분만 반영 (커스터마이징 유지)

### 이 레포의 커스터마이징

`.claude/siat/steps/`에는 GitHub 연동 hooks가 추가되어 있음:
- `spec`, `design`: `agent:siat-gh-issue-creator` (post-hook)
- `implement`: `agent:siat-gh-pr-creator` (post-hook)
