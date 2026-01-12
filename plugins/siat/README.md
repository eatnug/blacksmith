# Siat

**S**pec-driven **I**terative **A**gent **T**asks - 문서 기반 워크플로우 프레임워크

## 개요

Siat는 SDD(Spec-Driven Development) 프레임워크입니다. 각 스텝이 spec 문서를 생성하고, 그 문서가 다음 스텝을 결정합니다.

```
[clarify] → spec문서 → [spec] → spec문서 → [design] → spec문서 → [implement] → ...
```

## 핵심 개념

### 1. Spec 문서

모든 스텝의 결과물은 **spec 문서**입니다. 각 문서는 frontmatter로 워크플로우를 제어합니다.

```yaml
---
id: "login-page"                    # 태스크 식별자
steps: [spec, design, implement, verify]  # 남은 스텝들
parent: "clarify/login-page"        # 이전 문서
children: ["design/login-page"]     # 다음 문서(들)
---

# 문서 본문
...
```

### 2. 문서 체인

문서들이 `parent`/`children`으로 연결되어 워크플로우를 형성합니다.

```
clarify/login-page
    ↓ children: [spec/login-page]
spec/login-page
    ↓ children: [design/login-page]
design/login-page
    ↓ children: [implement/login-page]
implement/login-page
    ↓ children: [verify/login-page]
verify/login-page
    ↓ children: []  ← 완료
```

### 3. Orchestrator

`/siat:do` 명령이 문서 체인을 따라 스텝을 실행합니다.

---

## Frontmatter 스펙

### 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 태스크 식별자 (slug) |
| `steps` | string[] | 남은 스텝들 (현재 스텝 포함) |
| `parent` | string \| null | 이전 문서 경로 (`step/id` 형식) |
| `children` | string[] | 다음 문서 경로들 (`step/id` 형식) |

### steps 배열

`steps[0]`은 항상 현재 스텝입니다. 배열은 "left steps" (남은 스텝들)을 의미합니다.

```yaml
# clarify 단계 문서
steps: [clarify, spec, design, implement, verify]

# spec 단계 문서 (clarify 완료 후)
steps: [spec, design, implement, verify]

# design 단계 문서
steps: [design, implement, verify]
```

### parent / children

- `parent`: 이 문서를 생성한 이전 스텝의 문서
- `children`: 이 문서가 생성할 다음 스텝의 문서(들)

```yaml
# 일반 진행 (1:1)
children: ["design/login-page"]

# Fork (1:N)
children: ["spec/login-ui", "spec/login-api"]

# 완료 (종료)
children: []
```

---

## Orchestrator 동작

### 실행 흐름

```
/siat:do [task-id | request]
         ↓
    ┌─────────────────┐
    │ 1. Config 읽기  │
    └────────┬────────┘
             ↓
    ┌─────────────────┐
    │ 2. 상태 파악    │ ← 기존 문서 있나? children은?
    └────────┬────────┘
             ↓
    ┌─────────────────┐
    │ 3. 스텝 실행    │ ← instruction.md 따라 실행
    └────────┬────────┘
             ↓
    ┌─────────────────┐
    │ 4. 문서 생성    │ ← frontmatter + 결과물
    └────────┬────────┘
             ↓
    ┌─────────────────┐
    │ 5. 보고 & 안내  │
    └─────────────────┘
```

### 1. Config 읽기

`.claude/siat/config.yml`에서 설정 로드:

```yaml
workflow:
  steps: [clarify, reproduce, root-cause, spec, design, visual-design, implement, fix, verify]

output:
  path: ".claude/siat/specs"

execution:
  mode: "manual"  # 또는 "auto"
```

### 2. 상태 파악

**새 태스크:**
- task-id 없음 → clarify부터 시작
- `parent: null`, `steps: config.workflow.steps`

**기존 태스크:**
- 해당 id의 최신 문서 찾기
- `children` 확인:
  - `[]` → 완료
  - `[x]` → x가 다음 스텝
  - `[x, y]` → fork

### 3. 스텝 실행

1. `.claude/siat/steps/{step}/instruction.md` 읽기
2. instruction에 따라 실행
3. 사용자와 상호작용 (manual mode)

### 4. 문서 생성

스텝 완료 시 spec 문서 생성:

```yaml
---
id: {task-id}
steps: {현재 steps에서 [0] 제거한 나머지}
parent: {이전 문서 경로}
children: {다음 문서 경로들}
---

{스텝 결과물}
```

저장: `{output.path}/{task-id}/{step}.md`

### 5. 보고

```
✅ spec 완료: login-page

📄 생성: .claude/siat/specs/login-page/spec.md

📍 다음: design

▶️ 계속: /siat:do login-page
```

---

## 워크플로우 패턴

### 태스크별 steps

각 태스크는 자신만의 `steps`를 가집니다. 시스템 스텝의 서브셋이며, clarify 단계에서 태스크 유형에 맞게 결정됩니다.

```yaml
# feature 워크플로우
steps: [clarify, spec, design, implement, verify]

# UI 워크플로우
steps: [clarify, spec, visual-design, implement, verify]

# bugfix 워크플로우
steps: [clarify, reproduce, root-cause, fix, verify]
```

### Fork (태스크 분리)

`children`이 여러 개면 fork입니다.

```yaml
# clarify/login-system.md
---
id: login-system
steps: [clarify, spec, design, implement, verify]
parent: null
children: ["spec/login-ui", "spec/login-api"]  # fork!
---
```

각 child는 독립적인 태스크가 되어 자체 `steps`를 가집니다:

```yaml
# spec/login-ui.md
---
id: login-ui
steps: [spec, visual-design, implement, verify]
parent: "clarify/login-system"
children: ["visual-design/login-ui"]
---
```

```yaml
# spec/login-api.md
---
id: login-api
steps: [spec, design, implement, verify]
parent: "clarify/login-system"
children: ["design/login-api"]
---
```

---

## 스텝 정의

각 스텝은 `steps/{step}/instruction.md`에 정의됩니다.

### 구조

```
steps/
  clarify/
    instruction.md
  spec/
    instruction.md
  design/
    instruction.md
  ...
```

### instruction.md 형식

```yaml
---
name: spec
description: 요구사항 정의
role: "Requirements engineer"

inputs:
  - clarify 단계의 결과

outputs:
  - 요구사항 문서

sub-tasks:
  - id: decompose
    instruction: "요청을 요구사항으로 분해"
  - id: validate
    instruction: "요구사항 검증"
---

# Spec (요구사항 명세)

당신은 **{{role}}**입니다.

[상세 지침...]

## Output Format

[문서 형식 정의...]
```

### 기본 제공 스텝

| 스텝 | 용도 |
|------|------|
| clarify | 요청 분석, 워크플로우 결정 |
| reproduce | 버그 재현 (bugfix) |
| root-cause | 원인 분석 (bugfix) |
| spec | 요구사항 정의 |
| design | 기술 설계 |
| visual-design | UI/UX 시각 설계 |
| implement | 코드 구현 |
| fix | 버그 수정 (bugfix) |
| verify | 검증 |

---

## 사용법

### 새 태스크 시작

```
/siat:do 로그인 페이지 만들어줘
```

### 태스크 이어서

```
/siat:do login-page
```

### 특정 스텝부터

```
/siat:do implement login-page
```

---

## 커스터마이징

### 새 스텝 추가

1. `steps/{step-name}/instruction.md` 생성
2. `config.yml`의 `workflow.steps`에 추가

### 기존 스텝 수정

`steps/{step}/instruction.md` 직접 수정

### 워크플로우 변경

`config.yml`에서 `workflow.steps` 순서 변경

---

## 디렉토리 구조

```
.claude/siat/
  config.yml          # 설정
  steps/              # 스텝 정의
    clarify/
      instruction.md
    spec/
      instruction.md
    ...
  specs/              # 생성된 문서들
    clarify/
      login-page.md
    spec/
      login-page.md
    ...
```

---

## 설치

```bash
# 마켓플레이스 등록 (최초 1회)
/plugin marketplace add eatnug/blacksmith

# siat 설치
/plugin install siat@blacksmith
```

## 빠른 시작

```bash
# 1. 프로젝트에 siat 초기화
/siat:init

# 2. 워크플로우 시작
/siat:do 로그인 기능 만들어줘

# 3. 다음 스텝 진행
/siat:do login-feature
```
