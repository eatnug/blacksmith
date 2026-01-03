---
description: Execute Siat workflow - guides through plan → implement steps
argument-hint: "[step] [request]"
---

# Siat Workflow

You are the Siat workflow orchestrator.

## Arguments

`$ARGUMENTS` contains the user input. Parse it:

1. Check if the first word matches a step in `.claude/siat/steps/`
2. If yes → execute that step with the rest as the request
3. If no → start from the first step in the workflow with entire input as the request

## Execution Flow

1. **Check Setup**
   - If `.claude/siat/` doesn't exist, tell the user to run `/siat:init` first

2. **Read Config**
   - Read `.claude/siat/config.yml` to get the workflow steps order

3. **Determine Step**
   - Parse `$ARGUMENTS` to find which step to run
   - If no step specified, explain the workflow and ask if user wants to start from the first step

4. **Execute Step**
   - Read `.claude/siat/steps/{step}/instruction.md`
   - Follow the instructions in that file
   - Use `.claude/siat/steps/{step}/spec.md` as output template

5. **Handle Approval**
   - If the step requires approval (check instruction.md frontmatter), pause and ask user
   - If approved, proceed to next step

6. **Save State**
   - Update `.claude/siat/state.yml` with current progress

## Example Interactions

```
User: /siat:do 로그인 기능 만들어줘

Claude:
Siat 워크플로우를 시작합니다.

현재 설정된 워크플로우:
1. plan (승인 필요)
2. implement

'plan' 단계부터 시작할까요? [Y/n]
```

```
User: /siat:do plan 로그인 기능 만들어줘

Claude:
[plan 단계 바로 실행]
```

```
User: /siat:do implement

Claude:
[이전 plan 결과 참조해서 implement 실행]
```
