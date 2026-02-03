---
name: fm:generate-handoff
description:
  Generate a structured handoff document for session continuity. Use at the end
  of a work session to capture context, decisions, and next steps for a future
  Claude session.
argument-hint: [optional-descriptive-name]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - TaskCreate
  - TaskUpdate
  - TaskList
---

<objective>
Generate a handoff document that preserves session context for a future Claude session. The document enables a fresh session to continue work WITHOUT re-explaining context.

**What this does:**

1. Determines handoff file location (task folder or general handoffs)
2. Creates tracking tasks for section-by-section completion
3. Fills each section by reviewing conversation and applying noise filters
4. Produces complete handoff with file pointers and next steps

**Output:** Markdown handoff file at `build-cycle/tasks/{TASK-ID}/HANDOFF.md` or
`build-cycle/handoffs/YYYY-MM-DD-[name].md` </objective>

<execution_context> @./.claude/flomaster/templates/handoff-template.md
</execution_context>

<context>
Optional argument: $ARGUMENTS — descriptive name for the handoff file (used if no active task)

**Core filtering principle:**

> "If the next session doesn't have this information, will it:
>
> 1. Make a wrong decision?
> 2. Redo work that's already done?
> 3. Miss important context that changes the approach?
>
> **If NO to all three → DON'T INCLUDE IT**" </context>

<process>

## 1. Determine Handoff Location

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► INITIALIZING HANDOFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Determining handoff location...
```

**Decision tree:**

1. **Is this session about a specific task (TASK-XX)?**
   - Look for TASK-ID references in the conversation
   - Check project_tasks.md for what's in progress

2. **If YES (task exists)**: Use `build-cycle/tasks/{TASK-ID}/HANDOFF.md`
   - If HANDOFF.md **doesn't exist** → CREATE it with full template
   - If HANDOFF.md **already exists** → APPEND a new session entry (see template
     for format)

3. **If NO (no task context)**: Use
   `build-cycle/handoffs/YYYY-MM-DD-[descriptive-name].md`
   - Name from `$ARGUMENTS` or derive from session context
   - This is ONLY for orphan sessions with no task

**Key principle:** One task = one cumulative HANDOFF.md. Each session on that
task APPENDS to the same file, building a complete history. The handoffs/ folder
is only for sessions with no task context.

```bash
# Create directory as needed
mkdir -p build-cycle/tasks/{TASK-ID}/   # OR
mkdir -p build-cycle/handoffs/
```

---

## 2. Create Tracking Tasks

Use TaskCreate to create tasks for each handoff section:

1. Create handoff file with template
2. Fill Quick Context (with file pointers)
3. Fill What We Accomplished
4. Fill Key Decisions Made
5. Fill Technical Findings
6. Fill Current State
7. Fill Open Items
8. Fill Next Steps
9. Review and finalize

---

## 3. Create or Append Handoff

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► CREATING/APPENDING HANDOFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Checking if HANDOFF.md exists...
◆ Writing template structure (or appending session)...
```

**If HANDOFF.md doesn't exist:**

- Read the template from `<execution_context>`
- Write to the determined location with full template structure

**If HANDOFF.md already exists (task folder):**

- Read existing file
- APPEND a new session entry at the end:

```markdown
---

# Session: YYYY-MM-DD HH:MM

**Goal**: {what we set out to accomplish this session} **Outcome**: {SUCCESS |
PARTIAL | BLOCKED | PIVOTED}

## What We Did

- ✅ {outcome-1}
- ✅ {outcome-2}

## Key Findings

- {finding if any}

## What's Next

1. {next-action-1}
2. {next-action-2}
```

This keeps all sessions for a task in one cumulative document.

---

## 4. Fill Each Section

For EACH section (use TaskUpdate to track progress):

1. **Mark task in_progress**
2. **Review conversation** for content relevant to THIS section
3. **Apply noise filter** — only include what passes Core Principle
4. **Edit section** — replace `[TO BE FILLED]` with actual content
5. **Mark task completed**

**Section guidance** (see template file for details):

- **Quick Context**: 2-3 sentences + file pointers (CRITICAL)
- **Accomplished**: Concrete outcomes with ✅ checkmarks
- **Decisions**: Table format, include rationale
- **Findings**: Finding → Evidence → Implication
- **Current State**: Artifacts + locations
- **Open Items**: Table with status (BLOCKED/DEFERRED/OPEN)
- **Next Steps**: Numbered priority list

---

## 5. Review and Finalize

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► FINALIZING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Running fresh session test...
```

Verify handoff passes the "fresh session test":

- [ ] Could a new session understand what happened?
- [ ] Could it continue without clarifying questions?
- [ ] Would it avoid re-doing completed work?

Check for: redundant info, missing file pointers, unclear language.

</process>

<anti_patterns>

- Don't include back-and-forth clarifications — only final decisions
- Don't include failed debugging attempts — unless they taught something
- Don't include tool outputs with no signal
- Don't include intermediate states — code that was later replaced
- Don't include process narration — "First I read the file..."
- Don't include emotional content — "Great question!"
- Don't repeat information that's in pointed-to files </anti_patterns>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► HANDOFF COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Location**: {handoff_file_path} **Task**: {TASK-ID or "General"} **Action**:
{CREATED new handoff | APPENDED session entry}

**File pointers included:**

- {list of files the next session should read}

───────────────────────────────────────────────────────────────

## ▶ Session Complete

The handoff document is ready. A future Claude session can resume by reading
this handoff file.

**Recommended**: `/clear` to start fresh context for next task.

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> Handoff generation is complete when:

- [ ] Location determined (task folder if task exists, handoffs/ folder
      otherwise)
- [ ] Checked if HANDOFF.md exists (append vs create)
- [ ] Tracking tasks created
- [ ] Content filled (full template if new, session entry if appending) and
      passes noise filter
- [ ] File pointers included in Quick Context (or in session entry)
- [ ] Fresh session test passes
- [ ] User informed of location and whether created or appended
      </success_criteria>
