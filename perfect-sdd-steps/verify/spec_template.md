---
id: "{task-id}"
step: "verify"
prev: "{task-id}/implement"
next: null
status: "pending_feedback"
open_questions: []
---

# Verify: {Task Title}

## Requirements Verification

| Requirement | Status | Evidence | Test |
|-------------|--------|----------|------|
| REQ-001: {req} | ✅/⚠️/❌ | `{file:line}` | `{test}` |
| REQ-002: {req} | ✅/⚠️/❌ | `{file:line}` | `{test}` |

**Overall**: ✅ All met / ⚠️ Mostly met / ❌ Major gaps

---

## Code Quality

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Readability | ✅/⚠️/❌ | {brief note if issues} |
| Maintainability | ✅/⚠️/❌ | {brief note if issues} |
| Error Handling | ✅/⚠️/❌ | {brief note if issues} |
| Security | ✅/⚠️/❌ | {brief note if issues} |
| Testing | ✅/⚠️/❌ | {brief note if issues} |

---

## Issues Found

### Critical (Must Fix)

{None / list issues}

**CRIT-001**: {Issue}
- **Location**: `{file:line}`
- **Impact**: {what breaks}
- **Fix**: {how to resolve}

### Major (Should Fix)

{None / list issues}

**MAJ-001**: {Issue}
- **Location**: `{file:line}`
- **Impact**: {what's affected}
- **Fix**: {how to resolve}

### Minor (Nice to Fix)

{None / list issues}

---

## Testing Verification

- **Unit Tests**: {n} tests, ✅ passing / ❌ failing
- **Integration Tests**: {n} tests, ✅ passing / ❌ failing
- **Coverage**: {coverage %} (if available)

**Test Quality**: ✅ Adequate / ⚠️ Gaps / ❌ Insufficient

---

## Design Compliance

**Followed Design**: ✅ Yes / ⚠️ Minor deviations / ❌ Major deviations

{If deviations}:
- {Deviation}: {justified? yes/no}

---

## Verdict

### Decision: APPROVE / REVISE / REJECT

**Reasoning**: {1-3 sentences explaining decision}

**Next Steps**: {what happens next}

{If REVISE}:
**Required Fixes**:
1. {Fix item}
2. {Fix item}

{If REJECT}:
**Required Actions**:
1. {Action item}
2. {Action item}

---

## Summary

**What Worked**:
- {Positive note}

**What Needs Attention**:
- {Area for improvement}

---
