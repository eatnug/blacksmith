---
description: Initialize Siat workflow in your project - interactive setup wizard
argument-hint: "[--force]"
---

# Siat Init - Interactive Setup

You are an interactive setup wizard for siat workflows.

## Arguments

`$ARGUMENTS` parsing:
- `--force`: Overwrite existing files (ask confirmation first)

## Setup Flow

### 1. Check Current State

Check `.claude/siat/` directory:

```
config.yml      → exists?
constitution.md → exists?
steps/          → exists? which steps?
```

### 2. Branch by State

**If nothing exists (fresh setup):**
→ Go to Fresh Setup Flow

**If partially exists:**
→ Go to Update Flow

**If everything exists:**
→ Go to Check for Updates Flow

---

## Fresh Setup Flow

Output:
```
📦 Siat 워크플로우를 설정합니다.

설정할 항목:
1. config.yml - 워크플로우 설정
2. constitution.md - 전역 원칙
3. steps/ - 스텝 정의
```

### Step 1: config.yml

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ config.yml

워크플로우 순서와 실행 모드를 정의합니다.
```

Read `templates/config.yml` from plugin directory and show summary:
- steps 순서
- execution mode
- hooks 설정

```
→ 기본값으로 생성합니다. (나중에 수정 가능)

✅ .claude/siat/config.yml 생성됨
```

Create `.claude/siat/config.yml` by copying template.

### Step 2: constitution.md

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2️⃣ constitution.md

모든 스텝에서 따라야 할 **전역 원칙**입니다.

예시:
- "추측하지 않고 [NEEDS CLARIFICATION] 마커 사용"
- "테스트 없이 구현 없다"
- "breaking change 금지"
```

Read `templates/constitution.md` and show it.

Use AskUserQuestion:
```yaml
question: "constitution.md를 어떻게 설정할까요?"
options:
  - label: "기본값 사용"
    description: "불명확 처리 원칙 + 빈 프로젝트 원칙 섹션"
  - label: "직접 작성"
    description: "빈 템플릿을 생성하고 직접 작성"
  - label: "나중에"
    description: "지금은 스킵 (없어도 동작함)"
```

Based on answer:
- 기본값: Copy `templates/constitution.md`
- 직접 작성: Create minimal template, tell user to edit
- 나중에: Skip, note that it's optional

### Step 3: steps/

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣ steps/

각 스텝의 실행 지침(instruction.md)과 결과 템플릿(spec.md)입니다.
```

List available templates from `templates/steps/`:
```
기본 제공 스텝:
- spec: 요구사항 분석
- design: 설계 문서 작성
- implement: 구현
```

Use AskUserQuestion:
```yaml
question: "steps를 어떻게 설정할까요?"
options:
  - label: "기본 스텝 사용"
    description: "spec → design → implement 복사"
  - label: "선택적으로"
    description: "필요한 스텝만 선택"
  - label: "직접 만들게"
    description: "빈 폴더만 생성"
```

Based on answer:
- 기본 스텝: Copy all from `templates/steps/`
- 선택적으로: Show multiselect for steps, copy selected
- 직접 만들게: Just create empty `.claude/siat/steps/`

### Step 4: Complete

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ 설정 완료!

생성된 파일:
.claude/siat/
├── config.yml
├── constitution.md
└── steps/
    ├── spec/
    ├── design/
    └── implement/

다음 단계:
1. constitution.md에 프로젝트 원칙 추가
2. /siat:do spec "첫 태스크" 로 시작
```

---

## Update Flow (Partial Missing)

When some files exist but others don't:

```
📦 Siat 설정을 확인합니다.

✅ config.yml
❌ constitution.md
✅ steps/ (spec, design, implement)
```

For each missing item, explain and ask:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

constitution.md가 없습니다.

v3.2.0부터 추가된 기능입니다.
모든 스텝에서 따라야 할 전역 원칙을 정의합니다.

주요 기능:
- [NEEDS CLARIFICATION] 마커로 불명확한 부분 표시
- 프로젝트별 규칙 정의 (예: 테스트 필수)
```

Use AskUserQuestion:
```yaml
question: "constitution.md를 추가할까요?"
options:
  - label: "추가"
    description: "기본 템플릿으로 생성"
  - label: "스킵"
    description: "없어도 동작함 (선택사항)"
```

---

## Check for Updates Flow

When all required files exist:

```
📦 Siat 설정을 확인합니다.

✅ config.yml
✅ constitution.md
✅ steps/ (spec, design, implement)

모든 필수 파일이 있습니다.
```

Check for new features in templates that user might want:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 새 기능 안내

[만약 새 스텝 템플릿이 있다면]
templates/steps/review/ 가 추가되었습니다.
코드 리뷰 스텝을 워크플로우에 추가할 수 있습니다.

[만약 템플릿에 새 섹션이 있다면]
instruction.md에 hooks 섹션이 추가되었습니다.
스텝별로 pre/post hook을 정의할 수 있습니다.

자세한 내용은 README를 참고하세요.
```

Don't force anything, just inform.

---

## --force Flag

If `--force` is passed and files exist:

```
⚠️ 기존 파일을 덮어쓰시겠습니까?

덮어쓸 파일:
- config.yml (수정됨)
- constitution.md (수정됨)
- steps/spec/instruction.md (수정됨)
```

Use AskUserQuestion to confirm before overwriting.

---

## Important Notes

- Always create `.claude/siat/specs/` directory for outputs
- Use `templates/` from plugin directory as source
- Preserve user customizations by default
- Be informative but not pushy about optional features
