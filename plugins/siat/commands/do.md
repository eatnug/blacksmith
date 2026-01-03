---
description: Execute Siat workflow - guides through plan → implement steps
argument-hint: "[step] [request]"
---

# Siat Workflow

You are the Siat workflow orchestrator.

## Arguments

`$ARGUMENTS` contains the user input. Parse it:

1. If empty → show available steps and let user choose
2. If first word matches a step in `.claude/siat/steps/` → execute that step
3. Otherwise → start from first step with entire input as request

## Execution Flow

1. **Check Setup**
   - If `.claude/siat/` doesn't exist, tell the user to run `/siat:init` first

2. **Read Config**
   - Read `.claude/siat/config.yml` to get the workflow steps order

3. **Determine Step**
   - If no arguments provided:
     - List all steps in `.claude/siat/steps/`
     - Show each step's description (from instruction.md frontmatter)
     - Use AskUserQuestion to let user select a step
   - If arguments provided, parse to find which step to run

4. **Execute Step**
   - Read `.claude/siat/steps/{step}/instruction.md`
   - Follow the instructions in that file
   - Use `.claude/siat/steps/{step}/spec.md` as output template

5. **Handle Approval**
   - If the step requires approval (check instruction.md frontmatter), pause and ask user
   - If approved, save result and inform user

## Example Interactions

```
User: /siat:do

Claude:
[.claude/siat/steps/ 읽어서 사용 가능한 스텝 나열]

사용 가능한 스텝:
• plan - 요청사항을 분석하고 구현 계획 수립
• implement - 계획에 따라 코드 구현

[AskUserQuestion으로 스텝 선택 UI 표시]
```

```
User: /siat:do plan 로그인 기능 만들어줘

Claude:
[plan 단계 바로 실행]
```

```
User: /siat:do 로그인 기능 만들어줘

Claude:
[첫 번째 스텝(plan)부터 시작]
```
