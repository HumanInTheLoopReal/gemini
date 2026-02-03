# @google/gemini-cli-test-utils

Shared testing utilities for integration and unit tests across all packages.

## Package Purpose

Provides common test helpers for file system setup, integration testing, and
telemetry/tool call verification. Used for both unit tests and end-to-end
integration tests.

## Contents

```
src/
├── file-system-test-helpers.ts  # Temporary directory and file structure creation
├── test-rig.ts                  # TestRig class for integration testing
└── index.ts                     # Public exports
```

## Key Utilities

### File System Helpers

Create and manage temporary directories with a declarative structure:

```typescript
import { createTmpDir, cleanupTmpDir } from '@google/gemini-cli-test-utils';

// Create a temporary directory with files/subdirectories
const tmpDir = await createTmpDir({
  'package.json': '{ "name": "test" }',
  src: {
    'main.ts': '// main code',
    'utils.ts': '// utilities',
  },
  config: ['settings.json', 'defaults.json'],
});

// Use tmpDir for testing...

// Clean up when done
await cleanupTmpDir(tmpDir);
```

**Exports:**

- `createTmpDir(structure: FileSystemStructure): Promise<string>` — Creates
  temporary directory
- `cleanupTmpDir(dir: string): Promise<void>` — Deletes temporary directory and
  contents
- `FileSystemStructure` — Type definition for directory structure

### TestRig (Integration Testing)

Complete integration test harness for running the CLI and verifying behavior:

```typescript
import { TestRig } from '@google/gemini-cli-test-utils';

const rig = new TestRig();

// Setup
rig.setup('my test name', {
  settings: { sandbox: false },
  fakeResponsesPath: './fake-responses.json',
});

// Create files in test directory
rig.createFile('main.ts', 'console.log("hello")');
rig.mkdir('src');

// Run commands
const output = await rig.run({
  args: ['some-command', '--flag'],
  yolo: true,
});

// Verify tool calls via telemetry
await rig.waitForToolCall('read-file');
const toolLogs = rig.readToolLogs();
await rig.expectToolCallSuccess(['read-file']);

// Interactive testing
const interactive = await rig.runInteractive({ yolo: true });
await interactive.expectText('Enter message:');
await interactive.type('my input\r');
await interactive.expectExit();

// Cleanup
await rig.cleanup();
```

**Key Methods:**

- `setup(testName, options)` — Initialize test environment
- `run(options)` — Execute CLI command (returns stdout)
- `runCommand(args, options)` — Execute with specific args
- `runInteractive(options)` — Run in interactive mode
- `createFile(name, content)` — Create test file
- `mkdir(dir)` — Create test directory
- `readFile(name)` — Read test file content
- `waitForToolCall(toolName, timeout?, matchArgs?)` — Wait for tool execution
- `expectToolCallSuccess(toolNames, timeout?, matchArgs?)` — Assert tool
  succeeded
- `readToolLogs()` — Get all tool call telemetry
- `waitForTelemetryEvent(eventName, timeout?)` — Wait for telemetry event
- `readAllApiRequest()` — Get all API request logs
- `readLastApiRequest()` — Get most recent API request
- `waitForMetric(metricName, timeout?)` — Wait for metric telemetry
- `readMetric(metricName)` — Get metric value
- `readHookLogs()` — Get hook execution logs
- `cleanup()` — Cleanup test directories and processes

**InteractiveRun Methods:**

- `expectText(text, timeout?)` — Wait for text to appear in output
- `type(text)` — Type character by character with echo verification
- `sendText(text)` — Send text at once (may trigger paste detection)
- `sendKeys(text)` — Send keys with delay between characters
- `kill()` — Terminate process
- `expectExit()` — Wait for process exit

## Adding New Utilities

When adding shared test utilities:

1. Add to `src/` directory
2. Export from `src/index.ts`
3. Add proper TypeScript types and JSDoc comments
4. Document usage in this file and include examples

## Commands

```bash
npm run typecheck --workspace=@google/gemini-cli-test-utils  # Type check
```

## Notes

- This is a private package (not published)
- Used as dependency by integration tests and core tests
- TestRig handles sandbox environments (Docker, Podman) and telemetry parsing
- Timeouts are environment-aware (CI: 60s, Podman: 30s, local: 15s)
- Use `VERBOSE=true` or `KEEP_OUTPUT=true` environment variables for debugging
