---
description: Execute Siat workflow - document-driven step execution
argument-hint: "[task-id] [request]"
---

# Siat Workflow Orchestrator

문서 기반 워크플로우 실행기. 각 스텝의 spec 문서가 다음 스텝을 결정합니다.

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
id: string          # 태스크 식별자
steps: string[]     # 남은 스텝들 (현재 포함)
parent: string|null # 이전 단계 문서 (step/id)
children: string[]  # 다음 단계 문서들 (step/id)
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
