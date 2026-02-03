# Core Utilities

Shared utility functions for AI orchestration, file operations, shell execution,
error handling, and system integration. This module provides the foundational
building blocks used throughout the core package.

## Architecture

The utils module is organized into functional categories:

- **Error Handling**: `errors.ts`, `retry.ts`, `googleErrors.ts`,
  `googleQuotaErrors.ts`, `httpErrors.ts`, `errorReporting.ts`,
  `errorParsing.ts`, `quotaErrorDetection.ts`
- **File Operations**: `fileUtils.ts`, `paths.ts`, `pathReader.ts`,
  `pathCorrector.ts`, `bfsFileSearch.ts`, `fileDiffUtils.ts`,
  `getFolderStructure.ts`, `filesearch/` subdirectory
- **Shell & Process**: `shell-utils.ts`, `terminal.ts`, `stdio.ts`, `getPty.ts`
- **Git Integration**: `gitUtils.ts`, `gitIgnoreParser.ts`
- **AI Message Processing**: `partUtils.ts`, `messageInspectors.ts`,
  `thoughtUtils.ts`, `generateContentResponseUtilities.ts`
- **Context & Environment**: `workspaceContext.ts`, `environmentContext.ts`,
  `promptIdContext.ts`, `session.ts`
- **Data Structures**: `LruCache.ts`, `channel.ts`, `events.ts`
- **Text Processing**: `textUtils.ts`, `formatters.ts`, `editor.ts`,
  `editCorrector.ts`, `llm-edit-fixer.ts`
- **System Information**: `version.ts`, `package.ts`, `systemEncoding.ts`,
  `memoryDiscovery.ts`, `memoryImportProcessor.ts`, `debugLogger.ts`
- **Validation & Parsing**: `schemaValidator.ts`, `ignorePatterns.ts`,
  `geminiIgnoreParser.ts`, `language-detection.ts`
- **Utilities & Helpers**: `tokenCalculation.ts`, `summarizer.ts`,
  `checkpointUtils.ts`, `installationManager.ts`, `browser.ts`,
  `secure-browser-launcher.ts`, `fetch.ts`, `customHeaderUtils.ts`,
  `apiConversionUtils.ts`, `delay.ts`, `extensionLoader.ts`,
  `nextSpeakerChecker.ts`, `safeJsonStringify.ts`, `tool-utils.ts`,
  `userAccountManager.ts`

Key interfaces: `WorkspaceContext` (multi-directory management), `RetryOptions`
(retry configuration), `ProcessedFileReadResult` (file read results),
`ShellConfiguration` (shell execution), `CoreEventEmitter` (event system).

## Key Files

| File                   | Purpose                                                           | When to Modify                                     |
| ---------------------- | ----------------------------------------------------------------- | -------------------------------------------------- |
| `errors.ts`            | Error classes (`FatalError`, `CanceledError`) and type guards     | Adding new error types or authentication checks    |
| `retry.ts`             | Exponential backoff retry logic with quota handling               | Changing retry behavior or adding retry conditions |
| `fileUtils.ts`         | File I/O (read, BOM detection, binary detection, MIME types)      | Adding file type support or changing read limits   |
| `partUtils.ts`         | AI message part creation and conversion (Vercel AI SDK ↔ Gemini) | Working with message formats during SDK migration  |
| `messageInspectors.ts` | Type guards for message parts (`isTextPart`, `isToolCallPart`)    | Adding new part type checks                        |
| `shell-utils.ts`       | Shell command parsing, escaping, command permissions              | Modifying command parsing or shell support         |
| `workspaceContext.ts`  | Multi-directory workspace management and path validation          | Adding workspace features or path validation logic |
| `events.ts`            | Core event emitter with backlog (`CoreEventEmitter`)              | Adding new event types or changing event behavior  |
| `channel.ts`           | Simple async channel for inter-component communication            | Need async message passing between components      |
| `debugLogger.ts`       | Debug logging utility                                             | Changing debug output behavior                     |
| `filesearch/`          | File search with ignore patterns, caching, crawling               | Modifying file discovery or search performance     |

## Patterns

- **Functional utilities**: Pure functions with explicit parameters, no global
  state
- **Error classification**: Use `isRetryableError()`, `isAuthenticationError()`,
  `classifyGoogleError()` to categorize errors
- **Retry with backoff**: Use `retryWithBackoff()` with `RetryOptions` for
  transient failures (429, 5xx, network errors)
- **File type detection**: Use `detectFileType()` and `isBinaryFile()` with BOM
  awareness for encoding detection
- **Part conversions**: Use `createTextPart()`, `createToolCallPart()`, etc. for
  new format; legacy `partToString()` for Gemini SDK compatibility
- **Type guards**: Use `isTextPart()`, `isToolCallPart()`, etc. for
  discriminated union narrowing
- **Shell execution**: Use `getShellConfiguration()` for platform-specific shell
  setup, `escapeShellArg()` for injection prevention
- **Command parsing**: Use `parseCommandDetails()` (tree-sitter for bash,
  PowerShell AST for Windows) to extract command names safely
- **Workspace validation**: Use `WorkspaceContext.isPathWithinWorkspace()`
  before file operations
- **Event emission**: Use `coreEvents.emitFeedback()`, `emitConsoleLog()`, etc.
  with automatic backlog buffering
- **BOM handling**: `readFileWithEncoding()` auto-detects UTF-8/16/32 BOM and
  strips it

## Boundaries

- **DO**: Use these utilities for cross-cutting concerns (errors, files, shell,
  messages)
- **DO**: Export utilities from `index.ts` if used by multiple packages
- **DO**: Write co-located tests (`*.test.ts`) for all utilities
- **DO NOT**: Import UI dependencies (React, Ink) - utils must be UI-agnostic
- **DO NOT**: Import from `@google/gemini-cli` - this creates circular
  dependencies
- **DO NOT**: Put business logic here - utilities are general-purpose helpers
- This module handles generic operations, NOT domain-specific orchestration -
  orchestration belongs in `../core/`, `../agents/`, or `../services/`
- File operations handle I/O and encoding, NOT tool execution - tool logic
  belongs in `../tools/`
- Shell utilities parse and validate commands, NOT execute workflows - workflow
  logic belongs in `../core/` or `../agents/`

## Relationships

- **Depends on**: Node.js built-ins (`node:fs`, `node:path`,
  `node:child_process`), external libraries (`zod`, `web-tree-sitter`,
  `shell-quote`, `mime`)
- **Used by**: `../core/`, `../tools/`, `../services/`, `../agents/`, `../mcp/`,
  `@google/gemini-cli`
- **Exported from**: `../index.ts` (selective exports for public API)
- **filesearch/** subdirectory: Self-contained file search with ignore patterns,
  used by file discovery tools

## Adding New Utilities

1. Create `new-util.ts` with pure functions or simple classes
2. Add comprehensive tests in `new-util.test.ts` using Vitest
3. Export from `../index.ts` if needed by external packages (check if it's truly
   reusable)
4. Document with JSDoc comments explaining parameters, return types, and edge
   cases
5. Follow existing patterns: immutability, functional style, no side effects
   unless necessary
6. Use TypeScript strict mode - avoid `any`, prefer `unknown` with type guards

## Testing

- **Test files**: Co-located `*.test.ts` files with 100%+ coverage target
- **Mocking**: Use `vi.mock()` with `async (importOriginal)` pattern for ES
  modules
- **File operations**: Use `vi.mock('node:fs')` and
  `vi.mock('node:fs/promises')` with mock file systems
- **Shell parsing**: Mock tree-sitter initialization with `vi.hoisted()` for
  parser state
- **Event emitters**: Test listener registration, backlog flushing, and error
  isolation
- **Retry logic**: Use fake timers (`vi.useFakeTimers()`) to test backoff
  without delays
- **Key test utilities**: `@google/gemini-cli-test-utils` provides shared mocks
  and helpers
- **What to mock**: External I/O (fs, network, child_process), expensive
  operations (tree-sitter parsing)
- **What NOT to mock**: Pure functions, type guards, simple transformations

## Migration Notes

- **Phase 2 in progress**: Dual support for Vercel AI SDK types (`Part`,
  `Content`) and legacy Gemini SDK types (`PartUnion`, `Content`)
- Use `partUtils.ts` creators (`createTextPart()`, etc.) for new code
- Legacy functions (`partToString()`, `toContent()`) will be removed after
  migration completes
- `messageInspectors.ts` has both new type guards (`isTextPart()`) and legacy
  guards (`isFunctionCall()`)
- See `../types/messages.ts` for new discriminated union definitions
