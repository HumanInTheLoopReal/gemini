---
name: fm:create-command
description:
  Create new FM commands from descriptions or convert existing commands to FM
  format
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
Create new FM commands from descriptions, or convert existing commands to FM format.

**What this does:**

1. Detects mode (create from description vs convert existing file)
2. Gathers requirements interactively using AskUserQuestion
3. Maps content to FM template sections
4. Generates command with all required sections
5. Writes to `.claude/commands/fm/`
6. Runs verification to ensure quality

**Output:** Command file at `.claude/commands/fm/{command-name}.md` following FM
template structure.

**Modes:**

- **Create mode:** Input is a description → gather requirements, create new
  command
- **Convert mode:** Input is a file path → read, ask questions, convert to FM
  format

**Edge cases:**

- If source already follows FM template → runs verification only
- If source is trivially simple (< 10 lines) → warns user </objective>

<execution_context> @./.claude/flomaster/templates/command-template.md
</execution_context>

<context>
Input: $ARGUMENTS

**Template reference:** See `<execution_context>` above for the complete FM
command template structure, including:

- Required sections (frontmatter, objective, process, success_criteria)
- Optional sections (execution_context, context, anti_patterns, offer_next)
- Stage banner patterns (`FM ►`)
- Model profile resolution for agent-spawning commands
- Handle return state machines
- File content inlining for Task() calls
- Routing tables for multi-path commands </context>

<process>

## 0. Determine Mode

**If $ARGUMENTS is empty:**

```
ERROR: No input specified.

Usage: /fm:create-command <description | file-path | @file.md>

Examples:
  /fm:create-command "commit command with conventional commits"  ← create from description
  /fm:create-command .claude/commands/commit.md                  ← convert existing file
  /fm:create-command @my-command.md                              ← convert @file reference
```

STOP here.

Parse $ARGUMENTS to determine mode:

**Convert mode indicators:**

- Contains `/` or `\` (path separator)
- Ends with `.md`
- Starts with `.` or `@`
- Matches an existing command name (e.g., `commit`, `review-pr`)

**Create mode indicators:**

- Plain text description (usually multiple words)
- No file extension
- Doesn't match existing command file

```bash
INPUT="$ARGUMENTS"

# Check if it looks like a file path or command name
if [[ "$INPUT" == @* ]]; then
  # @file reference → convert mode
  FILE_PATH="${INPUT#@}"
  MODE="convert"
  echo "MODE: convert → @reference: $FILE_PATH"
elif [[ "$INPUT" == */* ]] || [[ "$INPUT" == *.md ]]; then
  # File path → convert mode
  FILE_PATH="$INPUT"
  MODE="convert"
  echo "MODE: convert → file path: $FILE_PATH"
elif [[ "$INPUT" =~ ^[a-z][-a-z0-9]*$ ]] || [[ "$INPUT" =~ ^[a-z]+:[a-z-]+$ ]]; then
  # Looks like a command name (e.g., "commit", "review-pr", "fm:plan-phase")
  COMMAND_NAME="$INPUT"
  # Search for it
  FOUND=$(find .claude/commands -name "${COMMAND_NAME}.md" -o -name "${COMMAND_NAME//:/-}.md" 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    FILE_PATH="$FOUND"
    MODE="convert"
    echo "MODE: convert → found command: $FILE_PATH"
  else
    # Command not found, treat as description
    MODE="create"
    DESCRIPTION="$INPUT"
    echo "MODE: create → description: $DESCRIPTION"
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

**1a-i. Clarify the command purpose:**

Use AskUserQuestion:

```
header: "Command Type"
question: "What type of command are you creating?"
options:
  - "Simple command" — Single task, no agent spawning (e.g., commit, lint)
  - "Orchestrator command" — Spawns subagents, manages workflow (e.g., plan-phase, execute-phase)
  - "Interactive command" — Gathers info via questions, then acts (e.g., create-plan)
  - "Utility command" — Helper/settings/status command (e.g., settings, progress)
```

**1a-ii. Gather key details:**

Use AskUserQuestion:

```
header: "Command Name"
question: "What should the command be called? (e.g., 'verify-tests', 'deploy-staging')"
```

Ask inline (freeform):

- "What's the one-line description for this command?"
- "What's the main thing this command does? (2-3 sentences)"

**1a-iii. Determine sections needed:**

Based on command type, determine which sections to include:

| Command Type | Sections                                                                 |
| ------------ | ------------------------------------------------------------------------ |
| Simple       | objective, context, process, success_criteria                            |
| Orchestrator | + execution_context, offer_next, model profile resolution, handle-return |
| Interactive  | + AskUserQuestion patterns, multi-step process                           |
| Utility      | objective, process (minimal), success_criteria                           |

**1a-iv. Gather process steps:**

Use AskUserQuestion:

```
header: "Process Steps"
question: "How many main steps will this command have?"
options:
  - "1-2 steps" — Very simple operation
  - "3-5 steps" — Standard command
  - "6+ steps" — Complex workflow
```

Ask: "Describe the main steps this command should perform (one per line):"

**1a-v. For orchestrator commands, gather agent details:**

If command type is "Orchestrator":

Use AskUserQuestion:

```
header: "Agents"
question: "What agents will this command spawn?"
multiSelect: true
options:
  - "Researcher" — For information gathering
  - "Planner" — For creating plans
  - "Executor" — For implementing plans
  - "Verifier" — For checking results
```

After gathering all requirements, proceed to **Step 5: Build FM Command**.

---

## 1b. Analyze Source Command (Convert Mode)

**If MODE = "convert":**

<core_principle> **RESTRUCTURE, NOT REDUCE.**

When converting, ALL content from the source MUST be preserved:

- Every rule, instruction, and step
- Every code block and example
- Every constraint and anti-pattern
- Every piece of domain logic

The goal is to REFORMAT into FM structure, not to summarize or simplify. If
something exists in the source, it MUST exist in the output. </core_principle>

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► ANALYZING COMMAND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read the source file:

```bash
cat "$FILE_PATH"
```

**Extract source command name** from frontmatter or filename:

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
CHAR_COUNT=$(wc -c < "$FILE_PATH" | tr -d ' ')
```

If `LINE_COUNT < 10` OR `CHAR_COUNT < 200`:

```
ERROR: Source command is too simple to template.

File: $FILE_PATH
Lines: $LINE_COUNT
Characters: $CHAR_COUNT

The FloMaster template is designed for commands with meaningful logic.
One-liners or trivial commands don't benefit from this structure.

If you believe this command should be templated anyway, add more
detail to the source first, then try again.
```

STOP here if too simple.

**Check if source already follows FM template:**

```bash
# Check for FM template markers
HAS_OBJECTIVE=$(grep -c "<objective>" "$FILE_PATH" || echo 0)
HAS_PROCESS=$(grep -c "<process>" "$FILE_PATH" || echo 0)
HAS_SUCCESS=$(grep -c "<success_criteria>" "$FILE_PATH" || echo 0)
HAS_FM_BANNER=$(grep -c "FM ►" "$FILE_PATH" || echo 0)
```

If `HAS_OBJECTIVE > 0` AND `HAS_PROCESS > 0` AND `HAS_SUCCESS > 0`:

```
Source already follows the template structure.

Running verification only...
```

Skip to **Step 7: Verification** (already FM format).

## 2. Parse Source Content

Extract all meaningful content from the source command. Create a structured
inventory.

**2a. Extract YAML frontmatter:**

```bash
# Extract frontmatter between --- markers
sed -n '/^---$/,/^---$/p' "$FILE_PATH" | grep -v "^---$"
```

Parse into:

- `source.name` — command name
- `source.description` — description
- `source.argument_hint` — argument hint (if present)
- `source.allowed_tools` — list of tools (if present)
- `source.other_frontmatter` — any other fields

**2b. Extract body sections:**

Scan the body (everything after frontmatter) for:

| Pattern                                    | Maps to                                      |
| ------------------------------------------ | -------------------------------------------- |
| `<objective>...</objective>`               | Keep as-is                                   |
| `<context>...</context>`                   | Keep as-is                                   |
| `<process>...</process>`                   | Keep as-is                                   |
| `<success_criteria>...</success_criteria>` | Keep as-is                                   |
| `<anti_patterns>...</anti_patterns>`       | Keep as-is                                   |
| `## Step N:` or `## Phase N:`              | Convert to `<process>` steps                 |
| `# Instructions` / `## Instructions`       | Convert to `<process>`                       |
| `# Usage` / `## Usage`                     | Extract to `<context>` or `argument-hint`    |
| Markdown lists of steps                    | Convert to `<process>`                       |
| `IMPORTANT:` / `NOTE:` / `WARNING:`        | Preserve inline or move to `<anti_patterns>` |
| Code blocks                                | Preserve in relevant sections                |
| File references (`@file`)                  | Move to `<context>`                          |
| Workflow references                        | Move to `<execution_context>`                |

**2c. Create content inventory:**

Build a structured list of ALL content found:

```
INVENTORY:
├── frontmatter
│   ├── name: [value]
│   ├── description: [value]
│   ├── argument-hint: [value or MISSING]
│   └── allowed-tools: [list or MISSING]
├── sections_found
│   ├── objective: [yes/no]
│   ├── context: [yes/no]
│   ├── execution_context: [yes/no]
│   ├── process: [yes/no]
│   ├── anti_patterns: [yes/no]
│   ├── offer_next: [yes/no]
│   └── success_criteria: [yes/no]
├── content_blocks
│   ├── [block 1 description]
│   ├── [block 2 description]
│   └── ...
└── unmapped_content
    └── [anything that doesn't fit a section]
```

Present inventory to confirm understanding:

```
## Source Analysis: $SOURCE_NAME

**File:** $FILE_PATH
**Lines:** $LINE_COUNT

### Content Found:

**Frontmatter:**
- name: $source.name
- description: $source.description
- argument-hint: [found/missing]
- allowed-tools: [list/missing]

**Sections:**
- objective: [✓ found / ✗ missing]
- context: [✓ found / ✗ missing]
- process: [✓ found / ✗ missing]
- success_criteria: [✓ found / ✗ missing]

**Content blocks identified:** N blocks

**Unmapped content:** [none / list items]

---

Proceed with conversion? (yes / review details first)
```

## 3. Detect and Abstract Project-Specific Content

Before converting, scan for content that is specific to the source
project/framework and should be abstracted for FloMaster.

**3a. Scan for project-specific patterns:**

Look for these categories of project-specific content:

| Category           | Detection Pattern                                                       | Examples                                      |
| ------------------ | ----------------------------------------------------------------------- | --------------------------------------------- |
| **Custom paths**   | Paths that don't start with `.claude/`, `.flomaster/`, or standard dirs | `thoughts/shared/`, `humanlayer-wui/`, `hld/` |
| **CLI commands**   | Commands that aren't standard unix/git                                  | `humanlayer thoughts sync`, `some-tool run`   |
| **Agent names**    | Agent references that aren't FM agents                                  | `linear-ticket-reader`, `thoughts-locator`    |
| **Ticket formats** | Project-specific issue IDs                                              | `ENG-XXXX`, `JIRA-123`                        |
| **Person names**   | Paths or refs with person names                                         | `thoughts/allison/`, `@john`                  |
| **Framework refs** | References to specific frameworks                                       | `gsd:`, `humanlayer:`, etc.                   |

```bash
# Detect custom directory paths (not .claude/, .flomaster/, node_modules/, etc.)
grep -oE '[a-zA-Z_-]+/[a-zA-Z_/-]+' "$FILE_PATH" | grep -v "^\.claude" | grep -v "^\.flomaster" | grep -v "node_modules" | sort -u

# Detect potential CLI commands (word followed by word, not in code context)
grep -oE '[a-z]+ [a-z]+ (sync|run|build|check|test)' "$FILE_PATH" | sort -u

# Detect agent references
grep -oE '\*\*[a-z-]+-[a-z]+\*\*' "$FILE_PATH" | sort -u
grep -oE 'agent[s]?.*:[^|]*' "$FILE_PATH" | sort -u

# Detect ticket ID patterns
grep -oE '[A-Z]+-[0-9X]+' "$FILE_PATH" | sort -u
```

**3b. Classify detected items:**

For each detected item, classify as:

- **Generic** — Standard patterns that need no change (e.g., `npm run`,
  `git commit`, `YYYY-MM-DD`)
- **Framework-specific** — From another framework, has FM equivalent (e.g.,
  `gsd:` → `fm:`)
- **Project-specific** — Unique to source project, needs user input (e.g.,
  `thoughts/shared/plans/`)

**3c. Present findings and ask user:**

```
## Project-Specific Content Detected

I found content that appears specific to the source project:

### Custom Paths
- `thoughts/shared/plans/` — appears 5 times
- `thoughts/allison/tickets/` — appears 3 times
- `humanlayer-wui/` — appears 2 times

### CLI Commands
- `humanlayer thoughts sync` — appears 3 times

### Agent Names
- `thoughts-locator` — appears 2 times
- `linear-ticket-reader` — appears 1 time

### Ticket Formats
- `ENG-XXXX` pattern — appears 4 times

---

For each category, I need to know how to handle it in the FM version.
```

**3d. Ask about each category using AskUserQuestion:**

For **Custom Paths**:

```
AskUserQuestion(
  header: "Custom Paths",
  question: "How should I handle these custom paths?",
  options: [
    { label: "Replace with FM paths", description: "I'll ask for FM equivalents for each" },
    { label: "Use placeholders", description: "Replace with {path-name} placeholders" },
    { label: "Remove entirely", description: "Delete references to these paths" },
    { label: "Keep as-is", description: "Preserve original paths (not recommended)" }
  ]
)
```

If "Replace with FM paths" selected, ask for each unique path:

```
AskUserQuestion(
  header: "Path: thoughts/shared/plans/",
  question: "What should `thoughts/shared/plans/` become in FloMaster?",
  options: [
    { label: ".flomaster/plans/", description: "Standard FM plans directory" },
    { label: ".planning/plans/", description: "Use .planning convention" },
    { label: "Custom", description: "I'll specify a custom path" }
  ]
)
```

For **CLI Commands**:

```
AskUserQuestion(
  header: "CLI Commands",
  question: "Found CLI command: `humanlayer thoughts sync`. How should I handle it?",
  options: [
    { label: "Remove", description: "Delete this command and related steps" },
    { label: "Replace", description: "I'll provide a replacement command" },
    { label: "Make optional", description: "Keep but mark as project-specific" }
  ]
)
```

For **Agent Names**:

```
AskUserQuestion(
  header: "Agent: thoughts-locator",
  question: "How should I handle the `thoughts-locator` agent reference?",
  options: [
    { label: "Rename to FM equivalent", description: "e.g., docs-locator, fm-locator" },
    { label: "Remove", description: "Delete this agent reference" },
    { label: "Keep generic", description: "Use a generic description instead" }
  ]
)
```

For **Ticket Formats**:

```
AskUserQuestion(
  header: "Ticket Format",
  question: "Found ticket format: `ENG-XXXX`. How should I handle it?",
  options: [
    { label: "Use {ISSUE-ID}", description: "Generic placeholder for any issue tracker" },
    { label: "Use ISSUE-XXX", description: "Generic example format" },
    { label: "Keep as-is", description: "Preserve ENG-XXXX format" }
  ]
)
```

**3e. Build replacement map:**

Based on user responses, create a replacement map:

```
REPLACEMENTS:
├── paths
│   ├── "thoughts/shared/plans/" → ".flomaster/plans/"
│   ├── "thoughts/allison/tickets/" → ".flomaster/tasks/"
│   └── "humanlayer-wui/" → "{frontend-dir}"
├── commands
│   └── "humanlayer thoughts sync" → REMOVE
├── agents
│   ├── "thoughts-locator" → "docs-locator"
│   └── "linear-ticket-reader" → REMOVE
└── formats
    └── "ENG-XXXX" → "{ISSUE-ID}"
```

**3f. Confirm replacement map:**

```
## Replacement Map

I'll make these substitutions during conversion:

| Original | Replacement |
|----------|-------------|
| `thoughts/shared/plans/` | `.flomaster/plans/` |
| `thoughts/allison/tickets/` | `.flomaster/tasks/` |
| `humanlayer-wui/` | `{frontend-dir}` |
| `humanlayer thoughts sync` | *(removed)* |
| `thoughts-locator` | `docs-locator` |
| `ENG-XXXX` | `{ISSUE-ID}` |

Proceed with these replacements? (yes / adjust / cancel)
```

**If "cancel":** Display: `Conversion cancelled.` and STOP.

Wait for confirmation before proceeding.

**3g. Apply replacements during conversion:**

Store the replacement map for use in Step 5 (Convert to FM Template).

All replacements will be applied when building the converted content.

## 4. Handle Missing Sections

For each REQUIRED section that's missing, ask user:

**Required sections:**

- `<objective>` — REQUIRED
- `<process>` — REQUIRED
- `<success_criteria>` — REQUIRED

**Optional sections:**

- `<context>` — optional but recommended
- `<execution_context>` — optional (only if refs workflows)
- `<anti_patterns>` — optional
- `<offer_next>` — optional (only if command routes to next action)

**For each missing REQUIRED section:**

Use AskUserQuestion:

- header: "Missing: [section]"
- question: "The source doesn't have a clear [section]. How should I handle
  this?"
- options:
  - "Generate it" — I'll create reasonable content based on the command's logic
  - "Skip it" — Omit this section (not recommended for required sections)
  - "Let me provide it" — I'll tell you what to put

**If "Let me provide it":** Wait for user input, use that content.

**If "Generate it":**

- For `<objective>`: Synthesize from description + overall command behavior
- For `<process>`: Structure existing instructions into numbered steps
- For `<success_criteria>`: Derive checkpoints from process steps

**If "Skip it":** Mark section as deliberately omitted (add comment).

**For missing OPTIONAL sections:**

Briefly note: "Optional sections [list] not found in source. These will be
omitted."

Only ask if the command clearly SHOULD have them (e.g., command has routing
logic but no `<offer_next>`).

## 5. Convert to FM Template

Build the new command file with FM branding. **Apply all replacements from
Step 3.**

**5a. Generate YAML frontmatter:**

```yaml
---
name: fm:{command-name}
description: { source.description }
argument-hint: { source.argument_hint or inferred }
allowed-tools:
  - { tools from source or inferred from content }
---
```

**Infer allowed-tools if missing:**

- Has `cat`, `ls`, `mkdir`, etc. → add `Bash`
- Has file reading → add `Read`
- Has file writing → add `Write`
- Has `grep` or search → add `Grep`
- Has glob patterns → add `Glob`
- Has Task() calls → add `Task`
- Has AskUserQuestion → add `AskUserQuestion`

**5b. Build sections (applying replacement map):**

**`<objective>`:**

For simple commands (no agent spawning):

```xml
<objective>
{Brief 1-2 sentence description}

**What this does:**
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Output:** {What the command produces}
</objective>
```

For orchestrator commands (spawns subagents):

```xml
<objective>
{Brief 1-2 sentence description}

**Default flow:** {Stage 1} → {Stage 2} → {Stage 3} → Done

**Orchestrator role:** {What the main command does - parse, validate, spawn, collect}

**Why subagents:** {Explain context management - e.g., "Research burns context fast. Fresh context per agent."}

**Output:** {What the command produces}

Context budget: ~{X}% orchestrator, 100% fresh per subagent.
</objective>
```

**`<execution_context>` (if applicable):**

```xml
<execution_context>
@./.claude/flomaster/workflows/{relevant-workflow}.md
@./.claude/flomaster/templates/{relevant-template}.md
</execution_context>
```

Note: Convert any `get-shit-done` or `gsd` references to `flomaster` or `fm`.

**`<context>`:**

```xml
<context>
{Argument description}: $ARGUMENTS

**Files to load:**
@{file references from source}
</context>
```

**`<process>`:**

Structure as numbered steps with stage banners for user feedback:

````xml
<process>

## 0. Resolve Model Profile (if command spawns agents)

```bash
MODEL_PROFILE=$(cat .flomaster/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
````

**Model lookup table:**

| Agent         | quality | balanced | budget |
| ------------- | ------- | -------- | ------ |
| fm-researcher | opus    | sonnet   | haiku  |
| fm-planner    | opus    | opus     | sonnet |
| fm-executor   | opus    | sonnet   | sonnet |

## 1. {First Major Step}

Display stage banner (for long operations or agent spawns):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► {STAGE NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ {What's happening...}
```

{Content}

```bash
{code blocks preserved}
```

## 2. {Second Major Step}

{Content}

## N. Handle {Agent} Return (if step spawns an agent)

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
```

**Branding conversion in process:**

- `GSD` → `FM`
- `gsd:` → `fm:`
- `get-shit-done` → `flomaster`
- `gsd-planner` → `fm-planner`
- `gsd-executor` → `fm-executor`
- Banner style: `GSD ►` → `FM ►`

**`<anti_patterns>` (if content found):**

```xml
<anti_patterns>
- Don't {extracted anti-pattern 1}
- Don't {extracted anti-pattern 2}
</anti_patterns>
```

**`<offer_next>` (if routing exists):**

```xml
<offer_next>
Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► {COMPLETION STATUS}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Completion summary}

───────────────────────────────────────────────────────────────

## ▶ Next Up

{Next action suggestion}

`/fm:{next-command}`

<sub>`/clear` first → fresh context window</sub>

───────────────────────────────────────────────────────────────
</offer_next>
```

**`<success_criteria>`:**

```xml
<success_criteria>
{Command name} is complete when:

- [ ] {Criterion 1 from process}
- [ ] {Criterion 2 from process}
- [ ] {Criterion N}
- [ ] User informed of next steps
</success_criteria>
```

## 6. Write Converted Command

**Determine output filename:**

```bash
# Convert source name to fm namespace
# gsd:plan-phase → plan-phase.md
# commit → commit.md
# some-tool:action → action.md

OUTPUT_NAME=$(echo "$SOURCE_NAME" | sed 's/.*://' | sed 's/[^a-z0-9-]/-/g')
OUTPUT_PATH=".claude/commands/fm/${OUTPUT_NAME}.md"
```

**Check for existing file:**

```bash
if [ -f "$OUTPUT_PATH" ]; then
  echo "WARNING: $OUTPUT_PATH already exists"
fi
```

If exists, ask user:

- "Overwrite existing file?"
- "Write to different name?"
- "Cancel"

**Write the file:**

Use Write tool to create `.claude/commands/fm/{command-name}.md` with the
converted content.

**Report:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► COMMAND CONVERTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Source:** $FILE_PATH
**Output:** $OUTPUT_PATH

**Sections created:**
- [✓] objective
- [✓] context
- [✓] process ({N} steps)
- [✓] success_criteria ({M} items)
- [✓/✗] anti_patterns
- [✓/✗] offer_next

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
grep -q "<objective>" "$NEW_FILE" && echo "✓ objective" || echo "✗ objective MISSING"
grep -q "<process>" "$NEW_FILE" && echo "✓ process" || echo "✗ process MISSING"
grep -q "<success_criteria>" "$NEW_FILE" && echo "✓ success_criteria" || echo "✗ success_criteria MISSING"

# Check frontmatter
grep -q "^name:" "$NEW_FILE" && echo "✓ frontmatter.name" || echo "✗ frontmatter.name MISSING"
grep -q "^description:" "$NEW_FILE" && echo "✓ frontmatter.description" || echo "✗ frontmatter.description MISSING"
```

**7b. Content completeness verification:**

Compare source and output to ensure nothing lost:

1. **Extract all code blocks from source:**

   ````bash
   grep -c '```' "$FILE_PATH"
   grep -c '```' "$NEW_FILE"
   ````

   Code block count should be equal or greater.

2. **Extract all file references from source:**

   ```bash
   grep -oE '@[a-zA-Z0-9_./-]+' "$FILE_PATH" | sort -u
   grep -oE '@[a-zA-Z0-9_./-]+' "$NEW_FILE" | sort -u
   ```

   All source refs should appear in output (possibly with path changes).

3. **Extract all command references from source:**

   ```bash
   grep -oE '/[a-z]+:[a-z-]+' "$FILE_PATH" | sort -u
   ```

   All should be converted to `/fm:` equivalents or preserved.

4. **Check for orphaned content:**
   - Any substantial text blocks from source not in output?
   - Any logic/conditions from source not in output?

**7c. Semantic verification:**

Read both files and verify:

1. **Behavior preserved:** Does the new command do the same thing?
2. **Logic intact:** Are all conditionals and branches preserved?
3. **Error handling:** Are error cases still handled?
4. **User interactions:** Are all prompts/questions preserved?

**7d. Report verification results:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► VERIFICATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Structural Checks
- [✓] YAML frontmatter valid
- [✓] All required sections present
- [✓] Section tags properly closed

## Content Completeness
- [✓] Code blocks: {N} source → {M} output
- [✓] File references: {N} preserved
- [✓] Command references: {N} converted

## Semantic Checks
- [✓] Core logic preserved
- [✓] Error handling intact
- [✓] User interactions preserved

───────────────────────────────────────────────────────────────

**Result:** PASSED ✓

**Output file:** .claude/commands/fm/{command-name}.md

───────────────────────────────────────────────────────────────
```

**If verification fails:**

```
## Verification Issues Found

| Check | Status | Details |
|-------|--------|---------|
| Code blocks | ⚠ | Source: 5, Output: 3 (2 missing) |
| File refs | ✓ | All preserved |
| Logic | ⚠ | Conditional at line 45 not found in output |

───────────────────────────────────────────────────────────────

**Action required:** Review the issues above.

Options:
1. Review and fix manually
2. Re-run conversion with more detail
3. Accept as-is (not recommended)
```

</process>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► COMMAND CONVERTED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{command-name}** — converted to FM format

Location: `.claude/commands/fm/{command-name}.md`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Test the command** — run it to verify it works

`/fm:{command-name}`

───────────────────────────────────────────────────────────────

**Also available:**

- `cat .claude/commands/fm/{command-name}.md` — review converted command
- `/fm:create-command {another-file}` — convert another command
- `/fm:create-command "description"` — create a new command

─────────────────────────────────────────────────────────────── </offer_next>

<anti_patterns>

- Don't invent content the source doesn't have (ask user first)
- Don't lose ANY logic, code, or instructions from source
- Don't convert commands that are too simple (< 10 lines)
- Don't skip verification even if conversion "looks right"
- Don't overwrite existing files without asking
- Don't change the command's behavior, only its structure
- Don't silently convert project-specific paths/tools — always ask user first
- Don't assume what a replacement should be — present options and let user
  decide
- Don't convert generic patterns (npm, git, standard dirs) — only
  project-specific content needs user input </anti_patterns>

<success_criteria> Command conversion is complete when:

- [ ] Source command located and read
- [ ] Source analyzed and content inventoried
- [ ] Project-specific content detected (paths, CLI tools, agents, ticket
      formats)
- [ ] User asked about each category of project-specific content
- [ ] Replacement map built and confirmed
- [ ] Missing sections identified and handled (user decided)
- [ ] All content mapped to FM template sections
- [ ] Replacements applied during conversion
- [ ] Branding converted (GSD → FM, gsd: → fm:)
- [ ] New file written to `.claude/commands/fm/`
- [ ] Structural verification passed
- [ ] Content completeness verification passed
- [ ] Semantic verification passed
- [ ] No content lost from source
- [ ] User informed of output location </success_criteria>
