# Siat

**S**pec-driven **I**terative **A**gent **T**asks - Universal SDD 구현체

---

## Universal SDD (Spec-Driven Development)

### 철학

- **Spec is Source of Truth**: 스펙이 개발을 이끈다
- **Human-in-the-loop**: AI가 작업하고, 사람이 검토
- **Linear Flow**: 분기 없이 순차 진행

### Core Entities

| Entity | 설명 |
|--------|------|
| **Step** | 작업 단위. instruction + spec_template |
| **Spec** | Step의 결과물. 마크다운 파일 |
| **Feedback** | approve / revise / reject |

### Spec 구조

```yaml
---
id: "{task-id}"
step: "{step-name}"
prev: "{task-id}/{prev-step}"   # nullable (첫 스텝)
next: "{task-id}/{next-step}"   # nullable (마지막 스텝)
status: "pending_feedback"
open_questions: []
---

# {Step}: {Task Title}

{content}
```

### 진행 방식

```
1. 사용자 요청
2. 첫 번째 스텝 실행
   ├─ AI가 instruction 읽고 작업
   ├─ spec_template 형식으로 spec 생성
   ├─ open_questions 있으면 해결
   ├─ 사용자 feedback 수집
   └─ approve → 다음 스텝 / revise → 재작업 / reject → 종료
3. 마지막 스텝까지 반복
4. 완료
```

### 파일 구조 (참고)

```
{config-dir}/
├── config.{ext}
├── steps/
│   └── {step}/
│       ├── instruction.{ext}
│       └── spec_template.{ext}
└── specs/
    └── {task-id}/
        └── {step}.{ext}
```

---

## Siat: Universal SDD의 구현

Siat는 Claude Code 환경에서 Universal SDD를 실행하는 플러그인입니다.

### 기본 Workflow

```yaml
steps:
  - specify    # 유저가 원하는 것 명확히
  - plan       # 구현/수정 계획
  - implement  # 실행
  - review     # 검증
```

이 workflow는 프로젝트별로 커스터마이징 가능합니다.

### Siat 고유 기능

| 기능 | 설명 |
|------|------|
| **Gateway** | questions/feedback I/O 채널 |
| **Hooks** | 확장 포인트 |
| **Presets** | 설정 묶음 (--remote 등) |

---

## Config

`.claude/siat/config.yml`:

```yaml
steps:
  - specify
  - plan
  - implement
  - review

output:
  path: ".claude/siat/specs"

gateway:
  questions: local    # local = AskUserQuestion
  feedback: local     # script:xxx.sh 로 오버라이드 가능

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
        - script:slack-notify.sh {spec_path}
      on_approve:
        - script:gh-issue-close.sh {spec_path}
```

---

## Gateway

사용자와 상호작용하는 채널입니다.

| Gateway | 설명 |
|---------|------|
| `questions` | open_questions 해결 방법 |
| `feedback` | approve/revise/reject 수집 방법 |

**값:**
- `local`: 기본값. Claude의 AskUserQuestion 사용
- `script:path/to/script.sh`: 스크립트로 대체 (remote 등)

---

## Hooks

워크플로우 확장 포인트입니다.

| Hook | 시점 | 용도 |
|------|------|------|
| `pre_step` | 스텝 실행 전 | 사전 검증 |
| `on_processed` | AI 작업 완료 후 | 알림, 이슈 생성 |
| `on_approve` | 승인 시 | 이슈 닫기 |
| `on_reject` | 거절 시 | 태스크 종료 처리 |
| `on_revise` | 수정 요청 시 | 재작업 트리거 |
| `on_complete` | 워크플로우 완료 시 | 최종 알림 |

**형식:**
```yaml
hooks:
  on_processed:
    - script:path/to/script.sh {spec_path}
    - script:another.sh {task_id}
```

---

## Presets

자주 쓰는 설정 묶음입니다.

```yaml
presets:
  remote:
    gateway: { ... }
    hooks: { ... }
```

**사용:**
```bash
/do --remote 로그인 기능       # --preset=remote 의 shorthand
/do --preset=remote 로그인 기능
/do --preset=slack 로그인 기능  # 커스텀 preset
```

---

## 디렉토리 구조

```
.claude/siat/
├── config.yml              # 설정
├── steps/                  # 스텝 정의
│   ├── specify/
│   │   ├── instruction.md
│   │   └── spec_template.md
│   ├── plan/
│   │   ├── instruction.md
│   │   └── spec_template.md
│   └── ...
└── specs/                  # 생성된 문서들
    └── {task-id}/
        ├── specify.md
        ├── plan.md
        ├── implement.md
        └── review.md
```

---

## 사용법

### 설치

```bash
# 마켓플레이스 등록
/plugin marketplace add eatnug/blacksmith

# siat 설치
/plugin install siat@blacksmith
```

### 초기화

```bash
/siat:init
```

### 워크플로우 실행

```bash
# 새 태스크 시작
/do 로그인 기능 만들어줘

# 태스크 이어서
/do login-feature

# remote 모드
/do --remote 로그인 기능
```

### 상태 확인

```bash
/status
```

---

## Spec Frontmatter

```yaml
---
id: "login-feature"
step: "plan"
prev: "login-feature/specify"
next: "login-feature/implement"
status: "pending_feedback"      # pending | pending_feedback | approved | rejected
open_questions:
  - id: "q1"
    question: "어떤 인증 방식을 사용할까요?"
    answer: null
    resolved: false
---
```

### Status

| Status | 설명 |
|--------|------|
| `pending` | 작업 중 |
| `pending_feedback` | 피드백 대기 |
| `approved` | 승인됨 |
| `rejected` | 거절됨 |

---

## 커스터마이징

### 스텝 추가

1. `steps/{step-name}/instruction.md` 생성
2. `steps/{step-name}/spec_template.md` 생성
3. `config.yml`의 `steps`에 추가

### 스텝 수정

`steps/{step}/instruction.md` 직접 수정

### Workflow 변경

`config.yml`에서 `steps` 순서/구성 변경

### Hook 추가

`config.yml`의 `hooks`에 스크립트 추가

### Preset 추가

`config.yml`의 `presets`에 새 preset 정의
