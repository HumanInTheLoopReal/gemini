---
name: fm:create-template
description:
  Create new FM templates from descriptions or convert existing templates to FM
  format
argument-hint: '<description | file-path>'
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Create new FM templates from descriptions, or convert existing templates to FM format.

**What this does:**

1. Detects mode (create from description vs convert existing file)
2. Gathers requirements interactively using AskUserQuestion
3. Maps content to FM template meta-structure
4. Generates template with all required sections
5. Runs verification to ensure quality

**Output:** Template file at `.claude/flomaster/templates/{name}.md` following
FM meta-template structure.

**Modes:**

- **Create mode:** Input is a description → gather requirements, create new
  template
- **Convert mode:** Input is a file path → read, ask questions, convert to FM
  format </objective>

<execution_context> @./.claude/flomaster/templates/template-meta.md
</execution_context>

<context>
Source: $ARGUMENTS

**Template reference:** See `<execution_context>` above for the complete FM
template meta-structure, including:

- Required sections (File Template, purpose, guidelines, examples)
- Optional sections (sections, lifecycle, anti_patterns, Related links)
- Placeholder format (`{placeholder-name}`)
- Example quality rules (complete, realistic, varied, self-contained)
- Anti-pattern Bad → Good transformation format </context>

<process>

## 0. Determine Mode

**If $ARGUMENTS is empty:**

```
ERROR: No input specified.

Usage: /fm:create-template <description | file-path>

Examples:
  /fm:create-template "phase execution summary"      ← create from description
  /fm:create-template .claude/templates/project.md   ← convert existing file
```

STOP here.

Parse $ARGUMENTS to determine mode:

**Convert mode indicators:**

- Contains `/` or `\` (path separator)
- Ends with `.md`
- Starts with `.` or `@`
- File exists at the path

**Create mode indicators:**

- Plain text description
- No file extension
- File doesn't exist at path

```bash
INPUT="$ARGUMENTS"

# Check if it looks like a file path
if [[ "$INPUT" == */* ]] || [[ "$INPUT" == *.md ]] || [[ "$INPUT" == .* ]] || [[ "$INPUT" == @* ]]; then
  # Strip @ if present
  FILE_PATH="${INPUT#@}"
  if [ -f "$FILE_PATH" ]; then
    MODE="convert"
    echo "MODE: convert → $FILE_PATH"
  else
    echo "File not found: $FILE_PATH"
    echo "Treating as description for create mode"
    MODE="create"
    TOPIC="$INPUT"
  fi
else
  MODE="create"
  TOPIC="$INPUT"
  echo "MODE: create → topic: $TOPIC"
fi
```

**If mode is ambiguous:** Use AskUserQuestion to clarify.

---

## 1a. Analyze Source Template (Convert Mode)

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
 FM ► ANALYZING TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read source file and extract:

```bash
cat "$FILE_PATH"
```

**1a. Identify template type:**

| Pattern                                | Template Type             |
| -------------------------------------- | ------------------------- |
| Has `## File Template` with code block | Document template         |
| Has `<tasks>` or `<objective>` XML     | Prompt/execution template |
| Has YAML frontmatter with `phase:`     | Phase plan template       |
| Pure markdown with `{placeholders}`    | Simple template           |

**1b. Extract existing sections:**

Scan for these patterns:

- `<template>...</template>` → File Template content
- `<purpose>...</purpose>` → Purpose section
- `<guidelines>...</guidelines>` → Guidelines
- `<example>...</example>` or `<examples>...</examples>` → Examples
- `<sections>...</sections>` → Section guidance
- `<lifecycle>...</lifecycle>` → Lifecycle info
- `<anti_patterns>...</anti_patterns>` → Anti-patterns
- `## File Template` → Alternative template marker
- Markdown headers (`#`, `##`) → Structure clues

**1c. Create inventory:**

```
SOURCE INVENTORY:
├── template_type: [document | prompt | phase | simple]
├── has_file_template: [yes/no]
├── has_purpose: [yes/no]
├── has_guidelines: [yes/no]
├── has_examples: [yes/no]
├── has_sections: [yes/no]
├── has_lifecycle: [yes/no]
├── has_anti_patterns: [yes/no]
├── example_count: [N]
└── unmapped_content: [list]
```

**1c-i. Check if source is trivially simple:**

```bash
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
```

If `LINE_COUNT < 5`:

```
ERROR: Source template is too simple to convert.

File: $FILE_PATH
Lines: $LINE_COUNT

FM templates require enough structure to benefit from the meta-format.
Add more content to the source first, then try again.
```

STOP here if too simple.

**1c-ii. Check if source already follows FM meta-template:**

```bash
HAS_FILE_TEMPLATE=$(grep -c "## File Template" "$FILE_PATH" || echo 0)
HAS_PURPOSE=$(grep -c "<purpose>" "$FILE_PATH" || echo 0)
HAS_GUIDELINES=$(grep -c "<guidelines>" "$FILE_PATH" || echo 0)
HAS_EXAMPLES=$(grep -c "<examples>" "$FILE_PATH" || echo 0)
```

If `HAS_FILE_TEMPLATE > 0` AND `HAS_PURPOSE > 0` AND `HAS_GUIDELINES > 0` AND
`HAS_EXAMPLES > 0`:

```
Source already follows the FM template meta-structure.

Running verification only...
```

Skip to **Step 6: Verification** (already FM format).

**1d. Present analysis:**

```
## Source Template Analysis

**File:** $FILE_PATH
**Type:** [template type]
**Lines:** [count]

### Sections Found:
- File Template: [✓/✗]
- Purpose: [✓/✗]
- Guidelines: [✓/✗]
- Examples: [✓/✗] ([N] examples)
- Sections: [✓/✗]
- Lifecycle: [✓/✗]
- Anti-patterns: [✓/✗]

### Content to Map:
[List of content blocks identified]

### Missing Required Sections:
[List sections that need to be created]

---

Proceed with conversion? (yes / review source first / cancel)
```

**If "cancel":** Display: `Conversion cancelled.` and STOP.

---

## 1b. Gather Requirements (Create Mode)

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► GATHERING REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**1a. Clarify the template purpose:**

Use AskUserQuestion:

```
header: "Template Purpose"
question: "What will this template produce?"
options:
  - "Planning document" — PROJECT.md, ROADMAP.md, STATE.md style
  - "Phase artifact" — PLAN.md, SUMMARY.md, CONTEXT.md style
  - "Research output" — STACK.md, FEATURES.md style
  - "Execution prompt" — Agent prompts, task definitions
```

**1b. Gather key details:**

Ask inline (freeform):

- "What's the one-line purpose of this template?"
- "What file path will the output live at?"
- "Who/what creates this file? Who/what reads it?"

**1c. Identify sections needed:**

Use AskUserQuestion:

```
header: "Template Sections"
question: "What main sections should the template have?"
multiSelect: true
options:
  - "Frontmatter (YAML metadata)"
  - "Overview/Summary section"
  - "Detailed content sections"
  - "Status/Progress tracking"
  - "References/Links"
```

**1d. Get example scenarios:**

Ask: "Give me 2-3 different scenarios where this template would be used. What
would a filled-out version look like for each?"

---

## 2. Handle Missing Sections

For each REQUIRED section not found in source (or not provided for create mode):

**Required:** File Template, `<purpose>`, `<guidelines>`, `<examples>`

Use AskUserQuestion:

```
header: "Missing: [section]"
question: "How should I handle the missing [section]?"
options:
  - "Generate it" — I'll create reasonable content based on context
  - "Let me provide it" — I'll tell you what to put
  - "Skip it" — Omit this section (not recommended)
```

**If "Generate it":**

- `<purpose>`: Synthesize from template content and output path
- `<guidelines>`: Derive from template structure and content patterns
- `<examples>`: Create 2-3 realistic filled-out versions

**If "Let me provide it":** Wait for user input.

---

## 3. Build FM Template

Display stage banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► BUILDING TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**3a. Generate header:**

```markdown
# [Template Name] Template

Template for `[output-path]` — [one-line purpose].

[If related files exist:]

> **Related:** [workflow.md](path), [agent.md](path)

---
```

**3b. Generate File Template section:**

````markdown
## File Template

```markdown
[Extract or create the actual template content] [Use {placeholders} for variable
content] [Include inline comments for guidance: <!-- explanation -->]
```
````

````

**File Template best practices:**

- **Enum fields need inline explanations:**
  ```markdown
  **Status**: {STATUS}
  <!-- STATUS: ACTIVE (in progress) | COMPLETE (done) | BLOCKED (waiting on external) | DEFERRED (postponed) -->
````

- **Optional sections should be marked:**

  ```markdown
  ## 8. Notes (Optional)

  {additional-context-if-needed}

  <!-- Remove this section if nothing to add. If content is important, move it to a structured section above. -->
  ```

- **Complex fields need format hints:**
  ```markdown
  **Date**: {YYYY-MM-DD HH:MM} **Files**: `{path}` - {purpose}
  ```

**3c. Generate `<purpose>` section:**

```xml
<purpose>

[2-3 sentences explaining:]
- What this file is
- What problem it solves
- Why it exists in the workflow

</purpose>
```

**3d. Generate `<sections>` section (if template has multiple parts):**

Use the **Goal/Include/Exclude/Format** pattern for each section:

```xml
<sections>

### [Section 1 Name]
**Goal:** [What this section accomplishes - one sentence]
**Include:** [What belongs here]
**Exclude:** [What does NOT belong here - prevents bloat]
**Format:** [How to structure the content - bullets, table, prose]

### [Section 2 Name]
**Goal:** [Purpose]
**Include:** [What belongs]
**Exclude:** [What doesn't belong]
**Format:** [Structure]

</sections>
```

**Section guidance quality rules:**

- **Goal** answers "why does this section exist?"
- **Include/Exclude** creates clear boundaries (prevents scope creep)
- **Format** eliminates ambiguity about structure
- For optional sections, add: **When to omit:** [conditions where section should
  be removed]

**3e. Generate `<lifecycle>` section:**

```xml
<lifecycle>

**When created:** [Command or trigger that creates this file]
**When read:** [Who/what consumes this file and when]
**When updated:** [Triggers that cause updates]

</lifecycle>
```

**3f. Generate `<guidelines>` section:**

```xml
<guidelines>

**The Core Filter Question:**
Before including ANY information, ask:
> "[Template-specific question that determines if content belongs]"

**Quality criteria:**
- [Specific, testable criterion]
- [Another criterion]

**Sizing rules:**
- [Size constraint with specific limits]

**Content standards:**
- [Standard that affects how content is written]

</guidelines>
```

**Guidelines quality rules:**

- **Core filter question** should be template-specific, not generic
  - Good: "Will the next session make a wrong decision without this?"
  - Bad: "Is this information useful?"
- **Quality criteria** must be testable (could someone verify yes/no?)
- **Sizing rules** should have specific limits ("2-3 sentences", "under 100
  lines")
- **Content standards** affect HOW content is written, not WHAT is included

**3g. Generate `<examples>` section:**

````xml
<examples>

**Example 1: [Scenario name]**

```markdown
[Fully filled-out template for scenario 1]
````

**Example 2: [Scenario name]**

```markdown
[Fully filled-out template for scenario 2]
```

</examples>
```

**3h. Generate `<anti_patterns>` section (if applicable):**

````xml
<anti_patterns>

**Bad:** [Anti-pattern description]
```markdown
[Example of what NOT to do]
````

**Good:** [Correct approach]

```markdown
[Example of correct usage - shows the TRANSFORMATION]
```

---

[Repeat for each anti-pattern, separated by ---]

</anti_patterns>

````

**Anti-pattern quality rules:**
- Always show **Bad → Good transformation** (not just "don't do X")
- Use **realistic examples** from the template's domain
- Focus on **common mistakes** that people actually make
- Include **3-5 anti-patterns** covering different failure modes:
  - Content quality (vague vs specific)
  - Scope creep (including too much)
  - Format violations (wrong structure)
  - Missing context (excluding important info)

---

## 4. Determine Output Path

**For convert mode:**
- Extract template name from source filename
- Convert to kebab-case
- Path: `.claude/flomaster/templates/{name}.md`

**For create mode:**
- Derive name from topic
- Convert to kebab-case
- Path: `.claude/flomaster/templates/{name}.md`

```bash
# Derive output name
if [ "$MODE" = "convert" ]; then
  TEMPLATE_NAME=$(basename "$FILE_PATH" .md | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
else
  TEMPLATE_NAME=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -c1-30)
fi

OUTPUT_PATH=".claude/flomaster/templates/${TEMPLATE_NAME}.md"
````

**Check for existing file:**

```bash
if [ -f "$OUTPUT_PATH" ]; then
  echo "WARNING: $OUTPUT_PATH already exists"
fi
```

If exists, use AskUserQuestion:

```
header: "File Exists"
question: "Template already exists at $OUTPUT_PATH. What should I do?"
options:
  - "Overwrite" — Replace existing file
  - "New name" — I'll provide a different name
  - "Cancel" — Abort conversion
```

---

## 5. Write Template

Ensure directory exists:

```bash
mkdir -p .claude/flomaster/templates
```

Write the file using Write tool.

Display completion:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► TEMPLATE CREATED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Output:** $OUTPUT_PATH

**Sections created:**
- [✓] File Template
- [✓] Purpose
- [✓] Sections
- [✓] Lifecycle
- [✓] Guidelines
- [✓] Examples ([N] scenarios)
- [✓/✗] Anti-patterns

───────────────────────────────────────────────────────────────

Running verification...
```

---

## 6. Verification

**6a. Structural verification:**

```bash
NEW_FILE="$OUTPUT_PATH"

# Check required sections
echo "Checking required sections..."
grep -q "## File Template" "$NEW_FILE" && echo "✓ File Template" || echo "✗ File Template MISSING"
grep -q "<purpose>" "$NEW_FILE" && echo "✓ Purpose" || echo "✗ Purpose MISSING"
grep -q "<guidelines>" "$NEW_FILE" && echo "✓ Guidelines" || echo "✗ Guidelines MISSING"
grep -q "<examples>" "$NEW_FILE" && echo "✓ Examples" || echo "✗ Examples MISSING"

# Count examples
EXAMPLE_COUNT=$(grep -c "Example [0-9]:" "$NEW_FILE" || echo 0)
echo "Examples found: $EXAMPLE_COUNT"
```

**6b. Content quality verification:**

Check for common issues:

- Placeholders are clear (`{placeholder-name}` format)
- No raw source content leaked through
- Examples are realistic and complete
- Guidelines are specific, not vague

**6c. Report results:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FM ► VERIFICATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Structural Checks
- [✓] File Template section present
- [✓] Purpose section present
- [✓] Guidelines section present
- [✓] Examples section present ({N} examples)

## Quality Checks
- [✓] Placeholders use {name} format
- [✓] Examples are complete
- [✓] Guidelines are specific

───────────────────────────────────────────────────────────────

**Result:** PASSED ✓

**Output file:** .claude/flomaster/templates/{name}.md

───────────────────────────────────────────────────────────────
```

**If verification fails:**

```
## Verification Issues Found

| Check | Status | Details |
|-------|--------|---------|
| File Template | ⚠ | Section missing or malformed |
| Examples | ⚠ | Only 1 example (need 2+) |
| Guidelines | ⚠ | Too vague |

───────────────────────────────────────────────────────────────

**Action required:** Review the issues above.
```

Use AskUserQuestion:

```
header: "Verification Failed"
question: "How should I proceed?"
options:
  - "Fix and retry" — I'll address the issues and re-run verification
  - "Accept as-is" — Proceed despite issues (not recommended)
  - "Start over" — Discard and begin again with more context
```

**If "Fix and retry":** Address issues, re-run Step 6. **If "Accept as-is":**
Proceed to `<offer_next>` with warning. **If "Start over":** STOP and prompt
user to re-run command.

</process>

<offer_next> Output this markdown directly (not as a code block):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ FM ► TEMPLATE READY ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**{Template Name}** — {one-line purpose}

Location: `.claude/flomaster/templates/{name}.md`

───────────────────────────────────────────────────────────────

## ▶ Next Up

**Use the template** — reference it in commands or workflows

```markdown
<execution_context> @./.claude/flomaster/templates/{name}.md
</execution_context>
```

───────────────────────────────────────────────────────────────

**Also available:**

- `cat .claude/flomaster/templates/{name}.md` — review template
- `/fm:create-template {another-file}` — convert another template

─────────────────────────────────────────────────────────────── </offer_next>

<anti_patterns>

- Don't create templates without examples — examples prevent ambiguity
- Don't use vague guidelines like "make it good" — be specific about quality
  criteria
- Don't skip the purpose section — it explains WHY the template exists
- Don't copy source content verbatim — adapt to FM meta-structure
- Don't create placeholder examples — examples must be realistic and complete
- Don't forget lifecycle — knowing when files are created/read/updated is
  critical
- Don't mix template content with guidance — keep File Template separate from
  explanation
- Don't carry over source-specific paths without asking — abstract to FM
  conventions
- Don't assume template names — derive from content or ask user
- Don't skip verification even if conversion "looks right" — always verify
  structure and quality </anti_patterns>

<success_criteria> Template conversion/creation is complete when:

- [ ] Mode determined (create vs convert)
- [ ] Source analyzed or requirements gathered
- [ ] Missing sections identified and handled
- [ ] File Template section created with {placeholders}
- [ ] Purpose section explains why template exists
- [ ] Sections guidance provided (if template has multiple parts)
- [ ] Lifecycle documented (created/read/updated)
- [ ] Guidelines are specific and actionable
- [ ] At least 2 realistic examples included
- [ ] Anti-patterns documented (if applicable)
- [ ] Output written to `.claude/flomaster/templates/`
- [ ] Structural verification passed
- [ ] Quality verification passed
- [ ] User informed of output location and next steps </success_criteria>
