# Common Operations

## Development Operations

### Operation: Initial Project Setup

**Scenario**: Setting up the Gemini CLI project for the first time on a new
development machine.

**Steps**:

1. Clone repository

   ```bash
   git clone https://github.com/google-gemini/gemini-cli.git
   cd gemini-cli
   ```

2. Install dependencies (Node.js 20+ required)

   ```bash
   npm install
   ```

3. Build the project

   ```bash
   npm run build
   ```

4. Verify installation
   ```bash
   npm start
   ```

**Expected Output**:

```
Gemini CLI starts and displays welcome screen
Interactive prompt appears for authentication
```

**Verification**:

```bash
npm start -- --version
```

---

### Operation: Pre-Commit Validation (Preflight Check)

**Scenario**: Running all quality checks before committing code changes or
opening a pull request. This is the single most important command for
contributors.

**Steps**:

1. Run the preflight command
   ```bash
   npm run preflight
   ```

This command executes sequentially:

- `npm run clean` — Remove build artifacts
- `npm ci` — Clean install dependencies
- `npm run format` — Run Prettier formatting
- `npm run build` — Compile TypeScript
- `npm run lint:ci` — Run ESLint
- `npm run typecheck` — TypeScript type checking
- `npm run test:ci` — Run all unit tests

**Expected Output**:

```
> @google/gemini-cli@0.26.0 preflight
✓ clean completed
✓ install completed
✓ format completed
✓ build completed
✓ lint completed
✓ typecheck completed
✓ test completed
```

**Verification**:

```bash
git status
# Should show only your intended changes, properly formatted
```

---

### Operation: Build Project After Code Changes

**Scenario**: Rebuilding the project after making code changes to test locally.

**Steps**:

1. Build all packages

   ```bash
   npm run build
   ```

2. (Optional) Build with sandbox container for full environment
   ```bash
   npm run build:all
   ```

**Expected Output**:

```
Packages compiled successfully to dist/ directories
```

**Verification**:

```bash
npm start
# CLI should launch with your changes
```

---

### Operation: Quick Code Formatting and Linting

**Scenario**: Formatting code and fixing lint issues before committing (faster
than full preflight).

**Steps**:

1. Format all code with Prettier

   ```bash
   npm run format
   ```

2. Run linter with auto-fix
   ```bash
   npm run lint:fix
   ```

**Expected Output**:

```
Files formatted and lint issues auto-fixed where possible
```

**Verification**:

```bash
npm run lint
# Should show no errors
```

---

### Operation: Clean Build Environment

**Scenario**: Resetting the build environment when encountering stale artifacts
or build issues.

**Steps**:

1. Clean all build artifacts

   ```bash
   npm run clean
   ```

2. Reinstall dependencies

   ```bash
   npm ci
   ```

3. Rebuild
   ```bash
   npm run build
   ```

**Expected Output**:

```
dist/ directories removed
node_modules reinstalled from lockfile
Fresh build completed
```

**Verification**:

```bash
npm start
```

---

## Core Operations

### Operation: Run Gemini CLI in Development Mode

**Scenario**: Running the CLI from source code for development and testing.

**Steps**:

1. Ensure project is built

   ```bash
   npm run build
   ```

2. Start in development mode
   ```bash
   npm start
   ```

**Expected Output**:

```
Gemini CLI interactive session starts
DEV environment variable set automatically
```

**Verification**:

```bash
# Within the CLI, type:
/about
# Should show development version info
```

---

### Operation: Run CLI with Specific Arguments

**Scenario**: Testing CLI with specific flags or in non-interactive (headless)
mode.

**Steps**:

1. Run with a prompt (non-interactive)

   ```bash
   npm start -- -p "Explain the architecture of this codebase"
   ```

2. Run with JSON output format

   ```bash
   npm start -- -p "List all files" --output-format json
   ```

3. Run with specific model
   ```bash
   npm start -- -m gemini-2.5-flash
   ```

**Expected Output**:

```json
{
  "status": "success",
  "response": "..."
}
```

---

### Operation: Configure Authentication for Development

**Scenario**: Setting up authentication to test the CLI with the Gemini API.

**Steps**:

1. Option A: Use API key

   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   npm start
   ```

2. Option B: Use OAuth login

   ```bash
   npm start
   # Select "Login with Google" when prompted
   ```

3. Option C: Use Vertex AI
   ```bash
   export GOOGLE_API_KEY="your-api-key"
   export GOOGLE_GENAI_USE_VERTEXAI=true
   npm start
   ```

**Expected Output**:

```
Authentication successful
Ready for prompts
```

**Verification**:

```bash
# Type a simple prompt to verify connectivity
> Hello, are you working?
```

---

### Operation: Enable Sandbox Mode for Safe Execution

**Scenario**: Running with sandboxing enabled for secure file and shell
operations.

**Steps**:

1. Set sandbox environment variable

   ```bash
   export GEMINI_SANDBOX=true
   ```

2. Build with sandbox container

   ```bash
   npm run build:all
   ```

3. Start CLI
   ```bash
   npm start
   ```

**Expected Output**:

```
CLI starts within sandbox container
File operations restricted to project directory
```

**Verification**:

```bash
# Check sandbox status in CLI
/settings
# Should show sandbox: enabled
```

---

## Testing Operations

### Operation: Run Unit Tests

**Scenario**: Running the unit test suite for `packages/core` and
`packages/cli`.

**Steps**:

1. Run all unit tests

   ```bash
   npm run test
   ```

2. Run tests for a specific file

   ```bash
   npm run test -- packages/cli/src/path/to/file.test.ts
   ```

3. Run tests with coverage
   ```bash
   npm run test:ci
   ```

**Expected Output**:

```
✓ packages/core tests passed
✓ packages/cli tests passed

Test Suites: X passed, X total
Tests:       Y passed, Y total
```

**Verification**:

```bash
echo $?
# Exit code 0 indicates all tests passed
```

---

### Operation: Run Integration (E2E) Tests

**Scenario**: Running end-to-end integration tests that validate full CLI
functionality.

**Steps**:

1. Run integration tests without sandbox

   ```bash
   npm run test:e2e
   ```

2. Run integration tests with Docker sandbox

   ```bash
   npm run test:integration:sandbox:docker
   ```

3. Run integration tests with Podman sandbox
   ```bash
   npm run test:integration:sandbox:podman
   ```

**Expected Output**:

```
Integration Tests:
✓ file-system tests
✓ shell command tests
✓ json-output tests
...
All integration tests passed
```

**Verification**:

```bash
# Check test output logs
VERBOSE=true KEEP_OUTPUT=true npm run test:e2e
```

---

### Operation: Debug Flaky Tests

**Scenario**: Identifying and debugging intermittently failing tests.

**Steps**:

1. Run deflake script to detect flaky tests

   ```bash
   npm run deflake -- --command="npm run test:integration:sandbox:none -- --retry=0"
   ```

2. Run specific test file with verbose output
   ```bash
   VERBOSE=true npm run test -- packages/cli/src/path/to/flaky.test.ts
   ```

**Expected Output**:

```
Test run 1: PASS
Test run 2: PASS
Test run 3: FAIL  <-- Flaky test identified
...
```

---

### Operation: Run Tests for Specific Package

**Scenario**: Running tests only for the package you're working on.

**Steps**:

1. Run core package tests

   ```bash
   npm run test --workspace @google/gemini-cli-core
   ```

2. Run CLI package tests
   ```bash
   npm run test --workspace @google/gemini-cli
   ```

**Expected Output**:

```
All tests in specified workspace pass
```

---

## Debugging Operations

### Operation: Debug CLI with VS Code

**Scenario**: Stepping through CLI code with VS Code debugger.

**Steps**:

1. Start CLI in debug mode

   ```bash
   npm run debug
   ```

2. In VS Code, open the Debug panel (F5 or Cmd+Shift+D)

3. Select "Attach" configuration

4. Connect debugger to Node.js process

**Expected Output**:

```
Debugger listening on ws://127.0.0.1:9229/...
For help, see: https://nodejs.org/en/docs/inspector
```

**Verification**:

```bash
# Set a breakpoint in VS Code and verify it's hit
# Alternatively, open chrome://inspect in Chrome
```

---

### Operation: Debug with React DevTools

**Scenario**: Debugging the React/Ink terminal UI components.

**Steps**:

1. Start CLI in development mode

   ```bash
   DEV=true npm start
   ```

2. In another terminal, run React DevTools

   ```bash
   npx react-devtools@4.28.5
   ```

3. DevTools should connect automatically to the running CLI

**Expected Output**:

```
React DevTools window opens
Component tree visible
```

**Verification**:

```bash
# Inspect component state in DevTools
# Components should reflect CLI UI state
```

---

### Operation: Enable Development Tracing

**Scenario**: Capturing OpenTelemetry traces for debugging agent behavior.

**Steps**:

1. Start telemetry collector (Genkit option)

   ```bash
   npm run telemetry -- --target=genkit
   ```

2. In another terminal, run CLI with tracing

   ```bash
   GEMINI_DEV_TRACING=true npm start
   ```

3. Open Genkit UI in browser (typically http://localhost:4000)

**Expected Output**:

```
Genkit Developer UI: http://localhost:4000
Traces visible in UI showing model calls, tool execution, etc.
```

**Verification**:

```bash
# Execute a command and check traces appear in UI
```

---

### Operation: Debug with Jaeger Tracing

**Scenario**: Using Jaeger for distributed tracing visualization.

**Steps**:

1. Start Jaeger and OTEL collector

   ```bash
   npm run telemetry -- --target=local
   ```

2. Run CLI with tracing enabled

   ```bash
   GEMINI_DEV_TRACING=true npm start
   ```

3. Open Jaeger UI (typically http://localhost:16686)

**Expected Output**:

```
Jaeger UI shows traces
Service: gemini-cli visible
Spans show model calls, tool execution timeline
```

---

### Operation: Troubleshoot Module Not Found Errors

**Scenario**: Fixing import errors or missing module issues after code changes.

**Steps**:

1. Clean and reinstall

   ```bash
   npm run clean
   npm ci
   ```

2. Rebuild project

   ```bash
   npm run build
   ```

3. Verify TypeScript compilation
   ```bash
   npm run typecheck
   ```

**Expected Output**:

```
No TypeScript errors
Module imports resolve correctly
```

**Verification**:

```bash
npm start
# CLI starts without import errors
```

---

### Operation: Debug Sandbox Permission Issues

**Scenario**: Troubleshooting "Operation not permitted" errors when sandboxing
is enabled.

**Steps**:

1. Check current sandbox configuration

   ```bash
   echo $GEMINI_SANDBOX
   ```

2. Temporarily disable sandbox for debugging

   ```bash
   GEMINI_SANDBOX=false npm start
   ```

3. If macOS, check Seatbelt profile

   ```bash
   echo $SEATBELT_PROFILE
   # Default: permissive-open
   ```

4. Check sandbox logs for restricted operations
   ```bash
   # Look for sandbox-related errors in CLI output
   ```

**Expected Output**:

```
With sandbox disabled, operations should succeed
Helps identify which operations are being blocked
```

**Verification**:

```bash
# Re-enable sandbox after identifying the issue
export GEMINI_SANDBOX=true
# Adjust sandbox configuration as needed
```

---

### Operation: Check CLI Exit Codes

**Scenario**: Understanding why the CLI exited with an error in automation
scripts.

**Steps**:

1. Run CLI command

   ```bash
   npm start -- -p "some command"
   ```

2. Check exit code

   ```bash
   echo $?
   ```

3. Reference exit code meanings:

| Exit Code | Error Type               | Description                        |
| --------- | ------------------------ | ---------------------------------- |
| 0         | Success                  | Command completed successfully     |
| 41        | FatalAuthenticationError | Authentication failed              |
| 42        | FatalInputError          | Invalid input (headless mode)      |
| 44        | FatalSandboxError        | Sandbox environment error          |
| 52        | FatalConfigError         | Invalid settings.json              |
| 53        | FatalTurnLimitedError    | Turn limit reached (headless mode) |

**Expected Output**:

```
Exit code maps to specific error type
```

**Verification**:

```bash
# Fix the underlying issue based on exit code
# Re-run command to verify
```

---

### Operation: View Debug Console in Interactive Mode

**Scenario**: Accessing the debug console while running the CLI interactively.

**Steps**:

1. Start CLI normally

   ```bash
   npm start
   ```

2. Press F12 to open debug console

3. View debug output and logs

**Expected Output**:

```
Debug panel opens showing internal logs
API calls, tool executions visible
```

**Verification**:

```bash
# Debug info should update as you interact with CLI
```
