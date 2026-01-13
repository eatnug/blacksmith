---
description: Execute Siat workflow - document-driven step execution
argument-hint: "[--remote] [task-id] [request]"
---

# Siat Workflow Orchestrator

문서 기반 워크플로우 실행기. 스크립트로 메타데이터를 자동 생성하고, AI는 본문 작성에만 집중합니다.

**워크플로우**: specify → plan → implement → review (linear)

---

## Flags

### `--remote` (리모트 모드)

GitHub Issue/PR 기반 비동기 승인 워크플로우 활성화:

```
/siat:do --remote 로그인 페이지 만들어줘
```

**동작:**
1. `siat-pre.sh`가 플래그를 파싱하고 `presets.remote` 설정 병합
2. 스크립트 출력의 `gateway`, `hooks` 설정을 그대로 사용
3. AI는 환경변수 설정이나 플래그 파싱 불필요

**필수 설정 (Slack 알림 사용 시):**
```bash
export SIAT_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

---

## Scripts 위치

siat 스킬의 `scripts/` 폴더:
- `siat-pre.sh` - 스텝 시작 전 메타데이터 생성
- `siat-post.sh` - 스텝 완료 후 검증 및 다음 스텝 계산
- `siat-gh-issue.sh` - GitHub 이슈 생성
- `siat-gh-pr.sh` - GitHub PR 생성

**경로 참조:** `${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/` 사용

**스크립트 실행 실패 시 (CRITICAL):**
- 스크립트가 없거나 실행 실패해도 **문서는 반드시 생성해야 함**
- 메타데이터를 직접 계산하여 진행
- 스크립트 없이도 워크플로우의 핵심(문서 생성)은 수행

---

## Config Format (v7.0)

```yaml
steps:
  - specify
  - plan
  - implement
  - review

output:
  path: ".claude/siat/specs"

gateway:
  questions: local              # local or script:xxx.sh
  feedback: local               # local or script:xxx.sh

hooks:
  pre_step: []
  on_processed: []
  on_approve: []
  on_reject: []
  on_revise: []
  on_complete: []

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

---

## Frontmatter Format (v7.0)

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

## Execution Flow

### 1. Pre-Step: 메타데이터 및 설정 자동 생성

**스크립트 실행 (플래그 포함하여 전달):**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-pre.sh .claude/siat/config.yml "{step}" "{$ARGUMENTS}"
```

**스크립트 출력 (JSON) - v7.1:**
```json
{
  "task_id": "login-page",
  "step": "specify",
  "spec_path": ".claude/siat/specs/login-page/specify.md",
  "task_dir": ".claude/siat/specs/login-page",
  "prev": null,
  "next": "login-page/plan",
  "is_new_task": true,
  "remote_mode": true,
  "steps": ["specify", "plan", "implement", "review"],
  "gateway": {
    "mode": "remote",
    "questions": "script:gh-poll.sh {spec_path} --type=questions",
    "feedback": "script:gh-poll.sh {spec_path} --type=feedback"
  },
  "hooks": {
    "on_processed": ["script:gh-issue.sh {spec_path}"],
    "on_approve": ["script:gh-issue-close.sh {spec_path}"]
  },
  "frontmatter": {
    "id": "login-page",
    "step": "specify",
    "prev": null,
    "next": "login-page/plan",
    "status": "pending_feedback",
    "open_questions": []
  }
}
```

**핵심: 스크립트가 모든 것을 결정**
- `--remote`/`--local` 플래그 파싱
- `presets.remote` 병합
- `gateway`, `hooks` 설정 제공
- AI는 스크립트 출력을 그대로 사용

---

### 2. Read Step Definition

`.claude/siat/steps/{step}/instruction.md` 읽기.
`.claude/siat/steps/{step}/spec_template.md` 템플릿 읽기.

---

### 3. Pre-Step Hooks

`config.hooks.pre_step`이 있으면 순차 실행.

---

### 4. Execute Step (AI 작업)

**AI가 하는 일:**
1. instruction.md 따라 분석/작업 수행
2. spec_template.md 템플릿의 본문 섹션 작성
3. `open_questions` 배열 작성 (미해결 질문)

**AI가 하지 않는 일 (스크립트가 처리):**
- task_id 생성
- 디렉토리 생성
- 경로 계산
- prev/next 계산

---

### 5. Generate Spec Document

스크립트가 제공한 frontmatter 골격 + AI가 작성한 본문 결합:

```yaml
---
id: "{from script}"
step: "{from script}"
prev: "{from script}"
next: "{from script}"
status: "pending_feedback"
open_questions: {AI writes if any}
---

{AI writes body following spec_template.md}
```

**저장 위치:** `{spec_path}` (스크립트가 제공한 경로)

---

### 6. Post-Step: 검증

**스크립트 실행:**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-post.sh "{spec_path}" .claude/siat/config.yml
```

**스크립트 출력 (JSON):**
```json
{
  "valid": true,
  "errors": [],
  "warnings": ["1 unresolved questions"],
  "spec": {
    "task_id": "login-page",
    "step": "specify",
    "status": "pending_feedback"
  },
  "next": {
    "step": "plan",
    "task_id": "login-page",
    "is_complete": false
  },
  "unresolved_questions": [
    {"question": "인증 방식?", "resolved": false, "context": "JWT vs Session"}
  ]
}
```

---

### 7. Handle Open Questions (Gateway: questions)

`unresolved_questions`가 있으면:

**gateway.questions == "local":**
```
AskUserQuestion:
  questions:
    - question: "인증 방식을 어떻게 할까요?"
      header: "인증"
      options:
        - label: "JWT"
          description: "stateless, 토큰 기반"
        - label: "Session"
          description: "서버 상태 유지"
```

**gateway.questions == "script:xxx.sh":**
스크립트 실행하여 답변 polling/수신

답변 받으면:
1. spec 문서 업데이트: `open_questions`에 `resolved: true`, `answer: "..."` 추가
2. 본문 해당 섹션에 답변 내용 반영
3. `siat-post.sh` 다시 실행하여 검증

---

### 8. On Processed Hooks

`config.hooks.on_processed`가 있으면 순차 실행.
(리모트 모드: GitHub 이슈 생성, Slack 알림 등)

---

### 9. User Feedback (Gateway: feedback)

스텝 완료 후 결과 보고 및 유저 승인:

**결과 보고:**
```
✅ {step} 완료: {task_id}

📄 생성: {spec_path}

📍 다음: {next.step} (또는 "🎉 완료")
```

**gateway.feedback == "local":**
```
AskUserQuestion:
  questions:
    - question: "{step} 결과를 확인해주세요. 어떻게 할까요?"
      header: "승인"
      options:
        - label: "Approve & Continue"
          description: "결과를 수락하고 다음 단계로 진행합니다"
        - label: "Approve & Stop"
          description: "결과를 수락하고 여기서 멈춥니다"
        - label: "Revise"
          description: "피드백을 주고 이 단계를 다시 실행합니다"
        - label: "Reject"
          description: "반려하고 워크플로우를 종료합니다"
```

**gateway.feedback == "script:xxx.sh":**
스크립트 실행하여 GitHub 코멘트 등에서 피드백 polling

---

### 10. Handle Feedback Response

**Approve & Continue:**
1. spec의 `status`를 `approved`로 업데이트
2. `config.hooks.on_approve` 실행
3. 다음 스텝으로 진행 (Step 1로 돌아감)

**Approve & Stop:**
1. spec의 `status`를 `approved`로 업데이트
2. `config.hooks.on_approve` 실행
3. 워크플로우 종료

**Revise:**
1. 피드백 입력 받기
2. spec의 `status`를 `revised`로 업데이트
3. `config.hooks.on_revise` 실행
4. Step 4로 돌아가 스텝 재실행

**Reject:**
1. spec의 `status`를 `rejected`로 업데이트
2. `config.hooks.on_reject` 실행
3. 워크플로우 종료

---

### 11. Workflow Complete

마지막 스텝 완료 후:
1. `config.hooks.on_complete` 실행
2. 완료 메시지 출력

```
🎉 워크플로우 완료: {task_id}

📁 생성된 문서:
  - specify.md
  - plan.md
  - implement.md
  - review.md
```

---

## Hook Types

hooks에서 사용 가능한 prefix:

| Prefix | 설명 | 예시 |
|--------|------|------|
| `script:` | bash 스크립트 실행 | `script:gh-issue.sh {spec_path}` |
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

### 새 태스크 시작 (로컬 모드)

```
> /siat:do 로그인 페이지 만들어줘

# 1. siat-pre.sh 실행
$ siat-pre.sh .claude/siat/config.yml "specify" "로그인 페이지 만들어줘"
{
  "task_id": "로그인-페이지-만들어줘",
  "step": "specify",
  "spec_path": ".claude/siat/specs/로그인-페이지-만들어줘/specify.md",
  ...
}

# 2. AI가 specify 실행, spec 작성

# 3. siat-post.sh 실행
$ siat-post.sh ".claude/siat/specs/로그인-페이지-만들어줘/specify.md"
{
  "valid": true,
  "next": {"step": "plan", "task_id": "로그인-페이지-만들어줘"}
}

# 4. AskUserQuestion으로 피드백 요청
"specify 결과를 확인해주세요. 어떻게 할까요?"
→ User: "Approve & Continue"

# 5. 다음 스텝(plan) 자동 진행...

✅ specify 완료

📄 생성: .claude/siat/specs/로그인-페이지-만들어줘/specify.md

📍 다음: plan
```

### 기존 태스크 계속

```
> /siat:do 로그인-페이지-만들어줘

# 마지막 spec 찾아서 다음 스텝 실행
# specify(approved) → plan 실행
```

### 리모트 모드

```
> /siat:do --remote 로그인 페이지 만들어줘

# 1. siat-pre.sh가 --remote 파싱, gateway/hooks 설정 반환
$ siat-pre.sh config.yml "specify" "--remote 로그인 페이지 만들어줘"
{
  "remote_mode": true,
  "gateway": { "mode": "remote", "questions": "script:...", "feedback": "script:..." },
  "hooks": { "on_processed": ["script:gh-issue.sh ..."] }
}

# 2-6. 동일하게 진행 (AI는 gateway 설정 따름)

# 7. on_processed hooks 실행
$ gh-issue.sh {spec_path}  # GitHub 이슈 생성

# 8. gateway.feedback = script:gh-poll.sh
$ gh-poll.sh {spec_path} --type=feedback
⏳ Waiting for approval on issue #42...

# 9. 유저가 GitHub에서 /approve 코멘트
# 10. 다음 스텝 자동 진행
```

**GitHub 코멘트 명령어:**
- `/approve` - 다음 스텝으로 진행
- `/revise 메시지` - 피드백과 함께 재시도
- `/reject` - 워크플로우 중단

---

## Critical Rules

1. **스크립트 먼저** - 모든 메타데이터는 siat-pre.sh가 생성
2. **AI는 본문만** - AI는 spec 본문과 open_questions만 작성
3. **검증 필수** - siat-post.sh로 반드시 검증
4. **경로 일관성** - 항상 `{output.path}/{task_id}/{step}.md` 구조
5. **문서 생성 필수 (CRITICAL)** - 스크립트 실패해도 spec 문서는 반드시 생성
6. **status 관리** - 피드백 결과에 따라 반드시 status 업데이트
7. **Linear Flow** - fork 없음, specify → plan → implement → review 순차 진행
