# Siat

Spec-driven development workflow. 각 팀이 자신만의 워크플로우를 정의하고, 문서 기반으로 스텝 간 컨텍스트를 전달합니다.

## 핵심 개념

### 워크플로우 예시

```
research → plan → implement → review
    │         │         │         │
    ▼         ▼         ▼         ▼
research.md  plan.md  implement.md  review.md
```

각 단계(step)가 끝나면 **문서(spec)가 생성**됩니다. 다음 단계는 이 문서를 읽고 시작합니다.

### 왜 이렇게?

- **컨텍스트 분리**: 각 단계의 분석 과정이 다음 단계를 오염시키지 않음
- **문서 기반 커뮤니케이션**: Claude든 사람이든, 문서를 보고 이어갈 수 있음
- **세션 분리 가능**: 단계 사이에 세션을 끊고 새로 시작해도 됨

### Constitution (전역 원칙)

`constitution.md`에 프로젝트 전역 원칙을 정의합니다. 모든 스텝에서 이 원칙을 따릅니다.

```markdown
# constitution.md

## 불명확 처리 원칙
- 추측하지 않는다
- `[NEEDS CLARIFICATION: 질문]` 마커를 붙인다
- 마커가 있으면 다음 단계 진행 불가

## 프로젝트 원칙
- 테스트 없이 구현 없다
- breaking change 금지
```

### 팀별 커스터마이징

단계(step)는 예시일 뿐, 팀에 맞게 정의합니다:

```yaml
# 팀 A: 기본
steps: [plan, implement]

# 팀 B: 리뷰 포함
steps: [plan, implement, review]

# 팀 C: 리서치 중심
steps: [research, design, prototype, implement, test]
```

### 각 단계 정의: instruction.md

각 단계는 `instruction.md`로 정의합니다. frontmatter에 메타데이터를 넣고, 본문에 지침을 작성합니다.

```markdown
---
name: plan
description: 요청사항을 분석하고 구현 계획 수립

inputs:
  - 무엇을 만들어야 하는지
  - 제약조건이나 요구사항

outputs:
  - 구현 접근법
  - 수정할 파일 목록

hooks:
  pre-step:
    - skill:clarify    # 시작 전 요구사항 확인
  post-step:
    - agent:reporter   # 완료 후 리포트 생성
---

# Plan

요청사항을 분석하고 구현 계획을 세워주세요.
```

### 훅(Hook) 시스템

각 단계 실행 전후에 에이전트나 스킬을 자동 실행할 수 있습니다.

```
pre-step hooks → 단계 실행 → post-step hooks
```

```yaml
# 예시 - 실제 훅은 팀에 맞게 정의하세요
hooks:
  pre-step:
    - agent:navigator   # 다음 단계 안내
    - skill:clarify     # 요구사항 명확화
  post-step:
    - agent:reporter    # 결과 리포트
```

- `agent:xxx`: 서브에이전트 호출 (컨텍스트 분리됨)
- `skill:xxx`: 스킬 호출

훅은 config.yml(전역)과 instruction.md(단계별) 모두에서 정의 가능하며, 합쳐져서 실행됩니다.

> **참고**: `navigator`, `reporter` 등은 siat이 제공하는 예시 에이전트입니다. 팀에서 만든 에이전트나 다른 플러그인의 스킬도 사용할 수 있습니다.

## 설치

[Blacksmith 마켓플레이스](../README.md)를 통해 설치:

```bash
# 마켓플레이스 등록 (최초 1회)
/plugin marketplace add eatnug/blacksmith

# siat 설치
/plugin install siat@blacksmith
```

## 빠른 시작

```bash
# 프로젝트에 siat 초기화
/siat:init

# 워크플로우 실행
/siat:do plan "로그인 기능 만들어줘"

# 다음 스텝 찾기
/siat:do
```

## 디렉토리 구조

### 플러그인 구조

```
plugins/siat/
├── agents/                    # 제공 에이전트
│   ├── hook-runner.md         # 훅 실행
│   ├── navigator.md           # 다음 스텝 찾기
│   ├── reporter.md            # 결과 리포트
│   └── step-executor.md       # 스텝 실행 (auto 모드)
├── commands/
│   └── do.md                  # 오케스트레이터
├── skills/
│   └── siat/SKILL.md          # 규칙 및 스키마
├── steps/                     # 기본 스텝 예시
│   ├── plan/
│   └── implement/
├── config.yml                 # 기본 설정
└── constitution.md            # 전역 원칙 템플릿
```

### 프로젝트 구조 (초기화 후)

```
.claude/siat/
├── config.yml                 # 워크플로우 설정
├── constitution.md            # 전역 원칙 (커스터마이징)
├── steps/                     # 스텝 정의
│   ├── plan/
│   │   ├── instruction.md     # 실행 지침
│   │   └── spec.md            # 결과 템플릿
│   └── implement/
│       ├── instruction.md
│       └── spec.md
└── specs/                     # 실행 결과물 (태스크별 폴더)
    ├── create-header/         # 태스크 1
    │   ├── plan.md
    │   ├── plan.report.md     # 리포트 (reporter 훅)
    │   └── implement.md
    ├── add-login/             # 태스크 2
    │   ├── plan.md
    │   └── implement.md
    └── fix-bug-123/           # 태스크 3
        └── plan.md            # 진행 중
```

## 설정

### config.yml

```yaml
workflow:
  name: "my-workflow"
  description: "우리 팀 워크플로우"

steps:
  - plan
  - implement
  # - review
  # - deploy

output:
  path: ".claude/siat/specs"

execution:
  mode: "manual"  # "manual" | "auto"

hooks:
  pre-step:
    - agent:navigator
  post-step:
    - agent:reporter
```

### 실행 모드

| 모드 | 설명 |
|------|------|
| `manual` | 스텝이 메인 컨텍스트에서 실행. 세션 분리는 사용자가 직접. |
| `auto` | 스텝이 서브에이전트에서 실행. 자동 컨텍스트 분리. |

```bash
# config 따름
/siat:do plan "헤더 만들어"

# auto 모드 강제
/siat:do --auto plan "헤더 만들어"
```

## 스텝 정의

### instruction.md

```yaml
---
name: plan
description: 요청사항을 분석하고 구현 계획 수립

inputs:
  - 무엇을 만들어야 하는지
  - 제약조건이나 요구사항

outputs:
  - 구현 접근법
  - 수정할 파일 목록

hooks:
  pre-step:
    - skill:clarify
  post-step:
    - agent:reporter
---

# Plan

요청사항을 분석하고 구현 계획을 세워주세요.
```

### spec.md (결과 템플릿)

```markdown
# Plan: {{title}}

## 요약

## 접근 방법

## 변경할 파일

| 파일 | 변경 내용 |
|------|----------|

## 주의사항
```

## 훅 시스템

스텝 실행 전후에 에이전트/스킬을 실행합니다.

```
pre-step hooks → 스텝 실행 → post-step hooks
```

### 훅 타입

```yaml
hooks:
  pre-step:
    - agent:navigator     # 에이전트 호출
    - skill:clarify       # 스킬 호출
  post-step:
    - agent:reporter
```

### 훅 병합

전역(config.yml) + 스텝별(instruction.md) 훅이 합쳐집니다.

```
최종 = 전역 훅 + 스텝별 훅
```

전역 훅이 먼저 실행됩니다.

### 외부 에이전트/스킬 사용

siat 내부뿐 아니라 외부 에이전트/스킬도 사용 가능:

```yaml
hooks:
  pre-step:
    - agent:my-custom-agent   # ~/.claude/agents/ 또는 .claude/agents/
    - skill:my-other-skill    # 다른 플러그인 스킬
```

## 제공 에이전트

| 에이전트 | 역할 |
|----------|------|
| `siat-hook-runner` | 훅 목록을 받아 순차 실행 |
| `siat-navigator` | specs 스캔하여 다음 스텝 찾기 |
| `siat-reporter` | 스텝 완료 후 리포트 생성 |
| `siat-step-executor` | auto 모드에서 스텝 실행 |

## 워크플로우 예시

### 기본 (plan → implement)

```yaml
steps:
  - plan
  - implement
```

### 코드 리뷰 포함

```yaml
steps:
  - plan
  - implement
  - review
```

### 디자인 시스템

```yaml
steps:
  - analyze
  - design
  - prototype
  - implement
  - test
```

## 사용 흐름

### 1. 새 태스크 시작

```bash
/siat:do plan "로그인 기능 만들어줘"
```

→ `.claude/siat/specs/create-login/plan.md` 생성

### 2. 다른 태스크도 시작 가능

```bash
/siat:do plan "헤더 컴포넌트 만들어줘"
```

→ `.claude/siat/specs/create-header/plan.md` 생성

여러 태스크를 병렬로 진행할 수 있습니다.

### 3. (선택) 세션 분리

컨텍스트가 무거워지면 새 세션 시작.

### 4. 다음 스텝 진행

```bash
# 특정 태스크 지정
/siat:do implement create-login

# 또는 navigator가 미완료 태스크 안내
/siat:do
```

→ `plan.md` 읽고 → `implement.md` 생성

### 5. 진행 상황 확인

```bash
/siat:do
```

→ 미완료 태스크 목록 표시

## 팁

- **세션 분리**: 각 스텝 완료 후 새 세션에서 다음 스텝 진행하면 컨텍스트 깔끔
- **auto 모드**: 빠르게 여러 스텝 돌릴 때 유용
- **훅 활용**: navigator로 자동 안내, reporter로 리포트 생성
- **커스텀 스텝**: 팀에 맞는 스텝 정의 (design, review, test 등)
