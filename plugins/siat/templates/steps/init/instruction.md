---
name: init
description: Siat 워크플로우 초기화
role: "Project analyst & setup wizard"

triggers:
  - "/siat init"
  - "/init"
---

# Init (초기화)

프로젝트에 Siat 워크플로우를 설정합니다.

---

## 실행 흐름

```
/siat init
    │
    ├── .claude/siat/ 없음?
    │   └── Fresh Setup
    │
    └── .claude/siat/ 있음?
        └── "/siat sync를 사용하세요"
```

---

## Fresh Setup

### 1. 코드베이스 분석

**서브에이전트로 실행** (메인 컨텍스트 보존)

분석 대상:
- 프로젝트 타입 (언어, 프레임워크)
- 디렉토리 구조
- 주요 패턴 (상태 관리, API, 테스트)
- 기존 컨벤션 (lint, format)

출력:
```yaml
project:
  name: "my-app"
  type: "frontend"
  language: "typescript"
  framework: "react"

patterns:
  state: "zustand"
  api: "REST + axios"
  test: "vitest"

conventions:
  style: "eslint + prettier"
  naming: "PascalCase components, camelCase utils"
```

### 2. Knowledge 초기화

분석 결과를 `.claude/knowledge/`에 저장:

```
.claude/knowledge/
├── architecture.md    # 기술 스택, 디렉토리 구조
├── conventions.md     # 네이밍, 코드 스타일
└── domains/           # 빈 폴더 (워크플로우 진행하며 채움)
```

### 3. Siat 설정 생성

```
.claude/siat/
├── config.yml         # 템플릿에서 복사
├── constitution.md    # 템플릿에서 복사
├── manifest.yml       # 설치 정보 + 스텝별 해시
├── specs/             # output 디렉토리
├── logs/              # 워크플로우 기록
└── steps/             # 템플릿에서 복사
    ├── clarify/
    ├── spec/
    ├── design/
    ├── implement/
    ├── evaluate/
    ├── reproduce/
    ├── root-cause/
    ├── fix/
    └── verify/
```

### manifest.yml 생성

각 스텝의 instruction.md 해시를 계산하여 기록:

```yaml
# .claude/siat/manifest.yml

installed_at: "{현재 시간}"
source: "siat-plugin"
version: "1.0.0"

steps:
  clarify:
    original_hash: "{hash of instruction.md}"
  spec:
    original_hash: "{hash of instruction.md}"
  # ... 각 스텝별
```

이 해시는 나중에 `/siat sync`에서 변경 감지에 사용됨.

### 4. 완료

```
✅ Siat 초기화 완료!

프로젝트 분석 결과:
- React + TypeScript (Next.js)
- 상태: Zustand
- 테스트: Vitest

생성된 파일:
- .claude/siat/ (워크플로우 설정)
- .claude/knowledge/ (프로젝트 지식)

다음 단계:
1. .claude/knowledge/ 확인 및 보강
2. /do "첫 태스크" 로 시작!
```

---

## 이미 설정된 경우

```
📦 Siat이 이미 설정되어 있습니다.

현재 설치된 스텝:
- spec, design, implement

템플릿 업데이트가 필요하면:
→ /siat sync

설정을 완전히 초기화하려면:
→ /siat init --force
```

---

## --force 플래그

기존 설정을 무시하고 새로 설정:

```
/siat init --force

⚠️ 기존 설정을 덮어씁니다.

보존될 파일:
- .claude/siat/specs/ (기존 output)
- .claude/knowledge/ (기존 지식)

초기화될 파일:
- .claude/siat/config.yml
- .claude/siat/constitution.md
- .claude/siat/steps/

진행할까요? [Y/n]
```

---

## 금지 사항

- 기존 specs/ 삭제 (output 보존)
- 기존 knowledge/ 삭제 (지식 보존)
- 사용자 확인 없이 덮어쓰기
