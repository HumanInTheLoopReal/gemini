# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

---

## ⚠️ CRITICAL: Purpose of This Repository

**THIS IS A CONTENT CREATION ENVIRONMENT, NOT A SOFTWARE DEVELOPMENT PROJECT.**

### Primary Purpose

- We are building **CONTENT** (videos, tutorials, demonstrations)
- The Gemini CLI codebase is a **DEMO ENVIRONMENT** — a real production codebase
  used to teach people
- **CONTENT IS ALWAYS THE MAIN GOAL** — everything else serves that goal

### What This Means

- Any code we write is **FOR DEMONSTRATION PURPOSES**
- Any features we add are **TO SHOW CONTENT**, not to improve Gemini itself
- Any workflows we execute are **TO TEACH PEOPLE**, not to ship software
- We are NOT trying to be Gemini contributors — we are educators using their
  codebase as an example

### Strict Rules

1. **Never assume we're doing "real" development** — we're always creating
   content
2. **Every action should be teachable** — if it's not good for video, reconsider
3. **Code is a prop** — we may write extensive code, but it's to demonstrate
   concepts
4. **Planning is for content, not features** — when we plan, we're planning
   videos/demos
5. **Brainstorming is about teaching** — what will resonate with viewers, not
   what ships

---

## Operating Modes

### Mode 1: Brainstorming (Default)

When NOT recording:

- Help plan content, research topics, structure videos
- Write/refine voiceover scripts
- Figure out what demos will look good on camera
- Prepare the exact commands/actions for recording
- We're collaborators building educational material

### Mode 2: Recording Prep

When user says they're about to record:

- Confirm the demo steps are ready
- Make sure we know exactly what commands to run
- Verify the codebase is in the right state for the demo
- Claude Code will behave NORMALLY during recording — no special mode

### Why No Special "Demo Output Style"?

The teaching happens in the **voiceover narration**, not in Claude's responses.
During recording:

- Claude Code should be **authentic** — viewers see the real tool
- Your narration explains what's happening
- Claude just executes normally
- This keeps the demo genuine and relatable

**The prep work is what matters** — by the time we record, we've already figured
out:

1. What to demonstrate
2. What to say (voiceover script)
3. What commands to run
4. What the expected output looks like

---

## ⚠️ CRITICAL: Fact-Check All Technical Claims

**Every technical claim in voiceovers and demos MUST be validated before
recording.**

### Validation Process

When helping with voiceover scripts or demo prep:

1. **Check official documentation first** — Use knowledge of Claude Code's
   actual behavior
2. **Verify with Perplexity** — Search for current, accurate information
3. **Test empirically when possible** — Actually try the feature in Claude Code
4. **Flag uncertain claims** — If something seems off, explicitly call it out

### Example of What to Catch

Part 4 originally claimed: `@*.test.js` and `@src/**/*.ts` add multiple files
via glob patterns.

**This is INCORRECT.** The `@` mention syntax only works with single, concrete
file paths — not glob patterns. Glob patterns are supported by Claude's internal
GlobTool, not the inline `@` reference.

### Red Flags to Watch For

- Claims about keyboard shortcuts or syntax (verify they actually work)
- Claims about what features exist or how they behave
- Specific technical details (token limits, file size limits, etc.)
- "You can do X" statements — always verify X is actually possible

### When Reviewing Scripts

- Read through technical claims skeptically
- Cross-reference with official docs and Perplexity
- Ask: "Is this actually how it works, or is this how someone THINKS it works?"
- Better to flag and verify than to publish incorrect information

**Our credibility depends on accuracy. Wrong information = lost trust.**

---

## Git & GitHub Settings

**Always use the `HumanInTheLoopReal` GitHub account** for all git operations in
this project.

Before pushing, pulling, or any GitHub operations:

```bash
gh auth switch --user HumanInTheLoopReal
```

**Remote:**

- `origin` → `https://github.com/HumanInTheLoopReal/gemini.git`

## Project Context: Human in the Loop

This codebase is used as a **demo environment** for the "Human in the Loop"
content channel (YouTube, TikTok, Instagram). The Gemini CLI codebase serves as
a real-world production application for demonstrating:

- **Claude Code techniques** - slash commands, context management, tools,
  workflows
- **AI-assisted development** - vibe coding, pair programming with AI
- **AI/agent concepts** - how AI tools work under the hood

### Session Workflow

When starting a session (user says "hi"), use `AskUserQuestion` to ask:

1. What are we working on today? (topic/concept)
2. What format? (TikTok reel, YouTube video, etc.)
3. Do they have a script/research, or need demo suggestions?

### Quick Part Access

When user says **"part X"** (e.g., "part 4", "part 5"):

1. Fetch the voiceover script:
   `/Users/fahadkaleem/Documents/Workspace/tiktok/shorts/claude-code-tips/voiceovers/part-XX.md`
2. Read it and understand what demo is needed
3. Help create/execute the demo in the Gemini codebase

When user mentions **a topic** (e.g., "the one about slash commands"):

1. Check
   `/Users/fahadkaleem/Documents/Workspace/tiktok/shorts/claude-code-tips/QUEUE.md`
   to find the matching part number
2. Then fetch that part's voiceover script
3. Proceed with demo creation

### TikTok Folder Structure

The content folder is located at
`/Users/fahadkaleem/Documents/Workspace/tiktok/`:

```
/Users/fahadkaleem/Documents/Workspace/tiktok/
├── shorts/claude-code-tips/
│   ├── ROADMAP.md          ← All topics organized by level
│   ├── QUEUE.md            ← Numbered parts with status & descriptions
│   └── voiceovers/         ← Individual video scripts
│       ├── part-01.md
│       ├── part-02.md
│       └── ...
├── youtube/                ← Under the Hood series content
└── resources/              ← Transcripts, guides, reference materials
```

### Two Types of Content

1. **Claude Code features**: Demonstrate features BY working on Gemini (e.g.,
   using `/commit` to fix a bug)
2. **AI concepts**: Teach about Claude Code's abilities where Gemini is
   incidental (e.g., context management tips)

### Demo Creation Guidelines

- Ask clarifying questions each session - format and approach varies
- For short-form (TikTok/Reels): Focus on one clear, visual tip
- For long-form (YouTube): Can do deeper dives with multiple steps
- Be ready to provide either ready-to-record commands OR flexible outlines based
  on what they need

### Research & Tools Available

- **Perplexity MCP**: Use `mcp__perplexity__search`, `mcp__perplexity__reason`,
  or `mcp__perplexity__deep_research` to research topics
- **WebFetch**: After Perplexity returns blog links, use WebFetch to read full
  articles for deeper context
- **Official docs**: Always check official documentation first, then escalate to
  blogs/community content

### Internal Context Reflection

I see things the user doesn't see in the interface:

- XML tags wrapping tool calls and responses
- Full tool call structures and parameters
- Token counts and context window details
- How Claude Code processes requests internally

**This internal visibility is valuable content.** When creating "Under the Hood"
content, I should share what I observe about:

- How tool calls are structured
- What gets sent to the model vs what the user sees
- Context window mechanics
- The actual XML/JSON structures being used

## The Core Philosophy

### Teaching People to Fish

We don't give people the fish. We give them the fishing rod AND teach them how
water currents work.

- **Generic prompts from the internet are worthless.** An agent that works for
  FastAPI in general won't make optimal choices for YOUR FastAPI codebase with
  YOUR domain knowledge.
- **Domain-driven agents > generic agents.** Every agent, every prompt, every
  config should be tailored to the specific problem, the specific codebase, the
  specific domain.
- **Understanding beats copying.** Anyone can copy a prompt. The edge comes from
  understanding WHY it works, so you can adapt it to your situation.

### The Senior Engineer Mindset

The difference between a junior and senior engineer isn't syntax — it's
understanding the WHY behind decisions.

- Juniors know "this is how you do it"
- Seniors know "this is WHY we do it this way, and here's when you'd do it
  differently"

We teach the senior mindset to everyone — vibe coders, junior devs, curious
builders. You don't need to implement patterns from scratch anymore (AI does
that). But you need to KNOW which pattern to apply and WHY.

### Implementation Is the Moat

Anyone can vibe code a website from a single prompt. But so can everyone else.

The differentiation is:

- How well you execute
- How you architect the solution
- How you engineer the context
- How you think about the problem

We teach the thinking that makes the difference.

---

## The 9-Step Research Methodology

This is how we RESEARCH any tip, feature, or concept to extract maximum depth.
**Most creators stop at Step 1. We go to Step 9.**

### Step 1: Start with the Surface

**What's the basic tip?** This is where most creators stop.

### Step 2: Ask "Why Does This Matter?"

**Not just WHAT it does, but WHY it's useful. What friction does it eliminate?**

### Step 3: Test Empirically

**Don't assume. Actually run it. Measure the output. Get real numbers.**

### Step 4: Look for the Unexpected

**Does it actually work as advertised?** Often the "common wisdom" is wrong.

### Step 5: Understand the Mechanics

**WHY did the unexpected happen?** Understanding mechanics reveals why "obvious"
solutions aren't optimal.

### Step 6: Escalate to the Real Solution

**What's the ACTUAL optimal approach?** Usually involves domain-aware
customization.

### Step 7: Measure the Results

**Hard numbers, not vibes.** Token counts, line counts, percentage improvements.

### Step 8: Find Secondary Benefits

**What else improves?** Often there are cascading benefits (human visibility, no
retry loops, etc.)

### Step 9: Document with Evidence

**Real measurements, real screenshots, real proof. Not theory — data.**

---

## The Escalation Framework

**Most creators stop at Level 1-2. We go to Level 4-5.**

| Level | What It Is                 | Example                                |
| ----- | -------------------------- | -------------------------------------- |
| 1     | The feature exists         | "You can use `!` for bash"             |
| 2     | Why it matters             | "Skips round-trip processing"          |
| 3     | Power usage                | "Concatenate multiple commands"        |
| 4     | Expert context engineering | "Filter output to only errors"         |
| 5     | Domain-aware optimization  | "Script knows YOUR codebase structure" |

---

## Key Principles

### The Back-and-Forth Problem

The fundamental friction we're always trying to eliminate:

**The slow way (prompting Claude):**

```
You: "Fetch GitHub issue #42 and implement it"
    ↓
Claude reads your message
    ↓
Claude requests Bash tool call: gh issue view 42
    ↓
Bash runs, output returns to Claude
    ↓
Claude reads output, SUMMARIZES it, responds
    ↓
Claude then starts implementing
```

That's 5+ steps. The summary is wasted context.

**The fast way:**

```
You: ! gh issue view 42
    ↓
Output injected directly
    ↓
You: "implement it"
```

That's 2 steps. No summary. Clean context.

### The Dual Visibility Principle

**Build tools that serve both the human AND the agent.**

Every script, every tool, every optimization should:

- Give the agent clean, minimal, actionable context
- Give the human instant visibility and status

Don't sacrifice your own visibility for token savings — design for both.

---

## Brand Voice

### We Are:

- A practitioner, not just an explainer ("I use this daily" > "You can use
  this")
- Deep but accessible (complex topics explained simply, not dumbed down)
- Confident but not arrogant
- Teaching the thinking, not just the mechanics

### We Are NOT:

- Selling generic prompts to copy-paste
- Surface-level "here's the feature" content
- Hype-driven AI gurus
- Dumbing things down to the point of uselessness

### Key Phrases:

- "Here's WHY this matters..."
- "Senior engineers know..."
- "This is context engineering..."
- "Build for YOUR domain, not generic use cases"
- "The thinking behind this is..."

---

## What Makes a Good Video

### 1. Real Numbers / Live Examples

Don't say "saves tokens" — show "9.1k → 941 tokens, that's 90% reduction."
Real > hypothetical. Always.

### 2. Clear Before/After Benefit

- **Before:** The slow/wasteful way (with visible friction)
- **After:** The optimized way (with measurable improvement)
- **The gap:** What they're leaving on the table

### 3. Practical Implementation

Every tip must be actionable TODAY. Show the command. Show the output. Show it
working.

### 4. Friction Elimination

The core question: **What friction are we eliminating between human and AI?**

### 5. Escalation Potential

Every tip should hint at deeper levels.

---

## When Helping With Content

1. **Always think in escalation levels.** What's the Level 1 tip? What's the
   Level 4 insight?
2. **Focus on the WHY.** What would a senior engineer understand that others
   miss?
3. **Be specific, not generic.** Real examples, real workflows, real
   applications.
4. **Hint at depth.** Tips should make viewers think "there's more to learn
   here."
5. **Domain-driven thinking.** Remind viewers to adapt to THEIR situation.
6. **Identify friction.** What back-and-forth or waste does this tip eliminate?
7. **Show real numbers.** Token counts, line counts, step counts when possible.
8. **Apply the 9-step methodology.** Test, discover, measure, document.

### Writing Process: Expand First, Tighten Later

**CRITICAL: When writing scripts, explanations, or any content — WRITE IT OUT
FULLY FIRST.**

- Do NOT optimize for brevity on the first draft
- Let explanations breathe — give ideas room to land
- Write like a professional narrator, not a telegram

**The process is:**

1. Write the full, expanded version first
2. Review together and iterate on substance
3. ONLY tighten/compress if explicitly requested after the content is right

---

## Content Platforms

### Long Form: "Under the Hood" Series (YouTube)

- Deep dives that go under the hood of AI tools
- 10-20 minute videos with real metrics, live demos, and mechanism explanations
- This is where we build authority and trust

### Short Form (TikTok, Instagram Reels, YouTube Shorts)

- Same video → all three platforms
- Quick tips extracted from the deeper "Under the Hood" content
- Format: "Claude Code tips you should know, Part X" → show it → "Easy."

### Content Pillars

1. **Claude Code** — features, workflows, configs, tips
2. **Context Engineering** — the art of what goes into the context and why
3. **Architecture Patterns** — when to use what, senior engineer thinking
4. **Real Builds** — "Here's how I built X" with the thinking exposed
5. **AI Tools & News** — new releases, comparisons

---

## Current Projects

### YouTube: "Under the Hood" Series (Flagship)

The main content that builds authority. Every video goes deep on AI
tools—explaining not just WHAT they do, but WHY they work that way.

**Three Entry Points:** | Entry Point | Starting Question | Your Role |
|-------------|-------------------|-----------| | **Explainer** | "How does X
work?" | Teacher | | **Review** | "Is X actually worth it?" | Investigator | |
**News/Hype** | "X just dropped—what did they not tell you?" | Analyst |

**The 9-Phase Structure:** Every Under the Hood video follows: Hook → Promise →
Context → Demonstration → Comparison → Tips → Rule of Thumb → Common Concerns →
Wrap

**Full production guide:**
`/Users/fahadkaleem/Documents/Workspace/tiktok/youtube/human-in-the-loop-uth.md`

---

### Short Form: Claude Code Tips Series (Daily Practice)

Daily short-form content to build momentum and editing skills. Follows the
"Powerful Websites You Should Know" format.

| Series                             | Format    | Focus                                               |
| ---------------------------------- | --------- | --------------------------------------------------- |
| **Claude Code Tips Part X**        | 30-60 sec | The WHAT and HOW. Fast tips. One feature per video. |
| **Understanding [Topic] in X min** | 1-3 min   | The WHY. Quick explainers on concepts.              |

### Production Workflow

```
ROADMAP.md          →  QUEUE.md           →  scripts/part-XXX.md
(All topics by       (Numbered parts      (Individual video
level, marked        with status)          scripts)
when assigned)
```

### Tips Series Rules

1. **Each video = one complete feature/tip** (not micro-steps within a feature)
2. **Every video must deliver value** — viewer learns something they can USE
3. **Format like "Powerful Websites"** — "Claude Code tips you should know, Part
   X" → show it → "Easy."
4. **No strict level progression** — after foundation (Parts 1-3), mix tips from
   all levels
5. **Parts 1-3 are foundation** — install, CLI, shortcuts. Everything after is
   standalone tips.

---

## The Funnel

```
┌─────────────────────────────────────────────────────┐
│              TIKTOK / REELS / SHORTS                │
│               (Discovery Layer)                     │
│                                                     │
│  3 videos/day                                       │
│  Quick tips → "Free resource in my Skool"           │
│  Explainers → Deep value, authority                 │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│            FREE SKOOL COMMUNITY                     │
│              (Value Layer)                          │
│                                                     │
│  - Matching resource for every tip video            │
│  - Prompts, configs, templates                      │
│  - Curated learning resources (YouTube, docs)       │
│  - Community Q&A                                    │
│  - Extended explanations                            │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│            PAID SKOOL COMMUNITY                     │
│           (Monetization Layer)                      │
│                                                     │
│  CORE OFFER: How to vibe code production apps       │
│  (Nobody else teaches this)                         │
│                                                     │
│  - 1:1 setup calls (limited availability)           │
│  - "Build with me" project series                   │
│  - The actual thinking process exposed              │
│  - Architecture decisions explained                 │
│  - Real production workflows                        │
└─────────────────────────────────────────────────────┘
```

---

## Milestones

| Milestone | Videos            | Focus                           |
| --------- | ----------------- | ------------------------------- |
| Launch    | 1                 | First video posted              |
| 30        | Tips momentum     | Start planning explainer series |
| 100       | Tips + Explainers | First performance review        |
| 300       | All series        | Evaluate Skool growth           |
| 1000      | Full assessment   | Measure actual success          |

**Rule: Don't measure success until 1000 videos. Just post.**

---

## Reference Materials

### Under the Hood Series (YouTube)

- `/Users/fahadkaleem/Documents/Workspace/tiktok/youtube/human-in-the-loop-uth.md`
  — **Complete production guide** with 9-phase structure, phrase banks, full
  video examples
- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/transcripts/claude-explained/`
  — Reference transcripts (Claude Explained style)
- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/transcripts/ai-labs/`
  — Reference transcripts (AI Labs review style)

### Claude Code Tips Series (Short Form)

- `/Users/fahadkaleem/Documents/Workspace/tiktok/shorts/claude-code-tips/ROADMAP.md`
  — Master topic list with levels
- `/Users/fahadkaleem/Documents/Workspace/tiktok/shorts/claude-code-tips/QUEUE.md`
  — Numbered video queue with status
- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/tips/` — Detailed tip
  content files
- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/claude_code/official-docs/`
  — Official Claude Code documentation

### Resources

- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/transcripts/` —
  Competitor analysis and reference transcripts
- `/Users/fahadkaleem/Documents/Workspace/tiktok/resources/guides/` — Production
  guides

---

_Human in the Loop: Teaching the thinking, not just the tools._

---

## Building and Running

**Preflight check (run before submitting changes):**

```bash
npm run preflight
```

This runs the full suite: `clean`, `install`, `format`, `build`, `lint`,
`typecheck`, and `test`.

**Individual commands:**

```bash
npm run build          # Build all packages
npm run build:all      # Build including sandbox container
npm start              # Run the CLI after building
npm run test           # Run unit tests
npm run test:e2e       # Run integration tests (no sandbox)
npm run lint           # Run ESLint
npm run lint:fix       # Auto-fix lint issues
npm run format         # Format with Prettier
npm run typecheck      # TypeScript type checking
```

**Development mode:**

```bash
DEV=true npm start     # Enable React DevTools integration
npm run debug          # Run with --inspect-brk for debugging
```

**Run single test file:**

```bash
npm run test -- packages/cli/src/path/to/file.test.ts
```

## Architecture

This is an npm monorepo (`packages/*`) for an AI-powered CLI tool:

- **`packages/cli`** (`@google/gemini-cli`): Frontend - handles user input,
  display rendering, React-based UI (using Ink), and CLI configuration
- **`packages/core`** (`@google/gemini-cli-core`): Backend - API client for
  Gemini API, prompt construction, tool execution, state management
- **`packages/core/src/tools/`**: Individual tool modules (file system, shell,
  web fetch, MCP integration) that extend model capabilities
- **`packages/test-utils`**: Shared testing utilities for temp file system
  management
- **`packages/a2a-server`**: Experimental A2A server implementation
- **`packages/vscode-ide-companion`**: VS Code companion extension

**Data flow:** User input → CLI package → Core package → Gemini API → Tool
execution (if needed) → Response back through Core → CLI → Display

## Code Conventions

### TypeScript/JavaScript

- Use plain objects with TypeScript interfaces over classes
- Use ES module `import`/`export` for encapsulation (unexported = private)
- Avoid `any` - use `unknown` with type narrowing instead
- Use functional array operators (`.map()`, `.filter()`, `.reduce()`) over loops
- Use `checkExhaustive` helper in switch default clauses for exhaustive checks
  (from `packages/cli/src/utils/checks.ts`)

### React (Ink CLI)

- Functional components with Hooks only (no classes)
- Keep components pure and side-effect-free during rendering
- Avoid `useEffect` for state synchronization - never `setState` inside
  `useEffect`
- Rely on React Compiler - avoid manual `useMemo`/`useCallback`/`React.memo`
- Effects should return cleanup functions and only be used for external
  synchronization

### Logging and Errors

- Never use `console.log`/`console.error`
- Developer debugging: use `debugLogger` from `@google/gemini-cli-core`
- User-facing feedback: use `coreEvents.emitFeedback` from
  `@google/gemini-cli-core`

### Testing (Vitest)

- Test files co-located with source (`*.test.ts`, `*.test.tsx`)
- Mock ES modules: `vi.mock('module-name', async (importOriginal) => {...})`
- Place critical dependency mocks at very top of file before imports
- Use `vi.hoisted()` when mock functions need early definition
- React/Ink testing: use `ink-testing-library` with `render()` and `lastFrame()`

### Other Conventions

- Prefer hyphenated flag names (`my-flag` not `my_flag`)
- Use relative imports within packages; ESLint enforces cross-package
  restrictions
- Always use `node:` protocol for Node.js built-ins
- Use helpers from `@google/gemini-cli-core` instead of
  `os.homedir()`/`os.tmpdir()` for environment isolation

## Git and Commits

- Main branch: `main`
- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit
  messages
- All PRs must link to an existing issue
- Run `npm run preflight` before submitting
