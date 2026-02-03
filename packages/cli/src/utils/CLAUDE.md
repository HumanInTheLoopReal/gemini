# CLI Utils

CLI-level utility functions for error handling, session management,
configuration, and infrastructure concerns. These helpers bridge the gap between
the interactive UI layer and the core orchestration engine.

## Architecture

Utils are organized into four categories:

1. **Error & Cleanup** (`errors.ts`, `cleanup.ts`, `events.ts`) - Terminal error
   handling, graceful shutdown, and event management
2. **Session & State** (`sessionUtils.ts`, `sessionCleanup.ts`, `sessions.ts`,
   `persistentState.ts`) - Session discovery, selection, cleanup, and
   cross-session state
3. **Configuration & Infrastructure** (`envVarResolver.ts`, `settingsUtils.ts`,
   `sandbox.ts`, `sandboxUtils.ts`, `terminalTheme.ts`) - Environment
   resolution, settings queries, sandboxing, and theme setup
4. **Utilities** (command parsing, git, markdown, stdin, process management,
   etc.) - Domain-specific helpers

## Key Files

| File                     | Purpose                                                                                  | When to Modify                                                                 |
| ------------------------ | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `errors.ts`              | Handles error output for JSON/text/streaming modes, tool errors, cancellation, max turns | When adding new fatal error types or changing error formatting                 |
| `cleanup.ts`             | Registers and runs sync/async cleanup functions on exit; manages telemetry shutdown      | When adding new exit lifecycle hooks or telemetry concerns                     |
| `sessionUtils.ts`        | Session discovery, selection, and metadata (SessionInfo, SessionSelector class)          | When changing session resolution logic, search patterns, or display formatting |
| `settingsUtils.ts`       | Settings schema queries, getters/setters, flattened schema access                        | When modifying how settings are loaded, validated, or displayed                |
| `envVarResolver.ts`      | Replaces `$VAR` and `${VAR}` placeholders with environment values                        | When changing env var resolution logic or adding filters                       |
| `sandbox.ts`             | Sandbox initialization, Docker/seatbelt setup, process management                        | When modifying sandbox execution, image names, or security profiles            |
| `commands.ts`            | Slash command parsing (path navigation, alias resolution)                                | When changing command resolution algorithm or alias behavior                   |
| `persistentState.ts`     | Cross-session global state (e.g., banner shown counts)                                   | When adding new persistent state keys beyond defaults                          |
| `commentJson.ts`         | JSON parsing with comment/trailing comma support                                         | When changing JSON parsing tolerances                                          |
| `deepMerge.ts`           | Recursive object merging for settings/config composition                                 | When changing merge semantics (arrays, overrides, etc.)                        |
| `gitUtils.ts`            | Git operations (status, current branch, staging)                                         | When modifying git integration or adding new git queries                       |
| `handleAutoUpdate.ts`    | Update checking and installation flow                                                    | When changing update mechanism or version check logic                          |
| `installationInfo.ts`    | Installation detection (npm, global, bundled) and version tracking                       | When supporting new install methods or versioning schemes                      |
| `startupWarnings.ts`     | Initialization-time user warnings                                                        | When adding new startup checks or warnings                                     |
| `sessionCleanup.ts`      | Session retention and cleanup (age/count-based)                                          | When modifying session cleanup logic, retention policies, or expiration rules  |
| `sessions.ts`            | Session listing and deletion operations                                                  | When changing session list/delete commands or output formatting                |
| `sandboxUtils.ts`        | Sandbox helper utilities (container paths, entrypoint, image parsing)                    | When modifying Docker container setup, path mappings, or entrypoint logic      |
| `readStdin.ts`           | Read piped input from stdin with size limits and timeout                                 | When changing stdin reading behavior or size limits                            |
| `relaunch.ts`            | CLI process relaunch mechanism for settings changes                                      | When modifying relaunch logic or exit code handling                            |
| `terminalTheme.ts`       | Terminal capability detection and theme setup                                            | When changing theme initialization or terminal background detection            |
| `events.ts`              | Event emitter for CLI events                                                             | When adding new CLI-level events or event types                                |
| `windowTitle.ts`         | Terminal window title management                                                         | When changing window title formatting or update logic                          |
| `userStartupWarnings.ts` | User-specific startup warnings and notifications                                         | When adding new user-facing startup messages                                   |
| `dialogScopeUtils.ts`    | Dialog scope utilities for UI state management                                           | When modifying dialog scoping or state isolation                               |
| `checks.ts`              | Validation and check utilities                                                           | When adding new validation or check functions                                  |
| `math.ts`                | Mathematical utility functions                                                           | When adding new math helpers                                                   |
| `resolvePath.ts`         | Path resolution utilities                                                                | When changing path resolution logic                                            |
| `processUtils.ts`        | Process management utilities (exit codes, signals)                                       | When modifying process lifecycle handling                                      |
| `updateEventEmitter.ts`  | Update event emitter for auto-update notifications                                       | When changing update notification logic                                        |
| `spawnWrapper.ts`        | Wrapper for child process spawning                                                       | When modifying child process execution                                         |
| `activityLogger.ts`      | Network request logging and activity tracking for debugging                              | When changing request logging, activity tracking, or debug output              |
| `skillSettings.ts`       | Skill enable/disable state management across configuration scopes                        | When modifying skill configuration storage or scope handling                   |
| `skillUtils.ts`          | Skill installation, loading, and feedback rendering utilities                            | When adding skill installation features or changing skill management logic     |

## Patterns

- **Error handling modes**: Respect `config.getOutputFormat()` (JSON,
  STREAM_JSON, TEXT) in `errors.ts` - never bypass output format
- **Session discovery**: Always filter for sessions with user/assistant messages
  (skip system-only); cache session lists with optional full content loading
- **Session cleanup**: Runs on startup; deletes corrupted sessions and applies
  retention policies (age-based via `maxAge`, count-based via `maxCount`); never
  deletes current session
- **Settings access**: Use dot notation keys (e.g., `"server.host"`) - the
  flattened schema handles nesting transparently
- **Cleanup registration**: Register functions early, run sync cleanup for
  critical paths (errors, non-interactive), async cleanup on normal exit
- **Environment resolution**: Support both `$VAR` and `${VAR}` syntax; preserve
  unresolved placeholders (don't error on missing vars)
- **Persistent state**: Cache in memory after first load; always call `save()`
  after mutation to ensure disk persistence
- **Sandbox paths**: Use `getContainerPath()` to convert Windows paths (C:\) to
  container paths (/c/) for Docker compatibility
- **Terminal theme**: Detect terminal background color and capabilities on
  startup; load custom themes from settings; auto-select theme based on terminal
  background
- **Stdin reading**: Set 500ms timeout for piped input detection; enforce 8MB
  size limit; gracefully handle non-TTY terminals

## Boundaries

- **DO**: Use `errors.ts` for all user-facing error output - ensures consistent
  formatting across modes
- **DO**: Register cleanup functions in `cleanup.ts` for resources that need
  shutdown (promises, streams, processes)
- **DO**: Query settings through `settingsUtils.ts` helpers - this ensures
  schema validation and default handling
- **DO**: Use `sessionCleanup.ts` for automated session cleanup - respects
  retention policies and never deletes active sessions
- **DO**: Use `readStdin.ts` for reading piped input - handles timeouts and size
  limits properly
- **DO**: Use `relaunch.ts` when CLI needs to restart (e.g., after settings
  changes) - uses RELAUNCH_EXIT_CODE
- **DO NOT**: Direct console.error/log in UI components - use error handlers or
  dispatch to app context
- **DO NOT**: Bypass environment resolution in config loading - always call
  `resolveEnvVarsInObject()` for user-provided configs
- **DO NOT**: Mutate session objects after they're returned - SessionInfo is
  used for display and caching
- **DO NOT**: Delete the current/active session - session cleanup and deletion
  operations must skip the active session
- This module handles CLI infrastructure, NOT core AI orchestration - core
  orchestration belongs in `@google/gemini-cli-core`
- This module handles non-interactive utilities; interactive terminal UI belongs
  in `../ui/`

## Relationships

- **Depends on**: `@google/gemini-cli-core` - Config, Storage, telemetry, error
  types, ChatRecordingService
- **Depends on**: `../config/settings.ts`, `../config/settingsSchema.ts` -
  Settings definitions and schema
- **Depends on**: `../ui/utils/textUtils.ts`, `../ui/commands/types.js` -
  UI-layer utilities (text sanitization, command types)
- **Depends on**: `../ui/utils/terminalCapabilityManager.js`, `../ui/themes/` -
  Terminal capability detection and theme management
- **Used by**: Error handlers in `../core/`, UI components in `../ui/`, command
  executors
- **Used by**: Cleanup hooks during process exit, session management in UI
  views, CLI startup initialization

## Adding New Utility

1. **Identify the category**: Is it error handling, session/state, config/infra,
   or domain-specific?
2. **Create the file** in appropriate location following naming (kebab-case.ts)
3. **Export functions** with clear JSDoc - describe inputs, outputs, side
   effects
4. **Add tests** (`.test.ts` co-located) - test both happy path and error cases
5. **Register if needed**: Cleanup functions? Register in `cleanup.ts`
6. **Document patterns**: Add pattern example to this file if the utility
   establishes a new pattern
7. **Add to this file's key files table** with clear purpose and modification
   guidance

## Testing

- Test files co-located as `*.test.ts` alongside source
- Mock `@google/gemini-cli-core` types (Config, Storage) using factory functions
  in tests
- Mock file system operations with `node:fs/promises` stubs
- Mock environment variables with `process.env` manipulation (restore after each
  test)
- Test error formatting with different output modes (TEXT, JSON, STREAM_JSON)
- For session tests: create mock ConversationRecord objects with sample
  messages, verify SessionInfo construction
- For session cleanup tests: mock file system operations, test retention
  policies (age/count), verify active session protection
- For settings tests: mock the schema and test flattening, getters, setters with
  nested structures
- For sandbox tests: mock Docker operations, test path conversion (Windows to
  container), verify entrypoint generation
- For stdin tests: mock process.stdin, test timeout behavior, verify size limit
  enforcement
- Integration tests in `*.integration.test.ts` can touch real file system (use
  temp directories)
