---
name: look-back
description: Review the current session to identify and fix mistakes. Use after completing tasks, when something seems wrong, or when the user asks to review work. Catches errors, missed requirements, and quality issues.
---

# Look Back

## Purpose

Review what has been done in the session to:
- Catch mistakes before they compound
- Ensure requirements were fully met
- Identify improvements or missed items
- Learn from errors to avoid repeating them

## When to Use

- After completing a significant task
- When something doesn't feel right
- User reports unexpected behavior
- Before declaring work "done"
- After multiple tool calls that might have introduced errors
- When context has grown large and details might be lost

## Instructions

### Step 1: Recall the Original Request

Go back to what the user originally asked for:
- What was the actual requirement?
- Were there implicit expectations?
- Did scope change during the conversation?
- Were all parts of the request addressed?

### Step 2: Review Actions Taken

Examine what was actually done:

1. **Files modified**: List all changed files
2. **Changes made**: What was added/removed/modified?
3. **Tools used**: Any failed commands? Unexpected outputs?
4. **Decisions made**: What choices were made along the way?

### Step 3: Verify Correctness

For each change, verify:

1. **Syntax**: No typos, correct language syntax
2. **Logic**: Does the code do what it should?
3. **Completeness**: All cases handled? Nothing half-done?
4. **Integration**: Works with existing code? No broken imports?
5. **Side effects**: Unintended changes elsewhere?

### Step 4: Check for Common Mistakes

Look for these frequent issues:

**Code Quality**
- Unused imports or variables
- Inconsistent naming
- Missing error handling
- Hardcoded values that should be configurable
- Copy-paste errors

**Logic Errors**
- Off-by-one errors
- Wrong comparison operators
- Missing null/undefined checks
- Incorrect boolean logic
- Race conditions

**Integration Issues**
- Broken imports/exports
- Type mismatches
- API contract violations
- Missing dependencies

**Security Issues**
- Exposed secrets or credentials
- SQL injection vulnerabilities
- XSS vulnerabilities
- Missing input validation

**Missed Requirements**
- Partial implementation
- Edge cases not handled
- Requirements misunderstood
- Scope creep or under-delivery

### Step 5: Verify Against Tests

If tests exist:
- Do existing tests still pass?
- Were new tests needed but not added?
- Do tests actually test the right things?

If no tests:
- Should there be tests for this change?
- Can we manually verify the change works?

### Step 6: Create Fix List

For any issues found:
1. List each issue clearly
2. Categorize by severity (critical/important/minor)
3. Propose specific fixes
4. Prioritize critical issues first

### Step 7: Execute Fixes

Address issues in order of severity:
1. Fix critical issues immediately
2. Fix important issues next
3. Note minor issues for later or ask user preference

### Step 8: Summarize for User

Provide a clear summary:
- What was reviewed
- Issues found (if any)
- Fixes applied
- Remaining concerns or recommendations

## Review Checklist

### Quick Review (after small changes)
- [ ] Change matches what was requested
- [ ] No syntax errors
- [ ] Imports/exports correct
- [ ] No obvious logic errors

### Standard Review (after feature implementation)
- [ ] All requirements addressed
- [ ] Error handling present
- [ ] Edge cases considered
- [ ] No security issues
- [ ] Code is readable
- [ ] Tests pass (if applicable)

### Deep Review (after complex changes)
- [ ] Full quick + standard review
- [ ] Performance implications considered
- [ ] Backward compatibility maintained
- [ ] Documentation updated if needed
- [ ] No regression in related features
- [ ] All todo items completed

## Example

After implementing a user search feature:

"Let me review what we've done:

**Original Request**: Add user search by name and email

**Changes Made**:
- Added `/api/users/search` endpoint in `routes/users.js`
- Added `searchUsers` function in `services/userService.js`
- Updated `UserList` component to include search input

**Review Findings**:

1. **Issue (Critical)**: SQL query is vulnerable to injection
   - Line 45 in userService.js uses string concatenation
   - Fix: Use parameterized queries

2. **Issue (Important)**: Missing pagination
   - Large result sets could crash the browser
   - Fix: Add limit/offset parameters

3. **Issue (Minor)**: Search is case-sensitive
   - Users might not find 'John' when searching 'john'
   - Fix: Use case-insensitive comparison

Applying critical fix now..."

## Anti-patterns to Avoid

- **Superficial review**: Don't just skim - actually trace the logic
- **Confirmation bias**: Look for problems, not just what works
- **Ignoring warnings**: Compiler/linter warnings are often real issues
- **Skipping verification**: Don't assume it works - check it
- **Overconfidence**: "I'm sure I did it right" is when mistakes hide
