# Perfect SDD - Quick Reference

> **4-step workflow: Requirements + code exploration happen organically**

---

## The Flow

```
CLARIFY → DESIGN → IMPLEMENT → VERIFY
 (≤250)    (≤250)    (≤150)      (≤150)
```

**Total context**: ~800 lines max (concise and focused)

---

## At a Glance

| Step | Role | Interactive | Purpose | Output |
|------|------|-------------|---------|--------|
| **CLARIFY** | Product Analyst + Archaeologist | **YES** | Requirements + code exploration together | Requirements, current state, patterns |
| **DESIGN** | Architect | No | Plan the solution | Approach, tasks, risks |
| **IMPLEMENT** | Engineer | No | Build it | Code, tests, verification |
| **VERIFY** | QA/Reviewer | No | Quality gate | APPROVE/REVISE/REJECT |

---

## Step Cheat Sheets

### 1. CLARIFY

**Mission**: Understand WHAT to build AND WHERE it fits - organically

**Process**:
```
1. Get user request
2. Explore relevant code
3. Ask informed question (based on code)
4. Get answer
5. Explore more based on answer
6. Repeat until clear
```

**Do**:
- ✅ Explore code WHILE asking questions
- ✅ Ask questions informed by code findings
- ✅ Make requirements testable
- ✅ Document both requirements AND current state

**Don't**:
- ❌ Get all requirements first, then explore
- ❌ Ask questions you could answer by reading code
- ❌ Jump to solutions
- ❌ Leave ambiguity

**Output**: `clarify.md` (≤250 lines)

**Key Sections**:
- Problem (2-3 sentences)
- Requirements (with acceptance criteria)
- Scope (in/out)
- Success Criteria
- Current Architecture
- Patterns & Constraints
- Key Insights

**Example Flow**:
```
User: "Add quantity control"
→ You: (explore) "Found CartItem..."
→ You: "Should there be max?" (saw item.stock)
→ User: "Yes, use stock"
→ You: (explore) "Stock is in item.stock"
→ Continue...
```

---

### 2. DESIGN

**Mission**: Plan HOW to move from current to target state

**Do**:
- ✅ Analyze gap explicitly
- ✅ Evaluate 2-3 options
- ✅ Make clear decision with rationale
- ✅ Create ordered tasks
- ✅ Identify risks

**Don't**:
- ❌ Write actual code
- ❌ Make product decisions
- ❌ Leave decisions ambiguous

**Output**: `design.md` (≤250 lines)

**Key Sections**:
- Gap Analysis
- Solution Options
- Decision (with rationale)
- Architecture (components)
- Implementation Plan
- Risks

---

### 3. IMPLEMENT

**Mission**: Build working, tested code per the design

**Do**:
- ✅ Follow design plan exactly
- ✅ Write tests
- ✅ Document deviations
- ✅ Verify acceptance criteria

**Don't**:
- ❌ Skip tests
- ❌ Deviate silently
- ❌ Leave debug code

**Output**: `implement.md` (≤150 lines)

**Key Sections**:
- Files Changed
- Task Completion
- Key Decisions
- Deviations (if any)
- Requirements Verification
- Testing

---

### 4. VERIFY

**Mission**: Final validation before shipping

**Do**:
- ✅ Read all prior specs
- ✅ Verify every requirement
- ✅ Review code quality
- ✅ Make clear decision

**Don't**:
- ❌ Approve without reading code
- ❌ Reject for style preferences
- ❌ Be vague

**Output**: `verify.md` (≤150 lines)

**Key Sections**:
- Requirements Verification
- Code Quality
- Issues Found (by severity)
- Testing Verification
- Verdict (APPROVE/REVISE/REJECT)

---

## Why CLARIFY Combines Both

### The Problem

❌ **Linear doesn't work**:
```
1. Get requirements (without seeing code)
   → Questions are generic, uninformed
2. Then explore code
   → "Oh, this already exists!"
   → "Oh, we can't do that!"
   → Back to step 1...
```

### The Solution

✅ **Organic exploration**:
```
1. Get basic request
2. Explore code
3. Ask informed question
4. Get answer
5. Explore more
6. Repeat...
```

**Benefits**:
- Smarter questions (based on actual code)
- Faster convergence (no back-and-forth)
- Better requirements (informed by reality)
- Clear understanding (both what and where)

---

## Common Patterns

### CLARIFY: Iterative Flow

```
User: "Add feature X"
↓
You: (quick explore) "Found area Y..."
↓
You: "Should this be A or B?" (informed by seeing Y)
↓
User: "B"
↓
You: (explore more) "B uses pattern C..."
↓
You: "Should we follow pattern C?" (informed question)
↓
User: "Yes"
↓
Result: REQ-001 + Pattern C constraint
```

### DESIGN: Making Decisions

```markdown
## Decision

**Selected**: Option A

**Rationale**: Follows existing patterns, more maintainable

**Trade-offs**: Slightly more files, but clearer separation
```

### IMPLEMENT: Documenting Deviations

```markdown
## Deviations

### DEV-001: Used different approach

- **Plan**: Use POST /api/update
- **Actual**: Used PATCH /api/:id
- **Reason**: POST deprecated
- **Impact**: None - same result
```

### VERIFY: Reporting Issues

```markdown
## Issues Found

### Critical

**CRIT-001**: No input validation
- **Location**: `form.ts:45`
- **Fix**: Add validateInput() from utils
```

---

## Spec Minimalism Rules

### ✅ Include

- Critical facts only
- Decisions with rationale
- Actionable items
- Explicit unknowns

### ❌ Exclude

- Examples/tutorials
- Repeated info
- "Nice to have" sections
- Storytelling

### Format

- **Use**: Bullets, tables, checklists
- **Avoid**: Prose paragraphs
- **Goal**: Scannable in < 1 minute

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| CLARIFY: Don't know what to explore | Start with general area, narrow down as you learn |
| CLARIFY: User gives vague answer | Show them code, ask specific question |
| DESIGN: Multiple options seem equal | Pick one, document rationale |
| IMPLEMENT: Design unclear | Document decision, flag for review |
| VERIFY: Not sure if critical | Err on side of caution, mark critical |
| Spec too long | Cut fluff. Every line must earn its place. |

---

## Success Metrics

**You're doing it right if**:
- ✅ CLARIFY produces clear requirements + current state understanding
- ✅ Questions in CLARIFY are informed by code
- ✅ DESIGN has all context needed (no exploration required)
- ✅ IMPLEMENT is mechanical (no architectural decisions)
- ✅ VERIFY finds few issues
- ✅ All specs under line limits

**You're doing it wrong if**:
- ❌ CLARIFY gets requirements without exploring code
- ❌ Questions are generic/uninformed
- ❌ DESIGN has to explore code or make product decisions
- ❌ IMPLEMENT has to make architecture decisions
- ❌ VERIFY finds critical issues
- ❌ Multiple REVISE cycles needed

---

## Workflow Comparison

| Aspect | Old (5 steps) | New (4 steps) |
|--------|---------------|---------------|
| **Steps** | DISCOVER → SPECIFY → ... | **CLARIFY** → ... |
| **Process** | Sequential | Iterative |
| **Questions** | Blind | Informed by code |
| **Context** | ~900 lines | ~800 lines |
| **Reality Match** | Artificial | Natural |

---

## One-Liners

- **CLARIFY**: "Explore and clarify together, iteratively"
- **DESIGN**: "Plan the gap bridge with precision"
- **IMPLEMENT**: "Execute the plan with quality"
- **VERIFY**: "Validate before you ship"

---

**Perfect SDD**: The workflow that matches how you actually work.
