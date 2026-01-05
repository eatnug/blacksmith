---
description: Configure Siat workflow settings interactively
argument-hint: "[setting] [value]"
---

# Siat Config

워크플로우 설정을 인터랙티브하게 변경합니다.

## Arguments

`$ARGUMENTS` 파싱:

1. 인자 없음 → 인터랙티브 메뉴 표시
2. `{setting}` → 해당 설정 현재 값 표시
3. `{setting} {value}` → 직접 설정 변경

Examples:
- `/siat:config` → 메뉴에서 선택
- `/siat:config output.path` → 현재 output path 표시
- `/siat:config mode auto` → 실행 모드를 auto로 변경

## Execution

### 1. Setup Check

```
Required:
- .claude/siat/config.yml
```

**If not set up:**

```
⚠️ Siat이 설정되지 않았습니다.

→ /siat:init 으로 먼저 설정하세요.
```

### 2. Interactive Menu (인자 없을 때)

AskUserQuestion으로 변경할 항목 선택:

```
? 무엇을 변경하시겠습니까?

  [ ] output.path - 스펙 저장 경로
  [ ] mode - 실행 모드 (manual/auto)
  [ ] steps - 워크플로우 스텝 순서
  [ ] hooks - 글로벌 훅 설정
  [ ] name - 워크플로우 이름
```

### 3. Setting: output.path

현재 값 표시 → 새 값 입력 요청:

```
📁 Output Path

현재: .claude/siat/specs

새 경로를 입력하세요 (상대 경로):
```

변경 시:
1. config.yml 업데이트
2. 기존 specs 이동 여부 확인 (AskUserQuestion)
3. 결과 표시

### 4. Setting: mode

```
⚙️ Execution Mode

현재: manual

? 실행 모드를 선택하세요:
  [ ] manual - 메인 컨텍스트에서 대화형 실행 (Recommended)
  [ ] auto - 에이전트가 격리된 환경에서 자동 실행
```

### 5. Setting: steps

```
📋 Workflow Steps

현재 순서: spec → design → implement

? 어떤 작업을 하시겠습니까?
  [ ] 스텝 추가 - 새 스텝을 워크플로우에 추가
  [ ] 스텝 제거 - 기존 스텝 제거
  [ ] 순서 변경 - 스텝 실행 순서 변경
```

#### 스텝 추가

1. `.claude/siat/steps/` 폴더에 정의된 스텝 스캔
2. config에 없는 스텝 목록 표시
3. 선택한 스텝을 어느 위치에 추가할지 선택

#### 스텝 제거

1. 현재 config의 스텝 목록 표시
2. 제거할 스텝 선택
3. **경고**: 스텝 폴더는 삭제하지 않음 (나중에 다시 추가 가능)

#### 순서 변경

1. 현재 순서 표시
2. 새 순서 입력 또는 드래그앤드롭 스타일 재배치

### 6. Setting: hooks

```
🪝 Global Hooks

현재:
  pre-step:  (없음)
  post-step: (없음)

? 어떤 훅을 설정하시겠습니까?
  [ ] pre-step - 모든 스텝 실행 전
  [ ] post-step - 모든 스텝 실행 후
```

사용 가능한 훅 타입:
- `agent:{agent-name}` - siat 에이전트 실행
- `skill:{skill-name}` - 스킬 실행

### 7. Setting: name

```
📛 Workflow Name

현재: blacksmith

새 이름을 입력하세요:
```

### 8. Apply Changes

변경 사항 적용:

1. config.yml 읽기
2. 해당 필드 수정
3. config.yml 쓰기 (Edit 사용)
4. 변경 확인 메시지

```
✅ 설정이 변경되었습니다.

변경 사항:
  output.path: .claude/siat/specs → .claude/siat/outputs

→ /siat:status 로 전체 설정 확인
```

## Direct Setting (인자로 직접 변경)

### 값만 확인

```
/siat:config output.path

📁 output.path: .claude/siat/specs
```

### 값 변경

```
/siat:config mode auto

✅ execution.mode: manual → auto
```

지원하는 direct 설정:
- `mode {manual|auto}` - 실행 모드
- `output.path {path}` - 출력 경로
- `name {name}` - 워크플로우 이름

복잡한 설정 (steps, hooks)은 인터랙티브 모드 필요.

## Important

- 설정 변경은 `.claude/siat/config.yml`만 수정
- 스텝 정의 (instruction.md, spec.md)는 직접 수정 필요
- 스텝별 hooks는 각 스텝의 instruction.md 프론트매터에서 수정
