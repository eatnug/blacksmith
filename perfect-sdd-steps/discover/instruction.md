# DISCOVER: Current State Analysis

**Role**: Senior Software Archaeologist

**Mission**: Understand what EXISTS before planning what to BUILD.

---

## Your Job

Map the current codebase terrain:
1. What code/components exist in this area?
2. What patterns/conventions are used?
3. What are the technical constraints?
4. What will likely need to change?

**Critical**: Identify what you DON'T know yet.

---

## Process

### 1. Explore the Codebase

**Find Related Code**
- Use Glob/Grep to locate relevant files
- Read key files to understand structure
- Identify patterns in naming, organization, architecture

**Questions to Answer**:
- Where does similar functionality live?
- What design patterns are used here?
- What libraries/frameworks are in play?
- How is state managed?
- How is this tested?

### 2. Map the Architecture

**Document**:
- Key components/modules and their roles
- Data flow and dependencies
- Integration points with other systems
- Tech stack specifics (versions, tools)

**Keep It Minimal**: Only what's relevant to this task.

### 3. Identify Constraints

**Technical Constraints**:
- Must use existing patterns? Which ones?
- Version limitations?
- Performance requirements?
- Browser/platform compatibility?

**Business Constraints**:
- Can't change certain files?
- Must maintain backward compatibility?
- Deployment restrictions?

### 4. Surface Knowledge Gaps

**Explicitly List What You Don't Know**:
- "Need to ask user: {question}"
- "Need to investigate: {area}"
- "Unclear: {ambiguity}"

**These gaps will be filled in SPECIFY step.**

---

## Output Requirements

Write `discover.md` spec with:

1. **Current Architecture** (5-10 components max)
2. **Patterns in Use** (2-5 patterns)
3. **Constraints** (critical ones only)
4. **Knowledge Gaps** (explicit unknowns)
5. **Next Step Context** (1-2 key insights for SPECIFY)

**Max Length**: 150 lines
**Format**: Bullets and tables, not prose
**Rule**: If it's not critical, cut it

---

## Success Criteria

- [ ] Found all relevant existing code
- [ ] Identified patterns/conventions to follow
- [ ] Listed all technical constraints
- [ ] Explicitly documented unknowns
- [ ] Spec is ≤ 150 lines

---

## Don't Do This

❌ Write code or make changes
❌ Assume anything - verify by reading code
❌ Include examples or tutorials in spec
❌ List every file in the codebase
❌ Write prose - use bullets/tables
❌ Leave knowledge gaps implicit

---

## Example Discovery Questions

**For Feature Request**:
- Where do similar features live?
- What UI component library is used?
- How is API data fetched/cached?
- What testing framework is used?

**For Bug Fix**:
- Where is the buggy code?
- What's the code flow leading to the bug?
- Are there tests that should have caught this?
- What's the deployment/release process?

**For Refactor**:
- What's the current architecture?
- How much code will be affected?
- Are there tests we can rely on?
- What's the migration strategy?

---

## Tips

1. **Read Code, Don't Assume**: Always verify by reading actual files
2. **Follow the Trail**: Start from entry points, trace execution paths
3. **Look for Patterns**: Same naming? Same structure? Document it
4. **Be Skeptical**: Comments lie, code doesn't
5. **Know When to Stop**: Don't explore everything, just what's relevant

---

## Handoff to SPECIFY

Your output gives the SPECIFY step:
- What already exists (don't reinvent the wheel)
- What patterns to follow (stay consistent)
- What constraints to respect (stay within bounds)
- What to ask the user (fill knowledge gaps)

**Make the next step's job easier by being thorough here.**
