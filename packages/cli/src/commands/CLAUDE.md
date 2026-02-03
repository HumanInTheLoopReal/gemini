# Commands Module

CLI command definitions and handlers for all top-level `gemini` subcommands.
Each command is a yargs CommandModule that parses arguments, validates input,
and delegates to business logic in the core or CLI services.

## Architecture

Commands are organized hierarchically:

- **Top-level commands** (`mcp.ts`, `extensions.tsx`, `hooks.tsx`, `skills.tsx`)
  define the parent command with subcommand registration
- **Subcommand files** (in `mcp/`, `extensions/`, `hooks/`, `skills/`
  subdirectories) implement individual operations
- **Utilities** (`utils.ts`) provide common helpers like CLI exit handling

Each command follows the yargs `CommandModule` pattern with `command`,
`describe`, `builder`, and `handler` properties.

## Key Files

| File                      | Purpose                                                                                       | When to Modify                               |
| ------------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------------- |
| `mcp.ts`                  | Parent command for MCP server management (add/remove/list)                                    | When adding new MCP-related operations       |
| `extensions.tsx`          | Parent command for extension lifecycle management (install/uninstall/list/enable/disable/etc) | When adding new extension operations         |
| `hooks.tsx`               | Parent command for hook management (migrate)                                                  | When adding new hook operations              |
| `skills.tsx`              | Parent command for skill management (list/enable/disable/install/uninstall)                   | When adding new skill operations             |
| `mcp/add.ts`              | Add MCP server handler - parses transport type, args, headers, environment                    | When changing MCP server configuration flow  |
| `mcp/list.ts`             | List configured MCP servers                                                                   | When changing MCP server listing             |
| `mcp/remove.ts`           | Remove MCP server handler                                                                     | When changing MCP server removal             |
| `hooks/migrate.ts`        | Migrate hooks from old format to new                                                          | When changing hook migration logic           |
| `extensions/install.ts`   | Install extension handler - validates source, requests consent, uses ExtensionManager         | When changing extension installation logic   |
| `extensions/enable.ts`    | Enable extension handler                                                                      | When changing extension enablement           |
| `extensions/disable.ts`   | Disable extension handler                                                                     | When changing extension disablement          |
| `extensions/list.ts`      | List installed extensions                                                                     | When changing extension listing              |
| `extensions/uninstall.ts` | Uninstall extension handler                                                                   | When changing extension removal              |
| `extensions/update.ts`    | Update extensions handler                                                                     | When changing extension update logic         |
| `extensions/link.ts`      | Link extension for local development                                                          | When changing local development workflow     |
| `extensions/new.ts`       | Create new extension scaffold                                                                 | When changing extension generation           |
| `extensions/validate.ts`  | Validate extension configuration                                                              | When changing validation rules               |
| `extensions/configure.ts` | Configure extension settings                                                                  | When changing extension configuration UI     |
| `extensions/utils.ts`     | Shared extension utilities (getExtensionAndManager)                                           | When adding shared extension command helpers |
| `skills/list.ts`          | List available skills                                                                         | When changing skill listing                  |
| `skills/enable.ts`        | Enable a skill                                                                                | When changing skill enablement               |
| `skills/disable.ts`       | Disable a skill                                                                               | When changing skill disablement              |
| `skills/install.ts`       | Install a skill                                                                               | When changing skill installation logic       |
| `skills/uninstall.ts`     | Uninstall a skill                                                                             | When changing skill removal                  |
| `utils.ts`                | CLI utility functions (exitCli)                                                               | When adding cross-command utilities          |

## Patterns

- **CommandModule exports**: Each file exports a `CommandModule` object named
  `*Command` (e.g., `installCommand`, `mcpCommand`)
- **Yargs builder pattern**: Commands use yargs `.option()`, `.positional()`,
  and `.middleware()` for argument parsing
- **Handler delegation**: Handlers extract argv values, call async business
  logic functions, then call `exitCli()`
- **Error handling**: Handlers catch errors, log via `debugLogger`, and call
  `process.exit(1)` on failure
- **Scope validation**: MCP commands validate `scope` option (user vs project)
  to prevent invalid writes
- **Consent patterns**: Extension install uses `requestConsentNonInteractive` or
  explicit `--consent` flag
- **Middleware initialization**: Top-level commands use
  `initializeOutputListenersAndFlush()` middleware to set up output handlers

## Boundaries

- **DO**: Define commands using yargs `CommandModule` pattern. Parse arguments
  with yargs options/positionals. Delegate business logic to handlers in core or
  services (ExtensionManager, SettingsManager).
- **DO NOT**: Place complex business logic in command handlers - keep handlers
  focused on argument parsing and delegation.
- **DO NOT**: Import React/Ink components - this module is headless/CLI-only and
  has zero UI dependencies.
- This module handles yargs command parsing and non-interactive flows, NOT
  interactive terminal UI. UI commands are in `../ui/commands/`.

## Relationships

- **Depends on**: `@google/gemini-cli-core` - uses ExtensionInstallMetadata,
  MCPServerConfig, debugLogger
- **Depends on**: `../config/` - uses ExtensionManager, loadSettings,
  promptForSetting, consent flows
- **Depends on**: `../utils/` - uses getErrorMessage, cleanup utilities
- **Used by**: `../config/config.ts` - registers commands with yargs CLI parser
  for non-interactive/headless mode

## Adding New Command

1. Create parent command file (e.g., `myfeature.ts`) with yargs `CommandModule`
   export
2. Create subdirectory `myfeature/` for subcommands
3. Implement each subcommand (e.g., `myfeature/action.ts`) with:
   - Async handler function (e.g., `handleAction()`) that does the work
   - yargs `CommandModule` export with builder and handler
   - Handler calls `exitCli()` when complete
4. Import subcommands in parent and register with `.command()` in builder
5. Add `initializeOutputListenersAndFlush()` middleware in parent builder
6. Register in `../config/config.ts` with `.command(myfeatureCommand)`

## Testing

- Test files co-located: `*.test.ts` alongside source
- Mock subcommand imports with `vi.mock('./subdir/subcommand.js', ...)`
- Mock `../gemini.js` for `initializeOutputListenersAndFlush()`
- Test top-level commands by mocking yargs with
  `{ command, middleware, demandCommand, version }` methods
- Verify subcommands are registered by checking `mockYargs.command.mock.calls`
- For handler tests, mock dependencies like `ExtensionManager`, `loadSettings`,
  `debugLogger`
- Use `vi.spyOn(console, 'log')` to verify log output from handlers
