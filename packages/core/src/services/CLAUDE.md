# Services

Business services providing core infrastructure and operational capabilities for
Gemini CLI. Services are stateful components that manage resources, external
interactions, and cross-cutting concerns like configuration, recording, and
execution.

## Architecture

Services follow a class-based pattern with dependency injection via constructor.
Each service encapsulates a specific domain of responsibility (file operations,
git interactions, chat recording, etc.) and maintains internal state. Services
are instantiated once and shared across the application lifecycle via the Config
object.

Key services include:

- Configuration management (`ModelConfigService`, `ContextManager`)
- External execution (`ShellExecutionService`, `GitService`)
- Chat lifecycle (`ChatRecordingService`, `SessionSummaryService`,
  `ChatCompressionService`)
- File operations (`FileSystemService`, `FileDiscoveryService`)
- Safety and control (`LoopDetectionService`)

## Key Files

| File                         | Purpose                                                                                      | When to Modify                                                       |
| ---------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `modelConfigService.ts`      | Resolves model configurations through alias resolution and override matching                 | When adding model config aliases or override logic                   |
| `contextManager.ts`          | Manages three-tier context loading (global, environment, JIT subdirectory) from memory files | When modifying memory discovery or context injection                 |
| `chatRecordingService.ts`    | Records complete conversation history to JSON files in `~/.gemini/tmp/<project>/chats/`      | When adding new message types or metadata to recordings              |
| `shellExecutionService.ts`   | Executes shell commands with PTY support, streaming output, and process management           | When modifying shell execution behavior or terminal handling         |
| `gitService.ts`              | Manages shadow git repository for checkpointing and file snapshots                           | When adding git-based features or checkpoint functionality           |
| `fileDiscoveryService.ts`    | Filters files based on .gitignore and .geminiignore patterns                                 | When modifying file filtering or ignore logic                        |
| `fileSystemService.ts`       | Abstraction for file system operations (read/write)                                          | When adding file system operations or alternate implementations      |
| `loopDetectionService.ts`    | Detects infinite loops in AI responses (tool calls, content chanting, LLM-based detection)   | When tuning loop detection thresholds or adding detection strategies |
| `sessionSummaryService.ts`   | Generates AI-powered one-line summaries of chat sessions                                     | When modifying summary generation or prompt strategy                 |
| `chatCompressionService.ts`  | Compresses chat history when approaching token limits                                        | When modifying compression strategy or token thresholds              |
| `environmentSanitization.ts` | Sanitizes and redacts environment variables for shell execution                              | When modifying environment variable filtering or redaction rules     |

## Patterns

- **Class-based services**: Services use classes (not plain objects) for
  stateful resource management - reference `ChatRecordingService`,
  `LoopDetectionService`, `ShellExecutionService`
- **Dependency injection via constructor**: Services receive dependencies (like
  `Config`) in constructors - reference `ContextManager(config: Config)`
- **Interface abstractions for testability**: Services expose interfaces for
  alternate implementations - reference `FileSystemService` interface with
  `StandardFileSystemService` implementation
- **Singleton lifecycle via Config**: Services are instantiated once and
  accessed via Config getters - reference `config.getBaseLlmClient()`,
  `config.getToolRegistry()`
- **Async initialization pattern**: Services with setup requirements expose
  `initialize()` methods - reference `GitService.initialize()`,
  `ChatRecordingService.initialize()`
- **Graceful degradation**: Services handle missing dependencies or errors
  without crashing - reference `ShellExecutionService` PTY fallback to
  child_process
- **Event-driven streaming**: Services that produce output use callback
  patterns - reference `ShellExecutionService.execute(onOutputEvent)`

## Boundaries

- **DO**: Create services for stateful, cross-cutting concerns (configuration,
  recording, external interactions)
- **DO**: Use class-based patterns with constructors for dependency injection
- **DO**: Design services to be instantiated once and shared across application
  lifecycle
- **DO**: Implement graceful degradation when dependencies are unavailable
- **DO NOT**: Put UI logic in services - services are UI-agnostic and belong to
  @google/gemini-cli-core
- **DO NOT**: Directly import other services - use Config or dependency
  injection
- **DO NOT**: Create services for stateless utilities - use utils/ directory
  instead
- This module handles business logic and resource management, NOT utilities -
  utilities belong in `../utils/`
- This module handles infrastructure services, NOT tools - AI tool
  implementations belong in `../tools/`

## Relationships

- **Depends on**:
  - `../config/` - Config object provides dependency injection and configuration
  - `../utils/` - Stateless utility functions for git, file, text operations
  - `../core/` - Core AI orchestration types and interfaces
  - `@google/genai` - Google GenAI SDK for AI interactions
  - `ai` - Vercel AI SDK abstractions
- **Used by**:
  - `../core/geminiChat.ts` - Uses services via Config for AI orchestration
  - `../tools/*` - Tools use services via context parameter
  - `../config/config.ts` - Config instantiates and manages service lifecycle

## Adding New Services

1. Create service class in `services/[serviceName].ts`
2. Define constructor accepting dependencies (typically `Config`)
3. Implement `initialize()` method if async setup is required
4. Export service class and any interfaces/types from the file
5. Add service to `../config/config.ts`:
   - Add private property for service instance
   - Add getter method `get[ServiceName](): ServiceType`
   - Instantiate service in Config constructor
6. Export from `../index.ts` for package-level access
7. Add co-located test file `[serviceName].test.ts`

## Testing

- Test files co-located: `*.test.ts` next to service files
- Mock external dependencies (file system, git, AI SDK) using Vitest mocks
- Use `vi.mock()` with `async (importOriginal)` pattern for module mocking
- For services with Config dependencies, create test Config instances
- Test error handling and graceful degradation paths
- For streaming services (like `ShellExecutionService`), test callback
  invocation
- For stateful services (like `LoopDetectionService`), test state management and
  reset behavior
- Use `vi.spyOn()` to verify method calls on service instances

Example test pattern:

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MyService } from './myService.js';
import type { Config } from '../config/config.js';

describe('MyService', () => {
  let service: MyService;
  let mockConfig: Config;

  beforeEach(() => {
    mockConfig = {
      /* mock config */
    } as Config;
    service = new MyService(mockConfig);
  });

  it('should handle operation', async () => {
    // test implementation
  });
});
```
