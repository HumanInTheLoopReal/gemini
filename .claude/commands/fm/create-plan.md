---
name: fm:create-plan
description:
  Create detailed implementation plans through interactive research and
  iteration
argument-hint: '<task-file.md | task description>'
model: opus
allowed-tools:
  - Read
  - Write
  - Task
  - TaskCreate
  - TaskUpdate
  - AskUserQuestion
  - Bash
  - Glob
  - Grep
---

<objective>
Create detailed, actionable implementation plans through an interactive, iterative research process.

**Default flow:** Read Context → Research → Clarify → Structure → Write Plan →
Review → Done

**Orchestrator role:** Parse arguments, read task files, spawn research agents,
collect findings, interact with user for clarifications, write final plan.

**Why subagents:** Research burns context fast. Spawning codebase-locator,
codebase-analyzer, and docs-locator as subagents keeps main context clean for
user interaction and plan writing.

**Output:** Implementation plan — co-located with task folder if provided, else
`.flomaster/plans/YYYY-MM-DD-description.md`

Context budget: ~20% orchestrator (argument handling, user interaction, plan
writing), 100% fresh per research subagent. </objective>

<context>
Task or ticket reference: $ARGUMENTS

**If arguments provided:**

- Read the referenced file(s) FULLY before any other action
- Begin research process immediately

**If no arguments provided:**

- Prompt user for task/ticket description
- Request relevant context, constraints, requirements
- Ask for links to related research or implementations </context>

<process>

## 0. Handle Invocation

**Check if parameters were provided:**

If `$ARGUMENTS` contains a file path or ticket reference:

- Skip the default message
- Immediately read the provided files FULLY
- Begin the research process (Step 1)

If `$ARGUMENTS` is empty, respond with:

```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a task file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a task file directly:
`/fm:create-plan .flomaster/tasks/issue-123.md`

For deeper analysis, try:
`/fm:create-plan think deeply about .flomaster/tasks/issue-123.md`
```

Then wait for the user's input.

## 1. Context Gathering & Initial Analysis

### 1a. Read All Mentioned Files Immediately and FULLY

- Task files (e.g., `.flomaster/tasks/issue-123.md`)
- Research documents
- Related implementation plans
- Any JSON/data files mentioned

**CRITICAL RULES:**

- Use the Read tool WITHOUT limit/offset parameters to read entire files. If the
  file is too big then read in chunks of 1000 lines
- DO NOT spawn sub-tasks before reading these files yourself in the main context
- NEVER read files partially - if a file is mentioned, read it completely

### 1b. Spawn Initial Research Tasks

Display spawning indicator:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► RESEARCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning research agents in parallel...
  → codebase-locator
  → codebase-analyzer
  → docs-locator
```

Before asking the user any questions, use specialized agents to research in
parallel:

| Agent                 | Purpose                                                      |
| --------------------- | ------------------------------------------------------------ |
| **codebase-locator**  | Find all files related to the task                           |
| **codebase-analyzer** | Understand how current implementation works                  |
| **docs-locator**      | Find existing documentation about this feature (if relevant) |

These agents will:

- Find relevant source files, configs, and tests
- Identify specific directories to focus on
- Trace data flow and key functions
- Return detailed explanations with file:line references

### 1c. Handle Research Returns

After all research agents complete:

**If agents found relevant files:**

- Display: `Research complete. Found {N} relevant files.`
- Continue to 1d

**If agents found nothing relevant:**

- Display: `Research found no directly relevant files. Expanding search...`
- Spawn broader search with relaxed criteria
- Or proceed with user clarification

### 1d. Read Files Identified by Research Tasks

After research tasks complete:

- Read ALL files they identified as relevant
- Read them FULLY into the main context
- This ensures complete understanding before proceeding

### 1e. Analyze and Verify Understanding

- Cross-reference task requirements with actual code
- Identify discrepancies or misunderstandings
- Note assumptions that need verification
- Determine true scope based on codebase reality

### 1f. Present Informed Understanding and Focused Questions

```
Based on the task and my research of the codebase, I understand we need to [accurate summary].

I've found that:
- [Current implementation detail with file:line reference]
- [Relevant pattern or constraint discovered]
- [Potential complexity or edge case identified]

Questions that my research couldn't answer:
- [Specific technical question that requires human judgment]
- [Business logic clarification]
- [Design preference that affects implementation]
```

**Only ask questions you genuinely cannot answer through code investigation.**

## 2. Research & Discovery

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► DEEP RESEARCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After getting initial clarifications:

### 2a. Handle Corrections

If the user corrects any misunderstanding:

- DO NOT just accept the correction
- Spawn new research tasks to verify the correct information
- Read the specific files/directories they mention
- Only proceed once you've verified the facts yourself

### 2b. Create Research Todo List

Use TaskCreate to create a todo list tracking exploration tasks and progress.
Update task status with TaskUpdate as you complete items.

### 2c. Spawn Parallel Sub-Tasks for Comprehensive Research

Create multiple Task agents to research different aspects concurrently:

**For deeper investigation:** | Agent | Use Case | |-------|----------| |
**codebase-locator** | Find specific files handling [component] | |
**codebase-analyzer** | Understand implementation details of [system] | |
**codebase-pattern-finder** | Find similar features to model after |

**For historical context:** | Agent | Use Case | |-------|----------| |
**docs-locator** | Find research, plans, decisions about this area | |
**docs-analyzer** | Extract key insights from relevant documents |

### 2d. Wait for ALL Sub-Tasks to Complete

Do not proceed until all research tasks have returned results.

### 2e. Present Findings and Design Options

```
Based on my research, here's what I found:

**Current State:**
- [Key discovery about existing code]
- [Pattern or convention to follow]

**Design Options:**
1. [Option A] - [pros/cons]
2. [Option B] - [pros/cons]

**Open Questions:**
- [Technical uncertainty]
- [Design decision needed]

Which approach aligns best with your vision?
```

## 3. Plan Structure Development

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► STRUCTURING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Once aligned on approach:

### 3a. Create Initial Plan Outline

```
Here's my proposed plan structure:

## Overview
[1-2 sentence summary]

## Implementation Phases:
1. [Phase name] - [what it accomplishes]
2. [Phase name] - [what it accomplishes]
3. [Phase name] - [what it accomplishes]

Does this phasing make sense? Should I adjust the order or granularity?
```

### 3b. Get Feedback on Structure

Wait for user approval before writing details. Allow adjustments to:

- Phase order
- Phase granularity
- Scope additions/removals

## 4. Detailed Plan Writing

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► WRITING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

After structure approval:

### 4a. Determine Output Path

**Priority 1: Co-locate with existing task folder**

If the user provided a task file path (e.g., `tasks/TASK-123/task.md` or
`tasks/TASK-123.md`):

- Extract the task directory from the input path
- Place the plan in that same directory

```bash
# If input was a file in a task directory
TASK_DIR=$(dirname "$TASK_FILE")

# Check if it looks like a task folder (contains task ID or is a dedicated folder)
if [[ "$TASK_DIR" == *tasks/* ]] || [[ "$TASK_DIR" == *tickets/* ]] || [[ -d "$TASK_DIR" ]]; then
  OUTPUT_PATH="${TASK_DIR}/PLAN.md"
fi
```

**Priority 2: Default to .flomaster/plans/**

If no task folder context exists (user provided description directly or file is
not in a task folder):

Format: `.flomaster/plans/YYYY-MM-DD-{ISSUE-ID}-description.md`

Where:

- `YYYY-MM-DD` is today's date
- `{ISSUE-ID}` is the issue/ticket number (omit if no ticket)
- `description` is a brief kebab-case description

**Examples:**

| Input                           | Output Path                                              |
| ------------------------------- | -------------------------------------------------------- |
| `tasks/ENG-123/task.md`         | `tasks/ENG-123/PLAN.md`                                  |
| `tasks/ENG-123.md`              | `tasks/ENG-123/PLAN.md` (create folder)                  |
| `tickets/ISSUE-456/`            | `tickets/ISSUE-456/PLAN.md`                              |
| `"Add user authentication"`     | `.flomaster/plans/2025-01-23-add-user-authentication.md` |
| `.flomaster/tasks/feature-x.md` | `.flomaster/tasks/PLAN.md`                               |

**Logic:**

1. If task file is in a dedicated folder → put PLAN.md there
2. If task file is standalone (e.g., `tasks/ENG-123.md`) → create folder
   `tasks/ENG-123/` and put PLAN.md there
3. If no task file context → use `.flomaster/plans/` with dated filename

### 4b. Write Plan Using Template

````markdown
# [Feature/Task Name] Implementation Plan

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

## Desired End State

[A Specification of the desired end state after this plan is complete, and how
to verify it]

### Key Discoveries:

- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview

[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]

**File**: `path/to/file.ext` **Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:

- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `npm run typecheck`
- [ ] Linting passes: `make lint`
- [ ] Integration tests pass: `make test-integration`

#### Manual Verification:

- [ ] Feature works as expected when tested via UI
- [ ] Performance is acceptable under load
- [ ] Edge case handling verified manually
- [ ] No regressions in related features

**Implementation Note**: After completing this phase and all automated
verification passes, pause here for manual confirmation from the human that the
manual testing was successful before proceeding to the next phase.

---

## Phase 2: [Descriptive Name]

[Similar structure with both automated and manual success criteria...]

---

## Testing Strategy

### Unit Tests:

- [What to test]
- [Key edge cases]

### Integration Tests:

- [End-to-end scenarios]

### Manual Testing Steps:

1. [Specific step to verify feature]
2. [Another verification step]
3. [Edge case to test manually]

## Performance Considerations

[Any performance implications or optimizations needed]

## Migration Notes

[If applicable, how to handle existing data/systems]

## References

- Original task: `{task_file_path}` (or description if no file)
- Related research: `.flomaster/research/[relevant].md`
- Similar implementation: `[file:line]`
````

## 5. Review

### 5a. Present Draft Plan Location

```
I've created the initial implementation plan at:
`{output_path}`

Please review it and let me know:
- Are the phases properly scoped?
- Are the success criteria specific enough?
- Any technical details that need adjustment?
- Missing edge cases or considerations?
```

### 5b. Iterate Based on Feedback

Be ready to:

- Add missing phases
- Adjust technical approach
- Clarify success criteria (both automated and manual)
- Add/remove scope items

### 5c. Continue Refining

Iterate until the user is satisfied with the plan.

---

## Reference: Success Criteria Guidelines

**Always separate success criteria into two categories:**

### Automated Verification (can be run by execution agents):

- Commands that can be run: `make test`, `npm run lint`, etc.
- Specific files that should exist
- Code compilation/type checking
- Automated test suites

### Manual Verification (requires human testing):

- UI/UX functionality
- Performance under real conditions
- Edge cases that are hard to automate
- User acceptance criteria

**Format example:**

```markdown
### Success Criteria:

#### Automated Verification:

- [ ] Database migration runs successfully: `make migrate`
- [ ] All unit tests pass: `go test ./...`
- [ ] No linting errors: `golangci-lint run`
- [ ] API endpoint returns 200: `curl localhost:8080/api/new-endpoint`

#### Manual Verification:

- [ ] New feature appears correctly in the UI
- [ ] Performance is acceptable with 1000+ items
- [ ] Error messages are user-friendly
- [ ] Feature works correctly on mobile devices
```

**Important:** Automated steps should use `make` whenever possible (e.g.,
`make -C {frontend-dir} check` instead of `cd {frontend-dir} && npm run fmt`).

---

## Reference: Common Implementation Patterns

### For Database Changes:

1. Start with schema/migration
2. Add store methods
3. Update business logic
4. Expose via API
5. Update clients

### For New Features:

1. Research existing patterns first
2. Start with data model
3. Build backend logic
4. Add API endpoints
5. Implement UI last

### For Refactoring:

1. Document current behavior
2. Plan incremental changes
3. Maintain backwards compatibility
4. Include migration strategy

---

## Reference: Sub-Task Spawning Best Practices

When spawning research sub-tasks:

1. **Spawn multiple tasks in parallel** for efficiency
2. **Each task should be focused** on a specific area
3. **Provide detailed instructions** including:
   - Exactly what to search for
   - Which directories to focus on
   - What information to extract
   - Expected output format
4. **Be EXTREMELY specific about directories:**
   - If task mentions "frontend", specify the exact frontend directory
   - If it mentions "backend", specify the exact backend directory
   - Never use generic terms - be specific about which component
   - Include full path context in prompts
5. **Specify read-only tools** to use
6. **Request specific file:line references** in responses
7. **Wait for all tasks to complete** before synthesizing
8. **Verify sub-task results:**
   - If sub-task returns unexpected results, spawn follow-up tasks
   - Cross-check findings against actual codebase
   - Don't accept results that seem incorrect

</process>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PLAN CREATED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{Plan Name}** — {N} phases

Location: `{output_path}`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Review the plan** — verify phases, success criteria, and scope

`cat {output_path}`

When ready to execute:

`/fm:execute-plan {output_path}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────

**Also available:**

- Edit the plan directly if adjustments needed
- `/fm:create-plan {another-task}` — plan another feature

─────────────────────────────────────────────────────────────── </offer_next>

<anti_patterns>

- Don't assume - verify everything with code investigation
- Don't write the full plan in one shot without user buy-in at each step
- Don't read files partially - always read complete files
- Don't spawn sub-tasks BEFORE reading task files yourself in main context
- Don't accept user corrections without verifying them through research
- Don't leave open questions in the final plan - research or ask immediately
- Don't write plans with unresolved questions - every decision must be made
- Don't skip the "What We're NOT Doing" section - it prevents scope creep
- Don't batch automated and manual verification - always separate them clearly
  </anti_patterns>

<success_criteria> fm:create-plan is complete when:

- [ ] All mentioned files read FULLY in main context
- [ ] Initial research tasks spawned and completed
- [ ] Files identified by research read FULLY
- [ ] Understanding presented with file:line references
- [ ] Clarifying questions asked (only those research couldn't answer)
- [ ] Design options presented with pros/cons
- [ ] Plan structure approved by user
- [ ] Complete plan written to appropriate location (task folder if exists, else
      `.flomaster/plans/`)
- [ ] Plan includes all required sections (Overview, Current State, Desired End
      State, What We're NOT Doing, Phases with success criteria)
- [ ] Each phase has BOTH automated AND manual verification criteria
- [ ] User has reviewed and approved the final plan
- [ ] No open questions remain in the plan </success_criteria>
