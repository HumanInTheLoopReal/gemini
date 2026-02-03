# FM Command Template

Template for `.claude/commands/fm/{command-name}.md` — Standardized slash
command structure with behavioral patterns for user feedback, agent
orchestration, and workflow routing.

> **Related:**
> [rewrite-command-with-template.md](../../commands/fm/rewrite-command-with-template.md),
> [rewrite-template.md](../../commands/fm/rewrite-template.md)

---

## File Template

````markdown
---
name: fm:{command-name}
description: { one-line-description }
argument-hint: '{argument-description}'
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

<objective>
{brief-1-2-sentence-description}

**What this does:**

1. {step-1}
2. {step-2}
3. {step-3}

**Output:** {what-the-command-produces}

<!-- For orchestrator commands that spawn subagents, add: -->
<!-- Context budget: ~{X}% orchestrator, 100% fresh per subagent. -->
</objective>

<execution_context>

<!-- Optional: Reference external workflow and template files -->

@./.claude/flomaster/workflows/{relevant-workflow}.md
@./.claude/flomaster/templates/{relevant-template}.md </execution_context>

<context>
{argument-name}: $ARGUMENTS

**Files to load:** @{file-reference-1} @{file-reference-2} </context>

<process>

## 0. Resolve Model Profile

<!-- Include this step only if command spawns agents -->

```bash
MODEL_PROFILE=$(cat .flomaster/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```
````

**Model lookup table:**

| Agent         | quality | balanced | budget |
| ------------- | ------- | -------- | ------ |
| fm-researcher | opus    | sonnet   | haiku  |
| fm-planner    | opus    | opus     | sonnet |
| fm-executor   | opus    | sonnet   | sonnet |

## 1. {first-major-step}

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► {STAGE NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ {What's happening...}
```

{step-content}

```bash
{code-blocks-as-needed}
```

## 2. {second-major-step}

{step-content}

## N. Handle {Agent} Return

<!-- Include after any step that spawns an agent -->

Parse agent output:

**`## {SUCCESS_STATUS}`:**

- Display: `{Success message}`
- Proceed to step {X}

**`## {BLOCKED_STATUS}`:**

- Present blocker information
- Offer options: 1) {Option A}, 2) {Option B}, 3) {Option C}
- Wait for user response

**`## {INCONCLUSIVE_STATUS}`:**

- Show what was attempted
- Offer: Add context, Retry, Manual

</process>

<anti_patterns>

- Don't {anti-pattern-1}
- Don't {anti-pattern-2}
- Don't {anti-pattern-3} </anti_patterns>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► {COMPLETION STATUS} ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Completion summary}

───────────────────────────────────────────────────────────────

## ▶ Next Up

**{Next action}** — {brief description}

`/fm:{next-command}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────

**Also available:**

- `/fm:{alternative-1}` — {description}
- `/fm:{alternative-2}` — {description}

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> {command-name} is complete when:

- [ ] {criterion-1}
- [ ] {criterion-2}
- [ ] {criterion-N}
- [ ] User informed of next steps </success_criteria>

````

<purpose>

This template defines the standard structure for FM (FloMaster) slash commands. It ensures commands provide consistent user feedback through stage banners, handle agent orchestration properly with structured prompts and return state machines, and route users to appropriate next actions. The template separates lean orchestration logic (in the command file) from detailed workflows (in external files).

</purpose>

<sections>

### YAML Frontmatter
**Goal:** Declare command metadata for discovery and execution
**Include:** name (with `fm:` prefix), description, argument-hint, allowed-tools list
**Exclude:** Implementation details, behavioral logic
**Format:** Standard YAML between `---` markers

### `<objective>`
**Goal:** Provide quick understanding of what the command does and why
**Include:** 1-2 sentence description, numbered "What this does" list, output description, context budget (for orchestrators)
**Exclude:** Implementation details, step-by-step process, error handling
**Format:** Brief prose + numbered list + one-liner output statement

### `<execution_context>`
**Goal:** Reference external workflow and template files
**Include:** `@` references to workflow files, template files used by the command
**Exclude:** Inline workflow logic, template content
**Format:** One `@` reference per line
**When to omit:** Simple commands that don't need external workflows

### `<context>`
**Goal:** Define inputs and files the command needs
**Include:** `$ARGUMENTS` reference with description, `@` file references
**Exclude:** Processing logic, conditionals
**Format:** Variable declarations + "Files to load" section with `@` refs

### `<process>`
**Goal:** Define the step-by-step execution flow
**Include:** Numbered steps, stage banners, bash code blocks, conditionals, agent spawn logic, handle-return sections
**Exclude:** Success criteria, next-step routing, anti-patterns
**Format:** Numbered `## N. {Step Name}` headers with content beneath each

### `<anti_patterns>`
**Goal:** Prevent common mistakes when implementing or modifying the command
**Include:** Don't statements with specific behaviors to avoid
**Exclude:** Positive guidance (that belongs in process), vague warnings
**Format:** Bulleted "Don't {action}" statements
**When to omit:** Simple commands with obvious implementation

### `<offer_next>`
**Goal:** Route user to appropriate next action after command completes
**Include:** Completion banner, summary, next command suggestion, alternatives
**Exclude:** Conditionals, decision logic (use routing table for multiple paths)
**Format:** Stage banner + summary + "Next Up" section + "Also available" list

### `<success_criteria>`
**Goal:** Define completion checklist for the command
**Include:** Testable criteria derived from process steps, final "user informed" item
**Exclude:** Implementation details, process steps (just outcomes)
**Format:** Bulleted `- [ ] {criterion}` checklist

</sections>

<lifecycle>

**When created:** When building a new FM slash command, or converting an existing command to FM format via `/fm:rewrite-command-with-template`
**When read:** By Claude when user invokes the slash command (e.g., `/fm:plan-phase`)
**When updated:** When command behavior needs modification, when adding new patterns, or when fixing bugs in command logic

</lifecycle>

<guidelines>

**The Core Filter Question:**
Before including ANY content in a command file, ask:
> "Does this belong in the lean orchestration layer, or should it be extracted to a workflow file?"

**Quality criteria:**
- Command file stays lean: ~50-150 lines for orchestration
- Every agent spawn has a corresponding "Handle Return" section
- Stage banners appear before long operations and at completion
- All required sections present: objective, process, success_criteria

**Sizing rules:**
- Objective: 2-5 lines of prose + numbered list
- Process steps: Each step 10-30 lines including code blocks
- Success criteria: 4-8 checklist items
- Anti-patterns: 3-10 items

**Content standards:**
- Use `FM ►` branding in all banners (not GSD, not generic)
- Use `fm:` prefix in command names and references
- Inline file contents for Task() calls (@ syntax doesn't work across agent boundaries)
- Include model profile resolution for commands that spawn agents

**Specialized sections (add when needed):**

| Section | When to add | Purpose |
|---------|-------------|---------|
| `<wave_execution>` | Parallel agent spawning | Document how to spawn multiple agents |
| `<checkpoint_handling>` | Non-autonomous agents | Document pause/resume flow |
| `<deviation_rules>` | Execution commands | Define auto-fix vs ask-user thresholds |
| `<commit_rules>` | Commands that modify code | Define git commit patterns |
| `<validation_rules>` | Commands with verification | Define what passes/fails |

</guidelines>

<examples>

**Example 1: Simple verification command**

```markdown
---
name: fm:verify-plan
description: Verify a phase plan is ready for execution
argument-hint: "<phase-number>"
allowed-tools:
  - Read
  - Bash
  - AskUserQuestion
---

<objective>
Verify that a phase plan meets quality standards before execution.

**What this does:**
1. Loads the phase plan file
2. Checks required sections exist
3. Validates success criteria are testable
4. Reports verification result

**Output:** Verification report with pass/fail status and any issues found.
</objective>

<context>
Phase number: $ARGUMENTS

**Files to load:**
@.flomaster/phases/{phase}/PLAN.md
</context>

<process>

## 1. Load and Parse Plan

Display stage banner:
````

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► VERIFYING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Checking phase $ARGUMENTS plan...

````

```bash
PLAN_FILE=".flomaster/phases/${ARGUMENTS}/PLAN.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan not found at $PLAN_FILE"
  exit 1
fi
````

## 2. Check Required Sections

```bash
grep -q "## Overview" "$PLAN_FILE" && echo "✓ Overview" || echo "✗ Overview MISSING"
grep -q "## Tasks" "$PLAN_FILE" && echo "✓ Tasks" || echo "✗ Tasks MISSING"
grep -q "## Success Criteria" "$PLAN_FILE" && echo "✓ Success Criteria" || echo "✗ Success Criteria MISSING"
```

## 3. Report Results

Present verification summary to user with pass/fail status.

</process>

<anti_patterns>

- Don't approve plans missing required sections
- Don't skip verification even if plan "looks complete"
- Don't modify the plan file during verification </anti_patterns>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► VERIFICATION COMPLETE
✓ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase {phase} plan verified successfully.

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Execute the plan** — implement the verified phase

`/fm:execute-phase {phase}`

<sub>`/clear` first → fresh context window</sub>

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> Plan verification is complete when:

- [ ] Plan file located and loaded
- [ ] Required sections checked (Overview, Tasks, Success Criteria)
- [ ] Verification result reported to user
- [ ] User informed of next steps </success_criteria>

````

**Example 2: Orchestrator command with agent spawning**

```markdown
---
name: fm:research-topic
description: Research a topic using parallel research agents
argument-hint: "<topic-description>"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
  - AskUserQuestion
---

<objective>
Research a topic comprehensively using specialized research agents.

**Default flow:** Parse topic → Spawn researchers → Collect results → Synthesize → Done

**Orchestrator role:** Parse topic, spawn research agents in parallel, collect and synthesize results.

**Why subagents:** Research burns context fast with web fetches and document analysis. Fresh context per agent ensures quality.

**Output:** Research summary document at `.flomaster/research/{topic-slug}.md`

Context budget: ~15% orchestrator, 100% fresh per subagent.
</objective>

<execution_context>
@./.claude/flomaster/workflows/research-workflow.md
</execution_context>

<context>
Topic: $ARGUMENTS
</context>

<process>

## 0. Resolve Model Profile

```bash
MODEL_PROFILE=$(cat .flomaster/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
````

**Model lookup table:**

| Agent         | quality | balanced | budget |
| ------------- | ------- | -------- | ------ |
| fm-researcher | opus    | sonnet   | haiku  |

## 1. Parse Topic and Plan Research

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► PLANNING RESEARCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Analyzing topic: $ARGUMENTS
```

Parse topic into research angles. Identify 2-3 sub-topics for parallel research.

## 2. Spawn Research Agents

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► RESEARCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning {N} research agents...
```

For each research angle, spawn agent:

```
Task(prompt="
<research_context>
**Topic:** {topic}
**Angle:** {specific-angle}
**Scope:** {what-to-cover}
</research_context>

<downstream_consumer>
Output consumed by orchestrator for synthesis.
Return structured findings with sources.
</downstream_consumer>

<quality_gate>
Before returning RESEARCH COMPLETE:
- [ ] At least 3 credible sources cited
- [ ] Key findings clearly summarized
- [ ] Gaps or uncertainties noted
</quality_gate>

<expected_output>
Return one of:
- ## RESEARCH COMPLETE — findings ready
- ## RESEARCH BLOCKED — couldn't find reliable sources
- ## RESEARCH INCONCLUSIVE — mixed or contradictory findings
</expected_output>
", subagent_type="fm-researcher", model="{resolved_model}", description="Research: {angle}")
```

## 3. Handle Researcher Returns

Parse each agent output:

**`## RESEARCH COMPLETE`:**

- Collect findings
- Proceed to synthesis

**`## RESEARCH BLOCKED`:**

- Note the blocked angle
- Ask user: Provide sources? Skip angle? Abort?

**`## RESEARCH INCONCLUSIVE`:**

- Flag for manual review
- Include in synthesis with caveats

## 4. Synthesize Results

Combine findings from all researchers into coherent summary document.

Write to `.flomaster/research/{topic-slug}.md`

</process>

<anti_patterns>

- Don't pass @ file references to Task() — inline content instead
- Don't spawn more than 5 research agents (context overhead)
- Don't synthesize without noting which findings are inconclusive
- Don't skip the quality gate check in agent prompts </anti_patterns>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► RESEARCH COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{topic}** — research synthesized

Location: `.flomaster/research/{topic-slug}.md`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Review findings** — read the research summary

`cat .flomaster/research/{topic-slug}.md`

───────────────────────────────────────────────────────────────

**Also available:**

- `/fm:research-topic {different-topic}` — research another topic
- `/fm:plan-phase` — use research to plan implementation

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> Research is complete when:

- [ ] Topic parsed into research angles
- [ ] Research agents spawned for each angle
- [ ] All agent returns handled appropriately
- [ ] Findings synthesized into summary document
- [ ] Document written to `.flomaster/research/`
- [ ] User informed of output location and next steps </success_criteria>

````

**Example 3: Command with routing table**

```markdown
---
name: fm:check-status
description: Check project status and route to appropriate next action
argument-hint: ""
allowed-tools:
  - Read
  - Bash
---

<objective>
Check current project status and route user to the most appropriate next action.

**What this does:**
1. Reads project state files
2. Determines current status
3. Routes to recommended next action

**Output:** Status summary with recommended next command.
</objective>

<context>
**Files to load:**
@.flomaster/STATE.md
@.flomaster/ROADMAP.md
</context>

<process>

## 1. Read State Files

```bash
STATE=$(cat .flomaster/STATE.md 2>/dev/null || echo "NOT_FOUND")
ROADMAP=$(cat .flomaster/ROADMAP.md 2>/dev/null || echo "NOT_FOUND")
````

## 2. Determine Status

Parse state to determine:

- Current phase number
- Phase status (planning, executing, verifying, complete)
- Any blockers

## 3. Route to Next Action

Based on status, determine route (see `<offer_next>` routing table).

</process>

<offer_next> Output this markdown directly (not as a code block). Route based on
status:

| Status               | Route   |
| -------------------- | ------- |
| `no_project`         | Route A |
| `needs_planning`     | Route B |
| `ready_to_execute`   | Route C |
| `execution_complete` | Route D |

---

**Route A: No project initialized**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► NO PROJECT FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No FloMaster project detected in this directory.

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Initialize project** — set up FloMaster structure

`/fm:new-project`

───────────────────────────────────────────────────────────────

---

**Route B: Needs planning**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PHASE {N} NEEDS
PLANNING ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase {N} is ready for planning.

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Plan the phase** — create execution plan

`/fm:plan-phase {N}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────

---

**Route C: Ready to execute**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PHASE {N} READY TO
EXECUTE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase {N} has a verified plan ready for execution.

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Execute the phase** — implement the plan

`/fm:execute-phase {N}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────

---

**Route D: Execution complete**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► PHASE {N} COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase {N} execution complete. Ready for verification.

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Verify the work** — check implementation against plan

`/fm:verify-work {N}`

<sub>`/clear` first → fresh context window</sub>

─────────────────────────────────────────────────────────────── </offer_next>

<success_criteria> Status check is complete when:

- [ ] State files read (or noted as missing)
- [ ] Current status determined
- [ ] Appropriate route selected
- [ ] User shown status summary and next action </success_criteria>

````

</examples>

<anti_patterns>

**Bad:** Vague objective without clear output
```markdown
<objective>
This command helps with planning.
</objective>
````

**Good:** Specific objective with numbered steps and output

```markdown
<objective>
Create a detailed execution plan for a project phase.

**What this does:**

1. Loads phase requirements from roadmap
2. Spawns planning agent with full context
3. Writes verified plan to phase directory

**Output:** Plan file at `.flomaster/phases/{N}/PLAN.md` </objective>
```

---

**Bad:** Missing handle-return section after agent spawn

```markdown
## 3. Spawn Planner Agent

Task(prompt="...", subagent_type="fm-planner", ...)

## 4. Write Plan File

<!-- Assumes agent always succeeds -->
```

**Good:** Explicit state machine for all return cases

```markdown
## 3. Spawn Planner Agent

Task(prompt="...", subagent_type="fm-planner", ...)

## 4. Handle Planner Return

Parse planner output:

**`## PLANNING COMPLETE`:**

- Extract plan content
- Proceed to step 5

**`## PLANNING BLOCKED`:**

- Display blocker information
- Offer: Provide context, Skip, Abort

**`## PLANNING INCONCLUSIVE`:**

- Show what was attempted
- Offer: Add context, Retry, Manual
```

---

**Bad:** Using @ syntax in Task() prompts

```markdown
Task(prompt=" @.flomaster/STATE.md @.flomaster/ROADMAP.md

Create a plan based on these files. ", ...)
```

**Good:** Inlining file content in Task() prompts

````markdown
## 2. Read Context Files

```bash
STATE_CONTENT=$(cat .flomaster/STATE.md)
ROADMAP_CONTENT=$(cat .flomaster/ROADMAP.md)
```
````

## 3. Spawn Agent

Task(prompt=" <context> **State:** ${STATE_CONTENT}

**Roadmap:** ${ROADMAP_CONTENT} </context>

Create a plan based on this context. ", ...)

````

---

**Bad:** No stage banners for user feedback
```markdown
## 1. Research Topic

Read documentation and search for information.

## 2. Synthesize Findings

Combine all research into summary.
````

**Good:** Stage banners at major transitions

```markdown
## 1. Research Topic

Display stage banner:
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► RESEARCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Gathering information on {topic}...

```

Read documentation and search for information.

## 2. Synthesize Findings

Display stage banner:
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► SYNTHESIZING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Combining research findings...

```

Combine all research into summary.
```

---

**Bad:** Monolithic command file with all logic inline

```markdown
<process>
## 1. First Step
[50 lines of detailed logic]

## 2. Second Step

[80 lines of edge case handling]

## 3. Third Step

[100 lines of validation rules] </process>
```

**Good:** Lean command with logic extracted to workflow

```markdown
<execution_context> @./.claude/flomaster/workflows/detailed-workflow.md
</execution_context>

<process>
## 1. First Step
Execute according to workflow section 1.

## 2. Second Step

Execute according to workflow section 2.

## 3. Third Step

Execute according to workflow section 3. </process>
```

</anti_patterns>
