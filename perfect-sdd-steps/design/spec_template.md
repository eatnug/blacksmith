---
id: "{task-id}"
step: "design"
prev: "{task-id}/specify"
next: "{task-id}/implement"
status: "pending_feedback"
open_questions: []
---

# Design: {Task Title}

## Gap Analysis

**Current State**: {Brief description}

**Target State**: {Brief description}

**What Changes**:
- Create: {what}
- Modify: {what}
- Delete: {what}

---

## Solution Options

### Option A: {Approach Name}

**Description**: {1 sentence}

| Aspect | Assessment |
|--------|------------|
| **Pros** | {benefits} |
| **Cons** | {drawbacks} |
| **Effort** | low/med/high |
| **Risk** | low/med/high |

### Option B: {Approach Name}

**Description**: {1 sentence}

| Aspect | Assessment |
|--------|------------|
| **Pros** | {benefits} |
| **Cons** | {drawbacks} |
| **Effort** | low/med/high |
| **Risk** | low/med/high |

---

## Decision

**Selected**: Option {A/B}

**Rationale**: {1-2 sentences explaining why}

**Trade-offs Accepted**: {what we're giving up}

---

## Architecture

### Components

| Component | Type | Purpose | Dependencies |
|-----------|------|---------|--------------|
| {Name} | component/hook/util | {role} | {what it uses} |

### Component Details

**{ComponentName}**
- **Location**: `{file path}`
- **Interface**: {props/params} → {returns}
- **Behavior**: {key behaviors}

---

## Implementation Plan

### Task 001: {Task Title}

- **Files**: Create/Modify `{path}`
- **Work**: {what to do}
- **Done When**: {completion criteria}
- **Depends On**: -

### Task 002: {Task Title}

- **Files**: Modify `{path}`
- **Work**: {what to do}
- **Done When**: {completion criteria}
- **Depends On**: Task 001

---

## Risks

### RISK-001: {Risk Description}

- **Likelihood**: low/med/high
- **Impact**: low/med/high
- **Mitigation**: {how to reduce}
- **Fallback**: {plan B if it happens}

---

## Testing Strategy

**Unit Tests**:
- {Component}: {what to test}

**Integration Tests**:
- {Scenario}: {what to test}

---

## Requirements Mapping

| Requirement | Implementation | Validation |
|-------------|----------------|------------|
| REQ-001 | {which component} | {which test} |

---
