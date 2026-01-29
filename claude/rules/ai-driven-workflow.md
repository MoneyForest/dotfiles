# AI-Driven Workflow

## Overview

AI drives the conversation by asking questions and seeking confirmation from the user.
The user makes decisions by selecting from options or approving proposed plans.

## Core Principles

### 1. Proactive Clarification

Ask questions proactively to eliminate ambiguity and improve work quality.

**When to ask:**
- Task purpose or background is unclear
- Multiple implementation approaches exist
- Scope or priority decisions are needed
- Technical trade-offs are involved
- Changes carry potential risks

### 2. Use AskUserQuestion Tool

**Always use the `AskUserQuestion` tool instead of text-based questions.**

Benefits:
- Users can select options with a single click
- Reduces ambiguity in responses
- Structured data makes follow-up easier

The tool supports:
- Single-select (default): User picks one option
- Multi-select (`multiSelect: true`): User can pick multiple options
- 2-4 options per question, 1-4 questions per call

### 3. Concrete Options

Always present specific options when asking questions. Avoid abstract questions.

**Good example:**
```
Which authentication method should we use?

A) JWT (Token-based)
   - Stateless, scalable
   - Requires token revocation implementation

B) Session (Server-side)
   - Simpler implementation
   - Requires session store (e.g., Redis)
```

**Bad example:**
```
How do you want to handle authentication?
```

### 4. Plan-First Approach

For complex tasks, present a plan and get approval before implementation.

**Plan should include:**
- Work steps (checkbox format)
- Decision points requiring confirmation at each step
- Anticipated risks and mitigations

## Workflow Phases

### Phase 1: Requirements Clarification

Confirm the following at task start:

1. **Purpose**: What to achieve and why
2. **Success criteria**: How to determine completion
3. **Scope**: What's included and excluded
4. **Constraints**: Technical, time, and compatibility with existing code

### Phase 2: Plan Presentation and Approval

```markdown
## Work Plan

### Summary
[Task summary]

### Steps
- [ ] Step 1: [Description]
  - Decision point: [What needs confirmation]
- [ ] Step 2: [Description]
- [ ] Step 3: [Description]

### Risks
- [Risk 1]: [Mitigation]

Does this plan look good to proceed?
```

### Phase 3: Incremental Implementation

- Report progress after completing each step
- Seek confirmation at important decision points
- Report unexpected issues immediately and discuss resolution approach

## Question Templates

### New Feature

```
Let me clarify a few things about this feature:

1. **Use case**: In what scenarios will this be used?
   - A) [Specific scenario 1]
   - B) [Specific scenario 2]
   - C) Other (please describe)

2. **Quality priority**:
   - A) Performance-focused
   - B) Maintainability/readability-focused
   - C) Extensibility-focused

3. **Relationship with existing code**:
   - A) Integrate with existing [X]
   - B) Implement as independent module
```

### Bug Fix

```
Let me confirm the fix approach:

1. **Fix scope**:
   - A) Minimal fix (affected area only)
   - B) Include related similar issues
   - C) Root cause fix with refactoring

2. **Testing**:
   - A) Update existing tests only
   - B) Add new test cases
   - C) Expand test coverage
```

### Refactoring

```
Let me confirm the refactoring approach:

1. **Goal**:
   - A) Improve readability
   - B) Improve performance
   - C) Improve testability
   - D) Remove code duplication

2. **Impact scope**:
   - A) Single file
   - B) Multiple files
   - C) API changes involved

3. **Compatibility**:
   - A) Maintain full backward compatibility
   - B) Breaking changes acceptable
```

## Notes

- Skip questions for urgent or obviously trivial tasks
- When user says "go ahead" or "I'll leave it to you", proceed following best practices
- When in doubt, always confirm
