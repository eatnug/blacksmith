---
id: "{task-id}"
step: "implement"
prev: "{task-id}/design"
next: "{task-id}/verify"
status: "pending_feedback"
open_questions: []
---

# Implement: {Task Title}

## Summary

{1-2 sentence summary of what was implemented}

---

## Files Changed

### Created

| File | Lines | Purpose |
|------|-------|---------|
| `{path}` | {n} | {what it does} |

### Modified

| File | Changes | Reason |
|------|---------|--------|
| `{path}` | +{n}/-{m} | {why modified} |

### Deleted

| File | Reason |
|------|--------|
| {path or "None"} | {why deleted} |

---

## Task Completion

| Task | Status | Notes |
|------|--------|-------|
| Task 001: {title} | ✅ | {any notes} |
| Task 002: {title} | ✅ | {any notes} |

---

## Key Decisions

**{Decision}**: {rationale}

---

## Deviations from Design

{None / list deviations}

### DEV-001: {What Changed}

- **Original Plan**: {what design said}
- **Actual Implementation**: {what was done}
- **Reason**: {why deviated}
- **Impact**: {what's affected}

---

## Requirements Verification

| Requirement | Status | Implementation | Test |
|-------------|--------|----------------|------|
| REQ-001: {req} | ✅ | `{file:line}` | `{test file}` |

**All requirements**: ✅ Met / ⚠️ Partial / ❌ Not met

---

## Testing

**Test Summary**:
- Unit Tests: {n} written, {n} passing
- Integration Tests: {n} written, {n} passing
- Coverage: {%} (if available)

**All Tests**: ✅ Passing / ❌ Failing

---

## Build & Quality

- [ ] Build: ✅ Passing
- [ ] Linter: ✅ No errors
- [ ] Type Check: ✅ No errors
- [ ] Existing Tests: ✅ Still passing

---

## Notes for Review

**Focus Areas**:
- {Area reviewer should pay attention to}

**Known Limitations** (if any):
- {Limitation with plan to address}

---
