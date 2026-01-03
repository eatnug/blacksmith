---
name: siat
description: |
  Siat 워크플로우 관리자.
  .claude/siat/ 폴더가 있는 프로젝트에서 워크플로우를 실행하고,
  siat 관련 파일을 수정할 때 규칙을 따릅니다.
---

# Siat

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
  pre-step:        # 스텝 실행 전 훅
    - agent:navigator
    - skill:clarify
  post-step:       # 스텝 실행 후 훅
    - agent:reporter
```

**허용되는 키만 사용하세요.** 임의의 키 추가 금지.

### 스텝 디렉토리 구조

```
.claude/siat/steps/{step-name}/
├── instruction.md   # 스텝 실행 지침
└── spec.md          # 결과물 템플릿
```

### instruction.md 형식

```markdown
---
name: step-name
description: 이 스텝이 하는 일

inputs:
  - 필요한 정보 1
  - 필요한 정보 2

outputs:
  - 결과물 1
  - 결과물 2

hooks:                    # 스텝별 훅 (config 오버라이드)
  pre-step:
    - skill:clarify
  post-step:
    - agent:reporter
---

# Step Name

스텝 실행 지침...
```

### spec.md 형식

```markdown
# Step Name: {{title}}

## 요약

## 상세 내용

## 결과
```

---

## 실행 모드

### manual (기본)

- 스텝이 메인 컨텍스트에서 실행
- 분석 과정이 컨텍스트에 쌓임
- 세션 분리는 사용자가 직접 관리

### auto

- 스텝이 서브에이전트에서 실행
- 결과 요약만 메인 컨텍스트에 남음
- `--auto` 플래그로 강제 가능

---

## 훅 시스템

### 훅 타입

| 접두사 | 설명 | 예시 |
|--------|------|------|
| `agent:` | 에이전트 호출 | `agent:navigator` |
| `skill:` | 스킬 호출 | `skill:clarify` |

### 실행 순서

```
pre-step hooks → step 실행 → post-step hooks
```

### 훅 병합

스텝의 instruction.md에 hooks가 있으면 config.yml과 합쳐짐 (extend).

```
최종 pre-step = 전역 pre-step + 스텝별 pre-step
최종 post-step = 전역 post-step + 스텝별 post-step
```

전역 훅이 먼저 실행되고, 스텝별 훅이 그 다음.

---

## 워크플로우 실행

### /siat:do [--auto] [step] [request]

1. **인자 파싱**
   - `--auto`: auto 모드 강제
   - `step`: 실행할 스텝 (없으면 navigator 사용)
   - `request`: 사용자 요청

2. **훅 실행**
   - pre-step, post-step 훅은 항상 서브에이전트로 실행
   - `siat-hook-runner` 에이전트가 처리

3. **스텝 실행**
   - manual 모드: 메인에서 직접
   - auto 모드: `siat-step-executor`가 처리

### 결과물 구조

```
.claude/siat/specs/
└── {task-slug}/
    ├── plan.md
    └── implement.md
```

---

## 제공 에이전트

| 에이전트 | 역할 |
|----------|------|
| `siat-hook-runner` | 훅 실행 (skill/agent 모두 처리) |
| `siat-navigator` | 다음 스텝 찾기 |
| `siat-reporter` | 결과 리포트 생성 |
| `siat-step-executor` | 스텝 실행 (agent 모드) |
