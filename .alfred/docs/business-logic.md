# Business Logic

## What is Gemini CLI?

Gemini CLI is an open-source terminal-based AI assistant that brings the power
of Google's Gemini models directly to developers' command lines. It solves the
problem of context-switching between development environments and AI tools by
embedding intelligent assistance directly where developers work—the terminal.

The service provides value by enabling developers to query codebases, generate
code, automate operational tasks, and execute complex multi-step workflows while
maintaining full control through an approval-based security model for file
modifications and shell commands.

## Core Concepts

### The Agentic Loop

The fundamental execution pattern where the AI model and tools collaborate
iteratively to complete tasks. The model receives a prompt, may request tool
executions to gather information or take actions, receives tool results, and
continues until the task is complete or reaches a stopping condition.

- **Turn**: A single round-trip of model request → tool execution → response
  within the agentic loop
- **Chat Session**: The complete conversation history maintained between user
  and model, including all turns
- **Streaming Response**: Model outputs arrive in chunks, allowing real-time
  display before completion

### Tools

Capabilities the AI model can invoke to interact with the development
environment. Tools are the model's "hands" for reading files, executing
commands, and searching codebases.

<tool_categories>

**Built-in Tools (14 core tools)**:

- **File Operations**: `read-file`, `write-file`, `edit`, `glob`, `ls`,
  `read-many-files`
- **Search**: `grep` (or `ripgrep` when available)
- **Shell Execution**: `shell` - runs commands with streaming output
- **Web Access**: `web-fetch`, `web-search`
- **Session Management**: `memory`, `write-todos`, `activate-skill`

**Discovered Tools**: Project-specific tools loaded via a discovery command
defined in settings

**MCP Tools**: External tools provided by Model Context Protocol servers,
enabling extensibility

</tool_categories>

### Policy Engine

The security system that governs whether tool executions are allowed, denied, or
require user confirmation. Implements a three-tier priority system where Admin
policies override User policies, which override Default policies.

<policy_decisions>

- **ALLOW**: Tool executes immediately without user interaction
- **ASK_USER**: Tool execution requires explicit user confirmation
- **DENY**: Tool execution is blocked (in non-interactive mode, ASK_USER becomes
  DENY)

</policy_decisions>

### Approval Modes

Different operational modes that affect how the policy engine evaluates tool
calls:

- **Default Mode**: Standard approval flow—dangerous operations require
  confirmation
- **YOLO Mode**: Allows most operations without confirmation (for trusted
  environments)
- **Plan Mode**: Restricts to read-only and search tools—write operations are
  denied

### Hooks

Extensibility points that intercept and modify behavior at 11 defined lifecycle
events. Hooks execute external commands, receive JSON input, and can block,
modify, or augment operations.

<hook_events>

- **Session Events**: `SessionStart`, `SessionEnd`
- **Agent Events**: `BeforeAgent`, `AfterAgent`
- **Model Events**: `BeforeModel`, `AfterModel`, `BeforeToolSelection`
- **Tool Events**: `BeforeTool`, `AfterTool`, `Notification`
- **Compression**: `PreCompress`

</hook_events>

### Model Context Protocol (MCP)

An open protocol for connecting AI assistants to external tool providers. MCP
servers expose tools that Gemini CLI discovers and integrates alongside built-in
tools, enabling infinite extensibility.

### Configuration Hierarchy

Settings are loaded and merged from multiple sources in precedence order (lowest
to highest):

1. Default values → 2. System defaults → 3. User settings
   (`~/.gemini/settings.json`) → 4. Project settings (`.gemini/settings.json`)
   → 5. Environment variables → 6. Command-line arguments

## Key Workflows

### Workflow 1: Interactive Conversation

**Purpose**: Enable developers to have natural language conversations with AI
about their codebase

**Trigger**: User launches `gemini` command and enters a prompt

**Steps**:

1. User input received and validated by CLI package
2. Session context assembled (system instruction, tools, history)
3. Prompt sent to Gemini API with available tool declarations
4. Model response streamed back in chunks, displayed in real-time
5. If model requests tool calls, tool execution workflow begins
6. Conversation history updated with user input and model response
7. User can continue conversation or exit

**Outcome**: User receives AI-generated response, potentially with tool-assisted
information

**Business Impact**: Enables intelligent code understanding, generation, and
assistance without leaving the terminal

### Workflow 2: Tool Execution with Policy Approval

**Purpose**: Safely execute model-requested operations with appropriate user
oversight

**Trigger**: Model generates a function call requesting tool execution

**Steps**:

1. Tool call request extracted from model response
2. Tool instance retrieved from Tool Registry
3. Policy Engine evaluates the tool call against configured rules
4. If ALLOW: proceed to execution
5. If ASK_USER: generate confirmation details, display to user, await response
6. If user approves: execute tool with abort signal support
7. Tool result captured and formatted for model consumption
8. Notification hook fired if configured
9. Results sent back to model as function response
10. Model continues with new information

**Outcome**: Tool executes with appropriate oversight, results flow back to
model

**Business Impact**: Maintains security while enabling powerful automation—users
retain control over file modifications and command execution

### Workflow 3: MCP Server Integration

**Purpose**: Extend Gemini CLI capabilities with external tool providers

**Trigger**: User configures MCP servers in settings, or extension provides
server configuration

**Steps**:

1. MCP server configurations loaded from settings during initialization
2. For each server, appropriate transport established (stdio, SSE, HTTP,
   WebSocket)
3. Tool discovery performed—server's available tools retrieved
4. Tools registered in Tool Registry with server prefix (e.g.,
   `server-name__tool-name`)
5. Policy rules applied—trusted servers may have tools auto-allowed
6. Tools become available for model to invoke
7. On tool call, MCP Client Manager routes request to appropriate server
8. Server executes tool, returns result in MCP format
9. Result transformed to Gemini API format and returned

**Outcome**: External tools seamlessly integrated alongside built-in tools

**Business Impact**: Enables ecosystem extensibility—teams can build custom tool
servers for their specific domains

### Workflow 4: Non-Interactive Headless Execution

**Purpose**: Enable Gemini CLI use in scripts, CI/CD pipelines, and automation

**Trigger**: User invokes `gemini -p "prompt"` without interactive mode

**Steps**:

1. Input collected from command-line prompt and/or stdin
2. Authentication validated (API key required for non-interactive)
3. Output format configured (text, JSON, or stream-JSON)
4. Single request sent to model with prompt
5. Policy decisions that require ASK_USER automatically become DENY
6. Model response captured with tool executions (if allowed)
7. Final output written to stdout in configured format
8. Exit with appropriate code

**Outcome**: Scriptable AI assistance for automated workflows

**Business Impact**: Enables integration into development pipelines, batch
processing, and programmatic AI interactions

### Workflow 5: Session Resume and Context Management

**Purpose**: Continue previous conversations without losing context

**Trigger**: User invokes `gemini --resume` or `/restore` command

**Steps**:

1. Session selector resolves target session (latest or specified)
2. Session file loaded from `.gemini/sessions/` directory
3. Conversation history reconstructed from recorded messages
4. Tool call history and results restored
5. Session ID preserved to continue recording to same file
6. User can continue conversation with full prior context
7. Context compression available if history grows too large

**Outcome**: Seamless continuation of complex, multi-turn conversations

**Business Impact**: Enables long-running projects and complex debugging
sessions that span multiple terminal sessions

## Decision Points

### Decision: Which Ranking Algorithm for Tool Selection?

**Context**: When the model generates tool call requests

**Criteria**:

- Tool name exact match in registry
- Tool exclusion rules from settings
- MCP server tool prefixing conventions

**Options**:

- **Exact Match**: Tool name must match registered name exactly
- **MCP Qualified Match**: For MCP tools, try both `tool-name` and
  `server__tool-name`
- **Tool Not Found**: Return error with suggestions for similar tool names

**Business Rationale**: Strict matching prevents accidental execution of wrong
tools while qualified matching supports MCP's namespacing convention

### Decision: Policy Rule Selection

**Context**: When determining whether a tool call should be allowed

**Criteria**:

- Rule priority (higher wins)
- Rule tier (Admin > User > Default)
- Tool name pattern matching
- Arguments pattern matching (regex)
- Current approval mode

**Options**:

- **First Match Wins**: Rules sorted by effective priority, first matching rule
  determines outcome
- **Shell Command Recursion**: Compound commands (`;`, `&&`, `||`) split and
  each sub-command evaluated
- **Default Fallback**: If no rule matches, use configured default decision

**Business Rationale**: Priority-based system ensures organizational policies
(Admin tier) always override user preferences, while shell splitting prevents
bypass via command chaining

### Decision: Model Fallback Handling

**Context**: When the primary model fails with quota or availability errors

**Criteria**:

- Error type (quota, network, 5xx responses)
- Authentication type
- Retry count exhausted
- Fallback model availability

**Options**:

- **Retry with Backoff**: Network errors and 5xx trigger exponential backoff
  retry
- **Quota Fallback**: Persistent 429 errors may trigger switch to fallback model
- **Fatal Exit**: Authentication errors or bad requests (400) exit immediately

**Business Rationale**: Resilient handling ensures user productivity despite
transient failures while avoiding infinite retry loops

### Decision: Hook Execution Strategy

**Context**: When a lifecycle event fires with configured hooks

**Criteria**:

- Hook matcher pattern (glob-style)
- Sequential vs parallel execution flag
- Hook source (project, user, system, extension)
- Trusted folder status

**Options**:

- **Parallel Execution**: Default for hooks without data dependencies
- **Sequential Execution**: When `sequential: true` flag set
- **Deny Untrusted**: Project hooks in untrusted folders are denied
- **Output Aggregation**: Multiple hook outputs merged using event-specific
  strategies

**Business Rationale**: Parallel execution maximizes performance while
sequential mode supports hooks that depend on each other's output

## Business Rules

### Tool Confirmation Requirements

**Rule**: File-modifying tools (`write-file`, `edit`) and shell commands require
user confirmation by default

**Rationale**: Prevents accidental data loss or unintended system modifications

**Impact**:

- Users see diff preview before file changes apply
- Shell commands display with full command text before execution
- YOLO mode bypasses for trusted development environments
- Non-interactive mode denies operations requiring confirmation

### Context Window Management

**Rule**: Conversations are limited by model context window (1M tokens for
Gemini 2.5 Pro)

**Rationale**: Prevents API errors from oversized requests

**Impact**:

- Context compression available when history grows large
- PreCompress hooks can inject summarization logic
- Token counting tracks usage throughout session
- Tool outputs can be truncated if exceeding configured thresholds

### Shell Command Safety

**Rule**: Compound shell commands are recursively evaluated—if any sub-command
would be DENIED, the entire command is DENIED

**Rationale**: Prevents policy bypass through command chaining (e.g.,
`allowed-cmd && denied-cmd`)

**Impact**:

- Commands with `;`, `&&`, `||`, `|` are split and each part evaluated
- Redirection (`>`, `>>`, `<`) can downgrade ALLOW to ASK_USER
- Commands that fail parsing default to ASK_USER

### MCP Server Trust Levels

**Rule**: MCP servers can be marked as "trusted" in configuration, which
auto-allows their tools

**Rationale**: Balances security with convenience for known-safe tool providers

**Impact**:

- Untrusted servers' tools default to ASK_USER policy
- Trusted servers' tools can be auto-allowed at user tier priority
- Extension-provided servers inherit extension trust level
- Server-specific tool exclusions still honored

### Authentication Tiering

**Rule**: Different authentication methods provide different capabilities and
quotas

**Rationale**: Supports multiple use cases from free personal use to enterprise
deployment

**Impact**:

- **Login with Google**: Free tier (60 req/min, 1000/day), automatic model
  updates
- **Gemini API Key**: Free tier (100 req/day) or paid, model selection control
- **Vertex AI**: Enterprise features, higher limits, Google Cloud integration
- Non-interactive mode requires API key or explicit auth setup

### Session Recording and Privacy

**Rule**: Conversations are recorded to session files by default, with opt-out
available

**Rationale**: Enables session resume and debugging while respecting privacy

**Impact**:

- Sessions stored in `.gemini/sessions/` directory
- Thoughts, messages, and tool calls captured with timestamps
- Telemetry separate from session recording with own opt-out
- Session cleanup removes expired sessions automatically

## Integration Points

### Upstream Systems (Data Sources)

**Gemini API** (`@google/genai`): Provides the AI model capabilities—content
generation, function calling, and streaming responses. The core value
proposition of the entire CLI.

**Model Context Protocol Servers**: External tool providers that expose
capabilities via MCP protocol. Can be local processes (stdio), remote services
(SSE/HTTP), or WebSocket connections.

**File System**: The local development environment—source code, configuration
files, and project structure that the AI assists with.

**Git Repository**: Version control context including status, history, and
branch information used for contextual understanding.

**IDE Companion** (VSCode Extension): Optional integration providing richer file
editing experience with IDE diff views.

### Downstream Systems (Data Consumers)

**Terminal Display**: The React/Ink UI renders model responses, tool
confirmations, and status information to the user's terminal.

**Session Storage**: Conversation history persisted to JSON files for resume
capability and debugging.

**Telemetry System**: Optional metrics and tracing sent to OpenTelemetry
backends for monitoring and analysis.

**Hook Commands**: External processes that receive lifecycle events and can
modify behavior or capture audit logs.

### Event Publishing

**Core Events** (`coreEvents`): Internal event emitter for coordination between
packages:

- `Output`: Content destined for user display
- `ConsoleLog`: Debug and diagnostic messages
- `UserFeedback`: Warnings, errors, and informational messages
- `RetryAttempt`: Signals retry operations for user visibility

**Message Bus**: Mediated communication channel for:

- Tool confirmation requests/responses
- Policy decision routing
- Hook execution coordination
- Dynamic policy updates during session

**Telemetry Events**: Structured events for observability:

- `SessionStart`/`SessionEnd` with source information
- `ToolCall` events with duration and outcome
- `HookCall` events for hook execution tracking
- `ContentRetry` events for debugging model failures
