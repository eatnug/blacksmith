# Perfect Spec-Driven Development (SDD) Workflow

## Executive Summary

This document proposes the **perfect SDD workflow** optimized for:
1. **Clarity**: Know exactly what to build
2. **Context**: Understand current state deeply
3. **Precision**: Bridge the gap with minimal deviation
4. **Focus**: Ultra-concise specs that don't distract reasoning models

---

## Core Philosophy

### The Problem with Current Workflows

Most SDD workflows jump too quickly from requirements to design without:
- **Understanding current state thoroughly**
- **Identifying knowledge gaps explicitly**
- **Keeping specs concise** (verbose specs distract LLMs)

### The Perfect SDD Flow

```
DISCOVER → SPECIFY → DESIGN → IMPLEMENT → VERIFY
    ↓          ↓         ↓          ↓          ↓
 Current    Target     Gap      Execute    Validate
  State      State   Analysis
```

**Key Principle**: Each step outputs a **minimal spec** with ONLY crucial information.

---

## The 5 Perfect Steps

### 1. DISCOVER (Current State Analysis)

**Role**: Senior Software Archaeologist

**Purpose**: Deeply understand what exists NOW before planning changes

**Key Questions**:
- What code/components exist in this area?
- What patterns/conventions are used?
- What are the technical constraints?
- What's the current architecture?
- What will we need to change/extend?

**Output**: `discover.md` (≤ 150 lines)
- Current architecture map
- Existing components/files
- Patterns in use
- Constraints
- **Knowledge gaps** (what we don't know yet)

**Why This Step Matters**:
Without understanding current state, you'll:
- Miss existing solutions
- Violate patterns
- Introduce inconsistencies
- Underestimate complexity

---

### 2. SPECIFY (Target State & Requirements)

**Role**: Senior Product Analyst

**Purpose**: Define WHAT we want to build and WHY

**Interactive**: YES - This step asks user questions

**Key Questions**:
- What's the problem we're solving?
- What do we want to achieve?
- What are success criteria?
- What's in/out of scope?
- What assumptions are we making?
- **What don't we know yet?**

**Output**: `specify.md` (≤ 200 lines)
- Problem statement (2-3 sentences)
- Requirements (must-have only)
- Success criteria (measurable)
- Scope (explicit in/out)
- Open questions (explicitly list unknowns)

**Critical**: This spec should be scannable in 30 seconds.

---

### 3. DESIGN (Gap Analysis & Solution)

**Role**: Software Architect

**Purpose**: Plan how to move from CURRENT to TARGET state

**Process**:
1. **Gap Analysis**: What's the delta between current and target?
2. **Options**: What are 2-3 viable approaches?
3. **Decision**: Which approach and why?
4. **Plan**: Detailed implementation tasks
5. **Risks**: What could go wrong?

**Output**: `design.md` (≤ 250 lines)
- Gap summary (current vs target)
- Recommended approach + rationale
- Components to create/modify
- Implementation tasks (ordered)
- Risk assessment

**No Fluff**: Every line must be actionable.

---

### 4. IMPLEMENT (Execution)

**Role**: Senior Software Engineer

**Purpose**: Build the solution according to design

**Process**:
1. Follow design plan exactly
2. Document any deviations
3. Test thoroughly
4. Verify acceptance criteria

**Output**: `implement.md` (≤ 150 lines)
- Files changed (created/modified/deleted)
- Key implementation decisions
- Deviations from design (if any)
- Test results
- Acceptance criteria checklist

**Rule**: If you deviate from design, you MUST document why.

---

### 5. VERIFY (Quality Gate)

**Role**: QA Engineer / Code Reviewer

**Purpose**: Final validation before shipping

**Process**:
1. Verify all requirements met
2. Check code quality
3. Validate tests pass
4. Final decision: APPROVE / REVISE / REJECT

**Output**: `verify.md` (≤ 150 lines)
- Requirements validation (each requirement checked)
- Critical issues (if any)
- Code quality assessment
- Final verdict + reasoning

**Concise**: Only report issues and final decision.

---

## Spec Minimalism Principles

### Current Problem
The existing spec templates are **too verbose**:
- specify.md template: ~150 lines
- plan.md template: ~180 lines
- implement.md template: ~200 lines
- review.md template: ~250 lines

**Total context**: ~780 lines passed between steps!

### Why This Is Bad
Reasoning models:
- Get distracted by verbose context
- Miss critical details buried in fluff
- Waste tokens on non-essential info
- Make errors due to information overload

### The Solution: Radical Conciseness

**Every spec must:**
1. ✅ Fit on 1-2 screens (max 200 lines)
2. ✅ Have NO redundant sections
3. ✅ Use bullets/tables (not prose)
4. ✅ State facts, not examples
5. ✅ Be scannable in < 1 minute

**Remove**:
- ❌ Example code in templates
- ❌ Verbose explanations
- ❌ Repeated information
- ❌ "Nice to have" sections
- ❌ Teaching content

**Keep**:
- ✅ Critical facts only
- ✅ Decisions with rationale
- ✅ Actionable items
- ✅ Explicit unknowns
- ✅ Key risks

---

## Perfect Spec Templates

### 1. DISCOVER Spec

```markdown
---
id: "{task-id}"
step: "discover"
status: "pending_feedback"
---

# Discover: {Task}

## Current Architecture

**Related Components**
- `{file}` - {role}
- `{file}` - {role}

**Patterns in Use**
- {pattern}: {where used}

**Tech Stack**
- {relevant technologies}

## Constraints

**Technical**
- {constraint}

**Business**
- {constraint}

## Knowledge Gaps

**What We Don't Know Yet**
1. {unknown - needs discovery}
2. {unknown - needs user input}

## Next Step Context

**For Specify Step**
- {critical insight that affects requirements}

---
```

### 2. SPECIFY Spec

```markdown
---
id: "{task-id}"
step: "specify"
prev: "{task-id}/discover"
status: "pending_feedback"
open_questions: []
---

# Specify: {Task}

## Problem

{2-3 sentence problem statement}

## Requirements

**Must Have**
1. {requirement} - {acceptance criteria}
2. {requirement} - {acceptance criteria}

## Scope

**In**: {what we're doing}
**Out**: {what we're NOT doing}

## Success Criteria

- [ ] {measurable criterion}
- [ ] {measurable criterion}

## Constraints

- {constraint}

## Assumptions

- {assumption}

---
```

### 3. DESIGN Spec

```markdown
---
id: "{task-id}"
step: "design"
prev: "{task-id}/specify"
status: "pending_feedback"
---

# Design: {Task}

## Gap Analysis

**Current**: {current state}
**Target**: {target state}
**Delta**: {what needs to change}

## Approach

**Decision**: {chosen approach}
**Why**: {1-2 sentence rationale}

## Components

**Create**
- `{file}` - {purpose}

**Modify**
- `{file}` - {changes}

## Implementation Plan

**Tasks** (in order)
1. [ ] {task} - `{file}` - {completion criteria}
2. [ ] {task} - `{file}` - {completion criteria}

## Risks

**Risk**: {risk}
- **Likelihood**: low/med/high
- **Impact**: low/med/high
- **Mitigation**: {how to address}

---
```

### 4. IMPLEMENT Spec

```markdown
---
id: "{task-id}"
step: "implement"
prev: "{task-id}/design"
status: "pending_feedback"
---

# Implement: {Task}

## Changes

**Created**
- `{file}` ({lines}) - {purpose}

**Modified**
- `{file}` (+{n}/-{m}) - {what changed}

## Key Decisions

- {decision}: {rationale}

## Deviations from Design

{None / list deviations with reasons}

## Testing

- [ ] Unit tests: {n} passing
- [ ] Integration tests: {n} passing
- [ ] Acceptance criteria: all met

---
```

### 5. VERIFY Spec

```markdown
---
id: "{task-id}"
step: "verify"
prev: "{task-id}/implement"
status: "pending_feedback"
---

# Verify: {Task}

## Requirements Validation

| Req | Status | Notes |
|-----|--------|-------|
| {req} | ✅/❌ | {notes if any} |

## Critical Issues

{None / list critical issues only}

## Verdict

**Decision**: APPROVE / REVISE / REJECT

**Reason**: {1-2 sentences}

**Action**: {what happens next}

---
```

---

## Comparison: Current vs Perfect

| Aspect | Current Workflow | Perfect Workflow |
|--------|-----------------|------------------|
| **Steps** | specify → plan → implement → review | discover → specify → design → implement → verify |
| **Current State** | Analyzed during plan | Dedicated discover step |
| **Spec Length** | ~150-250 lines each | ≤150-200 lines each |
| **Total Context** | ~780 lines | ~450 lines (42% reduction) |
| **Knowledge Gaps** | Implicit | Explicit in every step |
| **LLM Distraction** | High (verbose) | Low (concise) |
| **Scannability** | Difficult | Easy (< 1 min) |

---

## Implementation Recommendations

### Phase 1: Update Templates
1. Create new step directories:
   - `steps/discover/`
   - Rename `plan` → `design`
   - Rename `review` → `verify`

2. Rewrite instruction.md for each step:
   - Cut by 50%
   - Focus on critical guidance only
   - Remove examples (keep in separate docs)

3. Create minimal spec_template.md:
   - Use templates above as starting point
   - Maximum 150-200 lines
   - Only essential sections

### Phase 2: Update config.yml
```yaml
steps:
  - discover   # NEW: current state analysis
  - specify    # existing, but more interactive
  - design     # renamed from 'plan'
  - implement  # existing
  - verify     # renamed from 'review'
```

### Phase 3: Test & Iterate
1. Run on 3-5 real tasks
2. Measure:
   - Spec length
   - Time to complete
   - Quality of output
   - User satisfaction
3. Refine based on feedback

---

## Expected Benefits

### 1. Clearer Understanding
- **Discover step** ensures current state is deeply understood
- No more "I didn't know that existed" moments

### 2. Explicit Knowledge Gaps
- Every step surfaces "what we don't know"
- Forces clarification before proceeding

### 3. Better Plans
- **Design step** has full context (discover + specify)
- Gap analysis ensures nothing is missed

### 4. Less LLM Distraction
- 42% less context passed between steps
- Only critical information retained
- Faster processing, fewer errors

### 5. Faster Execution
- Clearer instructions = less confusion
- Minimal specs = less reading time
- Better plans = fewer iterations

---

## FAQ

### Q: Isn't DISCOVER redundant with DESIGN?
A: No. DISCOVER is exploratory (understand terrain), DESIGN is prescriptive (plan the route). Separating them ensures thorough analysis.

### Q: Won't shorter specs miss important details?
A: No. The key is removing REDUNDANCY and FLUFF, not critical information. Current specs repeat the same info 3-4 times.

### Q: What if we need longer specs for complex tasks?
A: Complex tasks should be broken into smaller tasks. Each task should have concise specs. Complexity doesn't justify verbosity.

### Q: How do we migrate existing workflows?
A: Run both workflows in parallel for 2-3 sprints. Compare outcomes. Migrate when confident.

---

## Conclusion

The **perfect SDD workflow** is:

1. **DISCOVER**: Know where you are
2. **SPECIFY**: Know where you're going
3. **DESIGN**: Plan how to get there
4. **IMPLEMENT**: Execute the plan
5. **VERIFY**: Confirm you arrived

With **radical conciseness** in every spec.

This ensures engineers:
- ✅ Know exactly what to build
- ✅ Understand current state deeply
- ✅ Identify knowledge gaps explicitly
- ✅ Plan precisely with minimal waste
- ✅ Deliver quality outcomes consistently

**Next Steps**: Implement Phase 1 (update templates) and test on real tasks.
