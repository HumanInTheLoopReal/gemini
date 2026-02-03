# Hook System

Gemini CLI's extensibility system for intercepting and modifying workflow
execution at 11 lifecycle events. Hooks enable custom tooling, governance, and
integration with external systems without modifying core code.

## Architecture

Modular pipeline architecture with 6 core components orchestrated by
`HookSystem`:

1. **HookRegistry** - Loads and validates hook definitions from config
2. **HookPlanner** - Selects matching hooks and creates execution plans
3. **HookRunner** - Executes command hooks (spawns processes, handles I/O)
4. **HookAggregator** - Merges multiple hook results using event-specific
   strategies
5. **HookEventHandler** - Event bus that coordinates hook execution
6. **HookTranslator** - Translates between AI SDK types and stable hook API
   types

Hook data flows through: Registry -> Planner -> Runner -> Aggregator ->
EventHandler

## Key Files

| File                  | Purpose                                                                                 | When to Modify                                                |
| --------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `types.ts`            | Hook event types, input/output interfaces, 11 event names (`HookEventName`)             | Adding new hook events or hook output fields                  |
| `hookSystem.ts`       | Main orchestrator, initializes all components                                           | Changing initialization logic or adding system-level features |
| `hookRegistry.ts`     | Loads hooks from config, handles precedence (Project > User > System > Extensions)      | Changing config loading or source precedence                  |
| `hookPlanner.ts`      | Matches hooks to events, creates execution plans (parallel vs sequential)               | Changing matcher logic or execution strategies                |
| `hookRunner.ts`       | Spawns command hooks, handles stdin/stdout/stderr, timeouts                             | Changing hook execution mechanics or I/O handling             |
| `hookAggregator.ts`   | Merges results with event-specific strategies (OR-logic, field replacement, tool union) | Adding new merge strategies for events                        |
| `hookEventHandler.ts` | Event bus with 11 `fire*Event()` methods, integrates with MessageBus                    | Adding new hook events or changing event handling             |
| `hookTranslator.ts`   | Decouples hooks from AI SDK version changes via stable `LLMRequest`/`LLMResponse` types | Supporting new AI SDK versions or adding hook API fields      |
| `index.ts`            | Public API exports                                                                      | Exposing new components or types                              |

## Patterns

- **Event-Driven Architecture**: Hook events fired via
  `HookEventHandler.fire*Event()` methods
- **Config Precedence**: Project > User > System > Extensions (see
  `ConfigSource` enum)
- **Execution Plans**: `HookPlanner` determines parallel vs sequential execution
  based on `sequential` flag
- **Merge Strategies**: Event-specific aggregation in `HookAggregator` (OR-logic
  for blocking, field replacement for model events, union for tool selection)
- **Stable Hook API**: `HookTranslator` decouples hooks from AI SDK changes -
  hooks always use `LLMRequest`/`LLMResponse` types
- **Command Hooks**: Execute external processes via shell, receive JSON input on
  stdin, output JSON on stdout
- **Hook Output Classes**: Event-specific classes (`BeforeToolHookOutput`,
  `BeforeModelHookOutput`, etc.) provide specialized methods like
  `getSyntheticResponse()`, `applyLLMRequestModifications()`
- **MessageBus Integration**: Hooks execute via MessageBus for mediated
  communication (optional, falls back to direct execution)

## Boundaries

- **DO**: Fire hooks through `HookEventHandler.fire*Event()` methods
- **DO**: Use `HookTranslator` for all AI SDK type conversions to maintain
  stability
- **DO**: Add event-specific merge logic in `HookAggregator` when creating new
  hook types
- **DO NOT**: Bypass `HookTranslator` - always use stable hook API types
  (`LLMRequest`/`LLMResponse`)
- **DO NOT**: Execute hooks directly via `HookRunner` - always go through
  `HookEventHandler`
- **DO NOT**: Modify hook inputs after passing to `fire*Event()` - base fields
  are added internally
- This module handles hook execution orchestration, NOT hook configuration -
  configuration is loaded from `Config` (see `../config/`)
- This module provides the hook event bus, NOT the integration points - callers
  (like `geminiChat.ts`) must interpret hook results in their context

## Relationships

- **Depends on**: `../config/` for `Config` class and hook definitions
- **Depends on**: `../confirmation-bus/` for `MessageBus` (optional mediated
  execution)
- **Depends on**: `../telemetry/` for `logHookCall()` and `HookCallEvent`
- **Depends on**: `@google/genai` types (`GenerateContentParameters`,
  `GenerateContentResponse`, etc.)
- **Used by**: `../core/client.ts` for hook system initialization and lifecycle
- **Used by**: `../services/chatCompressionService.ts` for SessionStart,
  SessionEnd, PreCompress events
- **Used by**: Tool execution flows for BeforeTool, AfterTool events

## Adding New Hook Events

1. Add event name to `HookEventName` enum in `types.ts`
2. Define input interface extending `HookInput` (e.g., `BeforeMyEventInput`)
3. Define output interface extending `HookOutput` (e.g., `BeforeMyEventOutput`)
4. Optionally create specialized output class extending `DefaultHookOutput` if
   custom methods needed
5. Add `fire*Event()` method to `HookEventHandler`
6. Add merge strategy to `HookAggregator.mergeOutputs()` if event needs custom
   aggregation logic
7. Add validation function to `HookEventHandler` (e.g.,
   `validateMyEventInput()`)
8. Add case to `handleHookExecutionRequest()` switch for MessageBus routing
9. Update exports in `index.ts`
10. Add telemetry logging in `logHookExecution()` if needed

## Testing

- **Unit Tests**: Each component has co-located `.test.ts` file
- **Mock Hooks**: Use `vi.hoisted()` to create mock command output for
  `HookRunner` tests
- **Test Execution Plans**: Mock `HookRegistry.getHooksForEvent()` to test
  planner logic
- **Test Aggregation**: Provide multiple `HookExecutionResult` objects to test
  merge strategies
- **Integration Tests**: Test full flow through
  `HookSystem.getEventHandler().fire*Event()`
- **Key Mocks**: Config (for hook definitions), MessageBus (for mediated
  execution), child_process.spawn (for command execution)
- **Test Patterns**: See `hookRunner.test.ts` for spawn mocking,
  `hookAggregator.test.ts` for merge strategy tests
