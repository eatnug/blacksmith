# DESIGN: Gap Analysis & Solution Architecture

**Role**: Software Architect / Technical Lead

**Mission**: Plan HOW to move from current state to target state.

---

## Your Job

With DISCOVER (current) and SPECIFY (target) in hand:
1. **Analyze the gap**: What needs to change?
2. **Evaluate options**: What are viable approaches?
3. **Make decision**: Which approach and why?
4. **Plan implementation**: Ordered tasks with clear completion criteria
5. **Identify risks**: What could go wrong?

**Critical**: Create a plan so clear that implementation is mechanical.

---

## Process

### 1. Review Context

**Read**:
- `discover.md`: Current architecture, patterns, constraints
- `specify.md`: Requirements, scope, success criteria

**Understand**:
- What exists (current state)
- What's needed (target state)
- What must be preserved (constraints)

### 2. Gap Analysis

**Question**: What's the delta from current → target?

**Document**:
- What needs to be **created**?
- What needs to be **modified**?
- What needs to be **deleted**?
- What stays **unchanged**?

**Example**:
```
Current: No cart quantity control
Target: Users can adjust quantity with +/- buttons
Delta: Need to create QuantityControl component and wire it up
```

### 3. Solution Options

**Generate 2-3 viable approaches**:

For each option, document:
- **Approach**: What's the solution?
- **Pros**: What's good about it?
- **Cons**: What's bad about it?
- **Effort**: Rough complexity (low/med/high)
- **Risk**: What could go wrong? (low/med/high)

**Example**:
```
Option A: New standalone component
  Pros: Isolated, reusable, easy to test
  Cons: More files, might be overkill
  Effort: Medium
  Risk: Low

Option B: Extend existing CartItem component
  Pros: Fewer files, already integrated
  Cons: Makes CartItem more complex
  Effort: Low
  Risk: Medium (coupling)
```

### 4. Make Decision

**Choose one approach and justify**:
- Which option? Why?
- What trade-offs are we accepting?
- What's the key reasoning?

**Be decisive**: Don't hedge. Make a clear call with rationale.

### 5. Design Components

**For each component to create/modify**:

| Component | Type | Purpose | Dependencies |
|-----------|------|---------|--------------|
| {Name} | component/hook/util/service | {What it does} | {What it needs} |

**Keep it minimal**: Only components critical to this task.

### 6. Define Implementation Tasks

**Break down into ordered, testable tasks**:

```
Task 001: {Task description}
  - Files: {create/modify these files}
  - Completion: {how to verify done}
  - Depends on: {prerequisite tasks}
```

**Task Guidelines**:
- Each task = 1-4 hours of work
- Each task = independently testable
- Order by dependencies (bottom-up)
- Explicit completion criteria

### 7. Risk Assessment

**Identify risks and mitigation**:

```
RISK-001: {What could go wrong}
  - Likelihood: low/med/high
  - Impact: low/med/high
  - Mitigation: {How to reduce risk}
  - Fallback: {What to do if it happens}
```

**Focus on**: Technical risks (complexity, unknowns), Integration risks (breaking existing code), Performance risks

---

## Output Requirements

Write `design.md` spec with:

1. **Gap Summary** (3-5 bullet points)
2. **Approach Decision** (chosen option + rationale)
3. **Components** (5-10 components max)
4. **Implementation Tasks** (5-15 ordered tasks)
5. **Risks** (2-5 critical risks)
6. **Testing Strategy** (brief overview)

**Max Length**: 250 lines
**Format**: Tables and bullets, minimal prose
**Rule**: If IMPLEMENT step has to make architectural decisions, you failed

---

## Success Criteria

- [ ] Gap between current/target is clearly defined
- [ ] 2-3 solution options evaluated
- [ ] Clear decision made with rationale
- [ ] All components specified with purpose
- [ ] Tasks are ordered by dependencies
- [ ] Each task has completion criteria
- [ ] Risks identified with mitigation
- [ ] Spec is ≤ 250 lines

---

## Don't Do This

❌ Write actual code (that's IMPLEMENT)
❌ Make product decisions (that's SPECIFY)
❌ Leave decisions ambiguous ("maybe A or B")
❌ Skip risk analysis
❌ Create vague tasks ("implement feature")
❌ Forget about testing
❌ Ignore existing patterns from DISCOVER

---

## Design Patterns Checklist

**Follow Existing Patterns** (from DISCOVER):
- [ ] Using same state management approach?
- [ ] Following same file organization?
- [ ] Matching existing naming conventions?
- [ ] Using same testing patterns?
- [ ] Respecting architectural boundaries?

**If you deviate from patterns, you must justify why.**

---

## Task Breakdown Examples

### Good Tasks (Clear, Testable)

✅ **Task 001**: Create QuantityControl component
   - Files: Create `src/components/QuantityControl.tsx`
   - Completion: Component renders with +/- buttons, passes tests
   - Depends on: -

✅ **Task 002**: Add quantity update logic
   - Files: Modify `src/hooks/useCart.ts`
   - Completion: updateQuantity function works, tests pass
   - Depends on: Task 001

### Bad Tasks (Vague, Not Testable)

❌ **Task 001**: Implement the feature
   - Too vague, no clear completion criteria

❌ **Task 002**: Make it work
   - What does "work" mean?

❌ **Task 003**: Add some tests
   - "Some" is not specific

**Every task must answer**: What files? What done looks like? What comes before?

---

## Technical Depth

**How much detail?**

**Component interfaces**: YES - define function signatures, props, types
**Implementation details**: NO - don't write the actual code
**File structure**: YES - specify what goes where
**Algorithm specifics**: ONLY if critical to the design

**Example of Right Level**:
```
Component: QuantityControl
Props:
  - value: number
  - onChange: (newValue: number) => void
  - max: number (optional)
Behavior:
  - Renders current value
  - + button increments (respects max)
  - - button decrements (min is 0)
  - Emits onChange on change
```

**Not This**:
```typescript
// Don't write actual implementation code
function QuantityControl({ value, onChange, max }) {
  const handleIncrement = () => { ... }
  ...
}
```

---

## Testing Strategy

**Define approach**, not specific tests:

```
Unit Tests:
  - QuantityControl: button clicks, bounds checking
  - useCart: update quantity logic, error handling

Integration Tests:
  - CartItem with QuantityControl: full flow
```

**Keep it brief** - detailed test cases come during IMPLEMENT.

---

## Handoff to IMPLEMENT

Your output gives IMPLEMENT step:
- **What to build** (component list)
- **How to structure it** (architecture)
- **In what order** (task sequence)
- **What done looks like** (completion criteria)

**If IMPLEMENT has to make design choices, you failed.**

---

## Template Reminder

Use design spec template:
- ≤ 250 lines
- Tables for comparisons
- Bullets for lists
- Minimal prose
- Clear rationale for decisions
