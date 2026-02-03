# Requests

<overview>
Gemini CLI is a terminal-based AI assistant built as a monorepo with React/Ink
frontend (`packages/cli`) and Node.js backend (`packages/core`). Requests flow
from user terminal input through the CLI package to the Core package, which
handles Gemini API integration and tool execution.
</overview>

## Entry Points Overview

<entry-points>

### Interactive Mode Entry

**File**: `packages/cli/src/gemini.tsx` - `main()` function (line 285)

The primary entry point for interactive terminal sessions:

```
main() → parseArguments() → loadSettings() → validateAuthMethod()
       → loadCliConfig() → initializeApp() → startInteractiveUI()
```

<startup-sequence>
1. **Argument parsing** - `parseArguments()` processes command-line flags
2. **Settings loading** - `loadSettings()` reads user/workspace/system config
3. **Auth validation** - `validateAuthMethod()` verifies credentials
4. **Config initialization** - `loadCliConfig()` creates `Config` object
5. **Sandbox check** - Launches sandbox environment if enabled
6. **Terminal setup** - Sets raw mode, enables alternate screen buffer
7. **App initialization** - `initializeApp()` sets up resources
8. **UI rendering** - `startInteractiveUI()` renders React/Ink UI
</startup-sequence>

### Non-Interactive Mode Entry

**File**: `packages/cli/src/nonInteractiveCli.ts` - `runNonInteractive()`
(line 57)

Used for piped input or `--prompt` flag:

```
runNonInteractive() → handleSlashCommand() or handleAtCommand()
                    → geminiClient.sendMessageStream()
                    → process events → write to stdout
```

### Config Class - Dependency Injection Container

**File**: `packages/core/src/config/config.ts`

Central object holding all application state:

- Tool registry
- Hook system
- Message bus
- Model configurations
- Content generator

Two-phase initialization:

1. Constructor (synchronous) - basic state setup
2. `initialize()` (async) - loads registries, starts MCP servers, initializes AI
   client

</entry-points>

## Request Routing Map

<routing>

### Input Type Routing

**File**: `packages/cli/src/ui/hooks/useGeminiStream.ts` (line 98+)

User input is classified and routed based on prefix:

| Input Pattern | Handler                            | Description            |
| ------------- | ---------------------------------- | ---------------------- |
| `/command`    | `slashCommandProcessor.ts`         | Slash commands         |
| `@file`       | `atCommandProcessor.ts`            | File references        |
| `~command`    | `shellCommandProcessor.ts`         | Direct shell execution |
| Regular text  | `geminiClient.sendMessageStream()` | AI conversation        |

### Slash Command Routing

**File**: `packages/cli/src/ui/hooks/slashCommandProcessor.ts`

Commands prefixed with `/` are routed to registered command handlers:

- `/help`, `/clear`, `/settings` - Built-in commands
- Custom skill commands - Via `activate_skill` tool

### Model Routing

**File**: `packages/core/src/routing/routingStrategy.ts`

Model selection strategy determines which model handles requests:

```typescript
routingContext = {
  history: chat.getHistory(),
  request: userMessage,
  signal: abortSignal,
  requestedModel: config.getModel()
}

router.route(routingContext) → { model: selectedModel }
```

</routing>

## Middleware Pipeline

<middleware>

### Hook System - 11 Lifecycle Events

**File**: `packages/core/src/hooks/hookSystem.ts`

Hooks intercept and modify request processing at defined points:

| Hook Event              | Timing                | Purpose                           |
| ----------------------- | --------------------- | --------------------------------- |
| `session-start`         | Session init          | Initialize session context        |
| `session-end`           | Session cleanup       | Cleanup and logging               |
| `before-agent`          | Before API call       | Add context, stop/block execution |
| `after-agent`           | After API response    | Process response, trigger effects |
| `before-model`          | Pre-API customization | Modify API request                |
| `after-model`           | Post-API processing   | Modify API response               |
| `before-tool-selection` | Tool filtering        | Filter available tools            |
| `before-tool-execution` | Intercept tool calls  | Validate/block tool execution     |
| `after-tool-execution`  | Process tool results  | Post-process tool output          |
| `thought-summary`       | Thinking output       | Custom thought processing         |
| `pre-compress`          | Before compression    | Context compression hooks         |

### Hook Execution Flow in GeminiClient

**File**: `packages/core/src/core/client.ts` (line 111-166)

```
sendMessageStream()
  │
  ├─→ fireBeforeAgentHookSafe(request, prompt_id)
  │     ├─→ hookOutput.shouldStopExecution() → yield AgentExecutionStopped
  │     ├─→ hookOutput.isBlockingDecision() → yield AgentExecutionBlocked
  │     └─→ hookOutput.getAdditionalContext() → append to request
  │
  ├─→ processTurn() → Turn.run()
  │
  └─→ fireAfterAgentHookSafe(request, prompt_id, turn)
        └─→ Post-response processing
```

### Policy Engine - Security Middleware

**File**: `packages/core/src/policy/policy-engine.ts`

Three-tier priority system controls tool execution:

| Tier    | Priority Range | Source                      |
| ------- | -------------- | --------------------------- |
| Admin   | 3.x            | System-wide policies        |
| User    | 2.x            | User preferences, CLI flags |
| Default | 1.x            | Built-in TOML policies      |

<policy-decisions>
- `ALLOW` - Execute without confirmation
- `ASK_USER` - Require user approval
- `DENY` - Block execution
</policy-decisions>

</middleware>

## Controller/Handler Analysis

<handlers>

### GeminiClient - Request Orchestrator

**File**: `packages/core/src/core/client.ts`

Central class orchestrating AI requests:

```typescript
class GeminiClient {
  // Main streaming method - yields ServerGeminiStreamEvent[]
  async *sendMessageStream(
    request: PartListUnion,
    signal: AbortSignal,
    prompt_id: string,
    turns: number = 100,
  ): AsyncGenerator<ServerGeminiStreamEvent, Turn>;
}
```

Key responsibilities:

- Hook execution (before/after agent)
- Turn management and loop detection
- Context compression
- Model routing

### Turn - Single Agentic Turn Manager

**File**: `packages/core/src/core/turn.ts`

Manages single turn within an agentic loop:

```typescript
class Turn {
  readonly pendingToolCalls: ToolCallRequestInfo[] = [];

  async *run(
    modelConfigKey,
    req,
    signal,
  ): AsyncGenerator<ServerGeminiStreamEvent>;
}
```

Processes Gemini API responses and yields events:

- `Content` - Text response chunks
- `Thought` - Extended thinking outputs
- `ToolCallRequest` - AI requests tool execution
- `Finished` - Response complete
- `Error` - Error occurred

### GeminiChat - API Layer

**File**: `packages/core/src/core/geminiChat.ts`

Manages chat session and API calls:

```typescript
async sendMessageStream(
  modelConfigKey: ModelConfigKey,
  message: PartListUnion,
  prompt_id: string,
  signal: AbortSignal
): AsyncGenerator<StreamEvent>
```

### Tool Registry

**File**: `packages/core/src/tools/tool-registry.ts`

Central registry managing all tools:

```typescript
class ToolRegistry {
  registerTool(tool: AnyDeclarativeTool): void;
  getTool(name: string): AnyDeclarativeTool | undefined;
  getFunctionDeclarations(): FunctionDeclaration[];
}
```

Built-in tools (14+):

- `read_file`, `write_file`, `edit_file` - File operations
- `shell` (run_shell_command) - Command execution
- `glob`, `grep`, `ripgrep`, `ls` - File search
- `web_fetch`, `web_search` - Web access
- `write_todos`, `memory` - Session management
- `activate_skill` - Skill invocation
- MCP tools - External tools via Model Context Protocol

### useGeminiStream - UI Hook

**File**: `packages/cli/src/ui/hooks/useGeminiStream.ts`

React hook consuming backend stream events:

```typescript
const useGeminiStream = (
  geminiClient: GeminiClient,
  history: HistoryItem[],
  addItem: AddItemFunction,
  config: Config,
  // ... other params
) => {
  // Processes ServerGeminiStreamEvent and updates UI state
};
```

Event handling:

- `Content` → Update message display
- `ToolCallRequest` → Schedule tool execution
- `ToolCallResponse` → Display tool result
- `Finished` → Mark response complete

</handlers>

## Authentication & Authorization Flow

<auth>

### Authentication Types

**File**: `packages/core/src/core/contentGenerator.ts`

```typescript
enum AuthType {
  LOGIN_WITH_GOOGLE    // OAuth2 - user account
  USE_GEMINI           // API key
  USE_VERTEX_AI        // Google Cloud Vertex AI
  COMPUTE_ADC          // Google Cloud ADC (service account)
}
```

### Auth Validation Flow

**File**: `packages/cli/src/gemini.tsx` (line 375-405)

```
main()
  │
  ├─→ validateAuthMethod() → Check auth type validity
  │
  ├─→ Interactive mode:
  │     └─→ config.refreshAuth(authType)
  │
  └─→ Non-interactive mode:
        └─→ validateNonInteractiveAuth() → config.refreshAuth()
```

### Credential Loading Priority

1. Environment variables: `GEMINI_API_KEY`, `GOOGLE_API_KEY`
2. Credential files in `~/.gemini/`
3. OAuth token storage: `MCPOAuthTokenStorage`
4. Service account credentials (Vertex AI)

### Tool Authorization

**File**: `packages/core/src/policy/policy-engine.ts` (line 276-437)

```typescript
async check(
  toolCall: FunctionCall,
  serverName: string | undefined
): Promise<{ decision: PolicyDecision; rule?: PolicyRule }>
```

Authorization flow:

1. Match tool call against policy rules (priority sorted)
2. For shell commands: recursively validate sub-commands
3. Run safety checkers if decision is not DENY
4. Apply non-interactive mode (ASK_USER → DENY)
5. Return final decision

### Hook Authorization

**File**: `packages/core/src/policy/policy-engine.ts` (line 490-562)

```typescript
async checkHook(request: HookExecutionRequest): Promise<PolicyDecision>
```

- Hooks globally disabled → DENY all
- Untrusted folders with project hooks → DENY
- Run hook-specific safety checkers
- Default: ALLOW

</auth>

## Error Handling Pathways

<errors>

### Error Classification

**File**: `packages/core/src/utils/errors.ts`

Three-tier error classification:

<error-tiers>
**Fatal Errors** - Exit immediately with specific codes:
- `FatalAuthenticationError` - Auth failed
- `FatalInputError` - Invalid input
- `FatalSandboxError` - Sandbox failure
- `FatalConfigError` - Configuration error

**Retryable Errors** - Exponential backoff with jitter:

- Network errors (ECONNREFUSED, timeout)
- HTTP 5xx (server errors)
- HTTP 429 (quota/rate limit)

**Recoverable Errors** - Log and allow model to self-correct:

- Tool execution failures
- File not found
- Validation errors </error-tiers>

### Tool Error Types

**File**: `packages/core/src/tools/tool-error.ts`

```typescript
enum ToolErrorType {
  // Fatal - exit immediately
  NO_SPACE_LEFT,
  SANDBOX_EXECUTION_ERROR,

  // Retryable - model may retry
  NETWORK_ERROR,
  TIMEOUT,
  TOOL_VALIDATION_ERROR,

  // Recoverable - model self-corrects
  DISCOVERED_TOOL_EXECUTION_ERROR,
  FILE_NOT_FOUND,
  STOP_EXECUTION,
}
```

### Retry Logic

**File**: `packages/core/src/utils/retry.ts`

```typescript
retryWithBackoff(apiCall, {
  onPersistent429: handleFallback,
  authType: config.getContentGeneratorConfig()?.authType,
  maxAttempts: availabilityMaxAttempts,
  getAvailabilityContext,
});
```

Retry behavior:

- Exponential backoff: 500ms → 1s → 2s → ...
- Max attempts: 2 initial + retries
- Yield `Retry` event to UI during retry
- Never retries on 400 Bad Request

### Stream Event Error Handling

**File**: `packages/core/src/core/turn.ts` (line 345-386)

```typescript
catch (e) {
  if (signal.aborted) {
    yield { type: GeminiEventType.UserCancelled };
    return;
  }

  if (e instanceof InvalidStreamError) {
    yield { type: GeminiEventType.InvalidStream };
    return;
  }

  // Report error and yield error event
  yield { type: GeminiEventType.Error, value: { error: structuredError } };
}
```

### Non-Interactive Error Handling

**File**: `packages/cli/src/nonInteractiveCli.ts` (line 489-501)

```typescript
} catch (error) {
  errorToHandle = error;
} finally {
  cleanupStdinCancellation();
  consolePatcher.cleanup();
}

if (errorToHandle) {
  handleError(errorToHandle, config);
}
```

</errors>

## Request Lifecycle Diagram

<lifecycle>

### Complete Request Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER INPUT (Terminal)                           │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    COMPOSER COMPONENT (Ink/React)                       │
│                                                                         │
│  • Captures keystrokes via KeypressContext                              │
│  • Manages text buffer via useTextBuffer()                              │
│  • Routes based on prefix (/, @, ~, or regular)                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
           ┌────────────┐  ┌────────────┐  ┌────────────┐
           │  / Slash   │  │  @ At      │  │  ~ Shell   │
           │  Command   │  │  Command   │  │  Command   │
           └────────────┘  └────────────┘  └────────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   useGeminiStream HOOK (CLI Package)                    │
│                                                                         │
│  • Prepares message as PartListUnion                                    │
│  • Calls geminiClient.sendMessageStream()                               │
│  • Consumes async generator of streaming events                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              GeminiClient.sendMessageStream() (Core Package)            │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ BEFORE-AGENT HOOK                                               │    │
│  │ • fireBeforeAgentHookSafe(request, prompt_id)                   │    │
│  │ • Can add context, stop execution, or block                     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ TURN PROCESSING                                                  │    │
│  │ • Check context window overflow                                  │    │
│  │ • Compress chat if needed                                        │    │
│  │ • Inject IDE context (if IDE mode)                               │    │
│  │ • Check loop detection                                           │    │
│  │ • Route to model (via ModelRouterService)                        │    │
│  │ • Apply availability policies                                    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Turn.run() → GeminiChat.sendMessageStream()                     │    │
│  │                                                                  │    │
│  │  • Before-model hook                                             │    │
│  │  • ContentGenerator.generateContentStream()                      │    │
│  │     └─→ @google/genai API call                                   │    │
│  │         └─→ Gemini API (Google servers)                          │    │
│  │  • Process streaming response                                    │    │
│  │  • After-model hook                                              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ AFTER-AGENT HOOK                                                │    │
│  │ • fireAfterAgentHookSafe(request, prompt_id, turn)              │    │
│  │ • Post-response processing                                       │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ (yields ServerGeminiStreamEvent[])
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      EVENT STREAM PROCESSING                            │
│                                                                         │
│  For each event:                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Content Event                                                   │    │
│  │ • addItem(GeminiMessage) → Update UI                            │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ ToolCallRequest Event                                           │    │
│  │ • scheduleToolCalls() via useReactToolScheduler                 │    │
│  │                                                                  │    │
│  │   ┌─────────────────────────────────────────────────────────┐   │    │
│  │   │ TOOL EXECUTION FLOW                                     │   │    │
│  │   │                                                         │   │    │
│  │   │ 1. Tool Validation (build phase)                        │   │    │
│  │   │    • Validate parameters against schema                 │   │    │
│  │   │                                                         │   │    │
│  │   │ 2. Policy Check (via MessageBus)                        │   │    │
│  │   │    • PolicyEngine.check(toolCall, serverName)           │   │    │
│  │   │    • Returns ALLOW, ASK_USER, or DENY                   │   │    │
│  │   │                                                         │   │    │
│  │   │ 3. User Confirmation (if ASK_USER)                      │   │    │
│  │   │    • Render confirmation dialog                         │   │    │
│  │   │    • Wait for user approval                             │   │    │
│  │   │                                                         │   │    │
│  │   │ 4. Execution (execute phase)                            │   │    │
│  │   │    • tool.execute(params, signal)                       │   │    │
│  │   │    • Stream output updates (if canUpdateOutput)         │   │    │
│  │   │                                                         │   │    │
│  │   │ 5. Return ToolResult                                    │   │    │
│  │   │    • llmContent: what AI sees                           │   │    │
│  │   │    • returnDisplay: what user sees                      │   │    │
│  │   │    • Optional error field                               │   │    │
│  │   └─────────────────────────────────────────────────────────┘   │    │
│  │                                                                  │    │
│  │ • yield ToolCallResponseEvent                                   │    │
│  │ • Tool response included in next API request                    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Finished Event                                                  │    │
│  │ • markResponding(false)                                         │    │
│  │ • Update StreamingState to Idle                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         UI STATE UPDATE                                 │
│                                                                         │
│  UIStateContext updated → Components re-render → Ink renders to TTY     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER SEES RESPONSE                              │
└─────────────────────────────────────────────────────────────────────────┘
```

### Stream Event Types

```typescript
type ServerGeminiStreamEvent =
  | ServerGeminiContentEvent // Text response chunk
  | ServerGeminiThoughtEvent // Extended thinking
  | ServerGeminiToolCallRequestEvent // Tool call request
  | ServerGeminiToolCallResponseEvent // Tool execution result
  | ServerGeminiToolCallConfirmationEvent // User confirmation needed
  | ServerGeminiFinishedEvent // Response complete
  | ServerGeminiErrorEvent // Error occurred
  | ServerGeminiRetryEvent // Retrying API call
  | ServerGeminiChatCompressedEvent // Context compressed
  | ServerGeminiLoopDetectedEvent // Loop detection triggered
  | ServerGeminiCitationEvent // Citation information
  | ServerGeminiMaxSessionTurnsEvent // Max turns exceeded
  | ServerGeminiContextWindowWillOverflowEvent // Context overflow warning
  | ServerGeminiInvalidStreamEvent // Invalid stream data
  | ServerGeminiModelInfoEvent // Model selection info
  | ServerGeminiAgentExecutionStoppedEvent // Hook stopped execution
  | ServerGeminiAgentExecutionBlockedEvent // Hook blocked execution
  | ServerGeminiUserCancelledEvent; // User cancelled
```

### Key Files by Concern

| Concern                | Key Files                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Startup**            | `gemini.tsx`, `initializer.ts`, `config/config.ts`                                     |
| **Auth**               | `config/auth.ts`, `core/contentGenerator.ts`, `mcp/oauth-provider.ts`                  |
| **Message Processing** | `core/client.ts`, `core/geminiChat.ts`, `core/turn.ts`                                 |
| **Tool Execution**     | `tools/tool-registry.ts`, `scheduler/tool-executor.ts`                                 |
| **Hook System**        | `hooks/hookSystem.ts`, `hooks/hookRegistry.ts`, `hooks/hookEventHandler.ts`            |
| **Policy Engine**      | `policy/policy-engine.ts`, `policy/config.ts`, `policy/toml-loader.ts`                 |
| **UI Integration**     | `ui/AppContainer.tsx`, `ui/hooks/useGeminiStream.ts`, `ui/contexts/UIStateContext.tsx` |
| **Streaming**          | `core/geminiChat.ts`, `core/turn.ts`, `ui/hooks/useGeminiStream.ts`                    |
| **Error Handling**     | `utils/retry.ts`, `utils/errors.ts`, `tools/tool-error.ts`                             |

</lifecycle>
