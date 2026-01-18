---
id: "{task-id}"
step: "clarify"
prev: null
next: "{task-id}/design"
status: "pending_feedback"
open_questions: []
---

# Clarify: {Task Title}

## Problem

{2-3 sentence description of the problem we're solving and why it matters}

---

## Requirements

### REQ-001: {Requirement}

**Acceptance**: {How to verify this is met}

### REQ-002: {Requirement}

**Acceptance**: {How to verify this is met}

---

## Scope

**In Scope** (What we WILL do):
- {Item}
- {Item}

**Out of Scope** (What we will NOT do):
- {Item} - {Why deferred/excluded}

---

## Success Criteria

- [ ] {Measurable criterion}
- [ ] {Measurable criterion}
- [ ] {Measurable criterion}

---

## Current Architecture

### Related Components

| Component | Path | Role | Relevance |
|-----------|------|------|-----------|
| {Name} | `{path}` | {what it does} | {why relevant to this task} |

### Data Flow

{Brief description of how data flows in the relevant area}

```
{Simple diagram if helpful}
[User Action] → [Component] → [Hook] → [API] → [Backend]
```

---

## Patterns & Constraints

### Patterns in Use

**{Pattern Name}**: {Where used and why relevant}
- Example: Optimistic Updates used in cart operations
- Must follow same approach for consistency

### Technical Constraints

- {Constraint with impact on implementation}
- Example: Must use existing Zustand store pattern

### Business Constraints

- {Constraint with impact on implementation}
- Example: Cannot change API contract

---

## Tech Stack

**Relevant Technologies**:
- {Technology/library} ({version}) - {used for what}

**Testing Approach**:
- {Testing framework/pattern used in this area}

---

## Integration Points

**Touches**:
- {System/component this will integrate with}
- {API endpoint this will use}

**Dependencies**:
- {What this depends on}

---

## Assumptions

- {Assumption we're making}
- {Assumption we're making}

{Note: If any assumption is wrong, we may need to revisit}

---

## Key Insights for Design

**Critical Context**:
- {Insight that will affect design decisions}
- {Insight about current code that design must consider}

**Recommendations**:
- {Recommendation based on current state}

**Watch Out For**:
- {Potential issue or complexity to be aware of}

---

## Discovery Summary

**Files Explored**:
- `{path}` - {what we learned}

**Key Findings**:
- {Important discovery about codebase}

---
