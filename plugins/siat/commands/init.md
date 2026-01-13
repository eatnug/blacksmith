---
description: Initialize Siat workflow in your project
argument-hint: "[--force]"
---

# Siat Init

프로젝트에 Siat 워크플로우 기본 구조를 생성합니다.

## Arguments

`$ARGUMENTS` parsing:
- `--force`: 기존 설정 덮어쓰기

---

## Flow

### 1. Check Current State

```
📦 Siat 설정 확인 중...
```

Check `.claude/siat/config.yml`.

**If exists (without --force):**
```
✅ Siat이 이미 설정되어 있습니다.

베스트프랙티스 적용: /siat blueprint
완전히 초기화: /siat init --force
```
→ Stop here.

**If exists with --force:**
Use AskUserQuestion to confirm:
```yaml
question: "기존 설정을 초기화할까요?"
options:
  - label: "초기화"
    description: "config, steps 초기화 (specs는 보존)"
  - label: "취소"
    description: "중단"
```

---

### 2. Output 경로 설정

Use AskUserQuestion:

```yaml
question: "Spec 문서를 어디에 저장할까요?"
header: "Output"
options:
  - label: ".claude/siat/specs (Recommended)"
    description: "기본 경로"
  - label: "docs/specs"
    description: "문서 폴더"
  - label: "직접 입력"
    description: "커스텀 경로"
```

---

### 3. Gateway 설정

Use AskUserQuestion:

```yaml
question: "유저 상호작용 방식을 선택하세요"
header: "Gateway"
options:
  - label: "Local (Recommended)"
    description: "CLI에서 직접 질문/피드백"
  - label: "Remote (GitHub)"
    description: "GitHub Issue 코멘트로 질문/피드백"
```

---

### 4. 파일 생성

```
⚙️ Siat 설정 생성 중...
```

**Create `.claude/siat/`:**

1. **config.yml** - 사용자 선택 반영

**Local 선택 시:**
```yaml
# Siat Configuration
# Universal SDD 구현체

# 워크플로우 스텝 정의
steps:
  - specify    # 유저가 원하는 것 명확히
  - plan       # 구현/수정 계획
  - implement  # 실행
  - review     # 검증

# 출력 경로
output:
  path: "{선택된 경로}"

# Gateway: 사용자 상호작용 채널
gateway:
  questions: local
  feedback: local

# Hooks: 워크플로우 확장 포인트
hooks:
  pre_step: []
  on_processed: []
  on_approve: []
  on_reject: []
  on_revise: []
  on_complete: []

# Presets: 자주 쓰는 설정 묶음
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

**Remote 선택 시:**
gateway 섹션을 remote preset 값으로 설정하고, hooks에 기본 remote hooks 추가.

2. **steps/** - 빈 디렉토리 (mkdir)

3. **specs/** - 빈 디렉토리 (mkdir)

---

### 5. 완료

```
✅ Siat 초기화 완료!

생성된 파일:
.claude/siat/
├── config.yml
├── specs/
└── steps/    (비어있음)

📦 스크립트는 siat 스킬의 scripts/ 폴더에 포함되어 있습니다.

▶️ 다음 단계: /siat blueprint 로 스텝 템플릿을 적용하세요!
```

---

## Important Notes

- `specs/`는 --force로도 보존됨
- init은 **빈 구조만 생성** - 스텝 템플릿은 blueprint로
- 바로 시작하려면: `/siat init` → `/siat blueprint`
