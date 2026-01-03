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

# GitHub 연동 설정 (선택)
sources:
  github:
    repo: null  # null이면 git remote에서 자동 감지
  defaults:
    plan:
      input:
        type: "github-issue"
        fallback: "manual"
    implement:
      output:
        type: "github-pr"
        draft: true
        link_issue: true
```

**허용되는 키:** `workflow`, `steps`, `output`, `sources`

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

# 입력 소스 설정 (선택, config.yml defaults 오버라이드)
input:
  type: "github-issue"  # manual | file | github-issue | github-pr
  fields: [title, body, labels]  # github-issue/pr 전용
  source: "plan"  # file 타입 전용: 이전 스텝 참조
  fallback: "manual"  # gh 미사용 시 대체

# 출력 설정 (선택)
output:
  type: "file"  # file | github-pr | github-issue-comment
  also:  # 추가 출력 (선택)
    - type: "github-issue-comment"
      template: "## Plan Created\n..."

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

---

## GitHub 연동

### Source Types

#### Input Sources

| Type | 설명 | 필드 | gh 명령 |
|------|------|------|--------|
| `manual` | 사용자 직접 입력 (기본) | - | - |
| `file` | 이전 스텝 결과 읽기 | `source`: 스텝 이름 | - |
| `github-issue` | GitHub Issue 읽기 | `fields`: [title, body, labels, comments] | `gh issue view` |
| `github-pr` | GitHub PR 읽기 | `fields`: [title, body, files, diff] | `gh pr view` |

#### Output Sinks

| Type | 설명 | 옵션 | gh 명령 |
|------|------|------|--------|
| `file` | 로컬 파일 저장 (기본) | - | - |
| `github-pr` | PR 생성 | `draft`, `link_issue`, `title`, `base` | `gh pr create` |
| `github-issue-comment` | Issue에 코멘트 | `template` | `gh issue comment` |

### gh CLI 요구사항

GitHub 연동을 사용하려면:
1. `gh` CLI 설치: https://cli.github.com/
2. 인증: `gh auth login`

gh가 없거나 인증되지 않으면 `fallback` 타입으로 대체됩니다.

### 컨텍스트 파일 (.task.yml)

스텝 간 데이터 전달을 위해 태스크 메타데이터 파일이 생성됩니다:

```yaml
# .claude/siat/specs/{task-slug}/.task.yml
task:
  slug: "implement-auth"
  title: "Implement User Authentication"

context:
  github:
    issue_number: 42
    issue_url: "https://github.com/owner/repo/issues/42"

steps:
  plan:
    status: "completed"
    approved: true
  implement:
    status: "pending"
```

이 파일은 다음 용도로 사용됩니다:
- 이전 스텝에서 가져온 GitHub Issue/PR 정보 저장
- 스텝 완료 상태 추적
- PR 생성 시 Issue 링크 (`Fixes #N`)
