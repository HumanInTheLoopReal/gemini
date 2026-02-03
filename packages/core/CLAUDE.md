# @google/gemini-cli-core

Backend package for AI orchestration, tools, and services. **Zero UI
dependencies**.

## Package Purpose

Core provides all backend functionality for Gemini CLI:

- Gemini API integration via `@google/genai`
- Tool execution and MCP (Model Context Protocol) support
- Agent orchestration and lifecycle management
- Configuration, telemetry, and safety systems

## Directory Structure

```
src/
├── __mocks__/         # Node module mocks for testing
├── agents/            # Agent execution, TOML loading, subagent wrappers
├── availability/      # Provider availability checking
├── code_assist/       # Legacy Google Code Assist (deprecated)
├── commands/          # Command definitions and handlers
├── config/            # Configuration loading, model configs
├── confirmation-bus/  # Tool confirmation messaging
├── core/              # Core orchestration (geminiChat, tokenLimits, hooks)
├── fallback/          # Model fallback handling
├── hooks/             # Hook system (planning, aggregation, triggers)
├── ide/               # IDE integration types and utilities
├── mcp/               # MCP client, OAuth, token storage
├── mocks/             # Test mocks and fixtures
├── output/            # JSON formatting, streaming output
├── policy/            # Policy enforcement
├── prompts/           # System prompts and templates
├── resources/         # Resource registry
├── routing/           # Request routing
├── safety/            # Safety checkers and protocol
├── scheduler/         # Tool execution scheduling
├── services/          # External service integrations
├── skills/            # Skill discovery and integration
├── telemetry/         # OpenTelemetry integration
├── test-utils/        # Internal test utilities
├── tools/             # Tool implementations (24+ tools)
├── types/             # Shared type definitions
└── utils/             # Utilities (git, file, shell, text, etc.)
```

## Key Dependencies

- **Gemini API**: `@google/genai` (direct API client, no intermediate SDKs)
- **MCP**: `@modelcontextprotocol/sdk`
- **Telemetry**: `@opentelemetry/*` (distributed tracing and metrics)
- **Google Cloud**: `@google-cloud/logging`, `google-auth-library`
- **Utilities**: `zod`, `glob`, `simple-git`, `diff`, `@iarna/toml`

## Critical Patterns

### No UI Imports

```typescript
// NEVER import from @google/gemini-cli or UI libraries
// This package must remain UI-agnostic
```

### Gemini API Usage

```typescript
// Use @google/genai directly for AI interactions
import { GoogleGenerativeAI } from '@google/genai';
import type { Content, Part } from '@google/genai';

const client = new GoogleGenerativeAI();
const response = await client.models.generateContent({
  model: 'gemini-2-0-flash',
  contents: messages,
});
```

### Tool Implementation

```typescript
// Tools follow a consistent pattern
export const myTool = {
  name: 'my_tool',
  description: 'Tool description',
  parameters: z.object({
    /* zod schema */
  }),
  execute: async (params, context) => {
    /* implementation */
  },
};
```

## Commands

```bash
npm run build --workspace=@google/gemini-cli-core    # Build
npm test --workspace=@google/gemini-cli-core         # Run tests
npm run typecheck --workspace=@google/gemini-cli-core # Type check
```

## Testing Notes

- Test files co-located: `*.test.ts` next to source
- Use `@google/gemini-cli-test-utils` for shared mocks
- Mock AI responses for deterministic tests
- Use `vi.mock()` with `async (importOriginal)` pattern

## Module Navigation

Each subdirectory has detailed guidance in its own CLAUDE.md:

| Module              | Purpose                                  | Guide                                       |
| ------------------- | ---------------------------------------- | ------------------------------------------- |
| `agents/`           | Agent execution, TOML loading, subagents | [CLAUDE.md](src/agents/CLAUDE.md)           |
| `availability/`     | Model health states, fallback policies   | [CLAUDE.md](src/availability/CLAUDE.md)     |
| `code_assist/`      | Legacy Google Code Assist (deprecated)   | [CLAUDE.md](src/code_assist/CLAUDE.md)      |
| `commands/`         | UI-agnostic slash command logic          | [CLAUDE.md](src/commands/CLAUDE.md)         |
| `config/`           | Central configuration, model aliases     | [CLAUDE.md](src/config/CLAUDE.md)           |
| `confirmation-bus/` | Event-driven policy enforcement          | [CLAUDE.md](src/confirmation-bus/CLAUDE.md) |
| `core/`             | AI orchestration, Gemini API integration | [CLAUDE.md](src/core/CLAUDE.md)             |
| `fallback/`         | Model fallback handling                  | [CLAUDE.md](src/fallback/CLAUDE.md)         |
| `hooks/`            | 11 lifecycle events, merge strategies    | [CLAUDE.md](src/hooks/CLAUDE.md)            |
| `ide/`              | IDE detection and integration            | [CLAUDE.md](src/ide/CLAUDE.md)              |
| `mcp/`              | Model Context Protocol client            | [CLAUDE.md](src/mcp/CLAUDE.md)              |
| `output/`           | JSON/JSONL formatters for headless CLI   | [CLAUDE.md](src/output/CLAUDE.md)           |
| `policy/`           | 3-tier rules, safety checkers            | [CLAUDE.md](src/policy/CLAUDE.md)           |
| `prompts/`          | System prompts and templates             | [CLAUDE.md](src/prompts/CLAUDE.md)          |
| `resources/`        | Resource definitions and registry        | [CLAUDE.md](src/resources/CLAUDE.md)        |
| `routing/`          | Model selection strategies               | [CLAUDE.md](src/routing/CLAUDE.md)          |
| `safety/`           | Plugin-based security validators         | [CLAUDE.md](src/safety/CLAUDE.md)           |
| `scheduler/`        | Tool execution scheduling                | [CLAUDE.md](src/scheduler/CLAUDE.md)        |
| `services/`         | Core services, dependency injection      | [CLAUDE.md](src/services/CLAUDE.md)         |
| `skills/`           | Skill discovery and integration          | [CLAUDE.md](src/skills/CLAUDE.md)           |
| `telemetry/`        | OpenTelemetry, privacy controls          | [CLAUDE.md](src/telemetry/CLAUDE.md)        |
| `tools/`            | 24+ tools, MCP integration               | [CLAUDE.md](src/tools/CLAUDE.md)            |
| `types/`            | Shared type definitions                  | [CLAUDE.md](src/types/CLAUDE.md)            |
| `utils/`            | Foundational utilities                   | [CLAUDE.md](src/utils/CLAUDE.md)            |
