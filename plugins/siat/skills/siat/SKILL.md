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

허용되는 키만 사용:

```yaml
workflow:
  name: "워크플로우 이름"
  description: "설명"

steps:
  - step1
  - step2
```

**절대 임의의 키를 추가하지 마세요.** `utilities`, `helpers`, `plugins` 같은 키는 허용되지 않습니다.

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

approval:
  required: true|false
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

## 워크플로우 실행

### 역할

1. `.claude/siat/config.yml`에서 워크플로우 설정 읽기
2. 현재 진행 상태 관리 (`.claude/siat/state.yml`)
3. 각 스텝 순서대로 실행
4. 승인이 필요한 스텝에서 사용자 확인 받기

### 스텝 실행 방법

각 스텝을 실행할 때:

1. `.claude/siat/steps/{step}/instruction.md` 읽기
2. frontmatter에서 inputs, outputs, approval 확인
3. instruction 본문의 지침 따르기
4. 결과를 `.claude/siat/steps/{step}/spec.md` 템플릿 형식으로 작성
5. 결과를 `.claude/siat/artifacts/{step}.md`에 저장

### 상태 관리

`.claude/siat/state.yml` 형식:

```yaml
current_run:
  request: "사용자 요청 내용"
  current_step: "plan"
  started_at: "2024-01-01T00:00:00Z"

steps:
  plan:
    status: "completed"  # pending | in_progress | completed | skipped
    artifact: ".claude/siat/artifacts/plan.md"
  implement:
    status: "pending"
```

### 워크플로우 흐름

```
시작
  ↓
config.yml 읽기
  ↓
state.yml 확인 (이전 진행 상태)
  ↓
다음 스텝 결정
  ↓
스텝 실행
  ↓
approval 필요? → 예: 사용자 확인 대기
  ↓
state.yml 업데이트
  ↓
다음 스텝 있음? → 예: 반복
  ↓
완료
```

### 중요 원칙

- 각 스텝의 instruction.md를 정확히 따르세요
- 스텝의 inputs가 명확하지 않으면 사용자에게 질문하세요
- 스텝의 outputs가 모두 결정되어야 해당 스텝이 완료됩니다
- approval이 필요한 스텝은 반드시 사용자 확인을 받으세요
