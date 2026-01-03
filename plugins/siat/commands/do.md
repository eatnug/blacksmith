---
description: Execute Siat workflow - guides through customizable steps with hooks
argument-hint: "[--auto] [step] [task-slug|request]"
---

# Siat Workflow Orchestrator

You are a lightweight orchestrator for siat workflows.

## Arguments

`$ARGUMENTS` contains the user input. Parse it:

1. `--auto` flag → force auto mode (override config)
2. First word matches a step → execute that step
3. Second word matches existing task slug → continue that task
4. No step specified → use navigator to find next step
5. Remaining text → the request (for new tasks)

Examples:
- `/siat:do` → navigate to find incomplete tasks
- `/siat:do plan 헤더 만들어줘` → new task, execute plan step
- `/siat:do implement create-header` → continue existing task
- `/siat:do --auto implement create-login` → continue in auto mode

## Execution Flow

### 1. Setup Check

If `.claude/siat/` doesn't exist, tell user to run `/siat:init` first.

### 2. Read Config

Read `.claude/siat/config.yml`:
- `steps`: workflow step order
- `output.path`: where specs are saved
- `execution.mode`: "manual" or "auto"
- `hooks.pre-step`: hooks to run before step
- `hooks.post-step`: hooks to run after step

### 3. Determine Execution Mode

```
if --auto flag:
    mode = "auto"
else:
    mode = config.execution.mode (default: "manual")
```

### 4. Resolve Step

If no step specified in arguments:
- Run `Task(siat-navigator)` to find next step
- Present options to user with AskUserQuestion
- Wait for selection

If step specified:
- Validate step exists in `.claude/siat/steps/{step}/`

### 5. Merge Hooks

Read step-specific hooks from `.claude/siat/steps/{step}/instruction.md` frontmatter:

```yaml
---
name: implement
hooks:
  post-step:
    - agent:siat-gh-pr-creator
---
```

Combine config hooks with step-specific hooks (extend, not override):

```
final_hooks.pre-step = config.hooks.pre-step + step.hooks.pre-step
final_hooks.post-step = config.hooks.post-step + step.hooks.post-step
```

Global hooks run first, then step-specific hooks.

### 6. Execute Pre-Step Hooks

If `final_hooks.pre-step` is not empty:

```
Task(siat-hook-runner, {
    hooks: final_hooks.pre-step,
    step: step_name,
    request: user_request
})
```

### 7. Execute Step

**If mode == "auto":**

```
Task(siat-step-executor, {
    step: step_name,
    task: task_slug,
    request: user_request,
    output_path: config.output.path
})
```

**If mode == "manual":**

Execute step directly in main context:
1. Read `.claude/siat/steps/{step}/instruction.md`
2. Follow instructions
3. Save output using spec.md template

### 8. Execute Post-Step Hooks

If `final_hooks.post-step` is not empty:

```
Task(siat-hook-runner, {
    hooks: final_hooks.post-step,
    step: step_name,
    result: step_output
})
```

### 9. Report Next Steps

Tell user:
- What was completed
- Next step in workflow (if any)
- How to continue

## Example Interactions

### No arguments (navigate)

```
User: /siat:do

Claude: [Task(siat-navigator)]

📋 진행 중인 태스크:

1. create-header
   ✅ plan
   ⬚ implement

[AskUserQuestion]
- create-header → implement 진행
- 새 태스크 시작
```

### With step (manual mode)

```
User: /siat:do plan 로그인 기능

Claude: [pre-step hooks via Task(siat-hook-runner)]
        [execute plan step in main context]
        [post-step hooks via Task(siat-hook-runner)]

        ✅ plan.md 저장 완료

        다음: implement
```

### With --auto flag

```
User: /siat:do --auto plan 로그인 기능

Claude: [pre-step hooks via Task(siat-hook-runner)]
        [Task(siat-step-executor) - isolated]
        [post-step hooks via Task(siat-hook-runner)]

        ✅ plan.md 저장 완료 (auto 모드)

        Summary:
        - JWT 인증 방식 선택
        - 3개 파일 수정 예정

        다음: implement
```

## Important

- Keep orchestration lightweight
- Delegate to agents via Task tool
- Hooks always run via siat-hook-runner (isolated)
- Step execution depends on mode
