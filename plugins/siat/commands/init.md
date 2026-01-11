---
description: Initialize Siat workflow - codebase analysis + setup
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

Check `.claude/siat/` directory.

**If exists (without --force):**
```
✅ Siat이 이미 설정되어 있습니다.

현재 스텝: {설치된 스텝 목록}

업데이트가 필요하면: /siat sync
완전히 초기화하려면: /siat init --force
```
→ Stop here.

**If exists with --force:**
```
⚠️ 기존 설정을 초기화합니다.

보존됨:
- .claude/siat/specs/ (기존 output)
- .claude/knowledge/ (기존 지식)

초기화됨:
- config.yml
- constitution.md
- manifest.yml
- steps/
```

Use AskUserQuestion to confirm.

**If not exists:**
→ Continue to Fresh Setup.

---

## Fresh Setup

### Step 1: 코드베이스 분석

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 코드베이스 분석 중...
```

**Use Task tool with subagent to analyze:**
- 프로젝트 타입 (언어, 프레임워크)
- 디렉토리 구조
- 주요 패턴 (상태 관리, API, 테스트)
- 기존 컨벤션

**Show result:**
```
프로젝트 분석 결과:
- 타입: {language} + {framework}
- 상태 관리: {state_management}
- API: {api_style}
- 테스트: {test_framework}
```

### Step 2: Knowledge 초기화

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 프로젝트 지식 초기화
```

Create `.claude/knowledge/`:
- `architecture.md` - 분석 결과 기반
- `conventions.md` - 분석 결과 기반
- `domains/` - 빈 폴더

```
✅ .claude/knowledge/ 생성됨
```

### Step 3: Siat 설정 생성

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚙️ Siat 설정 생성
```

Create `.claude/siat/`:
- `config.yml` - 템플릿에서 복사
- `constitution.md` - 템플릿에서 복사
- `manifest.yml` - 스텝별 해시 포함
- `specs/` - output 디렉토리
- `logs/` - 워크플로우 기록
- `steps/` - 템플릿에서 복사

**manifest.yml 생성:**
```yaml
installed_at: "{현재 시간}"
source: "siat-plugin"
version: "4.0.0"

steps:
  clarify:
    original_hash: "{hash}"
  spec:
    original_hash: "{hash}"
  # ... 모든 스텝
```

각 스텝의 `instruction.md` 파일 해시를 계산하여 기록.

```
✅ .claude/siat/ 생성됨
```

### Step 4: 완료

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Siat v4.0.0 초기화 완료!

생성된 파일:
.claude/
├── siat/
│   ├── config.yml
│   ├── constitution.md
│   ├── manifest.yml
│   ├── specs/
│   ├── logs/
│   └── steps/
│       ├── clarify/
│       ├── spec/
│       ├── design/
│       ├── implement/
│       ├── evaluate/
│       ├── reproduce/
│       ├── root-cause/
│       ├── fix/
│       └── verify/
└── knowledge/
    ├── architecture.md
    ├── conventions.md
    └── domains/

다음 단계:
1. .claude/knowledge/ 확인 및 보강
2. /do "첫 태스크" 로 시작!
```

---

## Important Notes

- specs/와 knowledge/는 --force로도 보존
- manifest.yml은 sync에서 사용
- 코드베이스 분석은 서브에이전트로 실행 (메인 컨텍스트 보존)
