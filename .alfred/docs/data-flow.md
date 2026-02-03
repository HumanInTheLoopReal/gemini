# Data Flow

<overview>
Gemini CLI implements a layered data flow architecture where user input travels through the CLI package (React/Ink UI) to the Core package (backend orchestration), then to the Gemini API, and back through tool execution and response rendering. Data is transformed at each layer boundary using typed interfaces and discriminated unions.
</overview>

## Data Models Overview

<data-models>

### Core Data Flow Types

The application uses three primary categories of data models:

<category name="streaming-events">
**Streaming Event Types** - `packages/core/src/core/turn.ts`

```typescript
enum GeminiEventType {
  Content = 'content',
  ToolCallRequest = 'tool_call_request',
  ToolCallResponse = 'tool_call_response',
  ToolCallConfirmation = 'tool_call_confirmation',
  UserCancelled = 'user_cancelled',
  Error = 'error',
  ChatCompressed = 'chat_compressed',
  Thought = 'thought',
  MaxSessionTurns = 'max_session_turns',
  Finished = 'finished',
  LoopDetected = 'loop_detected',
  Citation = 'citation',
  Retry = 'retry',
  ContextWindowWillOverflow = 'context_window_will_overflow',
  InvalidStream = 'invalid_stream',
  ModelInfo = 'model_info',
  AgentExecutionStopped = 'agent_execution_stopped',
  AgentExecutionBlocked = 'agent_execution_blocked',
}
```

The `ServerGeminiStreamEvent` is a discriminated union of 17 event types that
flow from the Gemini API through the core layer to the UI. </category>

<category name="tool-call-lifecycle">
**Tool Call Lifecycle Types** - `packages/core/src/scheduler/types.ts`

Tool calls progress through a state machine with these states:

| Type                 | Status              | Description                   |
| -------------------- | ------------------- | ----------------------------- |
| `ValidatingToolCall` | `validating`        | Parameters being validated    |
| `ScheduledToolCall`  | `scheduled`         | Queued for execution          |
| `WaitingToolCall`    | `awaiting_approval` | Waiting for user confirmation |
| `ExecutingToolCall`  | `executing`         | Currently running             |
| `SuccessfulToolCall` | `success`           | Completed successfully        |
| `ErroredToolCall`    | `error`             | Failed with error             |
| `CancelledToolCall`  | `cancelled`         | User cancelled                |

Key interfaces:

- `ToolCallRequestInfo`: Contains `callId`, `name`, `args`, `isClientInitiated`,
  `prompt_id`
- `ToolCallResponseInfo`: Contains `callId`, `responseParts`, `resultDisplay`,
  `error`, `errorType`
- `CompletedToolCall`: Union of
  `SuccessfulToolCall | CancelledToolCall | ErroredToolCall` </category>

<category name="ui-history-items">
**UI History Item Types** - `packages/cli/src/ui/types.ts`

The UI uses a discriminated union `HistoryItem` to represent all displayable
message types:

| Type                     | Purpose          | Key Fields                           |
| ------------------------ | ---------------- | ------------------------------------ |
| `HistoryItemUser`        | User input       | `text`                               |
| `HistoryItemGemini`      | AI response      | `text`                               |
| `HistoryItemToolGroup`   | Tool executions  | `tools: IndividualToolCallDisplay[]` |
| `HistoryItemInfo`        | System info      | `text`, `icon`, `color`              |
| `HistoryItemError`       | Errors           | `text`                               |
| `HistoryItemWarning`     | Warnings         | `text`                               |
| `HistoryItemCompression` | Chat compression | `compression: CompressionProps`      |
| `HistoryItemStats`       | Session stats    | `duration`, `quotas`                 |

Each item has a unique `id: number` for React reconciliation. </category>

<category name="tool-types">
**Tool System Types** - `packages/core/src/tools/tools.ts`

```typescript
interface ToolResult {
  llmContent: PartListUnion; // Content for LLM history
  returnDisplay: ToolResultDisplay; // User-facing display
  error?: {
    message: string;
    type?: ToolErrorType;
  };
}

type ToolResultDisplay = string | FileDiff | AnsiOutput | TodoList;

enum Kind {
  Read = 'read',
  Edit = 'edit',
  Delete = 'delete',
  Move = 'move',
  Search = 'search',
  Execute = 'execute',
  Think = 'think',
  Fetch = 'fetch',
  Other = 'other',
}
```

</category>

<category name="gemini-api-types">
**Gemini API Types** - `@google/genai`

Key types from the Gemini SDK:

- `Content`: Message content with `role` ('user' | 'model') and `parts`
- `Part`: Union type for text, function calls, function responses, inline data
- `FunctionCall`: Tool invocation request with `name` and `args`
- `FunctionDeclaration`: Tool schema for registration
- `GenerateContentResponse`: Streaming response with candidates, usage metadata
- `FinishReason`: Why generation stopped (STOP, TOOL_CALLS, etc.) </category>

<category name="confirmation-types">
**Confirmation Bus Types** - `packages/core/src/confirmation-bus/types.ts`

```typescript
enum MessageBusType {
  TOOL_CONFIRMATION_REQUEST = 'tool-confirmation-request',
  TOOL_CONFIRMATION_RESPONSE = 'tool-confirmation-response',
  TOOL_POLICY_REJECTION = 'tool-policy-rejection',
  TOOL_EXECUTION_SUCCESS = 'tool-execution-success',
  TOOL_EXECUTION_FAILURE = 'tool-execution-failure',
  UPDATE_POLICY = 'update-policy',
  HOOK_EXECUTION_REQUEST = 'hook-execution-request',
  HOOK_EXECUTION_RESPONSE = 'hook-execution-response',
  HOOK_POLICY_DECISION = 'hook-policy-decision',
  TOOL_CALLS_UPDATE = 'tool-calls-update'
}

type SerializableConfirmationDetails =
  | { type: 'info'; title: string; prompt: string; urls?: string[] }
  | { type: 'edit'; title: string; fileName: string; filePath: string; fileDiff: string; ... }
  | { type: 'exec'; title: string; command: string; rootCommand: string; ... }
  | { type: 'mcp'; title: string; serverName: string; toolName: string; ... };
```

</category>

<category name="hook-types">
**Hook System Types** - `packages/core/src/hooks/types.ts`

```typescript
enum HookEventName {
  BeforeTool = 'BeforeTool',
  AfterTool = 'AfterTool',
  BeforeAgent = 'BeforeAgent',
  Notification = 'Notification',
  AfterAgent = 'AfterAgent',
  SessionStart = 'SessionStart',
  SessionEnd = 'SessionEnd',
  PreCompress = 'PreCompress',
  BeforeModel = 'BeforeModel',
  AfterModel = 'AfterModel',
  BeforeToolSelection = 'BeforeToolSelection',
}

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
```

</category>

<category name="recording-types">
**Chat Recording Types** - `packages/core/src/services/chatRecordingService.ts`

```typescript
interface ConversationRecord {
  sessionId: string;
  projectHash: string;
  startTime: string;
  lastUpdated: string;
  messages: MessageRecord[];
  summary?: string;
}

interface MessageRecord {
  id: string;
  timestamp: string;
  content: PartListUnion;
  type: 'user' | 'gemini' | 'info' | 'error' | 'warning';
  toolCalls?: ToolCallRecord[]; // For gemini type
  thoughts?: ThoughtSummary[]; // For gemini type
  tokens?: TokensSummary; // For gemini type
  model?: string; // For gemini type
}

interface TokensSummary {
  input: number; // promptTokenCount
  output: number; // candidatesTokenCount
  cached: number; // cachedContentTokenCount
  thoughts?: number;
  tool?: number;
  total: number;
}
```

</category>

</data-models>

## Data Transformation Map

<transformations>

### Layer 1: User Input → Content

<transformation name="input-normalization">
**Location**: `packages/cli/src/services/prompt-processors/`

User input undergoes several processing stages:

1. **Shell Command Processing** (`shellProcessor.ts`)
   - Input: `~command args` or `! command`
   - Output: Shell execution result injected as context

2. **At-File Processing** (`atFileProcessor.ts`)
   - Input: `@filepath` references in prompt
   - Output: File contents injected into prompt parts

3. **Argument Processing** (`argumentProcessor.ts`)
   - Input: Command-line arguments (`--prompt`, `--file`)
   - Output: Additional content parts

4. **Content Assembly**
   - Input: Processed prompt string
   - Output: `Content[]` array for Gemini API
   - Transform: `createUserContent(message)` from `@google/genai`
     </transformation>

### Layer 2: Content → API Request

<transformation name="api-request-building">
**Location**: `packages/core/src/core/geminiChat.ts`

```
Content[] + SystemInstruction + Tool[] → GenerateContentParameters
```

Key transformations:

- `ensureActiveLoopHasThoughtSignatures()`: Adds thought signatures for preview
  models
- `resolveModel()`: Resolves model aliases ('auto', 'pro', 'flash') to concrete
  names
- Tool conversion: `DeclarativeTool[]` → `FunctionDeclaration[]`
  </transformation>

### Layer 3: API Response → Stream Events

<transformation name="response-parsing">
**Location**: `packages/core/src/core/turn.ts`

```
GenerateContentResponse → ServerGeminiStreamEvent
```

The `Turn.run()` async generator transforms each chunk:

| Response Content                    | Event Type        | Transformation               |
| ----------------------------------- | ----------------- | ---------------------------- |
| `candidate.content.parts[].text`    | `Content`         | Extract text, skip thoughts  |
| `candidate.content.parts[].thought` | `Thought`         | Parse via `parseThought()`   |
| `functionCalls[]`                   | `ToolCallRequest` | Create `ToolCallRequestInfo` |
| `finishReason`                      | `Finished`        | Include `usageMetadata`      |
| `citations`                         | `Citation`        | Aggregate and emit           |

</transformation>

### Layer 4: Tool Execution Pipeline

<transformation name="tool-execution">
**Location**: `packages/core/src/core/coreToolScheduler.ts`

```
ToolCallRequestInfo → ToolInvocation → ToolResult → ToolCallResponseInfo
```

State transitions:

```
validating → scheduled → awaiting_approval → executing → success/error/cancelled
```

Key transformations:

1. **Build Phase**: `tool.build(params)` validates and creates `ToolInvocation`
2. **Confirmation Phase**: `invocation.shouldConfirmExecute()` →
   `ToolCallConfirmationDetails`
3. **Execute Phase**: `invocation.execute(signal)` → `ToolResult`
4. **Response Phase**: Convert to `FunctionResponse` parts for next turn
   </transformation>

### Layer 5: Events → UI History

<transformation name="event-to-history">
**Location**: `packages/cli/src/ui/hooks/useGeminiStream.ts`

```
ServerGeminiStreamEvent → HistoryItem
```

| Event Type         | History Item Type                       |
| ------------------ | --------------------------------------- |
| `Content`          | `HistoryItemGemini` (accumulated)       |
| `ToolCallRequest`  | `HistoryItemToolGroup` (batched)        |
| `ToolCallResponse` | Updates existing `HistoryItemToolGroup` |
| `Error`            | `HistoryItemError`                      |
| `ChatCompressed`   | `HistoryItemCompression`                |
| `Thought`          | Updates UI thought state                |

</transformation>

### Cross-Layer Type Mappings

<type-mappings>
```
┌─────────────────────────────────────────────────────────────────┐
│                     TYPE TRANSFORMATION FLOW                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User Input (string)                                            │
│       ↓ createUserContent()                                     │
│  Content { role: 'user', parts: Part[] }                        │
│       ↓ sendMessageStream()                                     │
│  GenerateContentParameters { model, contents, config, tools }   │
│       ↓ Gemini API                                              │
│  AsyncGenerator<GenerateContentResponse>                        │
│       ↓ Turn.run()                                              │
│  AsyncGenerator<ServerGeminiStreamEvent>                        │
│       ↓ useGeminiStream hook                                    │
│  HistoryItem[] (React state)                                    │
│       ↓ React render                                            │
│  Terminal Output (Ink components)                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
</type-mappings>

</transformations>

## Storage Interactions

<storage>

### File System Storage Locations

<storage-paths>
**Location**: `packages/core/src/config/storage.ts`

| Path                              | Purpose                 | Access Pattern                   |
| --------------------------------- | ----------------------- | -------------------------------- |
| `~/.gemini/`                      | Global Gemini directory | Read/Write on startup            |
| `~/.gemini/settings.json`         | User settings           | Read on startup, write on change |
| `~/.gemini/memory.md`             | Global memory context   | Read per session                 |
| `~/.gemini/history/<hash>/`       | Per-project history     | Append on chat completion        |
| `~/.gemini/tmp/<hash>/chats/`     | Session recordings      | Continuous append                |
| `~/.gemini/commands/`             | User slash commands     | Read on startup                  |
| `~/.gemini/skills/`               | User skills             | Read on startup                  |
| `~/.gemini/agents/`               | User agent definitions  | Read on startup                  |
| `~/.gemini/policies/`             | User security policies  | Read on startup                  |
| `~/.gemini/oauth_creds.json`      | OAuth credentials       | Read/Write on auth               |
| `~/.gemini/google_accounts.json`  | Google account info     | Read/Write on auth               |
| `~/.gemini/mcp-oauth-tokens.json` | MCP OAuth tokens        | Read/Write per MCP auth          |
| `.gemini/`                        | Project-level config    | Read on session start            |
| `.gemini/settings.json`           | Project settings        | Read on startup                  |
| `.gemini/extensions/`             | Project extensions      | Read on startup                  |

</storage-paths>

### Chat Recording Storage

<chat-recording>
**Location**: `packages/core/src/services/chatRecordingService.ts`

Sessions are stored as JSON files in `~/.gemini/tmp/<project_hash>/chats/`:

```
session-2025-01-22T10-30-abc12345.json
```

File structure:

```json
{
  "sessionId": "uuid",
  "projectHash": "sha256-hash",
  "startTime": "ISO-8601",
  "lastUpdated": "ISO-8601",
  "messages": [
    {
      "id": "uuid",
      "timestamp": "ISO-8601",
      "type": "user",
      "content": "user message"
    },
    {
      "id": "uuid",
      "timestamp": "ISO-8601",
      "type": "gemini",
      "content": "response text",
      "toolCalls": [...],
      "thoughts": [...],
      "tokens": { "input": 100, "output": 50, "total": 150 },
      "model": "gemini-2.0-flash"
    }
  ],
  "summary": "One-line session summary"
}
```

Write patterns:

- `recordMessage()`: Appends user/assistant messages
- `recordThought()`: Queues thoughts for next gemini message
- `recordMessageTokens()`: Updates token counts
- `recordToolCalls()`: Enriches tool calls with registry metadata
- `saveSummary()`: Adds AI-generated summary </chat-recording>

### Configuration Hierarchy

<config-hierarchy>
**Precedence** (lowest to highest):

1. **Default Values**: Built into code
2. **System Settings**: `/Library/Application Support/GeminiCli/settings.json`
   (macOS)
3. **User Settings**: `~/.gemini/settings.json`
4. **Project Settings**: `.gemini/settings.json`
5. **Environment Variables**: `.env` files + system env
6. **Command-line Arguments**: `--model`, `--prompt`, etc.

Settings are merged at startup via the Config class, with higher precedence
overriding lower. </config-hierarchy>

### Memory Context Storage

<memory-storage>
Memory files provide persistent context across sessions:

| File                  | Scope        | Purpose                       |
| --------------------- | ------------ | ----------------------------- |
| `~/.gemini/memory.md` | Global       | User preferences, workflows   |
| `.gemini/GEMINI.md`   | Project      | Project-specific instructions |
| `GEMINI.md`           | Project root | Public project documentation  |

Memory discovery (`packages/core/src/utils/memoryDiscovery.ts`) crawls workspace
for `GEMINI.md` files and injects them as system context. </memory-storage>

</storage>

## Validation Mechanisms

<validation>

### Schema Validation

<schema-validation>
**Location**: `packages/core/src/utils/schemaValidator.ts`

Tool parameters are validated using JSON Schema via AJV (Another JSON Schema
Validator):

```typescript
class SchemaValidator {
  static validate(schema: unknown, data: unknown): string | null {
    // Returns null if valid, error message string if invalid
    const validate = ajValidator.compile(schema);
    const valid = validate(data);
    if (!valid && validate.errors) {
      return ajValidator.errorsText(validate.errors, { dataVar: 'params' });
    }
    return null;
  }
}
```

Used by `BaseDeclarativeTool.validateToolParams()` before tool execution.
</schema-validation>

### Tool Parameter Validation

<tool-validation>
**Location**: `packages/core/src/tools/tools.ts`

Two-phase validation in `BaseDeclarativeTool`:

1. **Schema Validation**: JSON Schema check via `SchemaValidator.validate()`
2. **Value Validation**: Custom `validateToolParamValues()` override for
   semantic checks

```typescript
validateToolParams(params: TParams): string | null {
  // Phase 1: Schema validation
  const errors = SchemaValidator.validate(this.schema.parametersJsonSchema, params);
  if (errors) return errors;

  // Phase 2: Custom value validation
  return this.validateToolParamValues(params);
}
```

</tool-validation>

### History Validation

<history-validation>
**Location**: `packages/core/src/core/geminiChat.ts`

Chat history is validated before API calls:

```typescript
function validateHistory(history: Content[]) {
  for (const content of history) {
    if (content.role !== 'user' && content.role !== 'model') {
      throw new Error(`Role must be user or model, but got ${content.role}.`);
    }
  }
}
```

Curated history extraction removes invalid model responses:

```typescript
function extractCuratedHistory(comprehensiveHistory: Content[]): Content[] {
  // Filters out invalid/empty model outputs
  // Ensures subsequent requests are accepted by the model
}
```

</history-validation>

### Response Validation

<response-validation>
**Location**: `packages/core/src/core/geminiChat.ts`

Stream responses are validated for completeness:

```typescript
function isValidResponse(response: GenerateContentResponse): boolean {
  if (response.candidates === undefined || response.candidates.length === 0) {
    return false;
  }
  const content = response.candidates[0]?.content;
  return content !== undefined && isValidContent(content);
}

function isValidContent(content: Content): boolean {
  if (content.parts === undefined || content.parts.length === 0) {
    return false;
  }
  for (const part of content.parts) {
    if (part === undefined || Object.keys(part).length === 0) {
      return false;
    }
    if (!part.thought && part.text !== undefined && part.text === '') {
      return false;
    }
  }
  return true;
}
```

Invalid streams trigger `InvalidStreamError` with retry logic for Gemini 2
models. </response-validation>

### Policy Validation

<policy-validation>
**Location**: `packages/core/src/policy/`

Tool execution is gated by policy engine:

```typescript
type PolicyDecision = 'ALLOW' | 'DENY' | 'ASK_USER';
```

Policy checks occur in `BaseToolInvocation.getMessageBusDecision()`:

- `ALLOW`: Execute without confirmation
- `DENY`: Throw error, block execution
- `ASK_USER`: Show confirmation dialog, await user response </policy-validation>

</validation>

## State Management Analysis

<state-management>

### React Context Architecture

<context-hierarchy>
**Location**: `packages/cli/src/ui/contexts/`

The UI maintains state through a layered context provider hierarchy:

```
AppContainer
├── UIStateContext          // Core UI state (history, dialogs, streaming)
├── UIActionsContext        // Dispatch methods for state mutations
├── ConfigContext           // Configuration values from Core
├── SettingsContext         // User settings (theme, editor, vim mode)
├── StreamingContext        // AI streaming state
├── KeypressContext         // Keyboard input handling
├── VimModeContext          // Vim mode state (NORMAL/INSERT)
├── SessionContext          // Session stats (duration, tokens, quotas)
├── ScrollProvider          // Scroll state management
├── MouseContext            // Mouse event handling
├── ShellFocusContext       // Shell input focus tracking
└── OverflowContext         // Overflow element tracking
```

</context-hierarchy>

### UIState Structure

<ui-state>
**Location**: `packages/cli/src/ui/contexts/UIStateContext.tsx`

Key state fields (~100 fields total):

| Category      | Fields                                                       | Purpose           |
| ------------- | ------------------------------------------------------------ | ----------------- |
| History       | `history`, `pendingHistoryItems`, `historyManager`           | Message display   |
| Streaming     | `streamingState`, `thought`, `activeHooks`                   | AI response state |
| Dialogs       | `isAuthDialogOpen`, `isSettingsDialogOpen`, etc.             | Modal state       |
| Input         | `buffer`, `inputWidth`, `shellModeActive`                    | User input        |
| Session       | `sessionStats`, `elapsedTime`, `currentModel`                | Session tracking  |
| Configuration | `slashCommands`, `commandContext`, `renderMarkdown`          | Runtime config    |
| UI Layout     | `terminalWidth`, `terminalHeight`, `availableTerminalHeight` | Layout dimensions |

</ui-state>

### Streaming State Machine

<streaming-state>
**Location**: `packages/cli/src/ui/types.ts`

```typescript
enum StreamingState {
  Idle = 'idle',
  Responding = 'responding',
  WaitingForConfirmation = 'waiting_for_confirmation',
}
```

State transitions:

```
Idle → (user submits) → Responding → (tool needs approval) → WaitingForConfirmation
                     ↓                                      ↓
                     → (stream ends) → Idle ← (user responds) ←
```

</streaming-state>

### Tool Call State Management

<tool-state>
**Location**: `packages/core/src/core/coreToolScheduler.ts`

The `CoreToolScheduler` maintains tool call state:

```typescript
private toolCalls: ToolCall[] = [];              // Current batch
private toolCallQueue: ToolCall[] = [];          // Pending queue
private completedToolCallsForBatch: CompletedToolCall[] = [];
private isScheduling = false;                     // Lock flag
private isCancelling = false;                     // Cancellation flag
```

State is broadcast via callbacks:

- `onToolCallsUpdate`: Called when any tool state changes
- `onAllToolCallsComplete`: Called when batch finishes
- `outputUpdateHandler`: Called for streaming tool output </tool-state>

### Event-Driven Communication

<event-bus>
**Location**: `packages/core/src/confirmation-bus/message-bus.ts`

The `MessageBus` provides pub/sub communication:

```typescript
interface MessageBus {
  publish(message: Message): Promise<void>;
  subscribe<T extends MessageBusType>(type: T, handler: Handler<T>): void;
  unsubscribe<T extends MessageBusType>(type: T, handler: Handler<T>): void;
}
```

Used for:

- Tool confirmation requests/responses
- Policy updates
- Hook execution coordination
- Tool call state broadcasts </event-bus>

</state-management>

## Serialization Processes

<serialization>

### JSON Serialization

<json-serialization>
**Chat Recording**: Sessions are serialized to JSON with `JSON.stringify(conversation, null, 2)` for human-readable output.

**Settings**: User/project settings stored as JSON files, parsed on load.

**Tool Results**: `ToolResult.llmContent` must be JSON-serializable
`PartListUnion`. </json-serialization>

### Content Serialization for API

<api-serialization>
**Location**: `packages/core/src/code_assist/converter.ts`

Content is serialized for the Gemini API using `@google/genai` types:

```typescript
function toParts(message: PartListUnion): Part[] {
  // Converts various input formats to Gemini Part[]
  // Handles: strings, Part objects, file data, inline data
}
```

Function responses are serialized as:

```typescript
{
  functionResponse: {
    id: callId,
    name: toolName,
    response: { result: "..." } | { error: "..." }
  }
}
```

</api-serialization>

### Hook Input/Output Serialization

<hook-serialization>
**Location**: `packages/core/src/hooks/hookRunner.ts`

Hooks receive JSON on stdin and output JSON on stdout:

```typescript
// Input to hook process
const hookInput: HookInput = {
  session_id: string,
  transcript_path: string,
  cwd: string,
  hook_event_name: string,
  timestamp: string,
  // Event-specific fields...
};
// Serialized: JSON.stringify(hookInput)

// Output from hook process
// Parsed: JSON.parse(stdout) as HookOutput
```

</hook-serialization>

### SDK Type Translation

<sdk-translation>
**Location**: `packages/core/src/hooks/hookTranslator.ts`

Hooks use stable types decoupled from the Gemini SDK:

```typescript
interface LLMRequest {
  model: string;
  contents: LLMContent[];
  systemInstruction?: string;
  tools?: LLMTool[];
  toolConfig?: HookToolConfig;
}

interface LLMResponse {
  candidates?: Array<{
    content?: LLMContent;
    finishReason?: string;
  }>;
  usageMetadata?: { ... };
}
```

Translation functions:

- `toHookLLMRequest()`: SDK → Hook format
- `fromHookLLMRequest()`: Hook → SDK format
- `toHookLLMResponse()`: SDK → Hook format
- `fromHookLLMResponse()`: Hook → SDK format </sdk-translation>

### Deep Copy for Immutability

<deep-copy>
**Location**: `packages/core/src/core/geminiChat.ts`

History is deep-copied to prevent external mutation:

```typescript
getHistory(curated: boolean = false): Content[] {
  const history = curated ? extractCuratedHistory(this.history) : this.history;
  return structuredClone(history);  // Deep copy
}
```

</deep-copy>

</serialization>

## Data Lifecycle Diagrams

<diagrams>

### Complete Request-Response Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GEMINI CLI DATA LIFECYCLE                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│  USER INPUT     │ "Fix the bug in auth.ts"
│  (Terminal)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PROMPT          │ @ file references resolved
│ PROCESSING      │ ~ shell commands executed
│ (CLI Package)   │ Arguments merged
└────────┬────────┘
         │ createUserContent()
         ▼
┌─────────────────┐
│ CONTENT[]       │ [{ role: 'user', parts: [{ text: '...' }] }]
│ (Core Package)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ BEFORE HOOKS    │ BeforeAgent → BeforeModel → BeforeToolSelection
│ (Hook System)   │ May modify request or block execution
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GEMINI CHAT     │ sendMessageStream()
│ (geminiChat.ts) │ History + SystemInstruction + Tools
└────────┬────────┘
         │ HTTP/2 Streaming
         ▼
┌─────────────────┐
│ GEMINI API      │ GenerateContentResponse chunks
│ (@google/genai) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ TURN PROCESSOR  │ Turn.run() async generator
│ (turn.ts)       │ Parses chunks → ServerGeminiStreamEvent
└────────┬────────┘
         │
         ├──────────────────────────────────────┐
         │ GeminiEventType.Content              │ GeminiEventType.ToolCallRequest
         ▼                                      ▼
┌─────────────────┐                    ┌─────────────────┐
│ CONTENT EVENT   │                    │ TOOL SCHEDULER  │
│ Text streaming  │                    │ (coreToolScheduler.ts)
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │                             ┌────────┴────────┐
         │                             │ TOOL LIFECYCLE  │
         │                             │ validating      │
         │                             │    ↓            │
         │                             │ scheduled       │
         │                             │    ↓            │
         │                             │ awaiting_approval (if needed)
         │                             │    ↓            │
         │                             │ executing       │
         │                             │    ↓            │
         │                             │ success/error   │
         │                             └────────┬────────┘
         │                                      │
         │                                      ▼
         │                             ┌─────────────────┐
         │                             │ TOOL RESULT     │
         │                             │ { llmContent,   │
         │                             │   returnDisplay }│
         │                             └────────┬────────┘
         │                                      │
         │                                      ▼
         │                             ┌─────────────────┐
         │                             │ FUNCTION        │
         │                             │ RESPONSE        │
         │                             │ → Next Turn     │
         │                             └────────┬────────┘
         │                                      │
         │◄─────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ AFTER HOOKS     │ AfterModel → AfterTool → AfterAgent
│ (Hook System)   │ May modify response
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ UI STATE        │ useGeminiStream hook
│ UPDATE          │ Events → HistoryItem[]
│ (CLI Package)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ REACT RENDER    │ Ink components
│ (Terminal)      │ Markdown, code blocks, tool output
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ CHAT RECORDING  │ Session JSON file
│ (Persistence)   │ ~/.gemini/tmp/<hash>/chats/
└─────────────────┘
```

### Tool Confirmation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOOL CONFIRMATION FLOW                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ TOOL INVOCATION │ tool.build(params)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ POLICY CHECK    │ getMessageBusDecision()
│ (MessageBus)    │
└────────┬────────┘
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
┌───────┐ ┌───────┐ ┌─────────────┐
│ ALLOW │ │ DENY  │ │ ASK_USER    │
└───┬───┘ └───┬───┘ └──────┬──────┘
    │         │            │
    │         │            ▼
    │         │    ┌─────────────────┐
    │         │    │ CONFIRMATION    │
    │         │    │ DETAILS         │
    │         │    │ (UI Dialog)     │
    │         │    └────────┬────────┘
    │         │             │
    │         │    ┌────────┴────────┐
    │         │    ▼                 ▼
    │         │ ┌──────┐      ┌───────────┐
    │         │ │ User │      │ User      │
    │         │ │ Approves    │ Cancels   │
    │         │ └───┬──┘      └─────┬─────┘
    │         │     │               │
    │         │     ▼               ▼
    │         │ ┌──────────┐  ┌───────────┐
    │         │ │ EXECUTE  │  │ CANCEL    │
    │         │ └────┬─────┘  └─────┬─────┘
    │         │      │              │
    ▼         ▼      ▼              ▼
┌─────────────────────────────────────────┐
│              TOOL RESULT                 │
│  SuccessfulToolCall | CancelledToolCall │
│           | ErroredToolCall             │
└─────────────────────────────────────────┘
```

### Message Bus Communication

```
┌─────────────────────────────────────────────────────────────────┐
│                    MESSAGE BUS ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   MESSAGE BUS   │
                    │   (Pub/Sub)     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ TOOL            │ │ POLICY          │ │ HOOK            │
│ CONFIRMATION    │ │ UPDATES         │ │ EXECUTION       │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ REQUEST         │ │ UPDATE_POLICY   │ │ HOOK_EXECUTION  │
│ ↓               │ │ (persist rule)  │ │ _REQUEST        │
│ RESPONSE        │ │                 │ │ ↓               │
│ (confirmed,     │ │                 │ │ HOOK_EXECUTION  │
│  outcome)       │ │                 │ │ _RESPONSE       │
└─────────────────┘ └─────────────────┘ └─────────────────┘

Publishers:
- CoreToolScheduler (confirmation requests)
- BaseToolInvocation (policy updates)
- HookEventHandler (hook requests)

Subscribers:
- UI (confirmation dialogs)
- PolicyEngine (rule updates)
- HookRunner (execution)
```

### Context Window Management

```
┌─────────────────────────────────────────────────────────────────┐
│                 CONTEXT WINDOW MANAGEMENT                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CONTEXT WINDOW (~1M tokens)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ SYSTEM INSTRUCTION                                        │   │
│  │ - Base system prompt                                      │   │
│  │ - Memory context (GEMINI.md files)                        │   │
│  │ - Active tools descriptions                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ CONVERSATION HISTORY                                      │   │
│  │ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐   │   │
│  │ │ User 1 │→│Model 1 │→│ User 2 │→│Model 2 │→│ User N │   │   │
│  │ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘   │   │
│  │                                                           │   │
│  │ When approaching limit:                                   │   │
│  │ ┌─────────────────────────────────────────────────────┐  │   │
│  │ │ COMPRESSION (ChatCompressionService)                │  │   │
│  │ │ - Summarize older messages                          │  │   │
│  │ │ - PreCompress hook notification                     │  │   │
│  │ │ - Emit ChatCompressed event                         │  │   │
│  │ └─────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ CURRENT REQUEST                                           │   │
│  │ - User message                                            │   │
│  │ - Injected file contents (@file)                          │   │
│  │ - Shell output (~command)                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Token accounting:
- estimateTokenCountSync() for pre-flight checks
- usageMetadata in response for actual counts
- ContextWindowWillOverflow event when approaching limit
```

</diagrams>
