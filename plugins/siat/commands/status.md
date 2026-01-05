---
description: Show Siat workflow status - current config, steps, hooks, and tasks
argument-hint: "[--verbose]"
---

# Siat Status

현재 워크플로우 설정과 진행 상황을 보여줍니다.

## Arguments

`$ARGUMENTS` 파싱:
- `--verbose` 또는 `-v` → 상세 정보 표시 (각 스텝의 hooks, 템플릿 정보 포함)
- 없으면 → 요약 정보만

## Execution

### 1. Setup Check

```
Required:
- .claude/siat/config.yml
- .claude/siat/steps/
```

**If not set up:**

```
⚠️ Siat이 설정되지 않았습니다.

→ /siat:init 으로 설정을 시작하세요.
```

### 2. Read & Display Config

`.claude/siat/config.yml` 읽고 표시:

```
📋 Siat Workflow Status
━━━━━━━━━━━━━━━━━━━━━━

Workflow: {name}
Description: {description}

Steps: {step1} → {step2} → {step3}
Mode: {execution.mode}
Output: {output.path}
```

### 3. Global Hooks

config의 글로벌 hooks 표시:

```
Global Hooks:
  pre-step:  {hooks.pre-step || "(없음)"}
  post-step: {hooks.post-step || "(없음)"}
```

### 4. Constitution

`.claude/siat/constitution.md` 존재 여부:

```
Constitution: ✅ 설정됨 / ⬚ 없음
```

### 5. Step Details (--verbose 시)

`--verbose` 플래그가 있으면 각 스텝의 상세 정보:

```
Steps:
━━━━━

1. spec
   Description: {description from frontmatter}
   Hooks:
     post-step: agent:siat-gh-issue-creator
   Template: spec.md ✅

2. design
   Description: {description}
   Hooks:
     post-step: agent:siat-gh-issue-creator
   Template: spec.md ✅

3. implement
   Description: {description}
   Hooks:
     post-step: agent:siat-gh-pr-creator
   Template: spec.md ✅
```

### 6. Tasks Overview

`{output.path}` 폴더의 태스크들 스캔:

```
Tasks:
━━━━━

Total: {n}개

진행 중:
  • create-header    [spec ✅ → design ✅ → implement ⬚]
  • login-feature    [spec ✅ → design ⬚]

완료:
  • user-profile     [spec ✅ → design ✅ → implement ✅]
```

각 태스크 폴더를 검사해서:
- 어떤 spec 파일이 있는지 확인
- workflow steps 기준으로 진행 상황 표시

### 7. Quick Actions

```
Quick Actions:
━━━━━━━━━━━━━

→ /siat:do                    다음 스텝 찾기
→ /siat:do {step} {task}      특정 태스크 계속
→ /siat:config                설정 변경
```

## Output Format

### Basic (default)

```
📋 Siat Workflow: blacksmith
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Steps:   spec → design → implement
Mode:    manual
Output:  .claude/siat/specs

Constitution: ✅

Tasks: 3개 (진행 중: 2, 완료: 1)
  • create-header    [spec ✅ design ✅ implement ⬚]
  • login-feature    [spec ✅ design ⬚]
  • user-profile     ✅ 완료

→ /siat:do 로 다음 스텝 진행
```

### Verbose (--verbose)

기본 출력 + 각 스텝의 hooks, description, 템플릿 정보

## Important

- 읽기 전용 커맨드 - 아무것도 수정하지 않음
- 설정 변경은 `/siat:config` 사용
