---
description: Execute Siat workflow - document-driven step execution
argument-hint: "[task-id] [request]"
---

# Siat Workflow Orchestrator

문서 기반 워크플로우 실행기. 스크립트로 메타데이터를 자동 생성하고, AI는 본문 작성에만 집중합니다.

---

## Scripts 위치

siat 스킬의 `scripts/` 폴더에 있음:
- `siat-pre.sh` - 스텝 시작 전 메타데이터 생성
- `siat-post.sh` - 스텝 완료 후 검증 및 다음 스텝 계산
- `siat-gh-issue.sh` - GitHub 이슈 생성
- `siat-gh-pr.sh` - GitHub PR 생성

**경로 참조:** 이 스킬 디렉토리의 `./scripts/` 폴더를 사용

---

## Execution Flow

### 1. Pre-Step: 메타데이터 자동 생성

**스크립트 실행:**
```bash
./scripts/siat-pre.sh .claude/siat/config.yml "{step}" "{$ARGUMENTS}"
```

**스크립트 출력 (JSON):**
```json
{
  "task_id": "login-page",
  "step": "clarify",
  "spec_path": ".claude/siat/specs/login-page/clarify.md",
  "task_dir": ".claude/siat/specs/login-page",
  "parent": null,
  "is_new_task": true,
  "steps": ["clarify", "prd", "design", "implement", "verify"],
  "frontmatter": {
    "id": "login-page",
    "steps": ["clarify", "prd", "design", "implement", "verify"],
    "parent": null,
    "children": []
  }
}
```

**이 정보를 변수로 저장하고 사용:**
- `task_id`, `step`, `spec_path` 등은 스크립트가 결정
- AI가 직접 계산하지 않음

---

### 2. Read Step Definition

`.claude/siat/steps/{step}/instruction.md` 읽기.
`.claude/siat/steps/{step}/spec.md` 템플릿 읽기.

---

### 3. Pre-Step Hooks

`config.hooks.pre-step` + `instruction.md frontmatter hooks.pre`가 있으면 실행.

---

### 4. Execute Step (AI 작업)

**AI가 하는 일:**
1. instruction.md 따라 분석/작업 수행
2. spec.md 템플릿의 본문 섹션 작성
3. `children` 배열 결정 (fork 여부)
4. `open_questions` 배열 작성 (미해결 질문)

**AI가 하지 않는 일 (스크립트가 처리):**
- ❌ task_id 생성
- ❌ 디렉토리 생성
- ❌ 경로 계산
- ❌ parent 추적
- ❌ steps 배열 계산

---

### 5. Generate Spec Document

스크립트가 제공한 frontmatter 골격 + AI가 작성한 본문 + children 결합:

```yaml
---
id: {from script: frontmatter.id}
steps: {from script: frontmatter.steps}
parent: {from script: frontmatter.parent}
children: {AI decides: [] or ["login-page/design"] or ["login-ui/design", "login-api/design"]}
open_questions: {AI writes if any}
---

{AI writes body following spec.md template}
```

**저장 위치:** `{spec_path}` (스크립트가 제공한 경로)

---

### 6. Post-Step: 검증 및 다음 스텝 계산

**스크립트 실행:**
```bash
./scripts/siat-post.sh "{spec_path}" .claude/siat/config.yml
```

**스크립트 출력 (JSON):**
```json
{
  "valid": true,
  "errors": [],
  "warnings": ["1 unresolved questions"],
  "spec": {
    "task_id": "login-page",
    "step": "clarify",
    "children": ["login-page/prd"]
  },
  "next": {
    "step": "prd",
    "task_id": "login-page",
    "is_complete": false,
    "is_fork": false
  },
  "unresolved_questions": [
    {"question": "인증 방식?", "resolved": false, "context": "JWT vs Session"}
  ]
}
```

**검증 실패 시:**
- `valid: false`면 errors 확인
- spec 문서 수정 후 다시 siat-post.sh 실행

---

### 7. Handle Open Questions

`unresolved_questions`가 있으면:

1. `AskUserQuestion`으로 각 질문 처리
2. 답변 받으면 spec 문서 업데이트:
   - frontmatter: `resolved: true`, `answer: "..."` 추가
   - 본문: 답변 내용 반영

---

### 8. Post-Step Hooks

`config.hooks.post-step` + `instruction.md frontmatter hooks.post`가 있으면 실행.

**GitHub 통합 hook 예시:**
```yaml
hooks:
  post-step:
    - script:./scripts/siat-gh-issue.sh {spec_path}
```

---

### 9. Report & Continue

**Manual mode:**
```
✅ {step} 완료: {task_id}

📄 생성: {spec_path}

📍 다음: {next.step} (또는 "완료")

▶️ 계속: /siat:do {task_id}
```

**Auto mode:**
- `next.is_complete`가 true일 때까지 자동 진행
- fork 시 병렬 처리

---

## Script Hook Types

hooks에서 사용 가능한 prefix:

| Prefix | 설명 | 예시 |
|--------|------|------|
| `script:` | bash 스크립트 실행 | `script:./scripts/siat-gh-issue.sh {spec_path}` |
| `agent:` | Task tool로 에이전트 실행 | `agent:siat-reporter` |
| `skill:` | Skill tool로 스킬 실행 | `skill:look-back` |
| (none) | 기본값: agent | `siat-reporter` |

**변수 치환:**
- `{spec_path}` → 현재 spec 파일 경로
- `{task_id}` → 현재 태스크 ID
- `{task_dir}` → 태스크 디렉토리 경로
- `{step}` → 현재 스텝 이름

---

## Examples

### 새 태스크 시작

```
> /siat:do 로그인 페이지 만들어줘

# 1. siat-pre.sh 실행
$ ./scripts/siat-pre.sh .claude/siat/config.yml "clarify" "로그인 페이지 만들어줘"
{
  "task_id": "로그인-페이지-만들어줘",
  "step": "clarify",
  "spec_path": ".claude/siat/specs/로그인-페이지-만들어줘/clarify.md",
  ...
}

# 2. AI가 clarify 실행, spec 작성

# 3. siat-post.sh 실행
$ ./scripts/siat-post.sh ".claude/siat/specs/로그인-페이지-만들어줘/clarify.md"
{
  "valid": true,
  "next": {"step": "prd", "task_id": "로그인-페이지-만들어줘"}
}

✅ clarify 완료

📄 생성: .claude/siat/specs/로그인-페이지-만들어줘/clarify.md

📍 다음: prd

▶️ 계속: /siat:do 로그인-페이지-만들어줘
```

### Fork 발생

```
> /siat:do login-system

# siat-post.sh 출력
{
  "next": {
    "is_fork": true,
    "fork_children": ["login-ui/design", "login-api/design"]
  }
}

🔀 Fork 감지: 2개 서브태스크
   - login-ui: UI 구현
   - login-api: API 구현

▶️ 계속:
   /siat:do login-ui
   /siat:do login-api
```

---

## Critical Rules

1. **스크립트 먼저** - 모든 메타데이터는 siat-pre.sh가 생성
2. **AI는 본문만** - AI는 spec 본문과 children/open_questions만 작성
3. **검증 필수** - siat-post.sh로 반드시 검증
4. **경로 일관성** - 항상 `{output.path}/{task_id}/{step}.md` 구조
