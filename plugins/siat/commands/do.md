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
4. No step specified → start from first step (clarify)
5. Remaining text → the request (for new tasks)

Examples:
- `/siat:do 헤더 만들어줘` → new task, start from clarify
- `/siat:do implement create-header` → continue existing task
- `/siat:do --auto implement create-login` → continue in auto mode

## Execution Flow

### 1. Read Config

Read `.claude/siat/config.yml`.

**If file not found:** Tell user to run `/siat:init` and stop.

Extract:
- `workflow.steps`: step order
- `workflow.skip_key`: key to read skip list from (default: "skip")
- `output.path`: where specs are saved
- `execution.mode`: "manual" or "auto"
- `hooks.pre-step`: hooks to run before step
- `hooks.post-step`: hooks to run after step

### 2. Initialize Context State

Maintain these in your context during workflow execution:

```
state = {
    skip: [],           # steps to skip
    completed: [],      # completed steps
    current_step: null  # current step
}
```

### 3. Read Constitution

If `.claude/siat/constitution.md` exists, read it. These are global principles that apply to ALL steps.

### 4. Determine Mode

```
if --auto flag:
    mode = "auto"
else:
    mode = config.execution.mode (default: "manual")
```

### 5. Execute Steps

Iterate through `workflow.steps` in order:

```
for step in workflow.steps:
    # Skip check
    if step in state.skip:
        print "⏭️ Skipping {step}"
        continue

    # Check requires (from step frontmatter)
    step_config = read steps/{step}/instruction.md frontmatter
    if step_config.requires:
        for required in step_config.requires:
            if required not in state.completed:
                # Run required step first
                execute(required)

    # Execute step
    execute(step)

    # Update state
    state.completed.append(step)

    # Read step output and update skip list
    step_output = read step's spec.md output
    if step_output has skip_key:
        state.skip.extend(step_output[skip_key])
```

### 6. Execute Single Step

#### 6.1 Merge Hooks

Read step-specific hooks from frontmatter:

```yaml
---
name: implement
requires: [spec, design]  # prerequisite steps
hooks:
  post-step:
    - agent:siat-gh-pr-creator
---
```

Combine: `final_hooks = config.hooks + step.hooks`

#### 6.2 Pre-Step Hooks

If `final_hooks.pre-step` is not empty:

```
Task(siat-hook-runner, {
    hooks: final_hooks.pre-step,
    step: step_name,
    request: user_request
})
```

#### 6.3 Execute

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
3. Save output to spec.md

#### 6.4 Post-Step Hooks

If `final_hooks.post-step` is not empty:

```
Task(siat-hook-runner, {
    hooks: final_hooks.post-step,
    step: step_name,
    result: step_output
})
```

### 7. Report

After each step (manual mode) or workflow completion (auto mode):
- What was completed
- What was skipped
- Next step (if any)
- How to continue

## Skip List Behavior

The skip list is **cumulative**:
- Starts empty
- After clarify runs, its output may contain skip list
- Any step can add to skip list via output
- Once a step is in skip list, it stays skipped

Example flow:
```
1. clarify runs → outputs skip: [reproduce, root-cause, fix]
2. state.skip = [reproduce, root-cause, fix]
3. reproduce → SKIPPED
4. root-cause → SKIPPED
5. spec runs → no skip output
6. design runs → no skip output
7. implement runs
8. fix → SKIPPED
9. verify runs
```

## Important

- Keep orchestration lightweight
- Delegate to agents via Task tool
- Maintain skip list in context (not file)
- Check `requires` before running each step
- Hooks always run via siat-hook-runner (isolated)
