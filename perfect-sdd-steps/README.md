# Perfect Spec-Driven Development (SDD) Steps

> **Optimized workflow for building software with clarity, precision, and minimal LLM distraction**

---

## Overview

This is a refined SDD workflow with **4 perfect steps** designed to:

1. ✅ **Clarify organically** - Requirements + codebase exploration together
2. ✅ **Plan precisely** - How to bridge the gap
3. ✅ **Execute cleanly** - With clear guidance
4. ✅ **Validate thoroughly** - Before shipping

### Key Innovation: Organic Clarification

**The Reality**: Requirements and code exploration don't happen sequentially - they inform each other!

❌ **Linear (doesn't work)**:
```
1. Get all requirements
2. Then explore code
```

✅ **Organic (how it actually works)**:
```
User: "Add quantity control"
→ You: (explore code) "Found CartItem..."
→ You: "Should there be a max?" (informed by seeing item.stock)
→ User: "Yes, stock limit"
→ Continue iterating...
```

**CLARIFY step does both simultaneously** - requirements become clear AS you explore the codebase.

---

## The 4 Steps

```
┌──────────┐   ┌──────────┐   ┌───────────┐   ┌──────────┐
│ CLARIFY  │ → │  DESIGN  │ → │ IMPLEMENT │ → │  VERIFY  │
└──────────┘   └──────────┘   └───────────┘   └──────────┘
  What +        How to          Execute         Quality
  Where         Bridge                           Gate
```

### 1. CLARIFY (Requirements + Context Discovery)

**Role**: Senior Product Analyst + Software Archaeologist
**Interactive**: **YES** - Iterative exploration with user
**Output**: `clarify.md` (≤250 lines)

**Purpose**: Understand WHAT to build AND WHERE it fits - simultaneously.

**What It Does**:
- Clarifies requirements through user questions
- Explores relevant codebase areas
- Asks informed questions based on code findings
- Documents must-have requirements with acceptance criteria
- Maps current architecture and patterns
- Identifies constraints and integration points

**Why It's Combined**:
- Can't ask smart questions without seeing the code
- Can't explore efficiently without knowing what you're looking for
- Requirements and codebase understanding inform each other

**Example Flow**:
```
1. User: "Add quantity control to cart"
2. You: (explore) Found CartItem component...
3. You: "Should this be part of CartItem or separate?" (informed question)
4. User: "Separate for reusability"
5. You: (explore more) Found item.stock property...
6. You: "Use stock as max limit?" (informed question)
7. User: "Yes"
8. Result: Clear requirements + understanding of where it fits
```

---

### 2. DESIGN (Gap Analysis & Solution)

**Role**: Software Architect / Technical Lead
**Interactive**: No
**Output**: `design.md` (≤250 lines)

**Purpose**: Plan HOW to move from current to target state.

**What It Does**:
- Analyzes the gap between current and target
- Evaluates 2-3 solution options
- Makes clear architectural decision with rationale
- Creates ordered implementation tasks
- Identifies and mitigates risks

**Why It Matters**: A clear plan makes implementation mechanical.

---

### 3. IMPLEMENT (Execution)

**Role**: Senior Software Engineer
**Interactive**: No
**Output**: `implement.md` (≤150 lines)

**Purpose**: Build working, tested code per the design.

**What It Does**:
- Executes design tasks in order
- Writes clean, tested code
- Documents any deviations from design
- Verifies all acceptance criteria met

**Why It Matters**: Quality implementation requires following the plan.

---

### 4. VERIFY (Quality Gate)

**Role**: QA Engineer / Code Reviewer
**Interactive**: No
**Output**: `verify.md` (≤150 lines)

**Purpose**: Final validation before shipping.

**What It Does**:
- Verifies all requirements met
- Reviews code quality
- Validates tests comprehensive and passing
- **Makes decision**: APPROVE / REVISE / REJECT

**Why It Matters**: Last checkpoint to catch issues before production.

---

## Spec Minimalism Principles

### The Problem

Traditional SDD specs are **too verbose**:
- Lengthy templates with many sections
- Repeated information across specs
- Examples and tutorials mixed with specs
- High token cost for LLMs
- **Result**: LLMs get distracted and miss critical details

### The Solution

**Each spec template**:
- ✅ Maximum 150-250 lines
- ✅ Only essential sections
- ✅ Bullets and tables (not prose)
- ✅ No examples or fluff
- ✅ Scannable in < 1 minute

**Total context**: ~800 lines for 4 steps (vs ~1200+ in verbose workflows)

---

## Usage

### Installation

1. Copy these step templates to your `.claude/siat/steps/` directory:

```bash
cp -r perfect-sdd-steps/clarify .claude/siat/steps/
cp -r perfect-sdd-steps/design .claude/siat/steps/
cp -r perfect-sdd-steps/implement .claude/siat/steps/
cp -r perfect-sdd-steps/verify .claude/siat/steps/
```

2. Update your `.claude/siat/config.yml`:

```yaml
steps:
  - clarify
  - design
  - implement
  - verify
```

### Running a Workflow

```bash
# Start a new task
/do "Add user authentication"

# Continue existing task
/do task-id

# With remote mode (GitHub/Slack integration)
/do --remote "Add user authentication"
```

---

## Comparison: Old vs New

| Aspect | Old (5 Steps) | New (4 Steps) |
|--------|---------------|---------------|
| **Steps** | discover → specify → design → implement → verify | **clarify** → design → implement → verify |
| **Problem** | ❌ Can't discover without knowing what to look for | ✅ Explore and clarify together |
| **Process** | ❌ Artificial separation | ✅ Natural, iterative flow |
| **Questions** | ❌ Asked blindly | ✅ Asked based on code findings |
| **Total Context** | ~900 lines | ~800 lines |
| **Efficiency** | Good | Better |

---

## Key Innovations

### 1. Organic Clarification Process

**Problem**: Can't get clear requirements without understanding current state, but can't explore efficiently without knowing what you're building.

**Solution**: CLARIFY step does both iteratively:
- Explore code → Ask informed questions → Refine requirements → Explore more

### 2. Informed Questions

**Instead of**:
- ❌ "What color should the button be?" (too detailed, premature)
- ❌ "Should we use React?" (you can see they're using React)

**Ask**:
- ✅ "I see CartItem uses optimistic updates. Same for quantity?"
- ✅ "Found item.stock property. Use this for max limit?"

### 3. Radical Spec Minimalism

**Problem**: Verbose specs cause LLM distraction, errors, slow processing.

**Solution**: Ultra-concise specs with only crucial information (≤250 lines each).

### 4. Clear Decision Points

Each step has explicit completion criteria and clear handoff to next step.

---

## Best Practices

### For CLARIFY
- ✅ Explore code while asking questions
- ✅ Ask questions informed by code findings
- ✅ Make requirements testable
- ✅ Document both requirements AND current state
- ❌ Don't get all requirements first then explore
- ❌ Don't ask questions you could answer by reading code

### For DESIGN
- ✅ Evaluate multiple options
- ✅ Make clear decision with rationale
- ✅ Create ordered tasks
- ❌ Don't write actual code
- ❌ Don't leave decisions ambiguous

### For IMPLEMENT
- ✅ Follow the plan exactly
- ✅ Document deviations
- ✅ Write tests
- ❌ Don't skip tests
- ❌ Don't silently deviate from design

### For VERIFY
- ✅ Read all prior specs
- ✅ Verify every requirement
- ✅ Be objective
- ❌ Don't approve without reading code
- ❌ Don't reject for style preferences

---

## FAQ

### Q: Why combine requirements and code exploration?

**A**: Because that's how it actually works! You can't ask smart questions about requirements without seeing the code, and you can't explore efficiently without knowing what you're building. They inform each other.

### Q: Won't this make CLARIFY too complex?

**A**: No - it makes it more natural. The artificial separation was actually more complex because you had to context-switch between "get requirements" mode and "explore code" mode.

### Q: What if I don't know what code to explore yet?

**A**: Start broad, then narrow down:
1. Get basic request from user ("add quantity control")
2. Explore general area (cart-related files)
3. Ask informed questions based on what you find
4. Explore more specifically based on answers
5. Iterate until clear

### Q: How long should CLARIFY take?

**A**: As long as needed to eliminate blocking unknowns. Could be 5 minutes for simple features, 30+ minutes for complex ones. Don't rush it - clarity here saves time later.

---

## Expected Benefits

1. **More Natural Flow**: Matches how developers actually work
2. **Better Questions**: Informed by actual code, not theoretical
3. **Less Back-and-Forth**: Fewer "oh wait, I didn't know X existed" moments
4. **Clearer Requirements**: Understanding code helps clarify what's realistic
5. **Faster Overall**: One organic phase vs two artificial phases

---

## File Structure

```
perfect-sdd-steps/
├── README.md (this file)
├── config.yml (workflow configuration)
├── clarify/
│   ├── instruction.md (guidance for AI)
│   └── spec_template.md (output format)
├── design/
│   ├── instruction.md
│   └── spec_template.md
├── implement/
│   ├── instruction.md
│   └── spec_template.md
└── verify/
    ├── instruction.md
    └── spec_template.md
```

---

## Contributing

Improvements welcome! When proposing changes:

1. **Maintain minimalism**: Don't add unless absolutely necessary
2. **Test on real tasks**: Validate changes work in practice
3. **Measure impact**: Does it improve clarity? Reduce errors?
4. **Document rationale**: Why is this change needed?

---

## Credits

Designed based on:
- Software engineering best practices
- LLM efficiency research
- Real-world SDD workflow analysis
- Feedback on how developers actually work

**Principle**: The best workflow is the one that matches reality, not theory.
