---
description: Initialize Siat workflow in your project
argument-hint: "[--force]"
---

# Siat Init

프로젝트에 Siat 워크플로우를 설정합니다.

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
  steps:
    - clarify
    - reproduce
    - root-cause
    - spec
    - design
    - visual-design
    - implement
    - fix
    - verify

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

2. **steps/** - 템플릿에서 복사
   - `clarify/instruction.md`
   - `spec/instruction.md`
   - `design/instruction.md`
   - ... (모든 스텝)

3. **specs/** - 빈 디렉토리

4. **manifest.yml** - 스텝 해시 기록
```yaml
installed_at: "{현재 시간}"
source: "siat-plugin"
version: "5.1.0"

steps:
  clarify:
    original_hash: "{hash}"
  spec:
    original_hash: "{hash}"
  # ...
```

---

### 5. 완료

```
✅ Siat v5.1.0 초기화 완료!

생성된 파일:
.claude/siat/
├── config.yml
├── manifest.yml
├── specs/
└── steps/
    ├── clarify/
    ├── spec/
    ├── design/
    ├── implement/
    └── ...

다음 단계:
▶️ /siat do "첫 태스크" 로 시작!
```

---

## Important Notes

- `specs/`는 --force로도 보존됨
- `manifest.yml`은 blueprint에서 사용
- 스텝 커스터마이징은 직접 `steps/*/instruction.md` 수정
