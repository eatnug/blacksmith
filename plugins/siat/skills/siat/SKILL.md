---
name: siat
description: |
  Siat 워크플로우 관리자.
  .claude/siat/ 폴더가 있는 프로젝트에서 워크플로우를 실행하고,
  siat 관련 파일을 수정할 때 규칙을 따릅니다.
---

# Siat

## 자동화 스크립트

이 스킬의 `scripts/` 폴더에 자동화 스크립트가 있습니다:

| 스크립트 | 용도 |
|----------|------|
| `siat-pre.sh` | 스텝 시작 전 메타데이터 자동 생성 |
| `siat-post.sh` | 스텝 완료 후 검증 및 다음 스텝 계산 |
| `siat-gh-issue.sh` | spec에서 GitHub 이슈 생성 |
| `siat-gh-pr.sh` | implement에서 GitHub PR 생성 |
| `siat-migrate.sh` | v6.x → v7.x 마이그레이션 |

### 사용 방법

스텝 시작 시:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-pre.sh .claude/siat/config.yml "{step}" "{request}"
```

스텝 완료 시:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-post.sh "{spec_path}" .claude/siat/config.yml
```

스크립트는 JSON을 출력하며, AI가 직접 계산하지 않아도 되는 메타데이터를 제공합니다.

### 마이그레이션

```bash
# 미리보기
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-migrate.sh .claude/siat/config.yml --dry-run

# 실행
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-migrate.sh .claude/siat/config.yml
```

스크립트가 config 형식을 자동 감지하여 변환:
- hooks.pre-step → hooks.pre_step (underscore)
- execution.mode → gateway (local/remote)
- 기존 문서의 frontmatter는 변경 안 함 (호환됨)

---

## 파일 수정 규칙

`.claude/siat/` 하위 파일을 수정할 때 반드시 이 규칙을 따르세요.

### config.yml (v7.0)

```yaml
# 워크플로우 스텝 정의
steps:
  - specify
  - plan
  - implement
  - review

# 출력 경로
output:
  path: ".claude/siat/specs"

# Gateway: 사용자 상호작용 채널
gateway:
  questions: local    # local or script:xxx.sh
  feedback: local     # local or script:xxx.sh

# Hooks: 워크플로우 확장 포인트
hooks:
  pre_step: []
  on_processed: []
  on_approve: []
  on_reject: []
  on_revise: []
  on_complete: []

# Presets: 자주 쓰는 설정 묶음
presets:
  remote:
    gateway:
      questions: script:gh-poll.sh {spec_path} --type=questions
      feedback: script:gh-poll.sh {spec_path} --type=feedback
    hooks:
      on_processed:
        - script:gh-issue.sh {spec_path}
      on_approve:
        - script:gh-issue-close.sh {spec_path}
```

**허용되는 키만 사용하세요.** 임의의 키 추가 금지.

### 스텝 디렉토리 구조

```
.claude/siat/steps/{step-name}/
├── instruction.md     # 스텝 실행 지침
└── spec_template.md   # 결과물 템플릿
```

### Spec 문서 저장 구조 (CRITICAL)

**피쳐 단위로 저장:**
```
{output.path}/{task_id}/{step}.md
```

예시:
```
.claude/siat/specs/
└── login-page/
    ├── specify.md
    ├── plan.md
    ├── implement.md
    └── review.md
```

**절대 스텝 단위로 저장하지 않음:**
```
# 잘못된 구조 - 사용 금지
.claude/siat/specs/
├── specify/
│   └── login-page.md
├── plan/
│   └── login-page.md
```

### Spec Frontmatter 형식 (v7.0)

```yaml
---
id: "task-id"
step: "specify"
prev: null                      # null or "{task-id}/{prev-step}"
next: "{task-id}/plan"          # null or "{task-id}/{next-step}"
status: "pending_feedback"      # pending_feedback | approved | revised | rejected
open_questions: []
---
```

---

## 훅 시스템

### 훅 타입

| 접두사 | 설명 | 예시 |
|--------|------|------|
| `script:` | bash 스크립트 실행 | `script:${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-issue.sh {spec_path}` |
| `agent:` | 에이전트 호출 | `agent:siat-reporter` |
| `skill:` | 스킬 호출 | `skill:clarify` |

### 변수 치환

훅에서 사용 가능한 변수:
- `{spec_path}` → 현재 spec 파일 경로
- `{task_id}` → 현재 태스크 ID
- `{task_dir}` → 태스크 디렉토리 경로
- `{step}` → 현재 스텝 이름

---

## 워크플로우 실행

### /siat:do [task-id] [request]

1. **Pre-step 스크립트 실행** → 메타데이터 자동 생성
2. **AI 스텝 실행** → 본문 작성, open_questions 결정
3. **Post-step 스크립트 실행** → 검증, 다음 스텝 계산
4. **On Processed Hooks 실행** → GitHub 이슈, Slack 알림 등
5. **User Feedback** → Approve, Revise, Reject
6. **Response Hooks 실행** → on_approve, on_revise, on_reject

### AI가 하는 일

- instruction.md 따라 분석/작업
- spec_template.md 템플릿의 본문 작성
- open_questions 작성

### AI가 하지 않는 일 (스크립트 처리)

- ❌ task_id 생성 (slugify)
- ❌ 디렉토리 생성
- ❌ 경로 계산
- ❌ prev/next 계산

---

## 제공 에이전트

| 에이전트 | 역할 |
|----------|------|
| `siat-navigator` | 다음 스텝 찾기 |
| `siat-reporter` | 결과 리포트 생성 |
| `siat-step-executor` | 스텝 실행 (auto mode) |
| `siat-gh-issue-creator` | GitHub 이슈 생성 |
| `siat-gh-pr-creator` | GitHub PR 생성 |
