# Architecture

## Overview

Gemini CLI is a terminal-based AI assistant built as an npm monorepo with a
React/Ink frontend and Node.js backend. The architecture follows a clean
separation between UI concerns (`packages/cli`) and backend logic
(`packages/core`), enabling both interactive terminal sessions and
non-interactive headless execution. The design philosophy emphasizes functional
programming patterns, plain objects over classes, and ES module encapsulation
for clear API boundaries.

## System Context

<system_context>

- **Primary Purpose**: An AI-powered CLI tool for software engineering tasks
  using Google's Gemini API
- **Ecosystem Position**: Part of the Google Gemini AI ecosystem, integrating
  with Gemini models for code assistance
- **Key Consumers**: Developers using terminal-based AI assistance, IDE
  integrations (VSCode), and automated pipelines
- **External Integrations**:
  - Google Gemini API (`@google/genai`) for AI model interactions
  - Model Context Protocol (MCP) servers for extensible tool capabilities
  - IDE companion extensions (VSCode) for editor integration
  - OpenTelemetry for distributed tracing and metrics
  - OAuth2/Google authentication for user identity </system_context>

## Entry Points

<entry_points>

### Main Application Entry

- **Bootstrap File**: `packages/cli/src/gemini.tsx:285` - `main()` function
  initializes the application
- **Interactive UI**: `packages/cli/src/gemini.tsx:172` - `startInteractiveUI()`
  renders React/Ink components
- **Non-Interactive Mode**: `packages/cli/src/nonInteractiveCli.ts` - Handles
  headless execution with piped input

### Initialization Flow

1. `main()` → Load settings and parse arguments
2. Validate authentication and refresh auth tokens
3. Handle sandbox mode (Docker/Podman) if configured
4. Initialize config with `loadCliConfig()` at
   `packages/cli/src/config/config.ts`
5. Initialize app with `initializeApp()` at
   `packages/cli/src/core/initializer.ts`
6. Fire `SessionStart` hook and render UI or execute non-interactively

### Command Registration

- CLI commands registered via yargs in `packages/cli/src/config/config.ts`
- Slash commands loaded from `packages/core/src/commands/` directory
- Skills discovered via `SkillManager` at
  `packages/core/src/skills/skillManager.ts`

### Hook Entry Points

- Hooks execute at 11 lifecycle events defined in
  `packages/core/src/hooks/types.ts:33-45`
- `HookEventHandler` at `packages/core/src/hooks/hookEventHandler.ts` fires
  events </entry_points>

## Core Components

<core_components>

### packages/cli - Terminal UI Package

| Component         | Purpose                                       | Location                                           |
| ----------------- | --------------------------------------------- | -------------------------------------------------- |
| `AppContainer`    | Root React component orchestrating UI state   | `packages/cli/src/ui/AppContainer.tsx`             |
| `App`             | Main application component                    | `packages/cli/src/ui/App.tsx`                      |
| `Composer`        | User input component with message composition | `packages/cli/src/ui/components/Composer.tsx`      |
| `MainContent`     | Primary content display area                  | `packages/cli/src/ui/components/MainContent.tsx`   |
| `SettingsContext` | Settings provider for all components          | `packages/cli/src/ui/contexts/SettingsContext.tsx` |
| `AppContext`      | Application state management                  | `packages/cli/src/ui/contexts/AppContext.tsx`      |

### packages/core - Backend Logic Package

| Component          | Purpose                                         | Location                                            |
| ------------------ | ----------------------------------------------- | --------------------------------------------------- |
| `Config`           | Central configuration and dependency injection  | `packages/core/src/config/config.ts`                |
| `GeminiClient`     | High-level orchestration for AI conversations   | `packages/core/src/core/client.ts:76`               |
| `GeminiChat`       | Low-level chat session with retry and streaming | `packages/core/src/core/geminiChat.ts:237`          |
| `Turn`             | Single conversation turn with tool execution    | `packages/core/src/core/turn.ts`                    |
| `ToolRegistry`     | Central registry for all tools                  | `packages/core/src/tools/tool-registry.ts:189`      |
| `HookSystem`       | Extensibility via lifecycle hooks               | `packages/core/src/hooks/hookSystem.ts`             |
| `PolicyEngine`     | Security policy enforcement                     | `packages/core/src/policy/policy-engine.ts`         |
| `MessageBus`       | Event-driven communication for confirmations    | `packages/core/src/confirmation-bus/message-bus.ts` |
| `ContentGenerator` | AI content generation abstraction               | `packages/core/src/core/contentGenerator.ts`        |

</core_components>

## Service Definitions

<service_definitions>

### AI Orchestration Services

| Service            | Purpose                              | Key Methods                                               |
| ------------------ | ------------------------------------ | --------------------------------------------------------- |
| `GeminiClient`     | Conversation orchestration           | `sendMessageStream()`, `generateContent()`, `resetChat()` |
| `GeminiChat`       | Chat session management              | `sendMessageStream()`, `getHistory()`, `setTools()`       |
| `ContentGenerator` | AI API abstraction                   | `generateContentStream()`, `generateContent()`            |
| `BaseLlmClient`    | Lightweight LLM client for utilities | `generateContent()` for next-speaker checks               |

### Tool Execution Services

| Service                 | Purpose                         | Key Methods                                                |
| ----------------------- | ------------------------------- | ---------------------------------------------------------- |
| `ToolRegistry`          | Tool registration and discovery | `registerTool()`, `getTool()`, `getFunctionDeclarations()` |
| `ShellExecutionService` | Shell command execution         | `execute()` with PTY or subprocess                         |
| `FileSystemService`     | File operations abstraction     | `readFile()`, `writeFile()`, `exists()`                    |
| `FileDiscoveryService`  | Project file discovery          | `discover()`, `getFiles()` with gitignore support          |

### Session Services

| Service                  | Purpose                      | Key Methods                            |
| ------------------------ | ---------------------------- | -------------------------------------- |
| `ChatRecordingService`   | Session transcript recording | `recordMessage()`, `recordToolCalls()` |
| `ChatCompressionService` | Context window compression   | `compress()` with summarization        |
| `LoopDetectionService`   | Infinite loop prevention     | `turnStarted()`, `addAndCheck()`       |
| `ContextManager`         | Context file management      | `loadContext()`, `getContextFiles()`   |

### Configuration Services

| Service                    | Purpose                           | Key Methods                              |
| -------------------------- | --------------------------------- | ---------------------------------------- |
| `ModelConfigService`       | Model configuration resolution    | `getResolvedConfig()` with inheritance   |
| `Storage`                  | Path resolution for settings/data | `getGlobalGeminiDir()`, `getGeminiDir()` |
| `ModelAvailabilityService` | Model health and fallback         | `getAvailability()`, `recordFailure()`   |
| `ModelRouterService`       | Model selection routing           | `route()` based on context               |

</service_definitions>

## Public API & Module Boundaries

<public_api>

### @google/gemini-cli-core Exports (`packages/core/src/index.ts`)

**Configuration**

- `Config`, `Storage`, `AuthType`, `ApprovalMode`
- Model configs: `DEFAULT_GEMINI_MODEL_AUTO`, `DEFAULT_GEMINI_FLASH_MODEL`

**Core Orchestration**

- `GeminiClient`, `GeminiChat`, `Turn`, `ContentGenerator`
- `coreEvents`, `CoreEvent` - Event emitter for cross-component communication

**Tools**

- `ToolRegistry`, `ToolResult`, `ToolInvocation`
- Built-in tools: `ReadFileTool`, `EditTool`, `WriteFileTool`, `ShellTool`,
  `GrepTool`, `GlobTool`

**Hooks**

- `HookSystem`, `HookRegistry`, `HookEventName`
- Hook outputs: `DefaultHookOutput`, `BeforeToolHookOutput`,
  `BeforeModelHookOutput`

**Policy**

- `PolicyEngine`, `PolicyDecision`, `PolicyRule`

**Services**

- `FileDiscoveryService`, `GitService`, `ChatRecordingService`
- `ShellExecutionService`, `FileSystemService`

**Utilities**

- `homedir()`, `tmpdir()` - Environment-isolated path helpers
- `debugLogger`, `coreEvents.emitFeedback()` - Logging abstraction
- Error classes: `FatalError`, `FatalAuthenticationError`, `FatalSandboxError`

### Module Boundaries

| Package                   | Imports From                | Never Imports                      |
| ------------------------- | --------------------------- | ---------------------------------- |
| `@google/gemini-cli`      | `@google/gemini-cli-core`   | N/A                                |
| `@google/gemini-cli-core` | Node.js, external libs      | `@google/gemini-cli`, UI libraries |
| Internal utils            | Nothing from parent modules | `Config` (prevents circular deps)  |

</public_api>

## Interface Contracts

<interface_contracts>

### Tool Interface

```typescript
// packages/core/src/tools/tools.ts
interface DeclarativeTool<TParams, TResult> {
  name: string;
  displayName: string;
  description: string;
  kind: Kind;
  schema: FunctionDeclaration;
  parameterSchema: Record<string, unknown>;
  isOutputMarkdown: boolean;
  canUpdateOutput: boolean;

  build(params: TParams): ToolInvocation<TParams, TResult>;
  validateToolParamValues(params: TParams): ToolValidationError | undefined;
}

interface ToolInvocation<TParams, TResult> {
  getDescription(): string;
  execute(
    signal: AbortSignal,
    updateOutput?: (output: string) => void,
  ): Promise<TResult>;
  shouldConfirmExecute(): ToolCallConfirmationDetails | undefined;
  toolLocations(): ToolCallLocation[];
}

interface ToolResult {
  llmContent: string | Part[]; // Content for AI model
  returnDisplay?: unknown; // Content for user display
  error?: { message: string; type: ToolErrorType };
  resultDisplay?: unknown; // Structured display data
}
```

### Hook Interface

```typescript
// packages/core/src/hooks/types.ts
interface HookInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  hook_event_name: string;
  timestamp: string;
}

interface HookOutput {
  continue?: boolean;
  stopReason?: string;
  suppressOutput?: boolean;
  systemMessage?: string;
  decision?: HookDecision; // 'ask' | 'block' | 'deny' | 'approve' | 'allow'
  reason?: string;
  hookSpecificOutput?: Record<string, unknown>;
}

// 11 Hook Events
enum HookEventName {
  BeforeTool,
  AfterTool,
  BeforeAgent,
  AfterAgent,
  Notification,
  SessionStart,
  SessionEnd,
  PreCompress,
  BeforeModel,
  AfterModel,
  BeforeToolSelection,
}
```

### Policy Interface

```typescript
// packages/core/src/policy/types.ts
interface PolicyRule {
  toolName?: string;
  argsPattern?: RegExp;
  decision: PolicyDecision;
  priority: number;
  modes?: ApprovalMode[];
}

enum PolicyDecision {
  ALLOW = 'allow',
  DENY = 'deny',
  ASK_USER = 'ask_user',
}

enum ApprovalMode {
  Default = 'default',
  Yolo = 'yolo',
  ReadOnly = 'read-only',
}
```

### Stream Event Interface

```typescript
// packages/core/src/core/geminiChat.ts
type StreamEvent =
  | { type: 'chunk'; value: GenerateContentResponse }
  | { type: 'retry' }
  | { type: 'agent_execution_stopped'; reason: string }
  | { type: 'agent_execution_blocked'; reason: string };
```

</interface_contracts>

## Design Patterns Identified

<design_patterns> | Pattern | Implementation | Rationale |
|---------|----------------|-----------| | **Dependency Injection** | `Config`
class as central DI container | Enables testing and modular configuration | |
**Two-Phase Initialization** | Constructor + `initialize()` method | Allows
passing Config before async init | | **Command Pattern** | Tools as declarative
command objects | Separates tool validation from execution | | **Observer/Event
Emitter** | `coreEvents`, `MessageBus` | Decouples components, enables hooks | |
**Strategy Pattern** | `ModelRouterService`, `FallbackModelHandler` | Pluggable
model selection algorithms | | **Registry Pattern** | `ToolRegistry`,
`AgentRegistry`, `PromptRegistry` | Centralized registration and discovery | |
**Decorator/Wrapper** | `LoggingContentGenerator`, `RecordingContentGenerator` |
Add behavior without modifying core | | **Builder Pattern** |
`DeclarativeTool.build()` → `ToolInvocation` | Validates params before creating
invocation | | **Pipeline Pattern** | Hook system: Registry → Planner → Runner →
Aggregator | Sequential processing with merge strategies | | **Lazy
Initialization** | Services created on first `get*()` access | Defers expensive
operations | | **Functional Style** | Array operators, immutable updates, plain
objects | React integration, less boilerplate | </design_patterns>

## Component Relationships

<component_relationships>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              User Input                                      │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    packages/cli (React/Ink Frontend)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ AppContainer│──│   Contexts  │──│  Components │──│   Commands  │        │
│  │   (Root)    │  │ (State Mgmt)│  │  (UI/Views) │  │  (Handlers) │        │
│  └──────┬──────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────┼───────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    packages/core (Node.js Backend)                           │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                           Config (DI Container)                       │   │
│  │  • ToolRegistry  • PolicyEngine  • MessageBus  • HookSystem          │   │
│  │  • ModelConfigService  • AgentRegistry  • SkillManager               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                     │                                        │
│          ┌──────────────────────────┼──────────────────────────┐            │
│          ▼                          ▼                          ▼            │
│  ┌───────────────┐        ┌───────────────┐        ┌───────────────┐       │
│  │  GeminiClient │───────▶│  GeminiChat   │───────▶│    Turn       │       │
│  │ (Orchestrator)│        │(Chat Session) │        │(Single Turn)  │       │
│  └───────────────┘        └───────────────┘        └───────┬───────┘       │
│                                                            │                │
│          ┌─────────────────────────────────────────────────┤                │
│          ▼                          ▼                      ▼                │
│  ┌───────────────┐        ┌───────────────┐      ┌────────────────┐        │
│  │ContentGenerator│       │  ToolRegistry │      │   HookSystem   │        │
│  │ (@google/genai)│       │  (24+ Tools)  │      │ (11 Events)    │        │
│  └───────┬───────┘        └───────┬───────┘      └────────┬───────┘        │
│          │                        │                       │                 │
│          ▼                        ▼                       ▼                 │
│  ┌───────────────┐        ┌───────────────┐      ┌────────────────┐        │
│  │  Gemini API   │        │ PolicyEngine  │      │  HookRunner    │        │
│  │ (External)    │        │ (TOML Rules)  │      │ (Subprocess)   │        │
│  └───────────────┘        └───────────────┘      └────────────────┘        │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                           Services Layer                              │   │
│  │  FileDiscoveryService │ GitService │ ShellExecutionService │         │   │
│  │  ChatRecordingService │ ChatCompressionService │ ContextManager      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          External Systems                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Gemini API  │  │ MCP Servers │  │ File System │  │    Shell    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Input** → CLI captures via React/Ink `Composer` component
2. **CLI Package** → Dispatches to `AppContext`, calls
   `GeminiClient.sendMessageStream()`
3. **GeminiClient** → Manages conversation state, fires hooks, delegates to
   `GeminiChat`
4. **GeminiChat** → Handles streaming, retries, history management
5. **ContentGenerator** → Makes actual Gemini API calls via `@google/genai`
6. **Tool Execution** → When model requests tools:
   - `ToolRegistry.getTool()` → Get tool definition
   - `PolicyEngine.getDecision()` → Check authorization
   - `MessageBus` → Request user confirmation if needed
   - `ToolInvocation.execute()` → Execute with output streaming
7. **Response** → Streams back through the same chain to UI
   </component_relationships>

## External Dependencies

<external_dependencies> | Dependency | Purpose | Type |
|------------|---------|------| | `@google/genai` | Gemini API client for AI
interactions | runtime | | `@modelcontextprotocol/sdk` | MCP server/client
integration | runtime | | `react` (v19) | UI component framework | runtime | |
`ink` (`@jrichman/ink`) | Terminal React renderer | runtime | | `zod` | Runtime
schema validation | runtime | | `yargs` | CLI argument parsing | runtime | |
`simple-git` | Git operations | runtime | | `glob` | File pattern matching |
runtime | | `diff` | Text diffing for edits | runtime | | `@iarna/toml` | TOML
policy file parsing | runtime | | `@opentelemetry/*` | Distributed tracing and
metrics | runtime | | `@google-cloud/logging` | Cloud logging integration |
runtime | | `google-auth-library` | OAuth/authentication | runtime | | `undici`
| HTTP client | runtime | | `web-tree-sitter` | Syntax parsing for shell
commands | runtime | | `keytar` | Secure credential storage | optional | |
`node-pty` / `@lydell/node-pty` | PTY for interactive shell | optional | |
`vitest` | Testing framework | dev | | `typescript` | Type checking | dev | |
`esbuild` | Bundling | dev | | `eslint`, `prettier` | Code quality | dev |
</external_dependencies>

## Key Methods & Functions

<key_methods>

### AI Orchestration

| Method                                     | Location                                   | Purpose                                              |
| ------------------------------------------ | ------------------------------------------ | ---------------------------------------------------- |
| `GeminiClient.sendMessageStream()`         | `packages/core/src/core/client.ts:734`     | Main conversation loop with hooks and tool execution |
| `GeminiChat.sendMessageStream()`           | `packages/core/src/core/geminiChat.ts:288` | Low-level streaming with retry logic                 |
| `GeminiChat.makeApiCallAndProcessStream()` | `packages/core/src/core/geminiChat.ts:442` | API call with hook integration                       |
| `Turn.run()`                               | `packages/core/src/core/turn.ts`           | Single turn execution with tool calls                |
| `getCoreSystemPrompt()`                    | `packages/core/src/core/prompts.ts`        | Generate system instruction                          |

### Tool System

| Method                                   | Location                                       | Purpose                          |
| ---------------------------------------- | ---------------------------------------------- | -------------------------------- |
| `ToolRegistry.registerTool()`            | `packages/core/src/tools/tool-registry.ts:214` | Register tool definition         |
| `ToolRegistry.getFunctionDeclarations()` | `packages/core/src/tools/tool-registry.ts:475` | Get schemas for Gemini API       |
| `DeclarativeTool.build()`                | `packages/core/src/tools/tools.ts`             | Create validated tool invocation |
| `ToolInvocation.execute()`               | Various tool files                             | Execute tool with abort signal   |
| `PolicyEngine.getDecision()`             | `packages/core/src/policy/policy-engine.ts`    | Authorize tool execution         |

### Hook System

| Method                                   | Location                                      | Purpose                       |
| ---------------------------------------- | --------------------------------------------- | ----------------------------- |
| `HookSystem.fireSessionStartEvent()`     | `packages/core/src/hooks/hookSystem.ts`       | Fire session lifecycle hooks  |
| `HookEventHandler.fireBeforeToolEvent()` | `packages/core/src/hooks/hookEventHandler.ts` | Fire tool interception hooks  |
| `HookRunner.execute()`                   | `packages/core/src/hooks/hookRunner.ts`       | Run shell command hooks       |
| `HookAggregator.mergeOutputs()`          | `packages/core/src/hooks/hookAggregator.ts`   | Combine multiple hook results |

### Configuration

| Method                                   | Location                                           | Purpose                               |
| ---------------------------------------- | -------------------------------------------------- | ------------------------------------- |
| `Config.initialize()`                    | `packages/core/src/config/config.ts`               | Async initialization of services      |
| `loadCliConfig()`                        | `packages/cli/src/config/config.ts`                | Load and merge CLI configuration      |
| `Storage.getGlobalGeminiDir()`           | `packages/core/src/config/storage.ts`              | Get user config directory             |
| `ModelConfigService.getResolvedConfig()` | `packages/core/src/services/modelConfigService.ts` | Resolve model config with inheritance |

### Application Entry

| Method                 | Location                                | Purpose                   |
| ---------------------- | --------------------------------------- | ------------------------- |
| `main()`               | `packages/cli/src/gemini.tsx:285`       | Application bootstrap     |
| `startInteractiveUI()` | `packages/cli/src/gemini.tsx:172`       | Initialize React/Ink UI   |
| `runNonInteractive()`  | `packages/cli/src/nonInteractiveCli.ts` | Headless execution        |
| `initializeApp()`      | `packages/cli/src/core/initializer.ts`  | Pre-render initialization |

</key_methods>

## Build & Development

<build_development>

### Essential Commands

```bash
npm run preflight          # REQUIRED before submitting - builds, tests, lints, typechecks
npm run build              # Build main project (esbuild bundling)
npm run build:all          # Build + sandbox container + VSCode companion
npm start                  # Start CLI after building
npm run debug              # Run with --inspect-brk for debugging
```

### Testing

```bash
npm run test               # Unit tests via Vitest (packages/core and packages/cli)
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

### Development Tracing

```bash
GEMINI_DEV_TRACING=true npm start           # Enable tracing
npm run telemetry -- --target=genkit        # Start Genkit trace viewer
npm run telemetry -- --target=local         # Start Jaeger trace viewer
```

### Extension Points

1. **Add New Tool**: Create in `packages/core/src/tools/`, extend
   `BaseDeclarativeTool`, register in config
2. **Add Hook Event**: Add to `HookEventName` enum, create input/output types,
   add fire method
3. **Add Policy Rule**: Create TOML in `packages/core/src/policy/policies/`
4. **Add CLI Command**: Create in `packages/cli/src/commands/`, register in
   config
5. **Add MCP Server**: Configure in `settings.json` under `mcpServers`

### Build System

- **Bundler**: esbuild via `esbuild.config.js`
- **Output**: `bundle/gemini.js` (single file)
- **Package builds**: `scripts/build_package.js` for workspace packages
- **TypeScript**: Project references for incremental builds </build_development>

## Available Documentation

<available_documentation> | Document | Path | Coverage | Quality |
|----------|------|----------|---------| | Root CLAUDE.md | `/CLAUDE.md` |
Project overview, architecture, conventions | Comprehensive | | CLI Package
CLAUDE.md | `/packages/cli/CLAUDE.md` | UI patterns, React/Ink usage | Good | |
Core Package CLAUDE.md | `/packages/core/CLAUDE.md` | Backend structure, tool
patterns | Good | | Tools Module CLAUDE.md |
`/packages/core/src/tools/CLAUDE.md` | Tool implementation guide | Detailed | |
Hooks Module CLAUDE.md | `/packages/core/src/hooks/CLAUDE.md` | Hook system
architecture | Detailed | | Policy Module CLAUDE.md |
`/packages/core/src/policy/CLAUDE.md` | Security policy system | Detailed | |
Config Module CLAUDE.md | `/packages/core/src/config/CLAUDE.md` | Configuration
management | Good | | Services Module CLAUDE.md |
`/packages/core/src/services/CLAUDE.md` | Service layer patterns | Good | |
Agents Module CLAUDE.md | `/packages/core/src/agents/CLAUDE.md` | Agent system |
Good | | MCP Module CLAUDE.md | `/packages/core/src/mcp/CLAUDE.md` | MCP
integration | Good | | Utils Module CLAUDE.md |
`/packages/core/src/utils/CLAUDE.md` | Utility functions | Good |

### Documentation Gaps

- No standalone API documentation (JSDoc comments exist but not extracted)
- No architectural decision records (ADRs)
- Limited end-user documentation (focused on developer guidance)
- No sequence diagrams for complex flows </available_documentation>

## Key Terms Defined

<key_terms> **Turn**: A single request-response cycle in a conversation,
potentially including multiple tool calls. Managed by the `Turn` class at
`packages/core/src/core/turn.ts`.

**Hook**: An extensibility mechanism that intercepts workflow execution at
defined lifecycle events. Hooks execute external commands and can modify, block,
or supplement AI behavior.

**Tool**: A capability exposed to the Gemini model for interacting with the
development environment. Tools follow a two-phase pattern: validation
(`build()`) and execution (`execute()`).

**Policy**: A security rule that controls whether a tool can execute. Policies
use a priority-based system with three tiers: Admin > User > Default.

**MCP (Model Context Protocol)**: A protocol for integrating external tool
servers, enabling extensible capabilities beyond built-in tools.

**ContentGenerator**: An abstraction layer over the `@google/genai` SDK that
handles AI content generation, supporting both streaming and non-streaming
modes.

**MessageBus**: An event-driven communication system for tool confirmations,
policy updates, and cross-component messaging.

**Session**: A continuous interaction between user and AI, tracked by a unique
session ID with optional persistence via `ChatRecordingService`.

**Approval Mode**: The security posture for tool execution: `default` (ask user
for dangerous operations), `yolo` (allow all), or `read-only` (deny writes).

**Context Window**: The token limit for AI model input. The system includes
compression (`ChatCompressionService`) to manage long conversations.

**Sandbox**: Optional Docker/Podman container isolation for executing the CLI in
a restricted environment.

**Skill**: A named, user-invocable capability (slash command) that expands to a
prompt template. Managed by `SkillManager`.

**Agent**: An AI-powered automation that can execute multi-step tasks with tool
access. Defined in TOML format and executed by `AgentRegistry`. </key_terms>
