# Quick Reference

## Project Identity

- **Name**: Gemini CLI
- **Purpose**: Terminal-based AI assistant powered by Google Gemini
- **Language**: TypeScript (ES Modules)
- **Framework**: React 19 + Ink (terminal UI), Node.js backend
- **Package Manager**: npm workspaces (monorepo)
- **Node Version**: >=20.0.0
- **Main Entry**: `packages/cli/src/gemini.tsx` (interactive),
  `bundle/gemini.js` (bundled)
- **Config Location**: `~/.gemini/settings.json` (user), `.gemini/settings.json`
  (project)

## File Structure (Critical Paths)

<structure>
- `packages/cli/`: React + Ink terminal UI (frontend)
  - `src/gemini.tsx`: Main interactive app entry
  - `src/commands/`: CLI command handlers
  - `src/ui/`: React Ink components
  - `src/config/`: CLI configuration management
- `packages/core/`: Node.js backend logic
  - `src/core/`: Agent/chat logic (`geminiChat.ts`, `turn.ts`, `client.ts`)
  - `src/tools/`: Tool implementations (24+ tools: read-file, shell, grep, etc.)
  - `src/hooks/`: Hook system for lifecycle events
  - `src/policy/`: TOML-based security policy engine
  - `src/mcp/`: Model Context Protocol integration
  - `src/utils/`: Shared utilities (errors, retry, file, shell, git)
- `packages/a2a-server/`: Agent-to-Agent server (experimental)
- `packages/vscode-ide-companion/`: VSCode extension
- `packages/test-utils/`: Shared testing utilities
</structure>

## Common Patterns

<patterns>

### Plain Objects over Classes

Use TypeScript interfaces with plain objects instead of classes for React
integration, serialization, and immutability.

### ES Module Encapsulation

- Exported items = public API
- Unexported items = private to module
- Always use `.js` extension in imports (even for `.ts` files)
- Use `node:` protocol for Node.js built-ins:
  `import * as fs from 'node:fs/promises'`

### Functional Style

Prefer `.map()`, `.filter()`, `.reduce()` over imperative loops.

### Error Classification

```typescript
// Three-tier error handling:
// 1. Fatal errors → exit immediately (FatalError, FatalAuthenticationError, etc.)
// 2. Retryable errors → exponential backoff (network, 5xx, 429)
// 3. Recoverable errors → log and allow model to self-correct
```

### Tool Two-Phase Pattern

```typescript
// 1. build() validates params → returns ToolInvocation
// 2. execute() performs work → returns ToolResult
const invocation = tool.build(params);
const result = await invocation.execute(signal);
```

### Zod Schema Validation

```typescript
const MySchema = z.object({ field: z.string() });
type MyType = z.infer<typeof MySchema>;
```

### Logging (No console.log)

```typescript
// Dev debugging:
import { debugLogger } from '@google/gemini-cli-core';
debugLogger('my-module', 'message');

// User feedback:
import { coreEvents } from '@google/gemini-cli-core';
coreEvents.emitFeedback({ type: 'info', message: '...' });
```

### React/Ink Rules

- Functional components with Hooks only
- Do NOT use `useMemo`/`useCallback` (React Compiler handles it)
- Do NOT call `setState` within `useEffect`
- File naming: PascalCase for components (`MyComponent.tsx`), camelCase for
  utilities (`myUtil.ts`)

</patterns>

## Most Common Commands/Operations

```bash
npm run preflight          # REQUIRED before submitting - full validation suite
npm run build              # Build main project
npm run build:all          # Build + sandbox + VSCode companion
npm start                  # Start CLI (dev mode, after building)
npm run test               # Run unit tests (all packages)
npm run test:e2e           # End-to-end integration tests
npm run lint               # ESLint check
npm run lint:fix           # Fix lint + format
npm run typecheck          # TypeScript type checking
npm run format             # Prettier formatting
```

<workspace_commands>

```bash
# Single package operations
npm run build --workspace=@google/gemini-cli-core
npm test --workspace=@google/gemini-cli
npm run typecheck --workspace=@google/gemini-cli-core

# Run single test file
npm run test -- packages/core/src/path/to/file.test.ts
```

</workspace_commands>

## Quick Start for Development

```bash
1. npm ci                  # Install dependencies (clean install)
2. npm run build           # Build all packages
3. npm start               # Run CLI in dev mode
4. npm run preflight       # Validate before committing
```

<debug_mode>

```bash
npm run debug              # Node.js debugger with --inspect-brk
DEV=true npm start         # Enable React DevTools integration
GEMINI_DEV_TRACING=true npm start  # Enable tracing
```

</debug_mode>

## Critical Gotchas

<gotchas>

### ESM Import Extensions Required

Always include `.js` extension in imports, even for TypeScript files:

```typescript
// Correct
import { helper } from './utils/helper.js';
// Wrong - will fail at runtime
import { helper } from './utils/helper';
```

### Module Boundaries (ESLint Enforced)

- Within a package: relative imports
- Cross-package: use package name (`@google/gemini-cli-core`)

### No os.homedir() or os.tmpdir() Directly

Use helpers from `@google/gemini-cli-core` for environment isolation:

```typescript
import { homedir, tmpdir } from '@google/gemini-cli-core';
```

### Build Before Test

Tests run against compiled `dist/` not `src/`. Always build first.

### Preflight Required Before Submit

`npm run preflight` runs: clean → install → format → build → lint → typecheck →
test

### React Compiler Handles Memoization

Do NOT manually add `useMemo`, `useCallback`, or `React.memo`.

### AbortSignal Propagation

All async operations should accept and check `AbortSignal`:

```typescript
async function doWork(signal: AbortSignal) {
  if (signal.aborted) throw createAbortError();
}
```

### License Headers Required

All source files require Apache 2.0 license headers.

</gotchas>

## Environment Management

<environment>

### Configuration Hierarchy (lowest to highest precedence)

1. Default values
2. System defaults file
3. User settings (`~/.gemini/settings.json`)
4. Project settings (`.gemini/settings.json`)
5. System settings
6. Environment variables (`.env` files)
7. Command-line arguments

### Environment Variable Prefixes

| Prefix         | Purpose                       |
| -------------- | ----------------------------- |
| `GEMINI_*`     | Core Gemini CLI configuration |
| `GEMINI_CLI_*` | CLI-specific settings         |
| `GOOGLE_*`     | Google Cloud configuration    |

### Authentication

```bash
# API Key
export GEMINI_API_KEY="YOUR_KEY"

# Google OAuth (default)
gemini  # Follow browser auth flow

# Vertex AI
export GOOGLE_API_KEY="YOUR_KEY"
export GOOGLE_GENAI_USE_VERTEXAI=true
```

### .env Files

Prefer `.gemini/.env` over `.env` for project-specific settings.

</environment>

## Testing

```bash
npm run test                         # Unit tests (core + cli)
npm run test:e2e                     # Integration tests (no sandbox)
npm run test:integration:sandbox:docker  # With Docker sandbox
```

<testing_patterns>

### Structure

- Test files co-located with source: `*.test.ts`, `*.test.tsx`
- Use `beforeEach` with `vi.resetAllMocks()`, `afterEach` with
  `vi.restoreAllMocks()`

### Mocking Pattern

```typescript
// Place vi.mock() at file top, before imports
vi.mock('node:fs/promises');
vi.mock('@google/genai');

// Use vi.hoisted() for mock functions needed in factory
const mockFn = vi.hoisted(() => vi.fn());
vi.mock('./module', () => ({ fn: mockFn }));
```

### React/Ink Testing

```typescript
import { render } from 'ink-testing-library';
const { lastFrame } = render(<MyComponent />);
expect(lastFrame()).toContain('expected text');
```

### Async Testing

```typescript
// Timers
vi.useFakeTimers();
await vi.advanceTimersByTimeAsync(1000);

// Rejections
await expect(promise).rejects.toThrow('error');
```

</testing_patterns>

## Glossary

| Term       | Definition                                                           |
| ---------- | -------------------------------------------------------------------- |
| **MCP**    | Model Context Protocol - standard for external tool integration      |
| **Tool**   | AI-invokable function (read-file, shell, grep, etc.)                 |
| **Hook**   | Lifecycle extension point (before-agent, after-tool-execution, etc.) |
| **Policy** | TOML-based security rules controlling tool permissions               |
| **Core**   | Backend package (`@google/gemini-cli-core`)                          |
| **CLI**    | Frontend package (`@google/gemini-cli`) with React/Ink UI            |
| **Ink**    | React renderer for terminal interfaces                               |
