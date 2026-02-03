# Testing

## Testing Philosophy

Gemini CLI follows a **behavior-focused testing approach** that prioritizes
verifying WHAT the code does rather than HOW it does it internally. Tests are
designed to validate functionality from a user's perspective, ensuring
components work correctly in isolation and integrate properly across packages.

The project maintains comprehensive test coverage across its monorepo structure,
with unit tests co-located alongside source files and integration tests
validating end-to-end functionality. External dependencies (Gemini API, file
system, shell execution) are mocked at appropriate boundaries, while internal
business logic is tested with real implementations to ensure correctness.

Key principles:

- **Test behavior, not implementation**: Focus on inputs and outputs, not
  internal mechanics
- **Mock boundaries, not internals**: Mock external APIs, file system, and
  network calls; test real business logic
- **Fast and isolated**: Each test verifies one specific behavior without
  depending on test execution order
- **Co-located tests**: Test files live next to their source files for easy
  navigation
- **Parallel execution**: Tests run concurrently with 8-16 threads for fast
  feedback

## Test Levels

### Unit Tests

<location>
- `packages/core/src/**/*.test.ts` - Core package unit tests
- `packages/cli/src/**/*.test.ts` and `*.test.tsx` - CLI package unit tests
- `packages/a2a-server/src/**/*.test.ts` - A2A server unit tests
- `packages/test-utils/` - Shared testing utilities
</location>

<purpose>
Test individual functions, classes, hooks, and components in isolation. Unit tests verify that modules behave correctly given specific inputs without requiring external services.
</purpose>

<scope>
- Business logic functions and transformations
- Tool implementations (read-file, write-file, shell, glob, grep)
- React/Ink UI components
- Custom hooks and context providers
- Configuration parsing and validation
- Policy engine rules
- Hook system aggregation and execution
</scope>

<runtime>
~30 seconds timeout per test; full unit suite runs in parallel with 8-16 threads.
</runtime>

<what_is_mocked>

- `@google/genai` - Gemini API client responses
- `node:fs` and `node:fs/promises` - File system operations
- `node:child_process` - Shell execution
- `@modelcontextprotocol/sdk` - MCP server interactions
- Environment variables and configuration
- Time/timers with `vi.useFakeTimers()` </what_is_mocked>

<what_is_not_mocked>

- Business logic functions
- Zod validation schemas
- Text processing utilities
- Internal calculations and transformations
- React component rendering (tested with ink-testing-library)
  </what_is_not_mocked>

### Integration Tests

<location>
- `integration-tests/` directory at repository root
- Configuration: `integration-tests/vitest.config.ts`
- Global setup: `integration-tests/globalSetup.ts`
</location>

<purpose>
Test the CLI end-to-end by spawning actual processes and verifying tool calls, telemetry events, and output. Integration tests validate that all components work together correctly.
</purpose>

<environments>
- **No sandbox** (`GEMINI_SANDBOX=false`): Tests run directly on host
- **Docker sandbox** (`GEMINI_SANDBOX=docker`): Tests run in Docker container
- **Podman sandbox** (`GEMINI_SANDBOX=podman`): Tests run in Podman container
</environments>

<runtime>
5 minute timeout per test; tests retry up to 2 times on failure.
</runtime>

<what_is_tested>

- Full request/response cycles with fake model responses
- Tool execution (file operations, shell commands, web fetch)
- Telemetry event emission and logging
- Interactive terminal sessions (PTY-based)
- Hook system integration
- Settings and configuration loading </what_is_tested>

<how_to_run>

```bash
# Without sandbox (fastest, most common)
npm run test:integration:sandbox:none

# With Docker sandbox
npm run test:integration:sandbox:docker

# With Podman sandbox
npm run test:integration:sandbox:podman

# All sandbox modes
npm run test:integration:all
```

</how_to_run>

### End-to-End Tests (E2E)

<location>
The E2E tests are the same as integration tests, run via the `test:e2e` script.
</location>

<purpose>
Alias for integration tests with verbose output enabled.
</purpose>

<how_to_run>

```bash
npm run test:e2e  # Runs test:integration:sandbox:none with VERBOSE=true KEEP_OUTPUT=true
```

</how_to_run>

## Test Structure

### Directory Organization

Tests are co-located with source files in a mirrored structure:

```
packages/
├── core/
│   ├── vitest.config.ts          # Core package test configuration
│   ├── test-setup.ts             # Global test setup (429 simulation, NO_COLOR)
│   └── src/
│       ├── agents/
│       │   ├── agentLoader.ts
│       │   └── agentLoader.test.ts
│       ├── core/
│       │   ├── geminiChat.ts
│       │   └── geminiChat.test.ts
│       ├── hooks/
│       │   ├── hookSystem.ts
│       │   └── hookSystem.test.ts
│       ├── tools/
│       │   ├── shellTool.ts
│       │   └── shellTool.test.ts
│       └── test-utils/           # Core-specific test utilities
│           ├── mock-message-bus.ts
│           └── testUtils.ts
│
├── cli/
│   ├── vitest.config.ts          # CLI package test configuration
│   ├── test-setup.ts             # React act() warning enforcement
│   └── src/
│       ├── services/
│       │   ├── CommandService.ts
│       │   └── CommandService.test.ts
│       ├── ui/
│       │   ├── auth/
│       │   │   ├── useAuth.ts
│       │   │   └── useAuth.test.tsx
│       │   └── components/
│       │       ├── Composer.tsx
│       │       └── Composer.test.tsx
│       └── test-utils/           # CLI-specific test utilities
│           ├── render.tsx        # Custom render with providers
│           ├── customMatchers.ts # Vitest custom matchers
│           └── mockCommandContext.ts
│
├── test-utils/                   # Shared test utilities package
│   └── src/
│       ├── file-system-test-helpers.ts  # Temp directory creation
│       ├── test-rig.ts                  # Integration test harness
│       └── index.ts
│
└── integration-tests/
    ├── vitest.config.ts          # Integration test config
    ├── globalSetup.ts            # Test environment setup
    ├── test-helper.js            # Re-exports from test-utils
    ├── file-system.test.ts       # File system tool tests
    ├── hooks-system.test.ts      # Hook system integration tests
    └── run_shell_command.test.ts # Shell execution tests
```

### Naming Conventions

<test_files>

- Unit tests: `{source-file}.test.ts` or `{source-file}.test.tsx`
- Examples: `geminiChat.test.ts`, `Composer.test.tsx`, `useAuth.test.tsx`
  </test_files>

<test_functions>

```typescript
// Pattern: test_{behavior}_{condition}
it('should load commands from a single loader', async () => { ... });
it('should transition to AwaitingApiKeyInput if USE_GEMINI and no key found', async () => { ... });
it('should fail safely when trying to edit a non-existent file', async () => { ... });
```

</test_functions>

<test_suites>

```typescript
// Use describe blocks for logical grouping
describe('CommandService', () => {
  describe('loading', () => { ... });
  describe('conflict resolution', () => { ... });
});

describe('useAuth', () => {
  describe('validateAuthMethodWithSettings', () => { ... });
  describe('useAuthCommand', () => { ... });
});
```

</test_suites>

### Test Configuration

<vitest_config> Each package has its own `vitest.config.ts`:

```typescript
// packages/core/vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    reporters: ['default', 'junit'],
    timeout: 30000,
    silent: true,
    setupFiles: ['./test-setup.ts'],
    outputFile: {
      junit: 'junit.xml',
    },
    coverage: {
      enabled: true,
      provider: 'v8',
      reportsDirectory: './coverage',
      include: ['src/**/*'],
      reporter: ['text', 'html', 'json', 'lcov', 'cobertura'],
    },
    poolOptions: {
      threads: {
        minThreads: 8,
        maxThreads: 16,
      },
    },
  },
});
```

</vitest_config>

<key_settings>

- **Parallel execution**: 8-16 threads for fast test runs
- **30 second timeout**: Default timeout for unit tests
- **5 minute timeout**: Integration tests use extended timeout
- **JUnit output**: `junit.xml` for CI integration
- **Coverage reports**: HTML, JSON, LCOV, Cobertura formats </key_settings>

## Running Tests

### Quick Commands

```bash
# Run all unit tests (core + cli packages)
npm run test

# Run unit tests for CI (includes coverage)
npm run test:ci

# Run specific package tests
npm test --workspace=@google/gemini-cli-core
npm test --workspace=@google/gemini-cli

# Run integration tests (no sandbox)
npm run test:e2e
npm run test:integration:sandbox:none

# Run integration tests with Docker sandbox
npm run test:integration:sandbox:docker

# Run all test types
npm run preflight  # Includes build, lint, typecheck, and tests
```

### Running Specific Tests

```bash
# Run specific test file
npm run test -- packages/core/src/hooks/hookSystem.test.ts

# Run tests matching pattern
npm run test -- --grep="should load commands"

# Run tests in watch mode (development)
npm run test -- --watch

# Run single integration test
npm run test:integration:sandbox:none -- integration-tests/file-system.test.ts
```

### Coverage Reports

```bash
# Generate coverage (included in test:ci)
npm run test:ci

# View HTML coverage report (after test run)
open packages/core/coverage/index.html
open packages/cli/coverage/index.html
```

<coverage_output> Coverage reports are generated in each package's `coverage/`
directory:

- `full-text-summary.txt` - Text summary
- `index.html` - Interactive HTML report
- `coverage-summary.json` - JSON summary
- `lcov.info` - LCOV format for CI tools
- `cobertura-coverage.xml` - Cobertura format </coverage_output>

### Debugging Tests

```bash
# Verbose output
npm run test -- --reporter=verbose

# Show console output
npm run test -- --silent=false

# Stop at first failure
npm run test -- --bail

# Integration test debugging
VERBOSE=true KEEP_OUTPUT=true npm run test:integration:sandbox:none
```

<debug_environment_variables>

- `VERBOSE=true` - Show detailed test output
- `KEEP_OUTPUT=true` - Preserve test output directories for inspection
- `REGENERATE_MODEL_GOLDENS=true` - Update fake model response fixtures
  </debug_environment_variables>

### CI/CD Integration

<when_tests_run>

- **Every commit**: Unit tests via `npm run test:ci`
- **Pull requests**: Full preflight check (`npm run preflight`)
- **Pre-merge**: Must pass all tests </when_tests_run>

<pipeline_stages>

1. `npm run preflight` - Clean, install, format, build, lint, typecheck, test
2. Unit tests generate JUnit XML reports for CI parsing
3. Coverage reports published as artifacts </pipeline_stages>

## Testing Patterns

### Mocking External APIs

<pattern_vi_mock> Use `vi.mock()` at the top of test files for module-level
mocks:

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock at module level before imports
vi.mock('@google/gemini-cli-core', async (importOriginal) => {
  const actual =
    await importOriginal<typeof import('@google/gemini-cli-core')>();
  return {
    ...actual,
    loadApiKey: () => mockLoadApiKey(),
  };
});

// For mocks needed in vi.mock() factory functions
const { mockHandleFallback } = vi.hoisted(() => ({
  mockHandleFallback: vi.fn(),
}));

vi.mock('../fallback/handler.js', () => ({
  handleFallback: mockHandleFallback,
}));
```

</pattern_vi_mock>

<pattern_mock_fs> Mock file system operations:

```typescript
const mockFileSystem = new Map<string, string>();

vi.mock('node:fs', () => ({
  mkdirSync: vi.fn(),
  writeFileSync: vi.fn((path: string, data: string) => {
    mockFileSystem.set(path, data);
  }),
  readFileSync: vi.fn((path: string) => {
    if (mockFileSystem.has(path)) {
      return mockFileSystem.get(path);
    }
    throw Object.assign(new Error('ENOENT'), { code: 'ENOENT' });
  }),
  existsSync: vi.fn((path: string) => mockFileSystem.has(path)),
}));
```

</pattern_mock_fs>

### Testing React/Ink Components

<pattern_render> Use `ink-testing-library` with custom render utilities:

```typescript
import { render, renderWithProviders } from '../../test-utils/render.js';

describe('MyComponent', () => {
  it('renders content', () => {
    const { lastFrame } = render(<MyComponent title="Test" />);
    expect(lastFrame()).toContain('Test');
  });

  it('works with providers', () => {
    const { lastFrame } = renderWithProviders(
      <MyComponent />,
      {
        settings: mockSettings,
        uiState: { streamingState: StreamingState.Idle },
        width: 80,
      }
    );
    expect(lastFrame()).toBeDefined();
  });
});
```

</pattern_render>

<pattern_hooks> Test custom hooks with `renderHook`:

```typescript
import { renderHook } from '../../test-utils/render.js';
import { waitFor } from '../../test-utils/async.js';

describe('useAuthCommand', () => {
  it('should initialize with Unauthenticated state', () => {
    const { result } = renderHook(() =>
      useAuthCommand(createSettings(AuthType.LOGIN_WITH_GOOGLE), mockConfig),
    );
    expect(result.current.authState).toBe(AuthState.Unauthenticated);
  });

  it('should transition states asynchronously', async () => {
    const { result } = renderHook(() => useAuthCommand(settings, config));

    await waitFor(() => {
      expect(result.current.authState).toBe(AuthState.Authenticated);
    });
  });
});
```

</pattern_hooks>

### Integration Test Patterns

<pattern_test_rig> Use `TestRig` for integration tests:

```typescript
import { TestRig, printDebugInfo, validateModelOutput } from './test-helper.js';

describe('file-system', () => {
  let rig: TestRig;

  beforeEach(() => {
    rig = new TestRig();
  });

  afterEach(async () => await rig.cleanup());

  it('should be able to read a file', async () => {
    // Setup test environment
    await rig.setup('should be able to read a file', {
      settings: { tools: { core: ['read_file'] } },
    });

    // Create test files
    rig.createFile('test.txt', 'hello world');

    // Run CLI command
    const result = await rig.run({
      args: `read the file test.txt`,
    });

    // Wait for and verify tool calls via telemetry
    const foundToolCall = await rig.waitForToolCall('read_file');
    expect(foundToolCall).toBeTruthy();

    // Validate output
    validateModelOutput(result, 'hello world', 'File read test');
  });
});
```

</pattern_test_rig>

<pattern_interactive> Test interactive sessions with PTY:

```typescript
it('should handle interactive input', async () => {
  await rig.setup('interactive test');

  const interactive = await rig.runInteractive({ yolo: true });

  // Wait for prompt
  await interactive.expectText('Type your message');

  // Type input
  await interactive.type('hello world\r');

  // Verify response
  await interactive.expectText('Response received');

  // Clean exit
  await interactive.expectExit();
});
```

</pattern_interactive>

### Fixture Usage

<pattern_fixtures> Create reusable test fixtures:

```typescript
// Create mock command
const createMockCommand = (name: string, kind: CommandKind): SlashCommand => ({
  name,
  description: `Description for ${name}`,
  kind,
  action: vi.fn(),
});

// Create mock loader
class MockCommandLoader implements ICommandLoader {
  private commandsToLoad: SlashCommand[];

  constructor(commandsToLoad: SlashCommand[]) {
    this.commandsToLoad = commandsToLoad;
  }

  loadCommands = vi.fn(async () => Promise.resolve(this.commandsToLoad));
}

// Use in tests
const mockCommandA = createMockCommand('command-a', CommandKind.BUILT_IN);
const mockLoader = new MockCommandLoader([mockCommandA]);
```

</pattern_fixtures>

<pattern_temp_files> Use file system helpers for temporary directories:

```typescript
import { createTmpDir, cleanupTmpDir } from '@google/gemini-cli-test-utils';

describe('file operations', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTmpDir({
      'package.json': '{ "name": "test" }',
      src: {
        'main.ts': '// main code',
        'utils.ts': '// utilities',
      },
    });
  });

  afterEach(async () => {
    await cleanupTmpDir(tmpDir);
  });

  it('reads project structure', () => {
    // tmpDir now contains the specified file structure
  });
});
```

</pattern_temp_files>

### Async Testing

<pattern_async> Handle async operations correctly:

```typescript
import { vi, beforeEach, afterEach } from 'vitest';

describe('async tests', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('handles async operations', async () => {
    const promise = asyncOperation();

    // Advance timers
    await vi.advanceTimersByTimeAsync(1000);

    const result = await promise;
    expect(result).toBeDefined();
  });

  it('handles rejections', async () => {
    await expect(failingOperation()).rejects.toThrow('Expected error');
  });
});
```

</pattern_async>

## Best Practices

### Writing Good Tests

<do>
- ✅ Test one behavior per test function
- ✅ Use descriptive test names: `it('should transition to AwaitingApiKeyInput if USE_GEMINI and no key found')`
- ✅ Follow Arrange-Act-Assert pattern
- ✅ Mock external dependencies (APIs, file system, network)
- ✅ Use fixtures for reusable test setup
- ✅ Test happy path first, then edge cases
- ✅ Keep tests fast and isolated
- ✅ Use `vi.resetAllMocks()` in `beforeEach` and `vi.restoreAllMocks()` in `afterEach`
- ✅ Place `vi.mock()` at file top, before imports
- ✅ Use `vi.hoisted()` for mock functions needed in `vi.mock()` factories
</do>

<dont>
- ❌ Mock internal business logic
- ❌ Test implementation details (private methods)
- ❌ Share state between tests
- ❌ Use actual sleep/delays (use fake timers)
- ❌ Assert multiple unrelated things in one test
- ❌ Rely on external services in unit tests
- ❌ Use `console.log` in tests (use `debugLogger` if needed)
- ❌ Skip the act() wrapper when testing React components
</dont>

### Test Structure Template

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mocks at top of file
vi.mock('dependency', () => ({ ... }));

describe('ModuleName', () => {
  // Setup and teardown
  beforeEach(() => {
    vi.resetAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('functionName', () => {
    it('should behave correctly when given valid input', () => {
      // Arrange: Set up test data and mocks
      const input = createTestInput();
      const mockDep = setupMock();

      // Act: Execute the behavior being tested
      const result = functionUnderTest(input, mockDep);

      // Assert: Verify expected outcome
      expect(result.status).toBe('success');
      expect(mockDep.method).toHaveBeenCalledWith(expected);
    });

    it('should handle error conditions', async () => {
      // Test error scenarios
      await expect(failingCall()).rejects.toThrow('Expected error');
    });
  });
});
```

### Common Scenarios

<scenario_api_endpoints> Testing service methods:

```typescript
it('should load commands from multiple loaders', async () => {
  const loader1 = new MockCommandLoader([mockCommandA]);
  const loader2 = new MockCommandLoader([mockCommandC]);

  const service = await CommandService.create(
    [loader1, loader2],
    new AbortController().signal,
  );

  const commands = service.getCommands();

  expect(commands).toHaveLength(2);
  expect(loader1.loadCommands).toHaveBeenCalledTimes(1);
});
```

</scenario_api_endpoints>

<scenario_error_handling> Testing error conditions:

```typescript
it('should handle loader failures gracefully', async () => {
  const successfulLoader = new MockCommandLoader([mockCommandA]);
  const failingLoader = new MockCommandLoader([]);
  vi.spyOn(failingLoader, 'loadCommands').mockRejectedValue(
    new Error('Loader failed'),
  );

  const service = await CommandService.create(
    [successfulLoader, failingLoader],
    new AbortController().signal,
  );

  // Should still return commands from successful loader
  expect(service.getCommands()).toHaveLength(1);
});
```

</scenario_error_handling>

<scenario_react_state> Testing React state changes:

```typescript
it('should update state on auth success', async () => {
  mockLoadApiKey.mockResolvedValue('stored-key');

  const { result } = renderHook(() =>
    useAuthCommand(createSettings(AuthType.USE_GEMINI), mockConfig),
  );

  await waitFor(() => {
    expect(mockConfig.refreshAuth).toHaveBeenCalledWith(AuthType.USE_GEMINI);
    expect(result.current.authState).toBe(AuthState.Authenticated);
  });
});
```

</scenario_react_state>

### Maintaining Tests

<when_to_update>

- Behavior changes (not internal refactoring)
- New features added
- Bug fixes (add regression test)
- API contracts change </when_to_update>

<avoiding_brittle_tests>

- Don't test implementation details
- Use semantic assertions (not exact string matching when possible)
- Mock stable contracts, not internals
- Keep test data minimal and relevant </avoiding_brittle_tests>

### Test Coverage Goals

<coverage_targets>

- Coverage is automatically collected via V8 provider
- Reports generated in multiple formats for different tooling
- Focus on testing behavior rather than chasing coverage numbers
  </coverage_targets>

<what_not_to_test>

- Auto-generated code (migrations, schemas)
- Third-party library internals
- Framework code
- Simple getters/setters without logic </what_not_to_test>

## Common Pitfalls

<pitfall name="Mocking too much">
**Problem**: Tests don't verify real behavior, only mock interactions
**Solution**: Only mock external boundaries; test real business logic
</pitfall>

<pitfall name="Tests depend on execution order">
**Problem**: Tests fail randomly when run in different order
**Solution**: Use `beforeEach`/`afterEach` to reset state; don't share mutable state between tests
</pitfall>

<pitfall name="Tests are slow">
**Problem**: Developers skip running tests
**Solution**: Mock external calls; use fake timers; avoid real network/file operations
</pitfall>

<pitfall name="Unclear test failures">
**Problem**: Hard to debug what went wrong
**Solution**: Use descriptive test names; use `printDebugInfo()` helper in integration tests
</pitfall>

<pitfall name="React act() warnings">
**Problem**: Tests fail with "not wrapped in act()" warnings
**Solution**: CLI test setup enforces act() warnings as errors; use the custom `render()` wrapper from test-utils
</pitfall>

<pitfall name="Forgetting to clean up">
**Problem**: Test artifacts accumulate; tests interfere with each other
**Solution**: Use `afterEach` with cleanup functions; use `TestRig.cleanup()` in integration tests
</pitfall>

## Related Documentation

- **Architecture**: See `.alfred/docs/architecture.md` for understanding what to
  test
- **Development Setup**: See repository root `CLAUDE.md` for build and run
  commands
- **Test Utilities Package**: See `packages/test-utils/CLAUDE.md` for detailed
  utility documentation
