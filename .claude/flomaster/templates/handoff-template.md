# Handoff Template

Template for capturing session context for seamless continuation by a future
Claude session.

> **Related:** [fm:generate-handoff](../../commands/fm/generate-handoff.md)

---

## File Location

**Decision tree for where to put the handoff:**

1. **Is this session about a specific task (TASK-XX)?**

   **YES** → Use `build-cycle/tasks/{TASK-XX}/HANDOFF.md`
   - If file **doesn't exist** → CREATE it with the template below
   - If file **already exists** → APPEND a new session entry (see "Appending
     Sessions" below)

   **NO** (general exploration, no clear task) → Use
   `build-cycle/handoffs/YYYY-MM-DD-{name}.md`

**Key principle:** One task = one cumulative HANDOFF.md containing ALL sessions
for that task. By the time a task is complete, the HANDOFF.md has the full
history. The `handoffs/` folder is ONLY for orphan sessions with no task
context.

---

## Appending Sessions

When `HANDOFF.md` already exists for a task, append a new dated section at the
END:

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

This keeps the full task history in one place while making each session's
contribution clear.

---

## File Template (New Handoff)

```markdown
# Session Handoff: {descriptive-title}

**Date**: {YYYY-MM-DD HH:MM} **Task**: {TASK-ID or "General"} **Session Goal**:
{what-we-set-out-to-accomplish} **Outcome**: {SUCCESS | PARTIAL | BLOCKED |
PIVOTED}

---

## 1. Quick Context

{2-3 sentences orienting a fresh session: project, phase, immediate focus}

**Read these files to catch up:**

- `{path/to/file1.md}` - {what it contains}
- `{path/to/file2.md}` - {what it contains}

---

## 2. What We Accomplished

{Bullet list of concrete outcomes - things DONE that won't need revisiting}

- ✅ {outcome-1}
- ✅ {outcome-2}

---

## 3. Key Decisions Made

{Decisions that should NOT be revisited unless explicitly requested}

| Decision | Rationale | Alternatives Rejected       |
| -------- | --------- | --------------------------- |
| {choice} | {why}     | {what we didn't do and why} |

---

## 4. Technical Findings

{Discoveries that inform future work - things we LEARNED}

- **Finding**: {what we discovered}
  - **Evidence**: {how we know}
  - **Implication**: {what this means for next steps}

---

## 5. Current State

{Where things stand RIGHT NOW - what exists, what's deployed}

**Artifacts created:**

- {file/endpoint/table}: `{location}` - {purpose}

**Code state:**

- Branch: {branch-name if applicable}
- Last commit: {commit-hash if applicable}

---

## 6. Open Items

{What's NOT done - blockers, unknowns, deferred items}

| Item   | Status                  | Blocker/Notes |
| ------ | ----------------------- | ------------- |
| {item} | {BLOCKED/DEFERRED/OPEN} | {why}         |

---

## 7. Next Steps (Prioritized)

{Explicit instructions for next session - what to do FIRST}

1. **{action-1}** - {brief context}
2. **{action-2}** - {brief context}

---

## 8. Session Notes (Optional)

{Context that doesn't fit above but might be useful}
```

<purpose>

The handoff document enables session continuity when context limits are reached
or work is paused. It solves the "cold start" problem where a new Claude session
would otherwise need to re-discover context, re-make decisions, and potentially
redo completed work.

A well-written handoff lets the next session pick up exactly where the previous
one left off, with full awareness of what was accomplished, what was decided
(and why), and what needs to happen next.

</purpose>

<sections>

### 1. Quick Context + File Pointers

**Goal:** Orient a fresh session in 2-3 sentences. **Include:** Project name,
current phase, immediate focus. **Exclude:** Full project history (that's in
other docs). **Critical:** File pointers are essential — a fresh session can
READ files rather than parse a massive handoff. Point to the task.md for the
task this handoff is about.

### 2. What We Accomplished

**Goal:** Prevent re-doing completed work. **Include:** Concrete, verifiable
outcomes (deployed X, created Y, validated Z). **Exclude:** Attempts, process
details, "we tried X" unless it led to a finding. **Format:** Bullet list with
✅ checkmarks.

### 3. Key Decisions Made

**Goal:** Prevent redundant discussions where the next session proposes
solutions already evaluated and dismissed. **Include:** Architecture choices,
approach selections, trade-offs made. **Exclude:** Micro-decisions (variable
names, formatting), obvious choices. **Format:** Table preserving the WHY, not
just the WHAT.

### 4. Technical Findings

**Goal:** Share permanent contributions to the project's collective
understanding. **Include:** Discoveries about the system, limitations found,
patterns identified. **Exclude:** Failed experiments that taught nothing, tool
outputs with no signal. **Format:** Finding → Evidence → Implication structure.

### 5. Current State

**Goal:** Provide a checkpoint to resume from. **Include:** What EXISTS now
(artifacts, deployments, code locations). **Exclude:** Historical states, what
used to exist. **Format:** List artifacts with locations and purposes.

### 6. Open Items

**Goal:** Direct next session to high-value work rather than having it
re-identify the same open questions. **Include:** Blockers, deferred decisions,
unknowns needing investigation. **Exclude:** Vague concerns, "nice to haves".
**Format:** Table with status (BLOCKED/DEFERRED/OPEN).

### 7. Next Steps (Prioritized)

**Goal:** Reduce cognitive load of context-switching by providing clear
continuity. **Include:** Specific actions in priority order. **Exclude:**
Long-term roadmap items, "eventually we should". **Format:** Numbered list, most
important first.

### 8. Session Notes (Optional)

**Goal:** Catch-all for context that doesn't fit elsewhere. **Include:** Edge
cases discovered, useful links, conversations. **Exclude:** If it's important,
it belongs in a structured section above.

</sections>

<lifecycle>

**When created:** At session end via `/fm:generate-handoff`, or manually when
pausing work.

**When read:** At session start when resuming work on a task. The HANDOFF.md in
a task folder contains the cumulative history of all sessions on that task.

**When updated (appended):**

- If working on a task that already has a HANDOFF.md → APPEND a new session
  entry
- Each session adds to the same file, building a complete task history
- The latest session entry shows what's next; earlier entries show how we got
  here

**File lifecycle for a task:**

```
Session 1: Create HANDOFF.md with full template
Session 2: Append "# Session: 2026-01-24" entry
Session 3: Append "# Session: 2026-01-25" entry
Task Complete: HANDOFF.md contains full history of all sessions
```

</lifecycle>

<guidelines>

**The Core Filter Question:** Before including ANY information, ask:

> "If the next session doesn't have this information, will it:
>
> 1. Make a wrong decision?
> 2. Redo work that's already done?
> 3. Miss important context that changes the approach?
>
> **If NO to all three → DON'T INCLUDE IT**"

**Quality criteria:**

- Fresh session test: Could a new Claude session understand what happened and
  continue without clarifying questions?
- No redundancy: Don't repeat information that's in pointed-to files
- Concrete over vague: "Deployed endpoint to staging" not "Made progress on
  deployment"
- Decisions include rationale: The WHY is as important as the WHAT

**Sizing rules:**

- Quick Context: 2-3 sentences max
- File pointers: 3-5 most relevant files
- Each section: As short as possible while passing the core filter

</guidelines>

<examples>

**Example 1: Feature Implementation (SUCCESS)**

```markdown
# Session Handoff: Online Feature Store Integration

**Date**: 2026-01-22 16:30 **Task**: TASK-01 **Session Goal**: Validate Online
Feature Store feasibility for ML Routing **Outcome**: SUCCESS

---

## 1. Quick Context

ML Routing build cycle, Week 1. We validated that Databricks Online Feature
Store can serve agent transaction features with acceptable latency (<50ms p99).
The steel thread is now unblocked.

**Read these files to catch up:**

- `build-cycle/progress/03-feature-store-validation.md` - Full validation
  results
- `codebases/routing-ml/features/online_features.py` - Feature serving code

---

## 2. What We Accomplished

- ✅ Deployed test feature table to Databricks Online Store
- ✅ Validated latency: 23ms p50, 47ms p99 (under 50ms target)
- ✅ Confirmed feature freshness: 15-minute sync lag acceptable for use case
- ✅ Created proof-of-concept endpoint in Connection Pacing

---

## 3. Key Decisions Made

| Decision                                | Rationale                                                        | Alternatives Rejected                         |
| --------------------------------------- | ---------------------------------------------------------------- | --------------------------------------------- |
| Use Databricks Online Store (not Redis) | Native integration with feature engineering, no additional infra | Redis would require separate sync pipeline    |
| 15-min sync acceptable                  | Transaction features don't change intra-day                      | Real-time sync adds complexity for no benefit |

---

## 4. Technical Findings

- **Finding**: Online Store requires features defined in Unity Catalog
  - **Evidence**: Deployment failed until we migrated feature table to UC
  - **Implication**: All feature tables must be UC-native going forward

---

## 5. Current State

**Artifacts created:**

- Feature table: `zg-pa-lab.ml_routing.agent_features_online` - Online-enabled
- Test endpoint: `routing-ml-feature-test` - Databricks serving endpoint

**Code state:**

- Branch: `feature/online-store-poc`
- Last commit: `a3b2c1d` - "Add online feature serving POC"

---

## 6. Open Items

| Item                           | Status | Blocker/Notes                       |
| ------------------------------ | ------ | ----------------------------------- |
| Production feature set         | OPEN   | Need Matt's final feature list      |
| Auth between CP and Databricks | OPEN   | Meeting with platform team Thursday |

---

## 7. Next Steps (Prioritized)

1. **Merge POC branch** - Code reviewed, ready to merge
2. **Schedule platform team sync** - Need to resolve auth approach
3. **Draft API contract** - CP ↔ ML endpoint request/response format

---

## 8. Session Notes (Optional)

Databricks docs for Online Store:
https://docs.databricks.com/en/machine-learning/feature-store/online-tables.html
```

**Example 2: Research Task (PARTIAL)**

```markdown
# Session Handoff: Connection Pacing Codebase Exploration

**Date**: 2026-01-21 14:15 **Task**: General **Session Goal**: Understand where
ML scoring would integrate into Connection Pacing **Outcome**: PARTIAL

---

## 1. Quick Context

ML Routing build cycle, Week 1. Exploring Connection Pacing codebase to find
integration point for ML model calls. Found the ranking logic but need to trace
how lead data flows in.

**Read these files to catch up:**

- `codebases/connection-pacing/src/ranking/AgentRanker.scala` - Current ranking
  implementation
- `build-cycle/shapeup/week-1/exploration-notes.md` - Raw exploration notes

---

## 2. What We Accomplished

- ✅ Located ranking entry point: `AgentRanker.rankAgents()`
- ✅ Identified current scoring: Uses `AgentScore` from agent-service
- ✅ Found lead context available at ranking time: lat/long, price, property
  type

---

## 3. Key Decisions Made

| Decision                             | Rationale                                            | Alternatives Rejected                                 |
| ------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------- |
| Hook into AgentRanker (not upstream) | Minimizes blast radius, existing tests cover ranking | Modifying lead ingestion would affect other consumers |

---

## 4. Technical Findings

- **Finding**: Lead lat/long comes from `LeadContext` not `LeadPrograms`
  - **Evidence**: Traced call from `ConnectionController` → `RankingService` →
    `AgentRanker`
  - **Implication**: We CAN get lead location without using LeadPrograms (which
    was a concern)

---

## 5. Current State

**Artifacts created:**

- None yet (research only)

**Code state:**

- No branches created

---

## 6. Open Items

| Item                                   | Status | Blocker/Notes                             |
| -------------------------------------- | ------ | ----------------------------------------- |
| How does auth work for external calls? | OPEN   | CP → Databricks auth pattern unclear      |
| Where does lead price come from?       | OPEN   | Not in LeadContext, need to trace further |

---

## 7. Next Steps (Prioritized)

1. **Trace lead price source** - Check LeadEnrichment service
2. **Find auth patterns** - Look at existing external service calls in CP
3. **Draft integration design** - Once data flow is clear

---

## 8. Session Notes (Optional)

Kendrew mentioned CP uses service mesh for external calls - check with him on
auth patterns.
```

</examples>

<anti_patterns>

**Bad:** Including back-and-forth clarifications

```markdown
## 3. Key Decisions Made

We discussed whether to use Redis or Databricks. I asked if latency mattered and
you said yes. Then we talked about sync frequency...
```

**Good:** Only the final decision with rationale

```markdown
## 3. Key Decisions Made

| Decision                    | Rationale                          | Alternatives Rejected                 |
| --------------------------- | ---------------------------------- | ------------------------------------- |
| Use Databricks Online Store | Native integration, no extra infra | Redis requires separate sync pipeline |
```

---

**Bad:** Process narration

```markdown
## 2. What We Accomplished

First I read the AgentRanker file. Then I searched for usages. Then I found the
controller that calls it. After that I traced the lead context...
```

**Good:** Concrete outcomes only

```markdown
## 2. What We Accomplished

- ✅ Located ranking entry point: `AgentRanker.rankAgents()`
- ✅ Traced lead context flow from controller to ranker
```

---

**Bad:** Vague accomplishments

```markdown
## 2. What We Accomplished

- ✅ Made good progress on the feature store
- ✅ Learned a lot about the codebase
```

**Good:** Specific, verifiable outcomes

```markdown
## 2. What We Accomplished

- ✅ Deployed feature table to Databricks Online Store
- ✅ Validated latency: 23ms p50, 47ms p99
```

---

**Bad:** Repeating file contents in handoff

```markdown
## 4. Technical Findings

The AgentRanker class has these methods:

- rankAgents(lead: Lead, agents: List[Agent]): List[RankedAgent]
- calculateScore(agent: Agent, lead: Lead): Double
- applyBoosts(score: Double, agent: Agent): Double [...continues for 50
  lines...]
```

**Good:** Point to file, summarize insight

```markdown
## 4. Technical Findings

- **Finding**: Ranking uses boost multipliers after base score
  - **Evidence**: See `AgentRanker.applyBoosts()` in ranking/AgentRanker.scala
  - **Implication**: ML score could replace base score, keep boost logic
```

</anti_patterns>
