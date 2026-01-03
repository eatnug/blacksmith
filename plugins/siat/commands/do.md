---
description: Execute Siat workflow - guides through plan → implement steps
argument-hint: "[step] [request]"
---

# Siat Workflow

You are the Siat workflow orchestrator.

## Arguments

`$ARGUMENTS` contains the user input. Parse it:

1. If empty → show incomplete tasks and let user choose (DO NOT auto-execute)
2. If first word matches a step in `.claude/siat/steps/` → execute that step
3. Otherwise → start from first step with entire input as request

## Execution Flow

1. **Check Setup**
   - If `.claude/siat/` doesn't exist, tell the user to run `/siat:init` first

2. **Read Config**
   - Read `.claude/siat/config.yml` to get the workflow steps order and output path

3. **Determine What To Do**

   **If no arguments provided:**
   - Scan `{output.path}/` (default: `.claude/siat/specs/`) for existing task folders
   - For each task folder, check which steps are completed (has `{step}.md` file)
   - Find incomplete tasks (tasks that haven't completed all steps in config.yml)
   - **IMPORTANT: DO NOT automatically execute anything. Only show information.**

   Display format:
   ```
   📋 진행 중인 태스크:

   1. create-header
      ✅ plan (완료)
      ⬚ implement (미완료)

   2. add-login
      ✅ plan (완료)
      ⬚ implement (미완료)
   ```

   Then use AskUserQuestion with options:
   - Each incomplete task as an option (e.g., "create-header → implement 진행")
   - "새 태스크 시작" option

   **Wait for user selection. Do not proceed until user chooses.**

   **If arguments provided:**
   - Parse to find which step/task to run

4. **Execute Step** (only after user selection)
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
[specs 폴더 스캔하여 미완료 태스크 확인]

📋 진행 중인 태스크:

1. create-header
   ✅ plan (완료)
   ⬚ implement (미완료)

2. add-login
   ✅ plan (완료)
   ⬚ implement (미완료)

[AskUserQuestion으로 선택 UI 표시]
- create-header → implement 진행
- add-login → implement 진행
- 새 태스크 시작

[사용자가 선택할 때까지 대기. 절대 자동 실행하지 않음]
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
