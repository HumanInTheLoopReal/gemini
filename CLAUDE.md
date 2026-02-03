# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

<!-- ═══════════════════════════════════════════════════════════════════════════
    WHAT: Project Overview
    ═══════════════════════════════════════════════════════════════════════════
    This section answers: "What is this project?"
    - Architecture and package structure
    - Key entry points and directories
    - How components interact
    ═══════════════════════════════════════════════════════════════════════════ -->

## Project Overview

Gemini CLI is a terminal-based AI assistant built as a monorepo with a React/Ink
frontend and Node.js backend.

### Architecture

| Package                         | Purpose                              | Entry Point      |
| ------------------------------- | ------------------------------------ | ---------------- |
| `packages/cli`                  | React + Ink terminal UI (frontend)   | `src/gemini.tsx` |
| `packages/core`                 | Node.js backend logic                | `src/index.ts`   |
| `packages/a2a-server`           | Agent-to-Agent server (experimental) | —                |
| `packages/vscode-ide-companion` | VSCode extension                     | —                |
| `packages/test-utils`           | Shared testing utilities             | —                |

### packages/cli Structure

- `commands/` — Command handlers (15+ commands)
- `ui/` — React Ink components for terminal rendering
- `services/` — CLI-specific services
- `config/` — Configuration management

### packages/core Structure

- `core/` — Agent/chat logic (`client.ts`, `geminiChat.ts`, `turn.ts`,
  `coreToolScheduler.ts`)
- `tools/` — Tool implementations (read-file, write-file, shell, glob, grep,
  web-fetch, etc.)
- `hooks/` — Hook system for extending behavior at defined points
- `policy/` — Security policy engine (TOML-based rules)
- `mcp/` — Model Context Protocol integration
- `agents/` — Agent definitions

### Interaction Flow

```
User Input → CLI Package → Core Package → Gemini API
                                      ↓
                              Tool Execution (if requested)
                              (user approval for file/shell changes)
                                      ↓
                              Response → CLI → User
```

### Git

Main branch: `main`

<!-- ═══════════════════════════════════════════════════════════════════════════
    WHY: Design Decisions
    ═══════════════════════════════════════════════════════════════════════════
    This section answers: "Why are things designed this way?"
    - Rationale behind architectural choices
    - Reasons for coding conventions
    - Prevents AI from "fixing" intentional design decisions
    ═══════════════════════════════════════════════════════════════════════════ -->

## Design Decisions

### Plain Objects over Classes

Use plain JavaScript objects with TypeScript interfaces instead of classes
because:

- **React integration** — Explicit props/state, easier data flow
- **Less boilerplate** — No constructors, `this` binding, getters/setters
- **Readability** — Properties directly accessible, no hidden state
- **Immutability** — Encourages creating new objects instead of mutating
- **Serialization** — Plain objects serialize to JSON naturally

### ES Module Encapsulation

Use `import`/`export` for public/private API boundaries instead of class access
modifiers:

- Exported items = public API; unexported items = private to module
- If you need to spy on an unexported function for testing, extract it to its
  own module with a proper public API (this is a code smell otherwise)

### Functional Style

Prefer array operators (`.map()`, `.filter()`, `.reduce()`, `.slice()`) over
imperative loops:

- Returns new arrays (immutable)
- More concise and declarative
- Pairs well with React's rendering model

### React Compiler Optimization

Do NOT use `useMemo`/`useCallback` — React Compiler handles memoization
automatically. Manual optimization adds complexity without benefit.

### Error Handling Strategy

Three-tier error classification enables appropriate responses:

- **Fatal errors** — Exit immediately with specific codes (authentication,
  sandbox, config failures)
- **Retryable errors** — Exponential backoff with jitter (network errors, 5xx,
  429 quota)
- **Recoverable errors** — Log and allow model to self-correct (tool execution
  failures)

### Async Patterns

- **AbortSignal propagation** — Enables clean cancellation throughout async
  operations
- **Async generators** — Streaming responses chunk-by-chunk
- **Promise.all** — Parallel execution for independent operations (hooks, tools,
  file reads)

### Restricted OS Imports

Do NOT use `os.homedir()` or `os.tmpdir()` directly — use helpers from
`@google/gemini-cli-core` for environment isolation (enables testing and
sandboxing).

<!-- ═══════════════════════════════════════════════════════════════════════════
    HOW: Working with This Codebase
    ═══════════════════════════════════════════════════════════════════════════
    This section answers: "How do I work with this codebase?"
    - Commands for building, testing, linting
    - Code conventions and patterns to follow
    - Testing practices
    - Configuration details
    ═══════════════════════════════════════════════════════════════════════════ -->

## Commands

### Essential Commands

```bash
npm run preflight          # REQUIRED before submitting - builds, tests, lints, typechecks
npm run build              # Build main project
npm run build:all          # Build project + sandbox + VSCode companion
npm start                  # Start CLI (after building)
npm run debug              # Debug mode with --inspect-brk
```

### Testing

```bash
npm run test               # Unit tests (packages/core and packages/cli)
npm run test:e2e           # End-to-end integration tests
npm run test:integration:sandbox:none    # Integration tests without sandbox
npm run test:integration:sandbox:docker  # Integration tests with Docker sandbox
```

### Code Quality

```bash
npm run lint               # ESLint
npm run lint:fix           # Fix linting + format
npm run format             # Prettier
npm run typecheck          # TypeScript type checking
```

### Dev Tracing

```bash
GEMINI_DEV_TRACING=true npm start           # Enable tracing
npm run telemetry -- --target=genkit        # Start Genkit trace viewer
npm run telemetry -- --target=local         # Start Jaeger trace viewer
```

---

## HOW: Code Conventions

### Import Rules

**Module Boundaries (ESLint enforced):** | Context | Pattern |
|---------|---------| | Within a package | Relative imports:
`import { helper } from '../utils/helper.js'` | | Cross-package | Package name:
`import { Storage } from '@google/gemini-cli-core'` |

**ESM Requirements:**

- Always include `.js` extension in imports (even for `.ts` files)
- Use `node:` protocol for Node.js built-ins:
  `import * as fs from 'node:fs/promises'`
- Use `import type` for type-only imports
- Prefer named exports over default exports

### File Naming

| Type             | Convention              | Example                            |
| ---------------- | ----------------------- | ---------------------------------- |
| React components | PascalCase              | `AboutBox.tsx`, `Composer.tsx`     |
| Custom hooks     | `use` + camelCase       | `useAuth.ts`, `useTerminalSize.ts` |
| Context files    | PascalCase + "Context"  | `SessionContext.tsx`               |
| Utilities        | camelCase               | `gitUtils.ts`, `fileUtils.ts`      |
| Test files       | Source + `.test.ts/tsx` | `gitUtils.test.ts`                 |

### TypeScript

- Use `unknown` instead of `any` — forces explicit type narrowing
- Avoid type assertions (`as Type`) — they bypass type checking
- Use `checkExhaustive` helper in switch default clauses
  (`packages/cli/src/utils/checks.ts`)
- Needing `any`/type assertions to test "private" internals = code smell

### Schema Validation (Zod)

```typescript
const PolicyRuleSchema = z.object({
  toolName: z.string(),
  decision: z.nativeEnum(PolicyDecision),
});
type PolicyRule = z.infer<typeof PolicyRuleSchema>;
```

- Schema constants: PascalCase + `Schema` suffix
- Inferred types: `type X = z.infer<typeof XSchema>`

### Async Patterns

**AbortSignal Support:**

```typescript
async function doWork(signal: AbortSignal) {
  if (signal.aborted) throw createAbortError();
  // ... work
}
```

**Streaming:**

```typescript
async function* streamResponse(): AsyncGenerator<StreamEvent> {
  for await (const chunk of stream) {
    yield { type: 'chunk', value: chunk };
  }
}
```

### Logging

- No `console.log` — use `debugLogger` from `@google/gemini-cli-core` for dev
  logs
- User-facing feedback: use `coreEvents.emitFeedback()` from
  `@google/gemini-cli-core`

### Style

- 2 spaces indentation
- 80 character line width
- Trailing commas, single quotes, semicolons required
- Use hyphens in flag names (`--my-flag` not `--my_flag`)
- Refer to project as "Gemini CLI" (not "the Gemini CLI")
- All source files require Apache 2.0 license headers
- Only write high-value comments; avoid talking to users through comments

---

## HOW: React/Ink (packages/cli)

### Core Principles

- Functional components with Hooks only (no class components)
- Pure render functions — no side effects in component body
- One-way data flow — pass data down via props, lift state up when sharing
- Never mutate state directly — use spread syntax or state setters
- Small, composable components over large monolithic ones

### Hooks Rules

- Call Hooks unconditionally at top level of components/custom Hooks
- Never call Hooks inside loops, conditionals, or nested functions
- Abstract repetitive logic into custom Hooks

### useEffect Usage

- Primarily for synchronization with external state (not for "do X when Y
  changes")
- Do NOT call `setState` within `useEffect` — degrades performance
- Always include all dependencies in the dependency array
- Return cleanup functions for subscriptions/resources
- User action logic belongs in event handlers, not useEffect

### Performance

- Do NOT use `useMemo`/`useCallback` — React Compiler handles it
- Use `useRef` only when genuinely needed (focus, animation, non-React libs)
- Never read/write `ref.current` during rendering (except lazy initialization)
- Use functional state updates: `setCount(c => c + 1)`

### Data Fetching

- Parallel fetching where possible (start multiple requests at once)
- Use Suspense for loading states
- Co-locate requests with components that need the data

---

## HOW: Testing (Vitest)

### Structure

- Test files co-located with source: `*.test.ts`, `*.test.tsx`
- Use `beforeEach` with `vi.resetAllMocks()`, `afterEach` with
  `vi.restoreAllMocks()`

### Mocking

- Place `vi.mock()` at file top, before imports, for critical dependencies
- Use `vi.hoisted()` for mock functions needed in `vi.mock()` factory
- Use `vi.spyOn()` for spying on methods
- Commonly mocked: `fs`, `fs/promises`, `os`, `path`, `child_process`,
  `@google/genai`, `@modelcontextprotocol/sdk`

### React/Ink Testing

- Use `render()` from `ink-testing-library`
- Assert output with `lastFrame()`
- Wrap components in necessary Context providers
- Mock custom hooks and complex child components

### Async Testing

- Use `async/await`
- Timers: `vi.useFakeTimers()`, `vi.advanceTimersByTimeAsync()`,
  `vi.runAllTimersAsync()`
- Rejections: `await expect(promise).rejects.toThrow(...)`

---

## HOW: Key Patterns

### Tool System

Tools registered in `packages/core/src/tools/tool-registry.ts`:

- Name and description
- Input schema validation
- Execution logic
- User confirmation requirements for dangerous operations

### Hook System

Hooks extend behavior at defined points: `before-agent`, `after-agent`,
`before-tool-execution`, `after-tool-execution`, etc. See
`packages/core/src/hooks/`.

### Policy Engine

TOML-based security policies in `packages/core/src/policy/`. Controls tool
permissions and shell command safety.

### Error Classes

Custom error hierarchy in `packages/core/src/utils/errors.ts`:

- `FatalError` base class with specific exit codes
- Subclasses: `FatalAuthenticationError`, `FatalInputError`,
  `FatalSandboxError`, `FatalConfigError`
- HTTP errors: `ForbiddenError` (403), `UnauthorizedError` (401),
  `BadRequestError` (400)

### Retry Logic

Centralized in `packages/core/src/utils/retry.ts`:

- Exponential backoff with jitter
- Automatic retry on network errors and 5xx/429 responses
- Never retries on 400 Bad Request
- Quota-aware: distinguishes terminal vs retryable quota errors

### Tool Errors

Classification in `packages/core/src/tools/tool-error.ts`:

- Fatal errors (e.g., `NO_SPACE_LEFT`) cause immediate exit
- Recoverable errors are logged and allow model to self-correct

---

## HOW: Configuration

### Environment Variable Naming

| Prefix         | Purpose                                         |
| -------------- | ----------------------------------------------- |
| `GEMINI_*`     | Core Gemini CLI configuration                   |
| `GEMINI_CLI_*` | CLI-specific settings (home, IDE, system paths) |
| `GOOGLE_*`     | Google Cloud configuration                      |

### Configuration Hierarchy (lowest to highest precedence)

1. Default values
2. System defaults file
3. User settings (`~/.gemini/settings.json`)
4. Project settings (`.gemini/settings.json`)
5. System settings
6. Environment variables (`.env` files)
7. Command-line arguments

### .env Files

- Prefer `.gemini/.env` over `.env` for project-specific settings
- `DEBUG` and `DEBUG_MODE` are excluded from project `.env` files by default

---

## HOW: Documentation

When editing `/docs`:

- Follow Google Developer Documentation Style Guide
- Sentence case for headings
- Second person ("you")
- Present tense
- Update `sidebar.json` when adding new pages

---

## General

If something is ambiguous, seek clarification before making assumptions.

For detailed coding conventions, see [GEMINI.md](./GEMINI.md).
