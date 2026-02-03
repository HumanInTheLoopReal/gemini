# CLI Services

Orchestrates command loading, validation, and execution. Manages custom commands
from files, built-in commands, and MCP prompts, with prompt processing pipeline
support.

## Architecture

The services module implements a **loader-based provider pattern** where
multiple independent command sources (`ICommandLoader` implementations) are
discovered and aggregated by the `CommandService`. A processing pipeline
(`IPromptProcessor`) transforms custom command prompts before execution.

```
CommandService (orchestrator)
├── BuiltinCommandLoader (hard-coded commands)
├── FileCommandLoader (TOML files from user/project/extensions)
├── McpPromptLoader (MCP server prompts)
└── SlashCommand execution with:
    └── PromptProcessors:
        ├── AtFileProcessor (@{ file injection })
        ├── ShellProcessor (!{ shell command execution })
        └── DefaultArgumentProcessor ({{args}} handling)
```

## Key Files

| File                                     | Purpose                                                                         | When to Modify                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `CommandService.ts`                      | Orchestrates loading and aggregation of all commands, resolves naming conflicts | When changing command discovery, conflict resolution, or loader composition |
| `types.ts`                               | Defines `ICommandLoader` interface contract                                     | When adding new loader capabilities or changing the loader protocol         |
| `BuiltinCommandLoader.ts`                | Loads hard-coded slash commands (about, help, auth, etc.)                       | When adding/removing built-in commands                                      |
| `FileCommandLoader.ts`                   | Discovers TOML command files from user/project/extension dirs                   | When changing command discovery paths, TOML schema, or file handling        |
| `McpPromptLoader.ts`                     | Converts MCP server prompts into executable commands                            | When changing MCP prompt handling, argument parsing, or completion          |
| `prompt-processors/types.ts`             | Defines `IPromptProcessor` interface and injection triggers                     | When adding new injection mechanism or changing processor contract          |
| `prompt-processors/argumentProcessor.ts` | Appends raw invocation if `{{args}}` not explicitly used                        | When changing default argument handling behavior                            |
| `prompt-processors/shellProcessor.ts`    | Handles `!{...}` shell injection and `{{args}}` escaping with approval flow     | When modifying shell execution, escaping, or permission checks              |
| `prompt-processors/atFileProcessor.ts`   | Handles `@{path}` file injection and validation                                 | When changing file injection security or content handling                   |
| `prompt-processors/injectionParser.ts`   | Parses `!{...}` and `@{...}` injection syntax                                   | When modifying injection syntax or parsing logic                            |

## Patterns

- **Loader Pattern**: Each `ICommandLoader` implementation independently
  discovers commands from a source (built-in code, files, or MCP).
  `CommandService` aggregates results via `Promise.allSettled()` for fault
  tolerance.
- **Processor Pipeline**: Custom commands use chained `IPromptProcessor`
  instances to transform prompts (`AtFileProcessor` → `ShellProcessor` →
  `DefaultArgumentProcessor`). Order matters—file content injected before shell
  commands execute.
- **Naming Resolution**: Extension commands that conflict with existing names
  get renamed to `extensionName.commandName`. Non-extension commands use "last
  wins" strategy based on loader order (user → project → extensions).
- **Security-First**: `AtFileProcessor` runs before `ShellProcessor` to prevent
  dynamic file path generation via shell commands. `ShellProcessor` tracks
  approval mode and throws `ConfirmationRequiredError` for unsafe commands.
- **TOML Schema Validation**: `FileCommandLoader` uses Zod schema for strict
  validation of command definitions (required `prompt`, optional `description`).

## Boundaries

- **DO**: Implement `ICommandLoader` for new command sources (e.g., remote APIs,
  databases)
- **DO**: Chain `IPromptProcessor` for prompt transformations before sending to
  the model
- **DO NOT**: Add business logic to command loaders—they discover and adapt, not
  execute
- **DO NOT**: Bypass the processor pipeline—shell injection and file inclusion
  MUST be validated
- **DO NOT**: Modify command names in FileCommandLoader except for safety (e.g.,
  colons to underscores)

**Module Responsibility**: Discovers, validates, and transforms commands from
multiple sources. Does NOT handle UI rendering, user interaction, or model
execution. Those belong in `../ui/commands/` and the core package.

## Relationships

- **Depends on**:
  - `@google/gemini-cli-core` - `Storage`, `Config`, `ShellExecutionService`,
    `escapeShellArg`, text processing utilities
  - `../ui/commands/types.js` - `SlashCommand`, `CommandContext`, `CommandKind`
    contracts
  - External: `glob`, `zod`, `@iarna/toml` for file discovery and validation

- **Used by**:
  - `../core/` (CLI main app) - initializes `CommandService` with all loaders,
    executes returned commands
  - `../ui/commands/` - calls `context.actions.submitPrompt()` with processed
    content

## Adding New Command Source

1. Create a new class implementing `ICommandLoader` interface with
   `loadCommands(signal: AbortSignal): Promise<SlashCommand[]>`
2. Implement command discovery logic (file system, API, database, etc.)
3. Adapt discovered items into `SlashCommand` objects with required fields:
   `name`, `description`, `kind`, `action`
4. Pass instance to
   `CommandService.create([builtin, file, mcp, newLoader], signal)`
5. Handle errors gracefully—use `Promise.allSettled()` in the orchestrator to
   prevent one loader failure from blocking others

## Adding New Processor

1. Create a new class implementing `IPromptProcessor` with
   `process(prompt: PromptPipelineContent, context: CommandContext): Promise<PromptPipelineContent>`
2. Transform `PromptPipelineContent` (array of part objects with `text` and
   other properties)
   - Uses `PartUnion` from `@google/genai` to represent text, image, and other
     content types
3. Add to the processor chain in `FileCommandLoader.parseAndAdaptFile()` in the
   correct order:
   - File injection (`AtFileProcessor`) first—prevents dynamic file generation
   - Shell execution (`ShellProcessor`) second—has side effects, needs validated
     inputs
   - Default handling (`DefaultArgumentProcessor`) last—fallback when no
     explicit args used
4. Test with multimodal content (text + images) if applicable

## Testing

- **Loader tests**: Mock `@google/gemini-cli-core` dependencies (Storage,
  Config, ShellExecutionService). Test command discovery with fixture TOML files
  and glob patterns.
- **Pipeline tests**: Create mock `CommandContext` with test invocations. Verify
  processor chains transform content correctly, including error cases (missing
  files, shell errors).
- **Integration tests**: Use `CommandService.create()` with all loaders, verify
  conflict resolution, name deduplication, and execution.
- **Security tests**: Verify shell injection requires approval, file paths are
  validated, and escape functions work correctly.
- **What to mock**: File system (fs), glob, Config, ShellExecutionService. Don't
  mock processor interfaces—test real chaining.
- **What not to mock**: Text processing utilities from core, Zod validation,
  injection parser logic.
