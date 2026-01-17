# Perfect SDD - Quick Reference

> **5-step workflow optimized for clarity, precision, and minimal LLM distraction**

---

## The Flow

```
DISCOVER → SPECIFY → DESIGN → IMPLEMENT → VERIFY
  (≤150)    (≤200)    (≤250)     (≤150)     (≤150)
```

**Total context**: ~900 lines max (vs ~1200+ in verbose workflows)

---

## At a Glance

| Step | Role | Interactive | Purpose | Output |
|------|------|-------------|---------|--------|
| **DISCOVER** | Software Archaeologist | No | Map current state | Current architecture, patterns, constraints, gaps |
| **SPECIFY** | Product Analyst | **YES** | Define target state | Requirements, scope, success criteria |
| **DESIGN** | Architect | No | Plan the gap bridge | Solution, tasks, risks |
| **IMPLEMENT** | Engineer | No | Build it | Code, tests, verification |
| **VERIFY** | QA/Reviewer | No | Quality gate | Verdict: APPROVE/REVISE/REJECT |

---

## Step Cheat Sheets

### 1. DISCOVER

**Mission**: Understand what EXISTS before planning what to BUILD

**Do**:
- ✅ Explore relevant codebase areas
- ✅ Document patterns and conventions
- ✅ List technical constraints
- ✅ Surface knowledge gaps explicitly

**Don't**:
- ❌ Make assumptions
- ❌ List every file
- ❌ Write prose

**Output**: `discover.md` (≤150 lines)

**Key Sections**:
- Current Architecture (components, patterns, tech stack)
- Constraints (technical, business)
- Knowledge Gaps (questions, unknowns)
- Key Insights (critical context for next step)

---

### 2. SPECIFY

**Mission**: Define WHAT we want to achieve and WHY

**Do**:
- ✅ Ask strategic questions to user
- ✅ Make requirements testable
- ✅ Set explicit scope boundaries
- ✅ Fill all knowledge gaps

**Don't**:
- ❌ Jump to solutions
- ❌ Leave ambiguity
- ❌ Include "nice to have" as requirements

**Output**: `specify.md` (≤200 lines)

**Key Sections**:
- Problem (2-3 sentences)
- Requirements (each with acceptance criteria)
- Scope (explicit in/out)
- Success Criteria (measurable)
- Constraints & Assumptions

**Interactive**: Uses AskUserQuestion to clarify

---

### 3. DESIGN

**Mission**: Plan HOW to move from current to target state

**Do**:
- ✅ Analyze gap explicitly
- ✅ Evaluate 2-3 options
- ✅ Make clear decision with rationale
- ✅ Create ordered implementation tasks
- ✅ Identify risks

**Don't**:
- ❌ Write actual code
- ❌ Make product decisions
- ❌ Leave decisions ambiguous

**Output**: `design.md` (≤250 lines)

**Key Sections**:
- Gap Analysis (current → target → delta)
- Solution Options (2-3 with pros/cons)
- Decision (which option + why)
- Architecture (components)
- Implementation Plan (ordered tasks)
- Risks (with mitigation)

---

### 4. IMPLEMENT

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
- Files Changed (created/modified/deleted)
- Task Completion (checklist)
- Key Decisions (important choices)
- Deviations (if any, with rationale)
- Requirements Verification (all checked)
- Testing (results)

---

### 5. VERIFY

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
- Requirements Verification (each checked)
- Code Quality (brief assessment)
- Issues Found (by severity: critical/major/minor)
- Testing Verification (adequate?)
- Verdict (APPROVE/REVISE/REJECT + reason)

**Decisions**:
- **APPROVE**: All requirements met, quality acceptable, no critical issues
- **REVISE**: Minor fixes needed, mostly good
- **REJECT**: Critical issues, major rework needed

---

## Spec Minimalism Rules

### ✅ Do Include

- Critical facts only
- Decisions with rationale
- Actionable items
- Explicit unknowns
- Key risks

### ❌ Don't Include

- Examples or tutorials
- Repeated information
- "Nice to have" sections
- Teaching content
- Storytelling

### Format

- **Use**: Bullets, tables, checklists
- **Avoid**: Prose paragraphs
- **Length**: Each section earns its place
- **Goal**: Scannable in < 1 minute

---

## Common Patterns

### Handling Knowledge Gaps

**In DISCOVER**:
```markdown
## Knowledge Gaps

### Questions for User
1. Should there be a max limit?

### Areas Needing Investigation
1. Current debounce strategy
```

**In SPECIFY**:
Fill gaps with AskUserQuestion

---

### Making Decisions

**In DESIGN**:
```markdown
## Decision

**Selected**: Option A

**Rationale**: Follows existing patterns, more maintainable

**Trade-offs Accepted**: Slightly more files
```

---

### Documenting Deviations

**In IMPLEMENT**:
```markdown
## Deviations from Design

### DEV-001: Used different API

- **Original Plan**: Use POST /api/cart/update
- **Actual**: Used PATCH /api/cart/:id
- **Reason**: POST endpoint deprecated
- **Impact**: None - same functionality
```

---

### Reporting Issues

**In VERIFY**:
```markdown
## Issues Found

### Critical

**CRIT-001**: No input validation
- **Location**: `form.ts:45`
- **Impact**: Allows injection
- **Fix**: Add validateInput() from utils
```

---

## Workflow Tips

### Starting a Task

1. Read user request
2. Run DISCOVER to understand current state
3. Use SPECIFY to clarify with user
4. Design the solution
5. Implement it
6. Verify quality

### When Stuck

- **In DISCOVER**: Can't find code? → Ask user for hints
- **In SPECIFY**: Unclear requirement? → AskUserQuestion
- **In DESIGN**: Multiple options seem equal? → Choose one with rationale
- **In IMPLEMENT**: Design unclear? → Document and flag
- **In VERIFY**: Not sure if issue is critical? → Err on side of caution

### Quality Checks

**Every spec should**:
- [ ] Be under max line limit
- [ ] Use bullets/tables (not prose)
- [ ] Include only essential info
- [ ] Have clear frontmatter
- [ ] Be scannable quickly

---

## Context Reduction Math

**Current Workflow** (~850 lines):
- specify: ~180 lines
- plan: ~220 lines
- implement: ~200 lines
- review: ~250 lines

**Perfect Workflow** (~645 lines):
- discover: ~120 lines
- specify: ~140 lines
- design: ~180 lines
- implement: ~110 lines
- verify: ~95 lines

**Reduction**: 24% less context

**Benefits**:
- Less LLM distraction
- Faster processing
- Lower token cost
- Fewer errors

---

## Key Innovations

1. **Explicit Discovery**: Dedicated step for current state analysis
2. **Knowledge Gap Surfacing**: Every step documents unknowns
3. **Radical Minimalism**: Ultra-concise specs (≤250 lines)
4. **Clear Decisions**: No ambiguity at any step
5. **Strong Handoffs**: Each step sets up the next perfectly

---

## Success Metrics

**You're doing it right if**:
- ✅ Specs are concise (under line limits)
- ✅ No knowledge gaps at design time
- ✅ Implementation is mechanical (no design decisions)
- ✅ Verify step finds few issues
- ✅ Tasks complete faster with fewer iterations

**You're doing it wrong if**:
- ❌ Specs exceed line limits
- ❌ DESIGN has to make product decisions
- ❌ IMPLEMENT has to make architecture decisions
- ❌ VERIFY finds critical issues
- ❌ Multiple REVISE cycles needed

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Spec too long | Cut fluff. Every line must earn its place. |
| Design ambiguous | Add explicit decision section with rationale. |
| Implement deviates | Document in spec. Consider if design needs revision. |
| Verify finds critical issues | Reject or revise. Don't approve with critical issues. |
| Knowledge gaps remain | Go back to SPECIFY and fill them. |
| Task taking too long | Break into smaller tasks. Each should be ≤200 lines spec. |

---

## Remember

- **Clarity over cleverness**: Simple, clear plans execute better
- **Facts over fluff**: Every word must earn its place
- **Explicit over implicit**: Surface unknowns, don't hide them
- **Quality over speed**: Better to do it right than to redo it
- **Shipping matters**: Don't block on perfection, but ensure quality

---

## File Locations

```
.claude/siat/
├── config.yml (set steps: discover, specify, design, implement, verify)
└── steps/
    ├── discover/
    │   ├── instruction.md
    │   └── spec_template.md
    ├── specify/
    ├── design/
    ├── implement/
    └── verify/
```

---

## One-Liners

- **DISCOVER**: "Map the terrain before planning the journey"
- **SPECIFY**: "Know exactly what you're building and why"
- **DESIGN**: "Plan the gap bridge with precision"
- **IMPLEMENT**: "Execute the plan with quality"
- **VERIFY**: "Validate before you ship"

---

**Perfect SDD**: Build the right thing, the right way, with clarity.
