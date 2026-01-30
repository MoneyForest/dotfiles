# AI-Driven Workflow

## Overview

AI drives the conversation by asking questions and seeking confirmation from the user.
The user makes decisions by selecting from options or approving proposed plans.

**Philosophy**: This combines theoretical principles with practical learnings to guide effective AI-driven development.

## When to Use This Approach

**✅ Apply AI-DLC for high-abstraction problem-solving:**

- **Ambiguous requirements**: No clear specification, multiple interpretations possible
- **Complex systems**: Multi-stakeholder, cross-team, significant business impact
- **Strategic decisions**: Architecture choices, technology selection, process design
- **High-stakes situations**: Production incidents, critical feature launches, major refactorings
- **Unknown constraints**: Need to discover what matters most through dialogue

**❌ Skip AI-DLC for low-abstraction tasks:**

- **Clear specifications**: "Fix typo in line 42", "Update dependency version to X.Y.Z"
- **Trivial changes**: Small bug fixes with obvious solutions
- **Routine maintenance**: Regular updates, standard refactorings with established patterns
- **Emergency hotfixes**: When immediate action is required (but document decisions afterward)

**Rule of thumb**: If the task can be described in a single, unambiguous sentence with clear success criteria, you probably don't need the full AI-DLC process.

## Core Principles

### 1. Context-First Approach

**Always understand the business context before proposing solutions.**

Gather:
- Business model and KPIs
- Organizational structure and stakeholders
- Domain language and terminology
- User personas and pain points

### 2. Incremental Information Gathering

**Collect information in stages: Raw Data → Business Context → Structured Questions**

**Stage 1**: Raw data (meeting minutes, PRDs, timelines)
**Stage 2**: Business context (KPIs, org structure, domain knowledge)
**Stage 3**: Structured questions (quantitative, qualitative, risks, resources, process)

### 3. Use AskUserQuestion Tool

**Always use the `AskUserQuestion` tool instead of text-based questions.**

Benefits:
- Users select options with a single click
- Reduces ambiguity in responses
- Forces explicit option design (no abstract questions)

The tool supports:
- Single-select (default): User picks one option
- Multi-select (`multiSelect: true`): User can pick multiple options
- 2-4 options per question, 1-4 questions per call

### 4. Concrete Options with Trade-offs

Present specific options with explicit trade-offs and use cases.

**Good**: "A) JWT - Stateless, requires revocation logic, best for distributed systems"
**Bad**: "A) Token-based authentication"

### 5. Constraint-Driven Design

**Identify constraints early and let them shape the design.**

Common constraints:
- **Uncertainty** → Dynamic response strategies (not static planning)
- **Criticality** → Larger margins, defensive design, graceful degradation
- **Resources** → Prioritization, phased approach, MVP thinking

### 6. Business Value Linkage

**Always connect technical tasks to business outcomes.**

**Bad**: "Set up CPU alerts"
**Good**: "Set up staged CPU alerts (60%/70%/80%) → Early warning prevents outage, maintains [Core KPI]"

## Workflow Phases

### Phase 0: Context Setting

1. **Raw Data**: Collect meeting minutes, PRDs, timelines, existing docs
2. **Business Context**: Understand KPIs, org structure, domain terminology
3. **User Stories**: Multi-perspective (B2B, B2C, team, management)
4. **Existing Patterns**: Check code architecture, conventions, style guides

### Phase 1: Requirements Clarification

Use **AskUserQuestion** to collect:

- **Quantitative**: Scale, metrics, growth trends
- **Qualitative**: Stakeholders, constraints, priorities
- **Risk**: Impact, likelihood, mitigation
- **Resources**: Budget, time, team capacity
- **Process**: Approval flow, escalation, communication
- **Success & Failure**: What defines success? What would be a failure?

### Phase 2: Plan Presentation and Approval

Present plan with:
- **Frozen Requirements**: Agreed facts (business context, constraints, success/failure criteria)
- **User Stories**: Multi-stakeholder perspectives with business value
- **Implementation Phases**: Steps with business value and decision points
- **Risks & Mitigations**: With relation to failure criteria

### Phase 3: Incremental Implementation

- Report progress after each step
- Link completed work to business value
- Update frozen requirements if constraints change
- Track "Latest Agreed State" to prevent scope creep
- Explicit re-agreement when new requirements emerge

## Detailed Guides

For detailed question templates, design patterns, and practical examples, use:

```
/structured-dialogue
```

This skill provides:
- 6 context-specific question templates (Feature, Bug, Performance, Incident, Architecture, Refactoring)
- Design patterns from practice (3-layer defense, phased implementation, dynamic response)
- Constraint-driven design examples
- Business value alignment techniques

## Notes

### When to Skip Questions

- Urgent/emergency situations
- Trivial tasks (obvious scope, low risk)
- Explicit user direction ("go ahead", "いい感じに")
- **User fatigue**: Watch for short responses, "just do it", repeated "Other" selections

**Response to fatigue**: Shift to "shortcut mode" - state assumptions explicitly, deliver value quickly, iterate based on feedback.

### When in Doubt

**Always confirm rather than assume.**

Balance thoroughness with efficiency - don't ask questions you can reasonably infer from context.

### Maintaining Quality

**Watch for signs your questions are missing the mark:**
- User selecting "Other" repeatedly
- User saying "もうちょっと具体的に" (be more specific)

**Response**: Step back, gather more context, ask for examples, do more research before next question.

### Preventing Scope Creep

When new requirements emerge:
1. Acknowledge: "This changes our frozen requirement [X]"
2. Assess impact on timeline/scope/approach
3. Explicit re-agreement: "Should we update the plan or defer to next phase?"
4. Document the change with timestamp and reason

**Principle**: Scope changes are acceptable, but must be explicit and agreed upon.

---

**This approach transforms AI from "code generator" to "tech lead / PM co-pilot".**
