# Tools Module

Tool implementations for AI-powered file operations, shell commands, web access,
and MCP (Model Context Protocol) integrations. This module provides the
declarative tool framework and 14 built-in tools that AI agents use to interact
with the development environment.

## Architecture

Tools follow a **two-phase validation/execution pattern** separating parameter
validation from execution:

1. **ToolBuilder** (`DeclarativeTool`) - Validates parameters, returns schema
2. **ToolInvocation** - Encapsulates validated call, handles confirmation,
   executes

Key interfaces: `DeclarativeTool<TParams, TResult>`,
`ToolInvocation<TParams, TResult>`, `ToolResult`, `ToolBuilder`

The module supports three tool types:

- **Built-in tools** - File operations, shell, search, web access, skills (14
  core tools)
- **Discovered tools** - Project-specific tools via discovery command
- **MCP tools** - External tools via Model Context Protocol servers

## Google Gemini API Integration

The tools module uses the `@google/genai` SDK directly (not Vercel AI SDK).
Tools are converted to Google Gemini `FunctionDeclaration` format for API calls.

Key integration points:

- Tools are registered as `FunctionDeclaration[]` via `ToolRegistry`
- Gemini API returns tool calls with validated parameters
- Execution flow: `gemini_api_call()` → `tool-call` response →
  `tool.build(args)` → `invocation.shouldConfirmExecute()` →
  `invocation.execute()` → result
- All tools follow the two-phase pattern (build/execute) with confirmation
  support
- Tool results are streamed back to the model as `ToolResult` messages

## Key Files

| File                    | Purpose                                                                                             | When to Modify                                        |
| ----------------------- | --------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `tools.ts`              | Core abstractions: `DeclarativeTool`, `BaseDeclarativeTool`, `ToolInvocation`, `BaseToolInvocation` | Adding new tool base classes or confirmation patterns |
| `tool-registry.ts`      | Central registry managing all tools, discovery, filtering                                           | Changing tool discovery or registration logic         |
| `tool-error.ts`         | Tool error types and fatal error detection                                                          | Adding new error categories                           |
| `tool-names.ts`         | Centralized tool name constants                                                                     | Adding new built-in tool names                        |
| `read-file.ts`          | Read file tool with pagination support                                                              | Modifying file reading behavior                       |
| `edit.ts`               | String replacement tool with smart correction                                                       | Changing file edit logic                              |
| `write-file.ts`         | Write entire file tool                                                                              | Changing file write behavior                          |
| `shell.ts`              | Shell command execution with streaming output                                                       | Modifying command execution                           |
| `glob.ts`               | File pattern matching tool                                                                          | Changing file search behavior                         |
| `grep.ts`               | Content search tool (glob-based)                                                                    | Modifying content search                              |
| `ripGrep.ts`            | Content search with ripgrep binary                                                                  | Modifying ripgrep integration                         |
| `ls.ts`                 | Directory listing tool                                                                              | Changing directory operations                         |
| `mcp-tool.ts`           | MCP tool wrapper and discovery                                                                      | Integrating external MCP tools                        |
| `mcp-client.ts`         | MCP protocol client implementation                                                                  | Changing MCP communication                            |
| `mcp-client-manager.ts` | Manages multiple MCP server connections                                                             | Adding MCP server lifecycle features                  |
| `modifiable-tool.ts`    | Trait for tools supporting user modification                                                        | Enabling inline editor modification                   |
| `web-fetch.ts`          | Web content fetching tool                                                                           | Changing web scraping                                 |
| `web-search.ts`         | Web search integration                                                                              | Modifying search behavior                             |
| `write-todos.ts`        | Todo list management tool                                                                           | Changing todo tracking                                |
| `memoryTool.ts`         | Memory persistence tool                                                                             | Modifying session memory                              |
| `read-many-files.ts`    | Batch file reading tool                                                                             | Modifying multi-file reads                            |
| `diffOptions.ts`        | Diff generation configuration                                                                       | Changing diff display                                 |
| `get-internal-docs.ts`  | Internal documentation retrieval tool                                                               | Modifying internal docs access                        |
| `activate-skill.ts`     | Skill activation and execution tool                                                                 | Changing skill behavior                               |

## Patterns

- **Declarative tool pattern**: Extend `BaseDeclarativeTool<TParams, TResult>`
  and implement `createInvocation()` to return a `BaseToolInvocation` subclass
- **Two-phase execution**: `build()` validates params → returns `ToolInvocation`
  → `execute()` performs work
- **Confirmation flow**: Tools can request user confirmation via
  `shouldConfirmExecute()` returning `ToolCallConfirmationDetails`
- **Modifiable tools**: Implement `ModifiableDeclarativeTool<TParams>` to
  support editor-based modification flow
- **Error handling**: Return `ToolResult` with optional `error` field containing
  `ToolErrorType` for structured errors
- **Streaming output**: Set `canUpdateOutput: true` and use `updateOutput`
  callback in `execute()` for live progress
- **MCP integration**: `DiscoveredMCPTool` wraps external tools, transforms MCP
  content blocks to GenAI `Part[]`
- **Schema validation**: Use JSON schema in constructor, override
  `validateToolParamValues()` for custom validation
- **Tool locations**: Override `toolLocations()` to report file paths affected
  by the tool for IDE integration

## Boundaries

- **DO**: Create tools as plain objects extending `BaseDeclarativeTool` with
  validated parameters
- **DO**: Use `ToolRegistry` for all tool registration and discovery
- **DO**: Return structured `ToolResult` with `llmContent` (for AI) and
  `returnDisplay` (for users)
- **DO**: Use centralized constants from `tool-names.ts` to prevent circular
  dependencies
- **DO NOT**: Import tools directly in agents - use `tool-names.ts` constants
  instead
- **DO NOT**: Execute tools without validation - always use `build()` →
  `execute()` pattern
- **DO NOT**: Perform UI operations in tools - this is a backend module, return
  data for CLI to render
- Tools handle **execution logic and validation**, NOT **UI rendering** -
  rendering belongs in `@google/gemini-cli`
- Tools provide **schemas and results**, NOT **direct LLM integration** -
  orchestration belongs in `core/geminiChat.ts`

## Relationships

- **Depends on**: `../config/` (Config), `../services/` (ShellExecutionService,
  FileSystemService), `../utils/` (file utils, shell utils),
  `../confirmation-bus/` (MessageBus), `../ide/` (IdeClient)
- **Used by**: `../core/geminiChat.ts` (tool execution), `../agents/` (agent
  tool access), `@google/gemini-cli` (tool rendering)

## Adding New Tools

1. Create `my-tool.ts` extending `BaseDeclarativeTool<MyToolParams, ToolResult>`
2. Define `MyToolParams` interface with parameter types
3. Create `MyToolInvocation` class extending
   `BaseToolInvocation<MyToolParams, ToolResult>`
4. Implement `createInvocation()` to return your invocation class
5. Implement `getDescription()` for human-readable tool description
6. Implement `execute()` with tool logic, returning `ToolResult`
7. Override `validateToolParamValues()` for custom validation beyond schema
8. Add tool constant to `tool-names.ts` if it's a built-in tool
9. Register tool in tool registry initialization (typically in `core/` setup)
10. Add comprehensive tests in `my-tool.test.ts`

Example:

```typescript
export class MyToolInvocation extends BaseToolInvocation<
  MyToolParams,
  ToolResult
> {
  getDescription(): string {
    return `My tool: ${this.params.input}`;
  }

  async execute(signal: AbortSignal): Promise<ToolResult> {
    // Tool logic here
    return {
      llmContent: 'Result for LLM',
      returnDisplay: 'User-friendly result',
    };
  }
}

export class MyTool extends BaseDeclarativeTool<MyToolParams, ToolResult> {
  static readonly Name = MY_TOOL_NAME;

  constructor(config: Config, messageBus?: MessageBus) {
    super(
      MyTool.Name,
      'MyTool',
      'Tool description for AI',
      Kind.Other,
      {
        /* JSON schema */
      },
      true, // isOutputMarkdown
      false, // canUpdateOutput
      messageBus,
    );
  }

  protected createInvocation(
    params: MyToolParams,
  ): ToolInvocation<MyToolParams, ToolResult> {
    return new MyToolInvocation(params, this.messageBus);
  }
}
```

## Testing

- Co-locate tests: `my-tool.test.ts` next to `my-tool.ts`
- Test validation: Call `build()` with invalid params, expect errors
- Test execution: Mock file system, shell, or external services
- Test confirmation flow: Mock `MessageBus` and verify confirmation requests
- Mock MCP clients using `vi.mock()` for MCP tool tests
- Use `@google/gemini-cli-test-utils` for shared fixtures and mocks
- Test error handling: Verify proper `ToolErrorType` in error cases
- Test tool locations: Verify `toolLocations()` returns correct paths
- For shell tools: Mock `ShellExecutionService.execute()`
- For file tools: Mock `FileSystemService` methods
- Don't mock `ToolRegistry` - test tool registration directly
