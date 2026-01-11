---
description: Execute Siat workflow - document-driven step execution
argument-hint: "[task-id] [request]"
---

# Siat Workflow Orchestrator

문서 기반 워크플로우 실행기. 각 스텝의 spec 문서가 다음 스텝을 결정합니다.

---

## ⛔ CRITICAL: Spec 문서 생성은 필수

**모든 스텝은 반드시 spec 문서를 생성해야 합니다. 예외 없음.**

### 왜 필수인가?

1. **워크플로우 추적**: spec 문서가 없으면 다음 스텝이 무엇인지 알 수 없음
2. **컨텍스트 전달**: auto mode에서 서브에이전트는 오직 spec 문서를 통해서만 정보를 받음
3. **히스토리 보존**: 나중에 왜 이렇게 결정했는지 추적 가능

### 금지 사항

- ❌ "버그가 간단해서" 바로 코드 수정
- ❌ "이미 원인을 알아서" 문서 스킵
- ❌ "시간 절약을 위해" 분석만 하고 넘어가기

### 필수 사항

- ✅ 모든 스텝은 `{output.path}/{step}/{task_id}.md` 파일 생성
- ✅ frontmatter에 `id`, `steps`, `parent`, `children` 포함
- ✅ 본문에 스텝 결과물 포함
- ✅ 파일 생성 후 `ls` 명령으로 존재 확인

**spec 문서가 생성되지 않으면 스텝은 완료된 것이 아닙니다.**

---

## Arguments

`$ARGUMENTS` 파싱:

1. 기존 task-id가 주어지면 → 해당 태스크 이어서 진행
2. 텍스트만 주어지면 → 새 태스크 시작 (clarify부터)

예시:
- `/siat:do 로그인 페이지 만들어줘` → 새 태스크
- `/siat:do login-page` → 기존 태스크 이어서
- `/siat:do spec login-page` → 특정 스텝부터 이어서

## Spec Document Frontmatter

각 스텝은 spec 문서를 생성하며, frontmatter 구조:

```yaml
---
# 필수 필드
id: string          # 태스크 식별자
steps: string[]     # 남은 스텝들 (현재 포함)
parent: string|null # 이전 단계 문서 (step/id)
children: string[]  # 다음 단계 문서들 (step/id)

# 선택 필드
open_questions:     # 미해결 질문 (do.md에서 처리)
  - question: string
    context: string   # 왜 이 질문이 필요한지
    resolved: boolean
    answer: string|null

learn: string[]     # 이 스텝에서 배운 것 (코드베이스/도메인)
feedback: string[]  # 사용자 피드백 (프로세스/instruction)
---
```

## Execution Flow

### 1. Read Config

`.claude/siat/config.yml` 읽기.

**파일 없으면:** `/siat:init` 실행 안내 후 종료.

추출:
- `workflow.steps`: 시스템 스텝 목록 (순서)
- `output.path`: spec 저장 경로
- `execution.mode`: "manual" | "auto"

### 2. Find Current State

**새 태스크인 경우:**
- `current_step = "clarify"`
- `task_id = slugify(request)`
- `parent = null`
- `steps = workflow.steps` (config에서)

**기존 태스크인 경우:**
- `{output.path}/` 에서 해당 task-id를 가진 최신 문서 찾기
- 문서의 `children` 확인
- `children`이 비어있으면 → 완료된 태스크
- `children`이 있으면 → 다음 스텝 결정

### 3. Execute Step

#### 3.1 Read Instruction

`.claude/siat/steps/{step}/instruction.md` 읽기.

#### 3.2 Pre-Step Hooks

`config.hooks.pre-step`이 있으면 실행.

#### 3.3 Execute

**Manual mode:**
- 메인 컨텍스트에서 직접 실행
- instruction.md 따라 진행
- 사용자와 상호작용

**Auto mode:**
```
Task(siat-step-executor, {
    step: step_name,
    task_id: task_id,
    request: request,
    parent: parent_doc_path
})
```

#### 3.4 Generate Spec Document

스텝 완료 후 spec 문서 생성:

```yaml
---
id: {task_id}
steps: {remaining_steps}  # 현재 스텝 + 남은 스텝들
parent: {parent_doc}      # 이전 문서 경로 또는 null
children: {next_docs}     # 다음 문서 경로들
---

{스텝 결과물}
```

**children 결정:**
- 다음 스텝이 있으면: `[{next_step}/{task_id}]`
- fork하면: `[{next_step}/{child1_id}, {next_step}/{child2_id}]`
- 마지막 스텝이면: `[]`

저장 위치: `{output.path}/{step}/{task_id}.md`

#### 3.5 Post-Step Hooks

`config.hooks.post-step`이 있으면 실행.

#### 3.6 Verify Spec Document (필수)

**스텝 완료 전, 반드시 파일 존재 여부를 확인하세요:**

```bash
ls {output.path}/{step}/{task_id}.md
```

**파일이 존재하지 않으면:**
1. 스텝을 완료 처리하지 않음
2. 3.4로 돌아가서 spec 문서를 먼저 생성
3. 문서 생성 후 다시 검증

**파일이 존재하면:**
- frontmatter 확인 (id, steps, parent, children)
- 본문에 스텝 결과물이 포함되어 있는지 확인
- 모두 확인되면 다음 단계로

#### 3.7 Resolve Open Questions

spec 문서의 `open_questions`를 확인:

```yaml
open_questions:
  - question: "인증 방식은 JWT? Session?"
    context: "API 설계에 영향"
    resolved: false
    answer: null
```

**미해결 질문이 있으면:**

1. `AskUserQuestion`으로 사용자에게 질문 (context 포함)
2. 답변 처리 **(둘 다 필수)**:

   **a) Frontmatter 업데이트:**
   ```yaml
   open_questions:
     - question: "인증 방식은 JWT? Session?"
       context: "API 설계에 영향"
       resolved: true
       answer: "JWT로 진행"
   ```

   **b) 본문 업데이트:**
   - 해당 질문이 언급된 부분을 찾아서
   - 답변 내용이 자연스럽게 반영되도록 수정
   - 형식은 자유 (문맥에 맞게)

3. **두 곳 모두 업데이트하지 않으면 완료로 처리하지 않음**

**모든 질문이 resolved면:** 다음 단계로

#### 3.8 Collect Feedback (optional)

`config.learning.enabled: true`인 경우:

1. 사용자에게 질문:
   ```
   "이 단계({step})에 대한 피드백이 있나요? (없으면 스킵)"
   ```

2. 피드백이 있으면:
   - spec 문서의 `feedback` 배열에 추가
   - `learn` 배열에 이 스텝에서 발견한 것들 추가 (자동)

3. 피드백이 없으면:
   - 스킵하고 다음 단계로

**Note:** 이 단계는 메인 컨텍스트에서 실행되므로 사용자 입력이 가능합니다.

### 4. Handle Fork

`children`이 2개 이상이면:

```
for each child in children:
    child_step = child.split('/')[0]
    child_id = child.split('/')[1]

    # 각 child에 대해 다음 스텝 실행
    execute_step(child_step, child_id, parent=current_doc)
```

Auto mode에서는 병렬 실행 가능.

### 5. Continue or Complete

**Manual mode:**
- 스텝 완료 후 상태 보고
- 다음 스텝 안내
- 사용자가 `/siat:do {task-id}` 로 이어서 진행

**Auto mode:**
- `children`이 비어있을 때까지 자동 진행
- fork 시 병렬 처리

### 6. Report

```
✅ {step} 완료: {task_id}

📄 생성된 문서: {output.path}/{step}/{task_id}.md

📍 현재 상태:
   - 완료: {completed_steps}
   - 다음: {next_step} (또는 "완료")

▶️ 계속하려면: /siat:do {task_id}
```

## Examples

### 새 태스크 시작

```
> /siat:do 로그인 페이지 만들어줘

🚀 새 태스크 시작: login-page
📍 현재 스텝: clarify

[clarify 실행...]

✅ clarify 완료

📄 specs/clarify/login-page.md 생성됨
   - steps: [clarify, spec, design, implement, verify]
   - children: [spec/login-page]

▶️ 계속하려면: /siat:do login-page
```

### 태스크 이어서

```
> /siat:do login-page

📍 태스크: login-page
📍 현재 스텝: spec (clarify → spec)

[spec 실행...]

✅ spec 완료

📄 specs/spec/login-page.md 생성됨
   - children: [design/login-page]

▶️ 계속하려면: /siat:do login-page
```

### Fork 발생

```
> /siat:do login-system

📍 현재 스텝: clarify

[clarify 분석 결과 fork 결정...]

✅ clarify 완료

📄 specs/clarify/login-system.md 생성됨
   - children: [spec/login-ui, spec/login-api]

🔀 Fork 감지: 2개 서브태스크
   - login-ui: UI 구현
   - login-api: API 구현

▶️ 계속하려면:
   /siat:do login-ui
   /siat:do login-api
```

## Important

- 문서 체인이 워크플로우를 결정 (config는 가능한 스텝 목록만)
- `steps` 배열의 첫 번째 = 현재 스텝
- `children`이 다음 스텝을 가리킴
- fork는 `children`이 여러 개일 때 발생
- `parent` 체인을 따라가면 루트(clarify)에 도달
