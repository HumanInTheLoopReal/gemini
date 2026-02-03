# Agent System

The agent system enables delegating specialized tasks to autonomous AI
sub-agents. Agents are defined via Markdown with YAML frontmatter or TypeScript
definitions, executed in isolated loops with their own tools and prompts, and
return structured results to parent agents.

## Architecture

This module implements a complete agent lifecycle: discovery, registration,
validation, execution, and result handling. Agents can be local (executed via
`LocalAgentExecutor`) or remote (A2A protocol, not yet implemented). The
`AgentRegistry` discovers agents from user and project directories, validates
them, and exposes them as tools via `delegate_to_agent`. Each agent runs in a
non-interactive loop with its own tool registry, prompt context, and termination
conditions.

Key interfaces: `AgentDefinition`, `LocalAgentDefinition`,
`RemoteAgentDefinition`, `AgentInputs`, `OutputObject`, `SubagentActivityEvent`.

## Key Files

| File                        | Purpose                                                                                                                                                                 | When to Modify                                                                         |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `types.ts`                  | Core type definitions: `AgentDefinition`, `LocalAgentDefinition`, `RemoteAgentDefinition`, `AgentInputs`, `OutputObject`, `SubagentActivityEvent`, `AgentTerminateMode` | When adding new agent configuration options or execution modes                         |
| `registry.ts`               | `AgentRegistry` class: discovers, validates, and registers agents from user/project directories. Generates tool descriptions and directory context for parent agents    | When changing agent discovery logic, registration precedence, or model config handling |
| `agentLoader.ts`            | Parses and validates Markdown agent definitions with YAML frontmatter. Converts frontmatter DTO to `AgentDefinition`. Loads agents from directories                     | When adding new Markdown configuration fields or changing validation rules             |
| `local-executor.ts`         | `LocalAgentExecutor` class: runs agent execution loop, handles tool calls, compression, recovery turns, and termination logic                                           | When modifying execution flow, termination behavior, or recovery logic                 |
| `delegate-to-agent-tool.ts` | `DelegateToAgentTool`: exposes all registered agents as a single discriminated union tool. Parent agents call this to delegate tasks                                    | When changing delegation interface or agent selection logic                            |
| `subagent-tool-wrapper.ts`  | `SubagentToolWrapper`: wraps a single `AgentDefinition` as a `DeclarativeTool`, creating appropriate invocations (local or remote)                                      | When adding new agent kinds or changing tool wrapper behavior                          |
| `local-invocation.ts`       | `LocalSubagentInvocation`: executes a local agent, bridges activity events to UI, formats results                                                                       | When changing local agent execution, output streaming, or result formatting            |
| `remote-invocation.ts`      | `RemoteAgentInvocation`: executes remote A2A agents via ADC handler. Manages authentication and message bridging to A2A protocol                                        | When implementing or modifying remote agent support                                    |
| `a2a-client-manager.ts`     | `A2AClientManager`: singleton managing A2A client creation, caching, and lifecycle for remote agent communication                                                       | When modifying A2A client configuration or authentication                              |
| `a2aUtils.ts`               | Utilities for extracting messages, tasks, and IDs from A2A protocol responses                                                                                           | When updating A2A response parsing logic                                               |
| `codebase-investigator.ts`  | Built-in agent for deep codebase analysis. Returns structured JSON report with findings, exploration trace, and relevant file locations                                 | When modifying the investigator's capabilities, prompt, or output schema               |
| `cli-help-agent.ts`         | Built-in agent for CLI command help and documentation. Returns structured command reference and usage information                                                       | When modifying CLI help agent capabilities or output format                            |
| `schema-utils.ts`           | `convertInputConfigToJsonSchema()`: converts `InputConfig` to JSON Schema for tool declarations                                                                         | When supporting new input parameter types                                              |
| `utils.ts`                  | `templateString()`: replaces `${...}` placeholders in prompts with `AgentInputs` values                                                                                 | When changing template syntax or validation logic                                      |

## Patterns

- **Agent Discovery**: `AgentRegistry` loads agents from `~/.gemini/agents/`
  (user-level) and `.gemini/agents/` (project-level, if trusted). Markdown files
  with YAML frontmatter are parsed; files starting with `_` are ignored.
- **Tool Exposure**: Agents are exposed as tools via `DelegateToAgentTool`
  (discriminated union of all agents) or `SubagentToolWrapper` (single agent
  wrapper).
- **Execution Loop**: `LocalAgentExecutor` runs a turn-based loop, calling the
  model, executing tool calls in parallel, handling the `complete_task` tool,
  and checking termination conditions (max turns, timeout, goal reached).
- **Termination & Recovery**: If an agent hits a termination limit (timeout, max
  turns, protocol violation), the executor attempts a single "grace period"
  recovery turn, prompting the agent to call `complete_task` immediately with
  best-effort results.
- **Activity Streaming**: `SubagentActivityEvent` provides observability into
  agent execution (tool calls, thoughts, errors). Events are bridged to UI via
  `updateOutput` callback.
- **Output Validation**: Agents can define `outputConfig` with a Zod schema. The
  `complete_task` tool validates output against this schema before accepting
  completion.
- **Template Substitution**: Prompts support `${input_name}` placeholders,
  replaced by `AgentInputs` via `templateString()`. Reference `InputConfig` and
  `PromptConfig`.

## Boundaries

- **DO**: Use agents for complex, multi-step tasks requiring specialized
  analysis (e.g., codebase investigation, deep research).
- **DO**: Define agent inputs via `InputConfig`, outputs via `OutputConfig` with
  Zod schemas.
- **DO**: Register agents in `~/.gemini/agents/` (user) or `.gemini/agents/`
  (project).
- **DO NOT**: Allow sub-agents to delegate to other agents - `agentLoader.ts`
  blocks `delegate_to_agent` in sub-agent tool lists to prevent recursion.
- **DO NOT**: Use agents for simple, single-tool tasks - use direct tool calls
  instead.
- This module handles agent lifecycle and execution, NOT tool implementation -
  tools belong in `../tools/`.
- This module handles agent definitions, NOT interactive chat - chat belongs in
  `../core/geminiChat.ts`.

## Relationships

- **Depends on**: `../tools/` (tool registry, tool invocation),
  `../core/geminiChat.ts` (model interaction), `../config/` (Config, Storage,
  model configs), `../services/chatCompressionService.ts` (history compression),
  `../utils/` (templating, environment context, thought parsing),
  `../telemetry/` (logging)
- **Used by**: `../tools/tool-registry.ts` (registers `delegate_to_agent` tool),
  parent agents (via tool calls), CLI (for direct agent invocation)

## Adding New Agents

### Via Markdown with YAML Frontmatter (Recommended for simple agents)

1. Create a `.md` file in `~/.gemini/agents/` or `.gemini/agents/`:

   ```markdown
   ---
   name: my-agent
   description: Agent description
   display_name: My Agent # optional
   kind: local
   tools: # optional
     - read_file
     - grep
   system_prompt: 'You are an agent specialized in...'
   model: gemini-2.0-flash # optional, defaults to parent model
   temperature: 0.1 # optional
   max_turns: 20 # optional
   timeout_mins: 10 # optional
   ---

   # Agent Documentation (optional)

   Additional markdown content describing your agent.
   ```

2. Restart Gemini CLI - `AgentRegistry` will discover and validate the agent on
   initialization.

### Via TypeScript (For complex agents with custom output schemas)

1. Create a new `LocalAgentDefinition` in a new file (e.g., `my-agent.ts`):

   ```typescript
   import { z } from 'zod';
   import type { LocalAgentDefinition } from './types.js';

   const MyAgentOutputSchema = z.object({
     result: z.string(),
     confidence: z.number(),
   });

   export const MyAgent: LocalAgentDefinition<typeof MyAgentOutputSchema> = {
     kind: 'local',
     name: 'my_agent',
     description: 'Agent description',
     inputConfig: {
       inputs: {
         target: {
           type: 'string',
           description: 'Target to analyze',
           required: true,
         },
       },
     },
     outputConfig: {
       outputName: 'analysis',
       description: 'Analysis result',
       schema: MyAgentOutputSchema,
     },
     promptConfig: {
       systemPrompt: 'You are...',
       query: 'Analyze ${target}',
     },
     modelConfig: { model: 'gemini-2.0-flash', temp: 0.1, top_p: 0.95 },
     runConfig: { max_time_minutes: 10, max_turns: 20 },
     toolConfig: { tools: ['ls', 'read_file'] },
   };
   ```

2. Register in `registry.ts` `loadBuiltInAgents()`:

   ```typescript
   import { MyAgent } from './my-agent.js';
   // ...
   this.registerAgent(MyAgent);
   ```

3. Update tests in `registry.test.ts` and add agent-specific tests.

## Testing

- **Agent Definitions**: Test Markdown frontmatter parsing and validation in
  `agentLoader.test.ts`. Ensure invalid configs throw `AgentLoadError`.
- **Execution**: Test `LocalAgentExecutor` in `local-executor.test.ts`. Mock
  `GeminiChat` and tool responses. Verify termination conditions, recovery
  logic, and output validation.
- **Tool Wrapping**: Test `SubagentToolWrapper` and `DelegateToAgentTool` in
  their respective test files. Verify schema generation and invocation creation.
- **Registry**: Test `AgentRegistry` in `registry.test.ts`. Mock file system for
  discovery. Verify precedence (project overrides user), model config
  registration.
- **Remote A2A**: Test `RemoteAgentInvocation` and `A2AClientManager` in
  `remote-invocation.test.ts` and `a2a-client-manager.test.ts`. Verify OAuth
  flow, message bridging, and client caching.
- **Integration**: Test end-to-end agent invocation via `delegate_to_agent` tool
  in integration tests.
- **Mocking**: Use `vi.mock()` for `geminiChat.ts`, `fs/promises`, `js-yaml`.
  Use `vi.hoisted()` for mocks needed in factories.
- **What to mock**: File system operations, model API calls, tool execution
  (when testing executor logic), A2A client calls. DO NOT mock `AgentDefinition`
  structures - use real test fixtures.
- **What not to mock**: Schema validation (Zod), template substitution (utils),
  JSON schema conversion (schema-utils) - these are pure functions.
