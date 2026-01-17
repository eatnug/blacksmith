# Example: Adding Cart Quantity Control

**Task**: "Add quantity increase/decrease buttons to shopping cart items"

This document shows how this task flows through both workflows.

---

## Current Workflow (4 Steps)

### Step 1: SPECIFY

**Spec Length**: ~180 lines

**Key Sections**:
- Original request
- Classification table
- Q&A record (10+ questions)
- Requirements (must have + nice to have)
- Scope (in/out)
- Success criteria
- Bug details (N/A for features but still in template)
- Open questions
- Next step handoff
- References

**Issues**:
- ❌ No current state analysis yet
- ❌ Many template sections unused (bug details)
- ❌ Nice-to-have mixed with must-have
- ❌ Q&A record adds length without value

---

### Step 2: PLAN

**Spec Length**: ~220 lines

**Key Sections**:
- Summary
- Context (NOW analyzing current state)
- Architecture design
- Component details
- Interface definitions
- Data flow
- Implementation tasks
- Risks
- Dependencies
- Testing strategy
- Requirements mapping
- Implementation notes

**Issues**:
- ❌ Tries to do current state analysis + design in one step
- ❌ Verbose component descriptions with examples
- ❌ Implementation notes add fluff
- ❌ Gap analysis implicit, not explicit

---

### Step 3: IMPLEMENT

**Spec Length**: ~200 lines

**Key Sections**:
- Plan summary
- Implementation log by phase
- File changes (created/modified/deleted)
- Test results
- Deviations
- Known issues
- Review prep checklist
- Notes for reviewer
- Memo section

**Issues**:
- ❌ Phase-by-phase log is verbose
- ❌ Memo section encourages fluff
- ❌ Review prep checklist duplicates verify step

---

### Step 4: REVIEW

**Spec Length**: ~250 lines

**Key Sections**:
- Overview table
- Requirements verification
- Design compliance
- Code quality review (many subsections)
- Testing verification
- Issues by severity
- Issue summary
- Final verdict
- Praise section
- Review checklist
- Appendix with file list

**Issues**:
- ❌ Praise section adds no value
- ❌ Appendix duplicates implement spec
- ❌ Many subsections for code quality

**Total Context**: ~850 lines across 4 specs

---

## Perfect Workflow (5 Steps)

### Step 1: DISCOVER

**Spec Length**: ~120 lines

**Content**:
```markdown
# Discover: Cart Quantity Control

## Current Architecture

### Related Components

| Component | Path | Role |
|-----------|------|------|
| CartItem | `src/components/cart/CartItem.tsx` | Renders cart item row |
| useCart | `src/hooks/useCart.ts` | Cart state management |
| cartApi | `src/api/cart.ts` | Cart backend calls |

### Patterns in Use

- **Optimistic Updates**: Used in cart operations (add/remove items)
- **Compound Components**: CartItem is composed of smaller parts
- **Custom Hooks**: Business logic in hooks, not components

### Tech Stack

- React 18 with TypeScript
- Zustand for state management
- React Testing Library for tests

## Constraints

### Technical

- Must use existing Zustand store pattern
- Must maintain optimistic update approach
- Must support keyboard accessibility

### Business

- Cannot change cart API contract
- Must maintain mobile responsiveness

## Knowledge Gaps

### Questions for User

1. Should there be a max quantity limit?
2. What happens if quantity exceeds stock?

### Areas Needing Investigation

1. Current debounce strategy for API calls

## Key Insights for Next Step

**Critical Context**:
- Cart already uses optimistic updates - new feature must match
- Existing CartItem is 200 lines - consider extracting quantity logic

**Recommendations**:
- Extract quantity control to separate component for reusability
```

**Benefits**:
- ✅ Current state fully mapped
- ✅ Patterns identified for consistency
- ✅ Constraints clear
- ✅ Knowledge gaps explicit
- ✅ Only 120 lines

---

### Step 2: SPECIFY

**Spec Length**: ~140 lines

**Content**:
```markdown
# Specify: Cart Quantity Control

## Problem

Users cannot adjust cart item quantities without removing and re-adding items. This creates friction in the checkout flow.

## Requirements

### REQ-001: Quantity Increase

**Acceptance**: User can click + button to increase quantity by 1. Cart updates immediately.

### REQ-002: Quantity Decrease

**Acceptance**: User can click - button to decrease quantity by 1 (min: 1). Cart updates immediately.

### REQ-003: Stock Limit

**Acceptance**: If quantity would exceed stock, show error message. Don't allow increase.

### REQ-004: Optimistic Update

**Acceptance**: UI updates immediately, syncs with backend asynchronously.

## Scope

**In Scope**:
- +/- buttons for quantity adjustment
- Stock limit validation
- Optimistic UI updates
- Error handling

**Out of Scope**:
- Direct numeric input (future)
- Bulk quantity changes (future)
- Save for later feature (separate task)

## Success Criteria

- [ ] User can adjust quantity in ≤ 2 clicks
- [ ] Change reflects in UI within 100ms
- [ ] Backend sync completes within 2s
- [ ] Stock overflow prevented and communicated

## Constraints

**From Discovery**:
- Must use Zustand store pattern
- Must maintain optimistic update approach
- Must be keyboard accessible

**New**:
- Max quantity: 99 (per product limit)

## Assumptions

- Stock data is available in cart item object
- API supports quantity update endpoint

## Context for Design

**Key Priorities**:
1. User experience over edge cases
2. Consistency with existing cart patterns
```

**Benefits**:
- ✅ Clear problem statement
- ✅ Every requirement has acceptance criteria
- ✅ Scope explicit
- ✅ Only 140 lines
- ✅ No fluff

---

### Step 3: DESIGN

**Spec Length**: ~180 lines

**Content**:
```markdown
# Design: Cart Quantity Control

## Gap Analysis

**Current State**: CartItem shows quantity as read-only text

**Target State**: CartItem has interactive +/- buttons for quantity adjustment

**What Changes**:
- Create: QuantityControl component
- Create: useQuantityUpdate hook
- Modify: CartItem to use QuantityControl
- Modify: useCart to add updateQuantity action

## Solution Options

### Option A: Standalone QuantityControl Component

| Aspect | Assessment |
|--------|------------|
| **Pros** | Reusable, testable, follows compound pattern |
| **Cons** | Additional file |
| **Effort** | Medium |
| **Risk** | Low |

### Option B: Inline in CartItem

| Aspect | Assessment |
|--------|------------|
| **Pros** | Fewer files |
| **Cons** | Makes CartItem more complex, less reusable |
| **Effort** | Low |
| **Risk** | Medium |

## Decision

**Selected**: Option A

**Rationale**: Follows existing compound component pattern. Reusable for wishlist feature (future).

**Trade-offs Accepted**: Slightly more files, but better architecture.

## Architecture

### Components

| Component | Type | Purpose | Dependencies |
|-----------|------|---------|--------------|
| QuantityControl | component | +/- buttons UI | useQuantityUpdate |
| useQuantityUpdate | hook | Update logic + debounce | useCart |

### Component Details

**QuantityControl**
- **Location**: `src/components/cart/QuantityControl.tsx`
- **Interface**: `{ value: number, productId: string, maxStock: number }` → `JSX.Element`
- **Behavior**: Renders +/- buttons, calls hook on click, disables at limits

**useQuantityUpdate**
- **Location**: `src/hooks/useQuantityUpdate.ts`
- **Interface**: `(productId: string)` → `{ increment, decrement, isUpdating }`
- **Behavior**: Optimistic update, debounced API call, error handling

## Implementation Plan

### Task 001: Create useQuantityUpdate hook

- **Files**: Create `src/hooks/useQuantityUpdate.ts`
- **Work**: Implement increment/decrement with optimistic update
- **Done When**: Hook works, unit tests pass
- **Depends On**: -

### Task 002: Create QuantityControl component

- **Files**: Create `src/components/cart/QuantityControl.tsx`
- **Work**: Render +/- buttons, wire to hook
- **Done When**: Component renders, tests pass
- **Depends On**: Task 001

### Task 003: Integrate into CartItem

- **Files**: Modify `src/components/cart/CartItem.tsx`
- **Work**: Replace quantity text with QuantityControl
- **Done When**: CartItem uses new component, tests updated
- **Depends On**: Task 002

### Task 004: Add stock validation

- **Files**: Modify `src/hooks/useQuantityUpdate.ts`
- **Work**: Check stock limit before increment
- **Done When**: Stock overflow prevented, tests pass
- **Depends On**: Task 001

## Risks

### RISK-001: Race condition on rapid clicks

- **Likelihood**: Medium
- **Impact**: Medium
- **Mitigation**: Use debounce (300ms) for API calls
- **Fallback**: Queue updates if issue persists

## Testing Strategy

**Unit Tests**:
- useQuantityUpdate: increment/decrement logic, debounce, errors
- QuantityControl: button clicks, disabled states

**Integration Tests**:
- CartItem with QuantityControl: full user flow

## Requirements Mapping

| Requirement | Implementation | Validation |
|-------------|----------------|------------|
| REQ-001 | QuantityControl + button | Test button click increases |
| REQ-002 | QuantityControl - button | Test button click decreases |
| REQ-003 | useQuantityUpdate stock check | Test max stock error |
| REQ-004 | useQuantityUpdate optimistic | Test UI updates immediately |
```

**Benefits**:
- ✅ Explicit gap analysis
- ✅ Options evaluated with rationale
- ✅ Clear decision
- ✅ Ordered tasks
- ✅ Only 180 lines

---

### Step 4: IMPLEMENT

**Spec Length**: ~110 lines

**Content**:
```markdown
# Implement: Cart Quantity Control

## Summary

Implemented QuantityControl component and useQuantityUpdate hook per design. All tasks completed, all tests passing.

## Files Changed

### Created

| File | Lines | Purpose |
|------|-------|---------|
| `src/hooks/useQuantityUpdate.ts` | 85 | Quantity update logic with optimistic updates |
| `src/components/cart/QuantityControl.tsx` | 65 | +/- buttons UI component |
| `src/hooks/useQuantityUpdate.test.ts` | 120 | Hook unit tests |
| `src/components/cart/QuantityControl.test.tsx` | 95 | Component unit tests |

### Modified

| File | Changes | Reason |
|------|---------|--------|
| `src/components/cart/CartItem.tsx` | +12/-3 | Integrated QuantityControl |
| `src/hooks/useCart.ts` | +25/-0 | Added updateQuantity action |

## Task Completion

| Task | Status | Notes |
|------|--------|-------|
| Task 001: useQuantityUpdate | ✅ | Added 300ms debounce |
| Task 002: QuantityControl | ✅ | Keyboard accessible |
| Task 003: CartItem integration | ✅ | Existing tests updated |
| Task 004: Stock validation | ✅ | Error toast on overflow |

## Key Decisions

**Debounce Duration**: Set to 300ms after testing. Balances UX and API calls.

**Error Display**: Used existing toast system for stock overflow errors.

## Deviations from Design

None - implemented exactly as designed.

## Requirements Verification

| Requirement | Status | Implementation | Test |
|-------------|--------|----------------|------|
| REQ-001: Increase | ✅ | `QuantityControl.tsx:34` | `QuantityControl.test.tsx:45` |
| REQ-002: Decrease | ✅ | `QuantityControl.tsx:42` | `QuantityControl.test.tsx:62` |
| REQ-003: Stock limit | ✅ | `useQuantityUpdate.ts:56` | `useQuantityUpdate.test.ts:89` |
| REQ-004: Optimistic | ✅ | `useQuantityUpdate.ts:23` | `useQuantityUpdate.test.ts:34` |

**All requirements**: ✅ Met

## Testing

**Test Summary**:
- Unit Tests: 18 written, 18 passing
- Integration Tests: 3 written, 3 passing
- Coverage: 94%

**All Tests**: ✅ Passing

## Build & Quality

- [x] Build: ✅ Passing
- [x] Linter: ✅ No errors
- [x] Type Check: ✅ No errors
- [x] Existing Tests: ✅ Still passing (342/342)
```

**Benefits**:
- ✅ Concise file change summary
- ✅ Task completion tracked
- ✅ Requirements verified
- ✅ Only 110 lines

---

### Step 5: VERIFY

**Spec Length**: ~95 lines

**Content**:
```markdown
# Verify: Cart Quantity Control

## Requirements Verification

| Requirement | Status | Evidence | Test |
|-------------|--------|----------|------|
| REQ-001: Increase | ✅ | `QuantityControl.tsx:34` | Passes |
| REQ-002: Decrease | ✅ | `QuantityControl.tsx:42` | Passes |
| REQ-003: Stock limit | ✅ | `useQuantityUpdate.ts:56` | Passes |
| REQ-004: Optimistic | ✅ | `useQuantityUpdate.ts:23` | Passes |

**Overall**: ✅ All met

## Code Quality

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Readability | ✅ | Clear naming, good structure |
| Maintainability | ✅ | Well separated concerns |
| Error Handling | ✅ | All edge cases covered |
| Security | ✅ | Input validated |
| Testing | ✅ | 94% coverage, comprehensive |

## Issues Found

### Critical

None

### Major

None

### Minor

None - code quality is excellent

## Testing Verification

- **Unit Tests**: 18 tests, ✅ passing
- **Integration Tests**: 3 tests, ✅ passing
- **Coverage**: 94%

**Test Quality**: ✅ Adequate

## Design Compliance

**Followed Design**: ✅ Yes

No deviations - implemented exactly as planned.

## Verdict

### Decision: APPROVE

**Reasoning**: All requirements met, excellent code quality, comprehensive tests. Ready for production.

**Next Steps**: Merge to main and deploy.

## Summary

**What Worked**:
- Clean separation of concerns (component + hook)
- Excellent test coverage
- Follows all existing patterns

**What Needs Attention**:
- None - ready to ship
```

**Benefits**:
- ✅ Quick requirements check
- ✅ Simple quality assessment
- ✅ Clear verdict
- ✅ Only 95 lines

---

**Total Context**: ~645 lines across 5 specs (24% reduction from current workflow)

---

## Key Differences Summary

| Aspect | Current Workflow | Perfect Workflow |
|--------|-----------------|------------------|
| **Current State Analysis** | Mixed into Plan step | Dedicated Discover step (120 lines) |
| **Spec Verbosity** | High (~850 lines total) | Low (~645 lines total) |
| **Knowledge Gaps** | Implicit | Explicit in every step |
| **Gap Analysis** | Implicit | Explicit section in Design |
| **Template Bloat** | Many unused sections | Only used sections |
| **Fluff Content** | Examples, notes, memos | Pure facts only |
| **LLM Efficiency** | Moderate | High |
| **Clarity** | Good | Excellent |

---

## Conclusion

For the same task, the perfect workflow produces:
- ✅ **24% less total context**
- ✅ **More explicit knowledge tracking**
- ✅ **Clearer separation of concerns**
- ✅ **Better current state understanding**
- ✅ **No template bloat**

**Result**: Faster execution, fewer errors, better outcomes.
