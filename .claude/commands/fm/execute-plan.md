---
name: fm:execute-plan
description:
  Execute approved implementation plans phase-by-phase with verification
  checkpoints
argument-hint: '<plan-file.md>'
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Task
  - TaskCreate
  - TaskUpdate
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Execute an approved implementation plan from `/fm:create-plan`, implementing each phase with verification checkpoints.

**Default flow:** Read Plan → Understand Context → Execute Phase → Verify →
Human Checkpoint → Next Phase → Done

**What this does:**

1. Reads the plan and all referenced files fully
2. Creates a todo list to track progress
3. Implements each phase according to the plan
4. Runs automated verification (tests, lint, typecheck)
5. Pauses for human verification before proceeding to next phase
6. Updates checkboxes in the plan file as work completes

**Output:** Implemented code with all phases verified and plan checkboxes
updated.

**Key behavior:** This command respects the human-in-the-loop principle —
automated checks run freely, but manual verification requires explicit human
confirmation before proceeding. </objective>

<context>
Plan file path: $ARGUMENTS

**If arguments provided:**

- Read the plan file FULLY
- Read the original task/ticket referenced in the plan
- Read ALL files mentioned in the plan
- Check for existing checkmarks to determine resume point

**If no arguments provided:**

- Prompt user for the plan path
- Suggest recent plans from `.flomaster/plans/` </context>

<process>

## 0. Handle Invocation

**If `$ARGUMENTS` is empty:**

```
I'll help you execute an implementation plan.

Please provide the path to your plan file:
- From a task folder: `tasks/TASK-123/PLAN.md`
- From flomaster: `.flomaster/plans/2025-01-23-feature-name.md`

Example:
`/fm:execute-plan .flomaster/plans/2025-01-23-user-auth.md`

Tip: If you need to create a plan first, use:
`/fm:create-plan <task-file or description>`
```

Then wait for user input.

**If `$ARGUMENTS` provided:**

- Proceed to Step 1

## 1. Read and Understand the Plan

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► LOADING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1a. Read the Plan File Completely

**CRITICAL:** Use Read tool WITHOUT limit/offset parameters. Read the entire
file. If a file is too large, read in chunks of 1000 lines.

### 1b. Check for Resume Point

Scan for existing checkmarks (`- [x]`):

- If checkmarks exist → plan is partially complete
- Find the first unchecked item (`- [ ]`)
- That's where to resume

### 1c. Read All Referenced Files

From the plan, identify and read FULLY:

- Original task/ticket file (from References section)
- All files listed in "Changes Required" sections
- Any related research documents
- Configuration files mentioned

**CRITICAL:** Never use limit/offset. Full context is essential for correct
implementation. If a file is too large, read in chunks of 1000 lines.

### 1d. Create Todo List

Use TaskCreate to create a todo list tracking:

- Each phase as a major item
- Key changes within each phase as sub-items

## 2. Verify Understanding

Before implementing, confirm understanding:

```
Based on the plan at `{plan_path}`, I understand:

**Goal:** [summary from Overview]

**Current Progress:**
- Phases completed: [N] of [M]
- Resume point: Phase [X], step [Y]

**This session:** I'll implement Phase [X]

**Files I'll modify:**
- [file 1] — [change summary]
- [file 2] — [change summary]

Ready to begin?
```

Wait for user confirmation before proceeding.

## 3. Execute Current Phase

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► EXECUTING PHASE [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ [Phase name from plan]
```

### 3a. Follow the Plan's Intent

Implement each change as specified in the plan:

- Follow the code patterns shown
- Respect the file structure indicated
- Apply changes in the order specified

### 3b. Adapt When Necessary

Plans are guides, not rigid scripts. If you encounter something unexpected:

**Minor discrepancies** (naming differs slightly, file moved):

- Adapt silently and continue
- Document the adaptation in a comment or note

**Significant mismatches:**

- STOP implementation
- Present the issue clearly:

```
Issue in Phase [N]:

Expected: [what the plan says]
Found: [actual situation]
Why this matters: [explanation]

Options:
1. [Adaptation approach] — [tradeoff]
2. [Alternative approach] — [tradeoff]
3. Ask for updated plan

How should I proceed?
```

Wait for user guidance.

### 3c. Update Plan Checkboxes

As you complete each item:

- Use Edit tool to change `- [ ]` to `- [x]` in the plan file
- This creates a persistent progress record

## 4. Run Automated Verification

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► VERIFYING PHASE [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4a. Run Success Criteria Commands

Execute each automated verification from the plan's "Automated Verification"
section:

```bash
# Common verification commands (use what the plan specifies)
npm run build
npm run typecheck
npm run lint
npm run test
```

### 4b. Handle Failures

**If verification fails:**

- Read the error output carefully
- Fix the issue
- Re-run verification
- Repeat until all automated checks pass

**If stuck on a failure:**

- Present the error clearly
- Explain what you've tried
- Ask for guidance

### 4c. Update Automated Checkboxes

Once all automated verification passes:

- Edit the plan file to check off each automated verification item

## 5. Pause for Human Verification

**This is the critical human-in-the-loop checkpoint.**

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► PHASE [N] READY FOR REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Automated verification passed:
✓ [List each automated check that passed]

Please perform manual verification from the plan:
- [ ] [Manual verification item 1]
- [ ] [Manual verification item 2]
- [ ] [Manual verification item N]

───────────────────────────────────────────────────────────────

When manual testing is complete, let me know:
- "continue" → proceed to Phase [N+1]
- "issue: [description]" → I'll address the problem
- "done" → if this was the final phase
```

**CRITICAL:** Do NOT proceed until user confirms. Do NOT check off manual
verification items yourself.

## 6. Handle User Response

**If "continue" or similar:**

- Check off manual verification items in the plan (user confirmed they pass)
- Proceed to next phase (return to Step 3)

**If "issue: [description]":**

- Understand the issue
- Fix it
- Re-run relevant verification
- Present for review again

**If "done" or final phase complete:**

- Proceed to Step 7 (Completion)

## 7. Multi-Phase Execution

**If user requests multiple phases:** (e.g., "execute phases 2-4" or "execute
all remaining phases")

- Execute each phase fully
- Run automated verification for each
- Skip human checkpoint pause UNTIL the final phase
- Present consolidated manual verification at the end

## 8. Completion

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► EXECUTION COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Plan:** `{plan_path}`
**Phases completed:** [N] of [M]

All automated verification passed.
All manual verification confirmed by user.
```

</process>

<anti_patterns>

- Don't read files partially — always read complete files without limit/offset
- Don't check off manual verification items without user confirmation
- Don't skip the human checkpoint pause (unless explicitly doing multi-phase
  execution)
- Don't assume the codebase matches the plan exactly — adapt thoughtfully
- Don't proceed after a verification failure without fixing the issue
- Don't implement multiple phases without verifying each one
- Don't ignore the plan's specified order or approach without good reason
- Don't forget to update checkboxes in the plan file as you complete items
  </anti_patterns>

<offer_next> Output this markdown directly (not as a code block):

**Route A: More phases remain**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PHASE [N] COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Progress:** Phase [N] of [M] complete

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Continue to Phase [N+1]** — {phase name}

`/fm:execute-plan {plan_path}` or just say "continue"

<sub>`/clear` first → fresh context window (recommended for large phases)</sub>

───────────────────────────────────────────────────────────────

---

**Route B: All phases complete**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PLAN COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{Plan Name}** — all {N} phases executed and verified

Location: `{plan_path}`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Commit your changes** — create a clean commit

`/commit`

───────────────────────────────────────────────────────────────

**Also available:**

- `cat {plan_path}` — review the completed plan
- `/fm:create-plan {another-task}` — start next feature

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> fm:execute-plan is complete when:

- [ ] Plan file read FULLY
- [ ] All referenced files read FULLY
- [ ] Resume point identified (if applicable)
- [ ] Understanding confirmed with user before starting
- [ ] Current phase implemented according to plan
- [ ] Mismatches handled (adapted or escalated to user)
- [ ] Automated verification passed
- [ ] Checkboxes updated in plan file for completed items
- [ ] Human verification checkpoint reached
- [ ] User confirmed manual testing passed
- [ ] Next steps presented (continue, commit, or done) </success_criteria>
