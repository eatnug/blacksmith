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

### 1. Setup Check (Lightweight)

Run ONE command to verify setup:

```bash
ls .claude/siat/
```

Check output:
- `config.yml` exists? ✓
- `steps/` folder exists? ✓

**If either missing:** Tell user to run `/siat:init` and stop.

**IMPORTANT:** Do NOT search for all step files. Just verify the folder exists.

### 2. Read Config

Read `.claude/siat/config.yml`:
- `steps`: workflow step order
- `output.path`: where specs are saved
- `execution.mode`: "manual" or "auto"
- `hooks.pre-step`: hooks to run before step
- `hooks.post-step`: hooks to run after step

### 2.5 Read Constitution

If `.claude/siat/constitution.md` exists, read it. These are global principles that apply to ALL steps:

- **불명확 처리 원칙**: 추측하지 말고 `[NEEDS CLARIFICATION: 질문]` 마커 사용
- **프로젝트 원칙**: 팀별 규칙

스텝 실행 시 이 원칙들을 준수해야 합니다.

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

## Important

- Keep orchestration lightweight
- Delegate to agents via Task tool
- Hooks always run via siat-hook-runner (isolated)
- Step execution depends on mode
