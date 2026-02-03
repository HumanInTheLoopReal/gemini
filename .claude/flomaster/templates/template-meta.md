# FM Template Meta-Structure Template

Template for `.claude/flomaster/templates/{template-name}.md` — defines the
structure all FM templates must follow.

> **Related:** [fm:rewrite-template](../../commands/fm/rewrite-template.md)
> (uses this to convert/create templates)

---

## File Template

````markdown
# {Template Name} Template

Template for `{output-path}` — {one-line-purpose}.

> **Related:** {optional-links-to-related-workflows-or-agents}

---

## File Template

```markdown
{actual-template-content-with-placeholders}
```
````

<purpose>

{2-3-sentences-explaining-what-this-file-is-what-problem-it-solves-why-it-exists}

</purpose>

<sections>

### {Section Name}

**Goal:** {what-this-section-accomplishes} **Include:** {what-belongs-here}
**Exclude:** {what-does-NOT-belong} **Format:**
{how-to-structure-bullets-table-prose}

### {Another Section Name}

**Goal:** {purpose} **Include:** {what-belongs} **Exclude:**
{what-doesnt-belong} **Format:** {structure} **When to omit:**
{conditions-for-optional-sections}

</sections>

<lifecycle>

**When created:** {command-or-trigger-that-creates-this-file} **When read:**
{who-or-what-consumes-this-file} **When updated:** {triggers-for-updates}

</lifecycle>

<guidelines>

**The Core Filter Question:** Before including ANY information, ask:

> "{template-specific-question-that-determines-if-content-belongs}"

**Quality criteria:**

- {specific-testable-criterion}
- {another-criterion}

**Sizing rules:**

- {size-constraint-with-specific-limits}

**Content standards:**

- {standard-that-affects-how-content-is-written}

</guidelines>

<examples>

**Example 1: {Scenario Name}**

```markdown
{complete-filled-out-template-for-scenario-1}
```

**Example 2: {Different Scenario Name}**

```markdown
{complete-filled-out-template-for-scenario-2}
```

</examples>

<anti_patterns>

**Bad:** {what-not-to-do}

```markdown
{bad-example}
```

**Good:** {correct-approach}

```markdown
{good-example-showing-the-transformation}
```

---

{repeat-for-each-anti-pattern-separated-by-horizontal-rules}

</anti_patterns>

````

<purpose>

The FM Template Meta-Structure defines the canonical format for all FM templates. It ensures consistency across the template library, provides clear guidance for template authors, and makes templates self-documenting. Every FM template follows this structure so that agents and humans can reliably parse, understand, and use any template in the system.

</purpose>

<sections>

### Header
**Goal:** Instant identification of template purpose
**Include:** Template name, output path, one-line purpose, related links
**Exclude:** Detailed explanations (save for purpose section)
**Format:** `# {Name} Template` followed by subtitle and optional related links

### File Template
**Goal:** Provide the actual template content ready for use
**Include:** Complete template with `{placeholders}` for variable content, inline comments for guidance
**Exclude:** Explanations of how to fill it (save for sections/guidelines)
**Format:** Markdown code block containing the template structure

### Purpose Section
**Goal:** Explain WHY this template exists
**Include:** What the file is, what problem it solves, why it exists in the workflow
**Exclude:** How to fill it out, usage instructions
**Format:** 2-3 sentences of prose in `<purpose>` tags

### Sections Section
**Goal:** Provide field-by-field guidance for each major part of the template
**Include:** Goal/Include/Exclude/Format for each section, optional "When to omit" for optional sections
**Exclude:** Examples (save for examples section), general guidelines (save for guidelines section)
**Format:** H3 headers for each section with structured guidance fields
**When to omit:** Only if the template has 2 or fewer simple sections

### Lifecycle Section
**Goal:** Document when the file is created, read, and updated
**Include:** Creation triggers, consumers, update triggers
**Exclude:** Detailed workflow descriptions
**Format:** Three labeled fields in `<lifecycle>` tags

### Guidelines Section
**Goal:** Establish quality criteria and content standards
**Include:** Core filter question, testable quality criteria, sizing rules, content standards
**Exclude:** Section-specific guidance (save for sections), examples
**Format:** Structured fields with specific, actionable rules in `<guidelines>` tags

### Examples Section
**Goal:** Show concrete, realistic filled-out templates
**Include:** 2-3 complete examples covering different scenarios
**Exclude:** Explanations of why examples are structured that way
**Format:** Named examples with full template content in code blocks within `<examples>` tags

### Anti-patterns Section
**Goal:** Prevent common mistakes by showing Bad to Good transformations
**Include:** Common mistakes with before/after examples, realistic scenarios
**Exclude:** Positive guidance (save for guidelines)
**Format:** Bad/Good pairs separated by horizontal rules in `<anti_patterns>` tags
**When to omit:** Only if the template is extremely simple with no common misuse patterns

</sections>

<lifecycle>

**When created:** `/fm:rewrite-template` command or manual authoring for new template types
**When read:** Template authors creating new FM templates, agents using `/fm:rewrite-template`, anyone reviewing template standards
**When updated:** When FM template conventions evolve or new best practices emerge

</lifecycle>

<guidelines>

**The Core Filter Question:**
Before including ANY section or guidance, ask:
> "Will someone filling out a template based on this structure understand exactly what to write and how to format it?"

**Quality criteria:**
- Every placeholder uses `{descriptive-name}` format with hyphens
- Examples are complete and realistic (no placeholder text remaining)
- Guidelines are specific and testable (could verify yes/no)
- Anti-patterns show transformation (Bad to Good, not just "don't do X")

**Sizing rules:**
- Purpose: 2-3 sentences maximum
- Sections guidance: 4 lines per section (Goal/Include/Exclude/Format)
- Examples: 2-3 examples minimum, each must be complete
- Anti-patterns: 3-5 patterns covering different failure modes

**Content standards:**
- Use sentence case for section headers
- Use present tense for all guidance
- Be prescriptive, not suggestive ("Include X" not "You might want to include X")
- Inline comments in templates use `<!-- explanation -->` format

</guidelines>

<examples>

**Example 1: Phase Summary Template**

```markdown
# Phase Summary Template

Template for `.planning/{milestone}/phase-{N}/SUMMARY.md` — captures what happened during phase execution.

> **Related:** [execute-phase](../../commands/gsd/execute-phase.md), [phase-plan](./phase-plan.md)

---

## File Template

```markdown
# Phase {phase-number}: {phase-title} - Summary

**Status**: {STATUS}
<!-- STATUS: COMPLETE | PARTIAL | BLOCKED -->

## What Was Built

{2-4-bullet-points-of-concrete-deliverables}

## Key Decisions Made

{decisions-that-affect-future-phases}

## Issues Encountered

{blockers-or-unexpected-problems}
<!-- Remove section if none -->

## Files Changed

- `{path}` - {what-changed}

---
*Completed: {YYYY-MM-DD}*
````

<purpose>

Phase summaries capture the outcome of phase execution for future context. They
document what was actually built (vs planned), key decisions that affect later
work, and any issues encountered. This enables session continuity and helps
future agents understand project history.

</purpose>

<sections>

### What Was Built

**Goal:** Document concrete deliverables from this phase **Include:** Actual
outputs, features completed, artifacts created **Exclude:** Plans, intentions,
or work that was attempted but not finished **Format:** 2-4 bullet points with
specific deliverables

### Key Decisions Made

**Goal:** Capture decisions that affect future phases **Include:** Architecture
choices, trade-offs made, deviations from plan **Exclude:** Routine
implementation details **Format:** Bullet points with context for WHY decision
was made

### Issues Encountered

**Goal:** Document problems for future reference **Include:** Blockers,
unexpected complications, workarounds used **Exclude:** Issues that were
resolved and have no future impact **Format:** Bullet points with problem and
resolution/status **When to omit:** If no significant issues encountered

### Files Changed

**Goal:** Quick reference for what was modified **Include:** Files created,
modified, or deleted with brief purpose **Exclude:** Generated files, lock
files, trivial changes **Format:** Bulleted list with path and description

</sections>

<lifecycle>

**When created:** End of `/gsd:execute-phase` after phase work completes **When
read:** Future sessions resuming work, `/gsd:progress` status checks **When
updated:** Rarely - only if significant context was missed initially

</lifecycle>

<guidelines>

**The Core Filter Question:** Before including ANY information, ask:

> "Will the next session make a wrong decision without this?"

**Quality criteria:**

- Every bullet point is concrete and specific (no vague summaries)
- Decisions include the WHY, not just the WHAT
- Issues include resolution status or next steps

**Sizing rules:**

- What Was Built: 2-4 bullets maximum
- Key Decisions: 1-3 decisions (only significant ones)
- Issues: 0-3 (remove section if none)
- Files Changed: Only files relevant to understanding the change

**Content standards:**

- Use past tense (this documents what happened)
- Be specific about file paths and function names
- Include dates in ISO format

</guidelines>

<examples>

**Example 1: Feature Implementation**

```markdown
# Phase 3: User Authentication - Summary

**Status**: COMPLETE

## What Was Built

- JWT-based authentication flow with refresh tokens
- Login/logout API endpoints (`/api/auth/*`)
- Protected route middleware for Express
- Session persistence using Redis

## Key Decisions Made

- Chose JWT over session cookies for stateless scaling (mobile app planned for
  Q2)
- Set token expiry to 15 minutes with 7-day refresh window (security vs UX
  balance)
- Used Redis for refresh token storage instead of PostgreSQL (faster lookups)

## Files Changed

- `src/middleware/auth.ts` - New auth middleware
- `src/routes/auth.ts` - Login/logout/refresh endpoints
- `src/services/token.ts` - JWT generation and validation
- `docker-compose.yml` - Added Redis service

---

_Completed: 2024-01-15_
```

**Example 2: Bug Fix Phase**

```markdown
# Phase 7: Memory Leak Fix - Summary

**Status**: COMPLETE

## What Was Built

- Fixed event listener cleanup in WebSocket handler
- Added memory monitoring to health check endpoint
- Heap snapshot tooling for future debugging

## Key Decisions Made

- Used WeakMap for client tracking instead of Map (automatic GC)
- Added 512MB memory limit to container config (fail-fast vs OOM)

## Issues Encountered

- Initial fix caused connection drops - reverted and used different approach
- Had to upgrade ws library to 8.x for proper cleanup hooks

## Files Changed

- `src/websocket/handler.ts` - Fixed listener cleanup
- `src/health/index.ts` - Added memory metrics
- `package.json` - Upgraded ws to 8.14.0

---

_Completed: 2024-01-18_
```

</examples>

<anti_patterns>

**Bad:** Vague summaries

```markdown
## What Was Built

- Worked on authentication
- Fixed some bugs
- Updated dependencies
```

**Good:** Specific deliverables

```markdown
## What Was Built

- JWT authentication with 15-min access / 7-day refresh tokens
- POST /api/auth/login and /api/auth/refresh endpoints
- authMiddleware() protecting all /api/protected/\* routes
```

---

**Bad:** Decisions without context

```markdown
## Key Decisions Made

- Used Redis
- JWT instead of sessions
```

**Good:** Decisions with WHY

```markdown
## Key Decisions Made

- Used Redis for refresh tokens (faster lookups than PostgreSQL, tokens are
  ephemeral)
- JWT over sessions (stateless for horizontal scaling, mobile app needs this)
```

---

**Bad:** Including every file touched

```markdown
## Files Changed

- src/auth.ts
- src/auth.test.ts
- package.json
- package-lock.json
- .gitignore
- tsconfig.json
- README.md
```

**Good:** Only meaningful changes

```markdown
## Files Changed

- `src/middleware/auth.ts` - New auth middleware
- `src/routes/auth.ts` - Login/logout endpoints
- `package.json` - Added jsonwebtoken dependency
```

</anti_patterns>

````

**Example 2: Handoff Context Template**

```markdown
# Handoff Context Template

Template for `.planning/HANDOFF.md` — transfers working context between sessions.

---

## File Template

```markdown
# Session Handoff

**From:** {previous-session-date-and-time}
**Status:** {READY_TO_CONTINUE | BLOCKED | NEEDS_REVIEW}

## Current State

{2-3-sentences-describing-where-things-stand}

## In Progress

- [ ] {task-that-was-being-worked-on}
  - Last action: {what-was-done}
  - Next step: {what-to-do-next}

## Blockers (if any)

- {blocker-description}: {what-is-needed-to-unblock}

## Key Context

{information-the-next-session-needs-to-avoid-re-discovering}

## Resumption Command

```bash
{exact-command-to-continue-work}
````

---

_Handoff created: {YYYY-MM-DD HH:MM}_

````

<purpose>

Handoff documents transfer working context between sessions, enabling seamless continuation without re-discovery. They capture the exact state of work, what was being done, and how to resume, preventing the "cold start" problem where a new session wastes tokens re-learning context.

</purpose>

<sections>

### Current State
**Goal:** Quick orientation on project status
**Include:** High-level summary of where things stand, phase/milestone context
**Exclude:** Detailed history, completed work
**Format:** 2-3 sentences of prose

### In Progress
**Goal:** Show exactly what was being worked on
**Include:** Active tasks, last action taken, immediate next step
**Exclude:** Completed tasks, future roadmap items
**Format:** Checkbox list with sub-bullets for last/next

### Blockers
**Goal:** Surface anything preventing progress
**Include:** What's blocked and what's needed to unblock
**Exclude:** Resolved blockers, minor inconveniences
**Format:** Bullet list with blocker and resolution needed
**When to omit:** If no blockers exist

### Key Context
**Goal:** Prevent re-discovery of important information
**Include:** Decisions made, gotchas discovered, relevant findings
**Exclude:** Information already documented elsewhere
**Format:** Prose or bullets depending on content

### Resumption Command
**Goal:** One-click continuation
**Include:** Exact command to resume work
**Exclude:** Alternative approaches, explanations
**Format:** Single code block with bash command

</sections>

<lifecycle>

**When created:** `/fm:generate-handoff` at session end, or manually when pausing work
**When read:** Session start via `/gsd:resume-work` or manual review
**When updated:** Overwritten each time a new handoff is created (single active handoff)

</lifecycle>

<guidelines>

**The Core Filter Question:**
Before including ANY information, ask:
> "Will the next session waste time without this, or re-make a decision differently?"

**Quality criteria:**
- Resumption command is copy-pasteable and works immediately
- In Progress tasks have clear "last action" and "next step"
- Key Context contains only information not documented elsewhere

**Sizing rules:**
- Current State: 2-3 sentences maximum
- In Progress: 1-3 active tasks only
- Key Context: Under 200 words
- Total document: Under 50 lines

**Content standards:**
- Use present tense for state, past tense for last action
- Include timestamps in ISO format
- Commands must be tested before inclusion

</guidelines>

<examples>

**Example 1: Mid-Feature Handoff**

```markdown
# Session Handoff

**From:** 2024-01-15 14:30
**Status:** READY_TO_CONTINUE

## Current State

Implementing user authentication for Phase 3. Login endpoint complete, working on token refresh logic.

## In Progress

- [ ] Implement refresh token endpoint
  - Last action: Created token validation helper in `src/services/token.ts`
  - Next step: Add POST /api/auth/refresh route handler

## Key Context

- Using Redis for refresh tokens (decision: faster than PostgreSQL for ephemeral data)
- Access tokens expire in 15 minutes, refresh tokens in 7 days
- Found bug in jsonwebtoken 8.x - using 9.0.0 instead

## Resumption Command

```bash
/gsd:execute-phase 3
````

---

_Handoff created: 2024-01-15 14:30_

````

**Example 2: Blocked Handoff**

```markdown
# Session Handoff

**From:** 2024-01-16 11:00
**Status:** BLOCKED

## Current State

Phase 4 (API rate limiting) blocked on infrastructure decision. Need stakeholder input.

## In Progress

- [ ] Implement rate limiting middleware
  - Last action: Researched Redis vs in-memory approaches
  - Next step: Waiting on decision for multi-instance deployment

## Blockers

- Rate limiting strategy: Need to know if app will run single-instance or multi-instance
  - If single: Can use in-memory rate limiting (simpler)
  - If multi: Need Redis-based approach (Phase 3 Redis can be reused)

## Key Context

- Drafted both implementations in `src/middleware/rateLimit.ts` (commented alternatives)
- express-rate-limit supports both approaches with different stores

## Resumption Command

```bash
# After decision is made:
/gsd:execute-phase 4
````

---

_Handoff created: 2024-01-16 11:00_

````

</examples>

<anti_patterns>

**Bad:** Vague "in progress" descriptions
```markdown
## In Progress
- Working on authentication
- Some refactoring
````

**Good:** Specific with last/next

```markdown
## In Progress

- [ ] Implement refresh token endpoint
  - Last action: Created token validation helper
  - Next step: Add POST /api/auth/refresh handler
```

---

**Bad:** Including completed work

```markdown
## In Progress

- [x] Set up project structure
- [x] Configure TypeScript
- [x] Add ESLint
- [ ] Implement auth
```

**Good:** Only active work

```markdown
## In Progress

- [ ] Implement refresh token endpoint
  - Last action: Created token validation helper
  - Next step: Add POST /api/auth/refresh handler
```

---

**Bad:** Untested resumption command

````markdown
## Resumption Command

```bash
npm run continue-phase-3
```
````

````

**Good:** Verified, working command
```markdown
## Resumption Command
```bash
/gsd:execute-phase 3
````

```

</anti_patterns>
```

</examples>

<anti_patterns>

**Bad:** Missing purpose section

```markdown
# My Template

## File Template

...

<guidelines>
...
</guidelines>
```

**Good:** Purpose explains WHY

```markdown
# My Template

## File Template

...

<purpose>
This template captures phase execution outcomes for session continuity.
It documents what was built, decisions made, and issues encountered so
future sessions can understand project history without re-discovery.
</purpose>

<guidelines>
...
</guidelines>
```

---

**Bad:** Vague guidelines

```markdown
<guidelines>
- Make it good
- Include relevant information
- Keep it reasonable length
</guidelines>
```

**Good:** Specific, testable guidelines

```markdown
<guidelines>
**The Core Filter Question:**
> "Will the next session make a wrong decision without this?"

**Quality criteria:**

- Every bullet point is concrete (names specific files, functions, decisions)
- Decisions include the WHY, not just the WHAT

**Sizing rules:**

- What Was Built: 2-4 bullets maximum
- Key Decisions: 1-3 significant decisions only </guidelines>
```

---

**Bad:** Incomplete examples

````markdown
<examples>

**Example 1: Basic Usage**

```markdown
# Phase Summary

**Status**: {status}

## What Was Built

{stuff that was built}
```
````

</examples>
```

**Good:** Fully filled examples

````markdown
<examples>

**Example 1: Feature Implementation**

```markdown
# Phase 3: User Authentication - Summary

**Status**: COMPLETE

## What Was Built

- JWT-based authentication flow with refresh tokens
- Login/logout API endpoints (`/api/auth/*`)
- Protected route middleware for Express

## Key Decisions Made

- Chose JWT over session cookies for stateless scaling
- Set token expiry to 15 minutes with 7-day refresh

## Files Changed

- `src/middleware/auth.ts` - New auth middleware
- `src/routes/auth.ts` - Login/logout endpoints

---

_Completed: 2024-01-15_
```
````

</examples>
```

---

**Bad:** Anti-patterns without transformation

```markdown
<anti_patterns>

- Don't be vague
- Don't include too much
- Don't forget the purpose </anti_patterns>
```

**Good:** Bad to Good transformations

````markdown
<anti_patterns>

**Bad:** Vague summaries

```markdown
## What Was Built

- Worked on authentication
- Fixed some bugs
```
````

**Good:** Specific deliverables

```markdown
## What Was Built

- JWT authentication with 15-min access / 7-day refresh tokens
- POST /api/auth/login endpoint with bcrypt password validation
```

</anti_patterns>

````

---

**Bad:** Placeholders without format hints
```markdown
## File Template

```markdown
**Date**: {date}
**Status**: {status}
**Files**: {files}
````

````

**Good:** Placeholders with inline guidance
```markdown
## File Template

```markdown
**Date**: {YYYY-MM-DD HH:MM}
**Status**: {STATUS}
<!-- STATUS: ACTIVE | COMPLETE | BLOCKED | DEFERRED -->
**Files**: `{path}` - {purpose}
````

````

---

**Bad:** Sections guidance missing Exclude field
```markdown
<sections>

### What Was Built
**Goal:** Document deliverables
**Include:** Completed features
**Format:** Bullet points

</sections>
````

**Good:** Complete Goal/Include/Exclude/Format

```markdown
<sections>

### What Was Built

**Goal:** Document concrete deliverables from this phase **Include:** Actual
outputs, features completed, artifacts created **Exclude:** Plans, intentions,
or work attempted but not finished **Format:** 2-4 bullet points with specific
deliverables

</sections>
```

</anti_patterns>
