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
| `siat-migrate.sh` | v5.x → v6.x 마이그레이션 |

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

### 마이그레이션 (v5.x → v6.x)

```bash
# 미리보기
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-migrate.sh .claude/siat/config.yml --dry-run

# 실행
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-migrate.sh .claude/siat/config.yml
```

마이그레이션 내용:
- 기존 `.claude/siat/scripts/` 폴더 삭제 (스킬에 포함됨)
- 스텝 단위 → 피쳐 단위 문서 구조 변환

---

## 파일 수정 규칙

`.claude/siat/` 하위 파일을 수정할 때 반드시 이 규칙을 따르세요.

### config.yml

```yaml
workflow:
  name: "워크플로우 이름"
  description: "설명"

steps:
  - step1
  - step2

output:
  path: ".claude/siat/specs"  # 결과물 저장 경로

execution:
  mode: "manual"  # "manual" | "auto"

hooks:
  pre-step: []
  post-step: []
  post-workflow: []

remote:
  slack_webhook_url: ""  # Slack Incoming Webhook URL
```

**허용되는 키만 사용하세요.** 임의의 키 추가 금지.

### 스텝 디렉토리 구조

```
.claude/siat/steps/{step-name}/
├── instruction.md   # 스텝 실행 지침
└── spec.md          # 결과물 템플릿
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
    ├── clarify.md
    ├── prd.md
    ├── design.md
    └── implement.md
```

**절대 스텝 단위로 저장하지 않음:**
```
# 잘못된 구조 - 사용 금지
.claude/siat/specs/
├── clarify/
│   └── login-page.md
├── prd/
│   └── login-page.md
```

### Spec Frontmatter 형식

```yaml
---
id: {task_id}                    # 태스크 식별자
steps: [current, next1, next2]   # 남은 스텝들
parent: {step/task_id} | null    # 이전 문서
children: [{step/task_id}, ...]  # 다음 문서들

# 선택적
open_questions:
  - question: "질문"
    context: "왜 필요한지"
    resolved: false
    answer: null
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
2. **AI 스텝 실행** → 본문 작성, children/open_questions 결정
3. **Post-step 스크립트 실행** → 검증, 다음 스텝 계산
4. **Hooks 실행** → 설정된 pre/post hooks

### AI가 하는 일

- instruction.md 따라 분석/작업
- spec.md 템플릿의 본문 작성
- children 배열 결정 (fork 여부)
- open_questions 작성

### AI가 하지 않는 일 (스크립트 처리)

- ❌ task_id 생성 (slugify)
- ❌ 디렉토리 생성
- ❌ 경로 계산
- ❌ parent 추적
- ❌ steps 배열 계산

---

## 제공 에이전트

| 에이전트 | 역할 |
|----------|------|
| `siat-navigator` | 다음 스텝 찾기 |
| `siat-reporter` | 결과 리포트 생성 |
| `siat-step-executor` | 스텝 실행 (auto mode) |
| `siat-gh-issue-creator` | GitHub 이슈 생성 |
| `siat-gh-pr-creator` | GitHub PR 생성 |
