---
name: forge
description: Detect recurring tasks and patterns in the session, then create a new skill to automate them. Use when noticing repeated workflows, common requests, or patterns that could become reusable skills.
---

# Forge

## Purpose

Identify recurring tasks, workflows, or patterns and forge them into reusable skills. This meta-skill helps build your personal toolkit by recognizing automation opportunities.

## When to Use

- Same type of request appears multiple times
- User has a consistent workflow they repeat
- A complex task could be templated
- User explicitly asks to create a skill from recent work
- Noticing "I do this a lot" moments

## Instructions

### Step 1: Detect Patterns

Analyze the session for recurring elements:

**Task Patterns**
- Similar requests with different targets (e.g., "format this file", "format that file")
- Multi-step workflows repeated with variations
- Boilerplate code generation requests
- Common debugging sequences

**Workflow Patterns**
- Consistent order of operations
- Same tools used in sequence
- Repeated verification steps
- Standard pre/post task actions

**Domain Patterns**
- Project-specific conventions
- Team coding standards
- Preferred libraries or approaches
- Common edge cases to handle

### Step 2: Evaluate Skill Potential

Not every pattern deserves a skill. Evaluate:

**Good Skill Candidates**
- Performed 3+ times with same structure
- Has clear inputs and outputs
- Takes multiple steps that are easy to forget
- Has specific quality criteria
- Involves domain knowledge that's easy to miss

**Poor Skill Candidates**
- One-off tasks unlikely to recur
- Trivial operations (single command)
- Highly variable tasks with no consistent structure
- Tasks requiring extensive human judgment

### Step 3: Extract the Pattern

Define the skill structure:

1. **Name**: Short, descriptive, action-oriented
   - Good: `create-api-endpoint`, `setup-test-file`, `review-pr`
   - Bad: `thing`, `helper`, `misc`

2. **Trigger**: When should this skill activate?
   - Keywords users would say
   - Situations that call for this skill
   - File types or contexts

3. **Inputs**: What varies between uses?
   - File paths, names, values
   - Configuration options
   - Scope (single file vs. project-wide)

4. **Steps**: What's the consistent process?
   - Required actions in order
   - Decision points and branches
   - Verification checkpoints

5. **Outputs**: What's produced?
   - Files created/modified
   - Information gathered
   - State changes

### Step 4: Draft the Skill

Create the SKILL.md content:

```markdown
---
name: [skill-name]
description: [What it does. When to use it. Keywords that trigger it.]
---

# [Skill Title]

## Purpose
[Why this skill exists, what problem it solves]

## When to Use
[Specific situations, trigger phrases, contexts]

## Inputs
[What the user provides or what varies]

## Instructions
[Step-by-step process with clear actions]

## Examples
[Concrete examples of using this skill]

## Notes
[Edge cases, limitations, related skills]
```

### Step 5: Confirm with User

Before creating, present:
- Detected pattern summary
- Proposed skill name and description
- Key steps the skill will perform
- Where the skill will be saved

Ask:
- "Does this capture the workflow correctly?"
- "Any steps to add or remove?"
- "What should this skill be called?"
- "Save to personal (~/.claude/skills/) or project (.claude/skills/)?"

### Step 6: Create the Skill

After confirmation:

1. Create the skill directory:
   ```bash
   mkdir -p [location]/[skill-name]
   ```

2. Write the SKILL.md file

3. Verify creation:
   ```bash
   cat [location]/[skill-name]/SKILL.md
   ```

4. Inform user to restart Claude Code

### Step 7: Document the Skill

Provide the user with:
- How to invoke: `/skill-name` or `/namespace:skill-name`
- Example usage scenarios
- How to modify if needed

## Pattern Detection Checklist

Look for these signals:

- [ ] "Can you do that same thing for..."
- [ ] "Like we did before..."
- [ ] "The usual..."
- [ ] Same sequence of tool calls repeated
- [ ] Similar file modifications multiple times
- [ ] Consistent validation/verification steps
- [ ] User correcting the same type of mistake
- [ ] Boilerplate with variable parts

## Example: Detecting and Forging

**Observed Pattern** (over several requests):
1. User asks to add a new API endpoint
2. I create route file in `/routes`
3. I add controller in `/controllers`
4. I add service in `/services`
5. I update route index
6. I add basic tests

**Forge Analysis**:
- Recurring: Yes (3+ times)
- Consistent structure: Yes
- Clear inputs: endpoint name, HTTP method, resource
- Multiple steps: Yes (6 steps)
- Easy to miss steps: Yes (updating index, adding tests)

**Proposed Skill**:
```markdown
---
name: create-api-endpoint
description: Scaffold a new API endpoint with route, controller, service, and tests. Use when adding new endpoints or when user mentions "new endpoint", "add API", "create route".
---

# Create API Endpoint

## Inputs
- Endpoint name (e.g., "users", "products")
- HTTP methods needed (GET, POST, PUT, DELETE)
- Resource/entity it operates on

## Instructions
1. Create route file: `/routes/[name].js`
2. Create controller: `/controllers/[name]Controller.js`
3. Create service: `/services/[name]Service.js`
4. Add route to `/routes/index.js`
5. Create test file: `/tests/[name].test.js`
6. Verify all imports resolve

## Template
[Include boilerplate code templates]
```

**Confirm with user before creating.**

## Anti-patterns to Avoid

- **Over-generalizing**: Don't create one mega-skill; prefer focused skills
- **Premature optimization**: Wait for 3+ occurrences before forging
- **Missing context**: Include why steps matter, not just what to do
- **Rigid templates**: Allow for variation in inputs
- **Skipping confirmation**: Always verify with user before creating
