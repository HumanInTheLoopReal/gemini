---
name: fm:create-agent
description:
  Create new FM agents from descriptions or convert existing agents to FM format
argument-hint: '<description | file-path | @file.md>'
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Create new FM agents from descriptions, or convert existing agents to FM format.

**What this does:**

1. Detects mode (create from description vs convert existing file)
2. Gathers requirements interactively using AskUserQuestion
3. Maps content to FM agent template sections
4. **Preserves domain-specific sections** (methodology, protocols, modes) as-is
5. For convert mode: renames original with `-legacy` suffix
6. Writes agent to `.claude/agents/`
7. Runs verification to ensure quality

**Output:** Agent file at `.claude/agents/{agent-name}.md` following FM template
structure.

**Modes:**

- **Create mode:** Input is a description → gather requirements, create new
  agent
- **Convert mode:** Input is a file path → read, ask questions, convert to FM
  format

**Edge cases:**

- If source already follows FM template → runs verification only
- If source is trivially simple (< 15 lines) → warns user </objective>

<execution_context> @./.claude/flomaster/templates/agent-template.md
</execution_context>

<context>
Input: $ARGUMENTS

**Template reference:** See `<execution_context>` above for the complete FM
agent template structure, including:

- Required sections (frontmatter, role, execution_flow, success_criteria)
- Recommended sections (structured_returns, philosophy/core_principle)
- Optional sections (upstream_input, downstream_consumer, tool_strategy,
  critical_rules)
- Domain-specific sections by agent type (Researcher, Planner, Executor,
  Verifier, Debugger, Mapper, Roadmapper)
- Color conventions and step priority attributes </context>

<agent_type_summary>

## Agent Types Quick Reference

When converting, identify the agent type to know which domain-specific sections
to preserve:

### Researcher Agents

```
<tool_strategy>         — How to use Context7, WebSearch, WebFetch
<source_hierarchy>      — Confidence levels (HIGH/MEDIUM/LOW)
<verification_protocol> — How to verify claims
<research_modes>        — Ecosystem, Feasibility, Comparison modes
<output_formats>        — Document templates (SUMMARY.md, STACK.md, etc.)
```

### Planner Agents

```
<discovery_levels>      — When to research before planning
<task_breakdown>        — Task anatomy, sizing, types
<dependency_graph>      — Building dependency graphs
<scope_estimation>      — Context budget rules
<plan_format>           — PLAN.md structure
<goal_backward>         — Goal-backward methodology
<checkpoints>           — Checkpoint types and rules
<tdd_integration>       — TDD planning patterns
<gap_closure_mode>      — Planning from verification failures
<revision_mode>         — Updating plans based on feedback
```

### Executor Agents

```
<deviation_rules>       — Auto-fix rules during execution
<authentication_gates>  — Handling auth errors
<checkpoint_protocol>   — Checkpoint handling
<checkpoint_return_format> — Exact checkpoint structure
<continuation_handling> — Resuming after checkpoints
<tdd_execution>         — RED-GREEN-REFACTOR cycle
<task_commit_protocol>  — Per-task git commits
<summary_creation>      — Post-execution reporting
<state_updates>         — Updating STATE.md
<final_commit>          — Committing artifacts
```

### Verifier/Checker Agents

```
<core_principle>        — Single focused verification principle
<verification_process>  — Multi-level verification steps
<verification_dimensions> — What dimensions to check
<stub_detection_patterns> — How to find placeholder code
<issue_structure>       — YAML issue format
<examples>              — Concrete verification scenarios
```

### Debugger Agents

```
<hypothesis_testing>    — Scientific method for debugging
<investigation_techniques> — Debug methodologies
<verification_patterns> — Verifying fixes
<research_vs_reasoning> — When to research vs reason
<debug_file_protocol>   — State file format
<checkpoint_behavior>   — When to return checkpoints
<modes>                 — Different debugging modes
```

### Mapper/Synthesizer Agents

```
<why_this_matters>      — How outputs are consumed (detailed)
<templates>             — Document templates for each focus area
<output_format>         — Aggregation output structure
```

### Roadmapper Agents

```
<goal_backward_phases>  — Phase-level goal-backward
<phase_identification>  — Deriving phases from requirements
<coverage_validation>   — 100% requirement coverage
```

**CRITICAL:** When converting, preserve ALL domain-specific sections exactly as
they appear in the source. See the full template for complete documentation of
each section's purpose and format.

</agent_type_summary>

<process>

## 0. Determine Mode

**If $ARGUMENTS is empty:**

```
ERROR: No input specified.

Usage: /fm:create-agent <description | file-path | @file.md>

Examples:
  /fm:create-agent "researcher that finds codebase patterns"  ← create from description
  /fm:create-agent .claude/agents/my-agent.md                 ← convert existing file
  /fm:create-agent @some-agent.md                             ← convert @file reference
```

STOP here.

Parse $ARGUMENTS to determine mode:

**Convert mode indicators:**

- Contains `/` or `\` (path separator)
- Ends with `.md`
- Starts with `.` or `@`
- File exists at the path

**Create mode indicators:**

- Plain text description (usually multiple words)
- No file extension
- File doesn't exist at path

```bash
INPUT="$ARGUMENTS"

# Check if it looks like a file path
if [[ "$INPUT" == @* ]]; then
  # @file reference → convert mode
  FILE_PATH="${INPUT#@}"
  MODE="convert"
  echo "MODE: convert → @reference: $FILE_PATH"
elif [[ "$INPUT" == */* ]] || [[ "$INPUT" == *.md ]] || [[ "$INPUT" == .* ]]; then
  # File path → convert mode
  FILE_PATH="$INPUT"
  if [ -f "$FILE_PATH" ]; then
    MODE="convert"
    echo "MODE: convert → file path: $FILE_PATH"
  else
    echo "File not found: $FILE_PATH"
    echo "Treating as description for create mode"
    MODE="create"
    DESCRIPTION="$INPUT"
  fi
else
  # Plain text description → create mode
  MODE="create"
  DESCRIPTION="$INPUT"
  echo "MODE: create → description: $DESCRIPTION"
fi
```

**If mode is ambiguous:** Use AskUserQuestion to clarify.

**For convert mode, validate file exists:**

```bash
if [ "$MODE" = "convert" ] && [ ! -f "$FILE_PATH" ]; then
  echo "ERROR: File not found: $FILE_PATH"
  exit 1
fi
```

---

## 1a. Gather Requirements (Create Mode)

**If MODE = "create":**

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► GATHERING REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**1a-i. Clarify the agent type:**

Use AskUserQuestion:

```
header: "Agent Type"
question: "What type of agent are you creating?"
options:
  - "Researcher" — Gathers information, uses WebSearch/WebFetch (color: cyan)
  - "Planner" — Creates plans, breaks down tasks (color: green)
  - "Executor" — Implements plans, modifies code (color: yellow)
  - "Verifier" — Checks results, finds gaps (color: green)
  - "Debugger" — Investigates issues, finds root causes (color: orange)
  - "Mapper" — Analyzes codebase, produces documents (color: cyan)
```

**1a-ii. Gather key details:**

Use AskUserQuestion:

```
header: "Agent Name"
question: "What should the agent be called? (e.g., 'code-reviewer', 'test-generator')"
```

Ask inline (freeform):

- "What's the one-line description for this agent?"
- "What command(s) will spawn this agent? (e.g., /fm:review-code)"
- "What's the agent's core job? (2-3 sentences)"

**1a-iii. Determine tools needed:**

Use AskUserQuestion:

```
header: "Tools"
question: "What tools will this agent need?"
multiSelect: true
options:
  - "Read" — Read files
  - "Write" — Create/overwrite files
  - "Bash" — Run shell commands
  - "Grep" — Search file contents
  - "Glob" — Find files by pattern
  - "WebSearch" — Search the web
  - "WebFetch" — Fetch web pages
```

**1a-iv. Determine process steps:**

Ask: "Describe the main steps this agent should perform (one per line):"

**1a-v. Determine return formats:**

Use AskUserQuestion:

```
header: "Return Format"
question: "What return states should this agent have?"
multiSelect: true
options:
  - "COMPLETE" — Success, work done
  - "BLOCKED" — Cannot proceed, needs input
  - "CHECKPOINT" — Pausing for user verification
  - "INCONCLUSIVE" — Couldn't determine answer
```

After gathering all requirements, proceed to **Step 5: Build FM Agent**.

---

## 1b. Analyze Source Agent (Convert Mode)

**If MODE = "convert":**

<core_principle> **RESTRUCTURE, NOT REDUCE.**

When converting, ALL content from the source MUST be preserved:

- Every rule, instruction, and step
- Every code block and example
- Every constraint and anti-pattern
- Every piece of domain logic

The goal is to REFORMAT into FM structure, not to summarize or simplify. If
something exists in the source, it MUST exist in the output. </core_principle>

## 1. Read and Analyze Source Agent

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► ANALYZING AGENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read the source file:

```bash
cat "$FILE_PATH"
```

**Extract source agent name** from frontmatter or filename:

```bash
# Try frontmatter first
SOURCE_NAME=$(grep "^name:" "$FILE_PATH" | head -1 | sed 's/name:[[:space:]]*//')

# Fall back to filename
if [ -z "$SOURCE_NAME" ]; then
  SOURCE_NAME=$(basename "$FILE_PATH" .md)
fi
```

**Check if source is trivially simple:**

```bash
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
```

If `LINE_COUNT < 15`:

```
ERROR: Source agent is too simple to template.

File: $FILE_PATH
Lines: $LINE_COUNT

The FM agent template is designed for agents with meaningful logic.
Agents under 15 lines don't benefit from this structure.

If you believe this agent should be templated anyway, add more
detail to the source first, then try again.
```

STOP here if too simple.

**Check if source already follows FM template:**

```bash
# Check for FM template markers
HAS_ROLE=$(grep -c "<role>" "$FILE_PATH" || echo 0)
HAS_EXEC=$(grep -c "<execution_flow>\|<process>" "$FILE_PATH" || echo 0)
HAS_SUCCESS=$(grep -c "<success_criteria>" "$FILE_PATH" || echo 0)
HAS_FRONTMATTER=$(grep -c "^tools:" "$FILE_PATH" || echo 0)
```

If `HAS_ROLE > 0` AND `HAS_EXEC > 0` AND `HAS_SUCCESS > 0` AND
`HAS_FRONTMATTER > 0`:

```
Source already follows the FM agent template structure.

Running verification only...
```

Skip to **Step 7: Verification** (already FM format).

## 2. Parse Source Content

Extract all meaningful content from the source agent. Create a structured
inventory.

**2a. Extract YAML frontmatter:**

```bash
# Extract frontmatter between --- markers
sed -n '/^---$/,/^---$/p' "$FILE_PATH" | grep -v "^---$"
```

Parse into:

- `source.name` — agent name
- `source.description` — description
- `source.tools` — tools list (if present)
- `source.color` — color (if present)
- `source.other_frontmatter` — any other fields

**2b. Identify agent type:**

| Indicators                     | Agent Type   | Domain-Specific Sections to Preserve                                                                            |
| ------------------------------ | ------------ | --------------------------------------------------------------------------------------------------------------- |
| Spawns subagents, orchestrates | Orchestrator | checkpoint_handling, wave_execution                                                                             |
| Does research, uses WebSearch  | Researcher   | tool_strategy, source_hierarchy, verification_protocol, research_modes, output_formats                          |
| Executes plans, modifies code  | Executor     | deviation_rules, checkpoint_protocol, task_commit_protocol, tdd_execution, state_updates                        |
| Verifies/checks output         | Verifier     | verification_process, verification_dimensions, stub_detection_patterns, issue_structure                         |
| Creates plans/documents        | Planner      | discovery_levels, task_breakdown, dependency_graph, goal_backward, checkpoints, gap_closure_mode, revision_mode |
| Debugs/investigates            | Debugger     | hypothesis_testing, investigation_techniques, verification_patterns, debug_file_protocol, modes                 |
| Maps/synthesizes               | Mapper       | why_this_matters, templates, output_format                                                                      |
| Creates roadmaps               | Roadmapper   | goal_backward_phases, phase_identification, coverage_validation                                                 |

**2c. Extract ALL XML sections:**

Scan the body (everything after frontmatter) for ALL
`<section_name>...</section_name>` tags:

```bash
# List all XML section tags in the file
grep -oE '<[a-z_]+>' "$FILE_PATH" | sort -u | sed 's/<//;s/>//'
```

**Standard sections (map to template):**

| Pattern                                        | Maps to                                    |
| ---------------------------------------------- | ------------------------------------------ |
| `<role>...</role>`                             | Keep as-is                                 |
| `<objective>...</objective>`                   | Convert to `<role>`                        |
| `<philosophy>...</philosophy>`                 | Keep as-is                                 |
| `<core_principle>...</core_principle>`         | Keep as-is (different from philosophy!)    |
| `<process>...</process>`                       | Keep as-is or rename to `<execution_flow>` |
| `<execution_flow>...</execution_flow>`         | Keep as-is                                 |
| `<success_criteria>...</success_criteria>`     | Keep as-is                                 |
| `<structured_returns>...</structured_returns>` | Keep as-is                                 |
| `<anti_patterns>...</anti_patterns>`           | Keep or rename to `<critical_rules>`       |
| `<critical_rules>...</critical_rules>`         | Keep as-is                                 |

**Domain-specific sections (PRESERVE EXACTLY):**

Any section not in the standard list above should be preserved exactly as-is.
These include:

- Methodology sections (hypothesis_testing, goal_backward, etc.)
- Protocol sections (checkpoint_protocol, task_commit_protocol, etc.)
- Mode sections (gap_closure_mode, revision_mode, research_modes, etc.)
- Format sections (output_formats, plan_format, issue_structure, etc.)
- Detection sections (stub_detection_patterns, verification_patterns, etc.)

**2d. Extract non-XML content:**

Also look for:

- `## Step N:` or numbered steps → Convert to `<execution_flow>` with `<step>`
  tags
- `# Instructions` → Convert to `<execution_flow>`
- Tool usage sections → Extract to `<tool_strategy>` if research agent
- Output format sections → Extract to `<structured_returns>`

**2e. Create content inventory:**

Build a structured list of ALL content found:

```
INVENTORY:
├── frontmatter
│   ├── name: [value]
│   ├── description: [value]
│   ├── tools: [list or MISSING]
│   └── color: [value or MISSING]
├── agent_type: [orchestrator | researcher | executor | verifier | planner | debugger | mapper | roadmapper | general]
├── standard_sections
│   ├── role: [yes/no]
│   ├── philosophy: [yes/no]
│   ├── core_principle: [yes/no]
│   ├── upstream_input: [yes/no]
│   ├── downstream_consumer: [yes/no]
│   ├── tool_strategy: [yes/no]
│   ├── execution_flow/process: [yes/no]
│   ├── structured_returns: [yes/no]
│   ├── critical_rules/anti_patterns: [yes/no]
│   └── success_criteria: [yes/no]
├── domain_specific_sections
│   ├── [section_name_1]: [content summary]
│   ├── [section_name_2]: [content summary]
│   └── ...
├── content_blocks
│   ├── [block 1 description]
│   └── ...
└── unmapped_content
    └── [anything that doesn't fit a section]
```

Present inventory to confirm understanding:

```
## Source Analysis: $SOURCE_NAME

**File:** $FILE_PATH
**Lines:** $LINE_COUNT
**Agent Type:** [detected type]

### Standard Sections:
- role: [✓ found / ✗ missing]
- philosophy: [✓ found / ✗ missing]
- core_principle: [✓ found / ✗ missing]
- execution_flow: [✓ found / ✗ missing]
- structured_returns: [✓ found / ✗ missing]
- success_criteria: [✓ found / ✗ missing]

### Domain-Specific Sections (will preserve as-is):
- [section_name_1]: [line count] lines
- [section_name_2]: [line count] lines
- ...

### Frontmatter:
- name: $source.name
- description: $source.description
- tools: [found/missing]
- color: [found/missing]

**Content blocks identified:** N blocks
**Unmapped content:** [none / list items]

---

Proceed with conversion? (yes / review details first)
```

## 3. Detect and Abstract Project-Specific Content

Before converting, scan for content that is specific to the source
project/framework and should be abstracted for FM.

**3a. Scan for project-specific patterns:**

Look for these categories of project-specific content:

| Category               | Detection Pattern                                                       | Examples                                               |
| ---------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------ |
| **Custom paths**       | Paths that don't start with `.claude/`, `.flomaster/`, or standard dirs | `thoughts/shared/`, `humanlayer-wui/`, `.planning/`    |
| **Framework prefixes** | Non-FM command/agent prefixes                                           | `gsd:`, `humanlayer:`, `myproject:`                    |
| **Agent names**        | Agent references that aren't FM agents                                  | `gsd-planner`, `thoughts-locator`, `custom-researcher` |
| **Output paths**       | Hardcoded output directories                                            | `.gsd/`, `thoughts/`, `hld/`                           |
| **CLI commands**       | Project-specific CLI tools                                              | `humanlayer thoughts sync`, `gsd progress`             |

```bash
# Detect framework prefixes (non-fm: prefixes)
grep -oE '[a-z]+:[a-z-]+' "$FILE_PATH" | grep -v "^fm:" | sort -u

# Detect custom directory paths
grep -oE '\.[a-z]+/' "$FILE_PATH" | grep -v "^\.claude" | grep -v "^\.flomaster" | sort -u

# Detect agent name patterns (word-word format that might be agents)
grep -oE '[a-z]+-[a-z]+(-[a-z]+)?' "$FILE_PATH" | grep -v "^fm-" | sort -u
```

**3b. Classify detected items:**

For each detected item, classify as:

- **Generic** — Standard patterns that need no change (e.g., `npm run`,
  `git commit`)
- **Framework-specific** — From another framework, has FM equivalent (e.g.,
  `gsd:` → `fm:`, `gsd-planner` → `fm-planner`)
- **Project-specific** — Unique to source project, needs user input

**3c. Present findings and ask user:**

```
## Project-Specific Content Detected

I found content that appears specific to the source project/framework:

### Framework References (will auto-convert)
- `gsd:plan-phase` → `fm:plan-phase`
- `gsd-planner` → `fm-planner`
- `gsd-executor` → `fm-executor`

### Custom Paths
- `.gsd/` — appears 5 times
- `thoughts/shared/` — appears 3 times

### Other Patterns
- `humanlayer thoughts sync` — CLI command, appears 2 times

---

For each category, I need to know how to handle it in the FM version.
```

**3d. Ask about each category using AskUserQuestion:**

For **Framework References** (auto-convert by default):

```
AskUserQuestion(
  header: "Framework Refs",
  question: "I'll automatically convert framework references (gsd: → fm:, gsd-* → fm-*). Is this correct?",
  options: [
    { label: "Yes, convert all", description: "Auto-convert gsd → fm throughout" },
    { label: "Let me review", description: "Show me each conversion" },
    { label: "Keep original", description: "Don't convert framework names" }
  ]
)
```

For **Custom Paths**:

```
AskUserQuestion(
  header: "Custom Paths",
  question: "How should I handle custom paths like `.gsd/` or `thoughts/`?",
  options: [
    { label: "Replace with FM paths", description: "I'll ask for FM equivalents" },
    { label: "Use placeholders", description: "Replace with {path-name} placeholders" },
    { label: "Remove entirely", description: "Delete references to these paths" },
    { label: "Keep as-is", description: "Preserve original paths (not recommended)" }
  ]
)
```

If "Replace with FM paths" selected, ask for each unique path:

```
AskUserQuestion(
  header: "Path: .gsd/",
  question: "What should `.gsd/` become in FloMaster?",
  options: [
    { label: ".flomaster/", description: "Standard FM directory" },
    { label: ".planning/", description: "Use .planning convention" },
    { label: "Custom", description: "I'll specify a custom path" }
  ]
)
```

For **CLI Commands/Other**:

```
AskUserQuestion(
  header: "CLI: humanlayer thoughts sync",
  question: "Found CLI command: `humanlayer thoughts sync`. How should I handle it?",
  options: [
    { label: "Remove", description: "Delete this command and related steps" },
    { label: "Replace", description: "I'll provide a replacement" },
    { label: "Make generic", description: "Use a placeholder like {sync-command}" }
  ]
)
```

**3e. Build replacement map:**

Based on user responses, create a replacement map:

```
REPLACEMENTS:
├── framework
│   ├── "gsd:" → "fm:"
│   ├── "gsd-planner" → "fm-planner"
│   ├── "gsd-executor" → "fm-executor"
│   └── "GSD" → "FM"
├── paths
│   ├── ".gsd/" → ".flomaster/"
│   └── "thoughts/shared/" → ".flomaster/research/"
├── commands
│   └── "humanlayer thoughts sync" → REMOVE
└── agents
    └── "thoughts-locator" → "docs-locator"
```

**3f. Confirm replacement map:**

```
## Replacement Map

I'll make these substitutions during conversion:

| Original | Replacement |
|----------|-------------|
| `gsd:` | `fm:` |
| `gsd-planner` | `fm-planner` |
| `GSD ►` | `FM ►` |
| `.gsd/` | `.flomaster/` |
| `thoughts/shared/` | `.flomaster/research/` |
| `humanlayer thoughts sync` | *(removed)* |

Proceed with these replacements? (yes / adjust / cancel)
```

**If "cancel":** Display: `Conversion cancelled.` and STOP.

Wait for confirmation before proceeding.

**3g. Store replacement map:**

Store the replacement map for use in Step 5 (Convert to FM Agent Template). All
replacements will be applied when building the converted content.

## 4. Handle Missing Sections

For each REQUIRED section that's missing, ask user:

**Required sections:**

- YAML frontmatter with `name`, `description`, `tools`
- `<role>` — REQUIRED
- `<execution_flow>` or `<process>` — REQUIRED
- `<success_criteria>` — REQUIRED

**Strongly recommended sections:**

- `<structured_returns>` — output formats
- `<philosophy>` or `<core_principle>` — guiding mindset

**Note on philosophy vs core_principle:**

- `<philosophy>` = Broader mindset with multiple subsections (## headers)
- `<core_principle>` = Single focused truth (1-2 paragraphs)
- They can COEXIST — don't merge them!

**Optional sections:**

- `<upstream_input>` — what agent receives
- `<downstream_consumer>` — who uses output
- `<tool_strategy>` — for research agents
- `<critical_rules>` — anti-patterns

**For each missing REQUIRED section:**

Use AskUserQuestion:

- header: "Missing: [section]"
- question: "The source doesn't have a clear [section]. How should I handle
  this?"
- options:
  - "Generate it" — I'll create reasonable content based on the agent's logic
  - "Skip it" — Omit this section (not recommended for required sections)
  - "Let me provide it" — I'll tell you what to put

**If "Let me provide it":** Wait for user input, use that content.

**If "Generate it":**

- For `<role>`: Synthesize from description + overall agent behavior
- For `<execution_flow>`: Structure existing instructions into `<step>` tags
- For `<success_criteria>`: Derive checkpoints from process steps
- For `<structured_returns>`: Create output formats based on what agent produces

**If "Skip it":** Mark section as deliberately omitted (add comment).

**For missing frontmatter fields:**

If `tools` is missing, infer from content:

- Has file reading → `Read`
- Has file writing → `Write`
- Has `cat`, `ls`, `mkdir`, etc. → `Bash`
- Has `grep` or search → `Grep`
- Has glob patterns → `Glob`
- Has web search → `WebSearch`
- Has URL fetching → `WebFetch`
- Has Context7 usage → `mcp__context7__*`

If `color` is missing, suggest based on agent type:

- Researcher → `cyan`
- Planner → `green`
- Executor → `yellow`
- Verifier → `green`
- Debugger → `orange`
- Orchestrator → `purple`
- Mapper → `cyan`
- Checker → `blue`

## 5. Convert to FM Agent Template

Build the new agent file with FM structure. **Apply all replacements from
Step 3.**

**5a. Generate YAML frontmatter:**

```yaml
---
name: { agent-name }
description: { source.description }
tools: { inferred or source tools }
color: { inferred or source color }
---
```

**5b. Build sections in order (applying replacement map):**

The FM template follows this section ordering:

1. **Frontmatter**
2. **`<role>`**
3. **`<philosophy>` and/or `<core_principle>`** (can have both)
4. **`<upstream_input>`** (if present)
5. **`<downstream_consumer>`** or `<why_this_matters>`\*\* (if present)
6. **Domain-specific methodology sections** (preserve order from source)
7. **`<tool_strategy>`** (if research agent)
8. **`<execution_flow>` or `<process>`**
9. **`<structured_returns>`**
10. **`<critical_rules>` or `<anti_patterns>`** (if present)
11. **`<success_criteria>`**
12. **Additional specialized sections** (`<templates>`, `<modes>`, etc.)

**`<role>`:**

```xml
<role>
You are an FM {agent-type}. You {primary function}.

You are spawned by:

- `{command-1}` ({description})
- `{command-2}` ({description})

Your job: {one-line mission statement}

**Core responsibilities:**
- {responsibility 1}
- {responsibility 2}
- {responsibility 3}
</role>
```

**`<philosophy>` (if content found — broader mindset):**

```xml
<philosophy>

## {Principle Name}

{Explanation of the guiding principle}

**The trap:** {What goes wrong without this principle}
**The discipline:** {How to apply this principle}

## {Another Principle}

{Explanation}

</philosophy>
```

**`<core_principle>` (if content found — single focused truth):**

```xml
<core_principle>
**{Principle statement}**

{1-2 paragraph explanation of why this matters and what it means for the agent's behavior}
</core_principle>
```

**`<upstream_input>` (if applicable):**

```xml
<upstream_input>
**{Input Type}** (if exists) — {Source description}

| Section | How You Use It |
|---------|----------------|
| `{section}` | {how it constrains/informs this agent} |
</upstream_input>
```

**`<downstream_consumer>` or `<why_this_matters>` (if applicable):**

Use `<why_this_matters>` if the source has detailed consumption patterns with
tables. Use `<downstream_consumer>` for simpler descriptions.

```xml
<downstream_consumer>
Your {output} is consumed by {consumer} which uses it to:

| Output | How Consumer Uses It |
|--------|----------------------|
| {output section} | {how it's used} |
</downstream_consumer>
```

**Domain-specific sections:**

**PRESERVE EXACTLY AS-IS from source.** Do not restructure, rename, or
summarize. These sections contain the agent's core methodology and must not be
altered.

Insert them in the same relative order they appeared in the source.

**`<tool_strategy>` (for research agents):**

```xml
<tool_strategy>

## {Tool Name}: {When to Use}

**When to use:**
- {condition 1}
- {condition 2}

**How to use:**
```

{example usage}

```

**Best practices:**
- {practice 1}
- {practice 2}

</tool_strategy>
```

**`<execution_flow>` or `<process>`:**

Structure as named steps. Preserve `priority="first"` attribute if present:

````xml
<execution_flow>

<step name="load_context" priority="first">
{What to do first — context loading, state loading}

```bash
{commands}
````

**If {condition}:**

- {action}

**If {other condition}:**

- {other action} </step>

<step name="main_work">
{Main agent logic}
</step>

<step name="return_result">
{How to format and return output}
</step>

</execution_flow>

````

**`<structured_returns>`:**

Use domain-appropriate status names (not generic STATUS_NAME):

```xml
<structured_returns>

## {OPERATION} COMPLETE

When {success condition}:

```markdown
## {OPERATION} COMPLETE

**{Field}:** {value}

### {Section}

{content format}
````

## {OPERATION} BLOCKED

When {blocked condition}:

```markdown
## {OPERATION} BLOCKED

**Blocked by:** {reason}

### Options

1. {option 1}
2. {option 2}
```

## CHECKPOINT REACHED

When {checkpoint condition}:

```markdown
## CHECKPOINT REACHED

**Type:** {human-verify | decision | human-action}

{checkpoint details}
```

</structured_returns>

````

**`<critical_rules>` or `<anti_patterns>`:**

```xml
<critical_rules>

**{Rule description}.** {Explanation of why and what to do instead.}

**{Another rule}.** {Explanation.}

</critical_rules>
````

**`<success_criteria>`:**

```xml
<success_criteria>

{Agent name} is complete when:

- [ ] {Criterion 1 from process}
- [ ] {Criterion 2 from process}
- [ ] {Criterion N}
- [ ] Structured return provided to caller

</success_criteria>
```

## 6. Rename Original and Write Converted Agent

**6a. Determine output paths:**

```bash
# Get the agent name (without path)
AGENT_BASENAME=$(basename "$FILE_PATH" .md)

# Output path is always .claude/agents/
OUTPUT_DIR=".claude/agents"
OUTPUT_PATH="${OUTPUT_DIR}/${AGENT_BASENAME}.md"

# Legacy path (rename original)
LEGACY_PATH="${FILE_PATH%.md}-legacy.md"
```

**6b. Handle file conflicts:**

```bash
# Check if output already exists (and is different from source)
if [ -f "$OUTPUT_PATH" ] && [ "$OUTPUT_PATH" != "$FILE_PATH" ]; then
  echo "WARNING: $OUTPUT_PATH already exists"
fi
```

If output exists and is different from source, ask user:

- "Overwrite existing file?"
- "Use different name?"
- "Cancel"

**6c. Ensure output directory exists:**

```bash
mkdir -p "$OUTPUT_DIR"
```

**6d. Rename original to legacy:**

```bash
# Only rename if source is not already in .claude/agents/ with -legacy suffix
if [[ "$FILE_PATH" != *"-legacy.md" ]]; then
  mv "$FILE_PATH" "$LEGACY_PATH"
  echo "Original renamed to: $LEGACY_PATH"
fi
```

**6e. Write the converted agent:**

Use Write tool to create `.claude/agents/{agent-name}.md` with the converted
content.

**6f. Report:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► AGENT CONVERTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Source:** $FILE_PATH → $LEGACY_PATH
**Output:** $OUTPUT_PATH

**Standard sections:**
- [✓] frontmatter (name, description, tools, color)
- [✓] role
- [✓/✗] philosophy
- [✓/✗] core_principle
- [✓/✗] upstream_input
- [✓/✗] downstream_consumer
- [✓] execution_flow ({N} steps)
- [✓/✗] structured_returns
- [✓/✗] critical_rules
- [✓] success_criteria ({M} items)

**Domain-specific sections preserved:**
- [✓] {section_name_1}
- [✓] {section_name_2}
- ...

───────────────────────────────────────────────────────────────

Running verification...
```

## 7. Verification

Run comprehensive verification to ensure nothing was lost.

**7a. Structural verification:**

Check new file has all required sections:

```bash
NEW_FILE="$OUTPUT_PATH"

# Check required sections exist
echo "Checking required sections..."
grep -q "^name:" "$NEW_FILE" && echo "✓ frontmatter.name" || echo "✗ frontmatter.name MISSING"
grep -q "^description:" "$NEW_FILE" && echo "✓ frontmatter.description" || echo "✗ frontmatter.description MISSING"
grep -q "^tools:" "$NEW_FILE" && echo "✓ frontmatter.tools" || echo "✗ frontmatter.tools MISSING"
grep -q "<role>" "$NEW_FILE" && echo "✓ role" || echo "✗ role MISSING"
grep -q "<execution_flow>\|<process>" "$NEW_FILE" && echo "✓ execution_flow" || echo "✗ execution_flow MISSING"
grep -q "<success_criteria>" "$NEW_FILE" && echo "✓ success_criteria" || echo "✗ success_criteria MISSING"
```

**7b. Domain-specific section verification:**

Ensure all domain-specific sections from source are present in output:

```bash
# Extract all XML tags from source
SOURCE_TAGS=$(grep -oE '<[a-z_]+>' "$LEGACY_PATH" 2>/dev/null | sort -u)

# Extract all XML tags from output
OUTPUT_TAGS=$(grep -oE '<[a-z_]+>' "$NEW_FILE" | sort -u)

# Check for missing tags
echo "Checking domain-specific sections..."
for tag in $SOURCE_TAGS; do
  if echo "$OUTPUT_TAGS" | grep -q "$tag"; then
    echo "✓ $tag preserved"
  else
    echo "✗ $tag MISSING"
  fi
done
```

**7c. Content completeness verification:**

Compare source (legacy) and output to ensure nothing lost:

1. **Extract all code blocks from source:**

   ````bash
   grep -c '```' "$LEGACY_PATH" 2>/dev/null || grep -c '```' "$FILE_PATH"
   grep -c '```' "$NEW_FILE"
   ````

   Code block count should be equal or greater.

2. **Check for key patterns preserved:**

   ```bash
   # Extract all bash commands from source
   grep -E "^\s*(cat|grep|ls|mkdir|git)" "$LEGACY_PATH" 2>/dev/null | wc -l
   grep -E "^\s*(cat|grep|ls|mkdir|git)" "$NEW_FILE" | wc -l
   ```

3. **Verify step/process structure:**
   ```bash
   # Count step definitions
   grep -c '<step\|## Step\|## [0-9]' "$NEW_FILE"
   ```

**7d. Semantic verification:**

Read both files and verify:

1. **Role preserved:** Does the agent still do the same thing?
2. **Process intact:** Are all steps/phases preserved?
3. **Output formats:** Are all return formats preserved?
4. **Rules/constraints:** Are all anti-patterns/rules preserved?
5. **Domain methodology:** Are all specialized sections preserved exactly?

**7e. Report verification results:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► VERIFICATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Structural Checks
- [✓] YAML frontmatter valid
- [✓] All required sections present
- [✓] Section tags properly closed

## Domain-Specific Sections
- [✓] All {N} domain sections preserved
- [✓] Section content unchanged

## Content Completeness
- [✓] Code blocks: {N} source → {M} output
- [✓] Process steps: {N} preserved
- [✓] Return formats: preserved

## Semantic Checks
- [✓] Agent role preserved
- [✓] Process logic intact
- [✓] Output formats complete

───────────────────────────────────────────────────────────────

**Result:** PASSED ✓

**Legacy file:** $LEGACY_PATH
**Output file:** $OUTPUT_PATH

───────────────────────────────────────────────────────────────
```

**If verification fails:**

```
## Verification Issues Found

| Check | Status | Details |
|-------|--------|---------|
| Code blocks | ⚠ | Source: 5, Output: 3 (2 missing) |
| Domain sections | ⚠ | Missing: hypothesis_testing |
| Steps | ✓ | All preserved |
| Returns | ⚠ | Missing BLOCKED return format |

───────────────────────────────────────────────────────────────

**Action required:** Review the issues above.

Options:
1. Review and fix manually
2. Re-run conversion with more detail
3. Accept as-is (not recommended)
```

</process>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► AGENT CONVERTED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{agent-name}** — converted to FM template format

Location: `.claude/agents/{agent-name}.md` Legacy: `{legacy-path}`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Review the converted agent** — verify it looks correct

`cat .claude/agents/{agent-name}.md`

───────────────────────────────────────────────────────────────

**Also available:**

- `diff {legacy-path} .claude/agents/{agent-name}.md` — compare changes
- `/fm:create-agent {another-file}` — convert another agent
- Delete legacy file when satisfied: `rm {legacy-path}`

─────────────────────────────────────────────────────────────── </offer_next>

<anti_patterns>

- Don't invent agent logic the source doesn't have (ask user first)
- Don't lose ANY process steps, code, or instructions from source
- Don't convert agents that are too simple (< 15 lines)
- Don't skip verification even if conversion "looks right"
- Don't overwrite existing agents without asking
- Don't change the agent's behavior, only its structure
- Don't delete the original — always rename to -legacy first
- Don't assume tools if the source doesn't use them — infer from actual content
- Don't add sections that have no source content — keep it lean
- Don't merge distinct steps into one — preserve granularity
- Don't merge `<philosophy>` and `<core_principle>` — they serve different
  purposes
- Don't restructure domain-specific sections — preserve them EXACTLY
- Don't rename domain-specific sections to "standard" names — they're
  intentionally specific
- Don't remove the `priority="first"` attribute from steps — it controls
  execution order
- Don't silently convert project-specific paths/agents — always ask user first
- Don't assume what a replacement should be — present options and let user
  decide
- Don't convert generic patterns (npm, git, standard tools) — only
  project-specific content needs user input </anti_patterns>

<success_criteria> Agent conversion is complete when:

- [ ] Source agent located and read
- [ ] Source analyzed and content inventoried
- [ ] Agent type identified
      (orchestrator/researcher/executor/verifier/planner/debugger/mapper/roadmapper)
- [ ] ALL domain-specific sections identified and marked for preservation
- [ ] Project-specific content detected (framework refs, paths, agents, CLI
      commands)
- [ ] User asked about each category of project-specific content
- [ ] Replacement map built and confirmed
- [ ] Missing REQUIRED sections identified and handled (user decided)
- [ ] All standard content mapped to FM template sections
- [ ] All domain-specific sections preserved EXACTLY as-is
- [ ] Replacements applied during conversion (gsd: → fm:, paths, etc.)
- [ ] YAML frontmatter complete (name, description, tools, color)
- [ ] `<role>` section defines agent identity and responsibilities
- [ ] `<execution_flow>` or `<process>` captures all steps (with priority
      attributes)
- [ ] `<success_criteria>` includes completion checklist
- [ ] `<structured_returns>` defines output formats (if agent returns)
- [ ] Original file renamed to `-legacy` suffix
- [ ] New file written to `.claude/agents/`
- [ ] Structural verification passed
- [ ] Domain-specific section verification passed
- [ ] Content completeness verification passed
- [ ] Semantic verification passed
- [ ] No content lost from source
- [ ] User informed of output locations </success_criteria>
