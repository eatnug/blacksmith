---
name: split
description: Break down complex tasks into small, focused subtasks. Use when facing large features, refactoring, or any task that could go wrong if attempted all at once. Reduces errors and makes progress trackable.
---

# Split

## Purpose

Large tasks are error-prone. By breaking them into small, well-defined pieces, each step becomes:
- Easier to verify
- Less likely to introduce bugs
- Recoverable if something goes wrong
- Trackable for progress

## When to Use

- Task involves multiple files or components
- Implementation has several distinct phases
- Risk of breaking existing functionality
- Task could take more than a few minutes
- Multiple approaches need to be evaluated
- Changes have dependencies on each other

## Instructions

### Step 1: Understand the Full Scope

Before splitting, understand the complete task:

1. **Read relevant code** - Don't plan blindly
2. **Identify all affected areas** - Files, functions, tests
3. **Map dependencies** - What must happen before what?
4. **Note integration points** - Where pieces connect

### Step 2: Identify Natural Boundaries

Split along these lines:

1. **By layer**: Database -> API -> UI
2. **By feature**: Core logic -> Edge cases -> Error handling
3. **By file/component**: One component at a time
4. **By operation**: Read -> Transform -> Write
5. **By risk**: Safe changes first, risky changes last

### Step 3: Create Atomic Subtasks

Each subtask should be:

- **Independent**: Completable without other pending subtasks
- **Verifiable**: Can confirm it works before moving on
- **Small**: 5-15 minutes of focused work
- **Specific**: Clear what "done" looks like

Good subtask:
"Add email validation to the signup form's email field"

Bad subtask:
"Improve form validation" (too vague, scope unclear)

### Step 4: Order by Dependencies and Risk

Arrange subtasks so that:
1. Prerequisites come before dependents
2. Foundation work comes before features
3. Low-risk changes come before high-risk ones
4. Reversible changes come before irreversible ones

### Step 5: Document the Plan

Use the todo list to track:
- Each subtask with clear description
- Current status (pending/in_progress/completed)
- Any blockers or notes discovered

### Step 6: Execute One at a Time

For each subtask:
1. Mark as in_progress
2. Focus only on that subtask
3. Verify it works
4. Mark as completed
5. Move to next

Do NOT:
- Work on multiple subtasks simultaneously
- Skip verification steps
- Change scope mid-subtask

## Splitting Strategies by Task Type

### New Feature
1. Design data structures/interfaces
2. Implement core logic (happy path)
3. Add input validation
4. Add error handling
5. Add edge cases
6. Add tests
7. Update documentation (if needed)

### Bug Fix
1. Reproduce the bug
2. Identify root cause
3. Write failing test
4. Implement fix
5. Verify test passes
6. Check for similar bugs elsewhere

### Refactoring
1. Ensure tests exist (add if missing)
2. Make one structural change
3. Verify tests still pass
4. Repeat until done

### Migration
1. Add new alongside old
2. Update consumers one by one
3. Verify each consumer works
4. Remove old code
5. Clean up

## Example

Task: "Add user profile picture upload"

Split into:
1. Add `profilePictureUrl` field to user model/schema
2. Create file upload API endpoint (accepts image, returns URL)
3. Add image validation (size, type, dimensions)
4. Create storage integration (S3/local/etc)
5. Add upload UI component with preview
6. Connect UI to API endpoint
7. Display profile picture in existing UI locations
8. Add error handling for upload failures
9. Add tests for upload flow

## Anti-patterns to Avoid

- **Over-splitting**: Don't create 50 subtasks for a simple feature
- **Under-splitting**: Don't have subtasks that take hours
- **Vague subtasks**: "Do the backend stuff" is not specific
- **Ignoring dependencies**: Don't plan to build UI before API exists
- **Rigid adherence**: Adjust the plan if you learn new information
