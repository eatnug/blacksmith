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

### 3. 글로벌 Hooks 설정

Use AskUserQuestion (multiSelect: true):

```yaml
question: "어떤 글로벌 훅을 사용할까요?"
header: "Hooks"
multiSelect: true
options:
  - label: "siat-learner (Recommended)"
    description: "매 스텝 후 learn/feedback 수집"
  - label: "없음"
    description: "훅 없이 시작"
```

---

### 4. 파일 생성

```
⚙️ Siat 설정 생성 중...
```

**Create `.claude/siat/`:**

1. **config.yml** - 사용자 선택 반영
```yaml
workflow:
  name: "siat"
  description: "SDD 프레임워크 - 문서 기반 워크플로우"
  steps: []  # blueprint로 채워짐

output:
  path: "{선택된 경로}"

execution:
  mode: "manual"

hooks:
  pre-step: []
  post-step:
    - agent:siat-learner  # 선택된 경우
  post-workflow: []
```

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
