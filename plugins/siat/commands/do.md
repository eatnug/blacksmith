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
3. If contains `#N` pattern (e.g., `#42`) → GitHub Issue/PR reference
4. Otherwise → start from first step with entire input as request

### GitHub Reference Parsing

Arguments may contain GitHub references:
- `#42` → Issue number 42
- `plan #42` → Execute plan step with Issue #42 as input
- `#42 implement` → Resume from implement step for Issue #42

## Execution Flow

1. **Check Setup**
   - If `.claude/siat/` doesn't exist, tell the user to run `/siat:init` first

2. **Read Config**
   - Read `.claude/siat/config.yml` to get the workflow steps order and output path
   - Check for `sources` section for GitHub integration settings

3. **Check gh CLI (if GitHub sources configured)**

   If the step's `input.type` or `output.type` uses GitHub:

   ```bash
   # Check if gh is installed
   which gh

   # If installed, check authentication
   gh auth status
   ```

   - If `gh` not found: warn and use `fallback` type (default: `manual`)
   - If `gh` not authenticated: warn with `gh auth login` instruction and use fallback

4. **Determine What To Do**

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

5. **Execute Step** (only after user selection)

   a. Read `.claude/siat/steps/{step}/instruction.md`

   b. **Process Input Source** (from instruction.md `input` or config.yml `sources.defaults`)

   | input.type | Action |
   |------------|--------|
   | `manual` | Use request text as input (default) |
   | `file` | Read `{output.path}/{task-slug}/{input.source}.md` |
   | `github-issue` | Run `gh issue view {number} --json title,body,labels,comments` |
   | `github-pr` | Run `gh pr view {number} --json title,body,files` |

   c. **Create/Update .task.yml** (context file)

   ```yaml
   # {output.path}/{task-slug}/.task.yml
   task:
     slug: "task-slug"
     title: "Task Title"
   context:
     github:
       issue_number: 42  # if from github-issue
       issue_title: "Issue Title"
   steps:
     plan:
       status: "in_progress"
   ```

   d. Follow the instructions in instruction.md
   e. Use `.claude/siat/steps/{step}/spec.md` as output template

6. **Handle Approval**
   - If the step requires approval (check instruction.md frontmatter), pause and ask user
   - If approved, proceed to save and output

7. **Process Output Sink** (from instruction.md `output`)

   | output.type | Action |
   |-------------|--------|
   | `file` | Save to `{output.path}/{task-slug}/{step}.md` (default) |
   | `github-pr` | Create PR with `gh pr create --title "..." --body "..."` |
   | `github-issue-comment` | Add comment with `gh issue comment {number} --body "..."` |

   For `github-pr` with `link_issue: true`:
   - Read `.task.yml` for `context.github.issue_number`
   - Add `Fixes #{number}` to PR body

   Process `output.also` array for additional outputs.

8. **Update .task.yml**
   - Mark step as `completed`
   - Store PR URL if created

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

### GitHub Integration Examples

```
User: /siat:do plan #42

Claude:
[gh 가용성 확인]
[gh issue view 42 --json title,body,labels 실행]

Issue #42: "Add user authentication"
- 요청: OAuth 로그인 기능 추가
- 라벨: feature, priority-high

[Issue 내용을 분석하여 plan 작성]
[.task.yml에 issue_number: 42 저장]
```

```
User: /siat:do implement
(이전에 #42 Issue로 plan을 진행한 경우)

Claude:
[.task.yml에서 context.github.issue_number 확인: 42]
[plan.md 읽어서 구현 진행]
[output.type이 github-pr인 경우:]

구현 완료. PR을 생성할까요?
[gh pr create --title "Add user authentication" --body "... Fixes #42"]
```

### Error Handling Examples

```
User: /siat:do plan #42
(gh가 설치되지 않은 경우)

Claude:
⚠️ gh CLI가 설치되어 있지 않습니다.
GitHub Issue를 직접 가져올 수 없어 manual 모드로 전환합니다.

Issue #42의 내용을 직접 입력해주세요:
```

```
User: /siat:do plan #42
(gh가 인증되지 않은 경우)

Claude:
⚠️ gh CLI가 인증되지 않았습니다.
`gh auth login` 명령을 실행하여 인증해주세요.

manual 모드로 전환합니다. Issue #42의 내용을 직접 입력해주세요:
```
