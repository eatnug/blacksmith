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

output:
  path: ".claude/siat/specs"  # 결과물 저장 경로 (선택, 기본값)
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

### 스텝 실행 방법

`/siat:do <step> <요청>` 실행 시:

1. 요청에서 태스크 slug 생성 (예: "헤더 만들어줘" → `create-header`)
2. `.claude/siat/steps/{step}/instruction.md` 읽기
3. frontmatter에서 inputs, outputs, approval 확인
4. instruction 본문의 지침 따르기
5. 같은 폴더의 `spec.md` 템플릿 형식으로 결과 작성
6. 결과를 `{output.path}/{task-slug}/{step}.md`에 저장
   - 기본 경로: `.claude/siat/specs/{task-slug}/{step}.md`

### 결과물 구조

```
.claude/siat/specs/
└── create-header/           # 태스크 slug
    ├── plan.md              # plan 스텝 결과
    └── implement.md         # implement 스텝 결과
```

### 워크플로우 흐름

```
/siat:do plan 헤더 만들어줘
  ↓
config.yml 읽기 (output.path 확인)
  ↓
태스크 slug 생성 (create-header)
  ↓
plan 스텝 실행
  ↓
approval 필요? → 예: 사용자 확인 대기
  ↓
specs/create-header/plan.md 저장
  ↓
완료
```

### 중요 원칙

- 각 스텝의 instruction.md를 정확히 따르세요
- 스텝의 inputs가 명확하지 않으면 사용자에게 질문하세요
- 결과물은 반드시 spec.md 템플릿 형식을 따르세요
- approval이 필요한 스텝은 반드시 사용자 확인을 받으세요
