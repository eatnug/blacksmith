---
name: clarify
description: Clarify user requests before taking action. Use when requirements are ambiguous, incomplete, or could be interpreted multiple ways. Helps prevent wasted effort from misunderstanding.
---

# Clarify

## Purpose

Before diving into implementation, ensure you fully understand what the user wants. This prevents building the wrong thing and saves time.

## When to Use

- Requirements are vague or ambiguous
- Multiple valid interpretations exist
- Critical details are missing
- User's intent is unclear
- Task scope could vary significantly based on interpretation

## Instructions

### Step 1: Identify Ambiguities

Review the user's request and identify:

1. **Missing context**: What information is absent?
   - Target files/directories
   - Expected behavior or output
   - Constraints or requirements
   - Edge cases

2. **Ambiguous terms**: What could mean different things?
   - "Fix" - what exactly is broken?
   - "Improve" - by what metric?
   - "Clean up" - what standards?
   - "Better" - in what way?

3. **Scope uncertainty**: How big is this task?
   - Single file or entire codebase?
   - Quick fix or refactor?
   - Temporary workaround or permanent solution?

4. **Assumptions to validate**: What are you assuming?
   - Technology choices
   - Coding conventions
   - Dependencies

### Step 2: Formulate Questions

Create focused questions that:
- Are specific and answerable
- Address one thing at a time
- Offer concrete options when possible
- Explain why the clarification matters

Good questions:
- "Should this function throw an error or return null when input is invalid?"
- "Do you want this change in file X only, or everywhere this pattern appears?"
- "Which authentication method: JWT tokens or session cookies?"

Bad questions:
- "What do you want?" (too vague)
- "Is this okay?" (doesn't clarify anything)

### Step 3: Present Questions Efficiently

- Group related questions together
- Prioritize the most critical questions first
- Provide your best guess with reasoning when appropriate
- Limit to 3-5 questions at a time to avoid overwhelming

### Step 4: Summarize Understanding

After receiving answers, confirm your understanding:
- Restate the task in your own words
- List key requirements and constraints
- Mention any assumptions you're making
- Get explicit confirmation before proceeding

## Example Interaction

User: "Make the login better"

Response:
I want to make sure I improve the login in the way you're looking for. A few questions:

1. **What aspect needs improvement?**
   - Security (stronger validation, rate limiting, 2FA)?
   - UX (clearer error messages, remember me, faster load)?
   - Code quality (refactoring, better error handling)?

2. **Are there specific issues you've noticed?**
   - Any bugs or error messages?
   - User complaints?

3. **What files/components handle login currently?**
   - Or should I search the codebase to find them?

## Anti-patterns to Avoid

- Don't ask questions you can answer by reading the code
- Don't ask about every tiny detail - use judgment for minor decisions
- Don't delay action when requirements are actually clear
- Don't ask the same question twice in different words
