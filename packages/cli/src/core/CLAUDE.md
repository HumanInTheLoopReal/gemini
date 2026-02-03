# CLI Core

Handles application startup initialization, authentication setup, and theme
validation. Runs before the React UI is rendered to establish a valid
application state.

## Architecture

The core module orchestrates three independent startup concerns:

1. **Authentication** (`auth.ts`) - Validates and refreshes auth credentials for
   the selected auth type
2. **Theme Validation** (`theme.ts`) - Ensures the configured theme exists in
   the theme registry
3. **Initialization** (`initializer.ts`) - Orchestrates the above and configures
   IDE mode if enabled

The module runs asynchronously and sequentially before React renders, ensuring
all initialization errors are caught and reported before the UI is shown.

## Key Files

| File                  | Purpose                                                        | When to Modify                                                     |
| --------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------ |
| `initializer.ts`      | Orchestrates app startup, logs config, enables IDE mode        | When adding new startup checks or changing initialization order    |
| `auth.ts`             | Handles initial credential refresh for selected auth type      | When changing authentication flow or error handling                |
| `theme.ts`            | Validates theme exists before rendering                        | When adding theme validation logic or integrating new theme system |
| `initializer.test.ts` | Tests initialization flow, IDE mode, auth/theme error handling | When modifying initialization behavior                             |
| `auth.test.ts`        | Tests auth null/success/error cases                            | When changing auth logic                                           |
| `theme.test.ts`       | Tests theme validation with existing/missing themes            | When modifying theme validation                                    |

## Patterns

- **No side effects during mocking**: Auth and theme validators are mocked in
  initializer tests to isolate initialization logic
- **Error aggregation**: `InitializationResult` collects both auth and theme
  errors, allowing UI to show all problems at once
- **Early validation**: Authentication and theme are validated before IDE
  connection to fail fast
- **Profiling instrumentation**: Startup profiler wraps auth step to track
  initialization performance
- **Context metadata collection**: `InitializationResult` includes
  `geminiMdFileCount` from config for UI context display

## Boundaries

- **DO**: Handle startup concerns only (auth, theme, IDE connection setup)
- **DO NOT**: Perform actual auth API calls or network requests beyond
  `config.refreshAuth()` - use the config object as the API boundary
- **DO NOT**: Render any UI components - this module runs before React is
  initialized
- **DO NOT**: Load settings or config directly - these are passed in via
  parameters

- This module orchestrates **initialization only**, NOT ongoing auth
  management - session refresh and token handling belong in
  `@google/gemini-cli-core`
- This module validates the **applied theme**, NOT theme definitions - theme
  registry and metadata belong in `../ui/themes/`
- This module handles **startup errors**, NOT recovery - UI dialogs and user
  recovery flows belong in `../ui/auth/`

## Relationships

- **Depends on**:
  - `@google/gemini-cli-core` - `Config`, auth types, error utilities, IDE
    client, startup profiler, logging
  - `../config/settings.js` - `LoadedSettings` interface for merged
    configuration
  - `../ui/themes/theme-manager.js` - Theme registry lookup via
    `themeManager.findThemeByName()`

- **Used by**:
  - `../gemini.tsx` (main app) - Calls `initializeApp()` before rendering React
    tree
  - Returns initialization results to be displayed in auth dialog if needed

## Adding New Startup Check

1. Create a new validation function (e.g.,
   `validateSomething(settings): string | null`)
2. Add the check to `initializeApp()` before returning `InitializationResult`
3. Add a new field to `InitializationResult` interface
4. Pass error/status to the UI via the result object
5. Update tests in corresponding `.test.ts` file to mock the new validator

## Testing

### How to test this module

- Run `npm test --workspace=@google/gemini-cli` to test all CLI modules
- Run specific test with `npm test -- initializer.test.ts` to isolate this
  module's tests

### Key test utilities

- `vitest` for test framework and mocking
- `vi.mock()` for mocking `@google/gemini-cli-core`, auth, and theme modules
- `vi.mocked()` to access mock implementations for assertions

### What to mock, what not to mock

**Mock these**:

- `@google/gemini-cli-core` - Use test doubles for Config, logging functions,
  IDE client
- `./auth.js` - Mock `performInitialAuth` to return null or error strings
- `./theme.js` - Mock `validateTheme` to return null or error strings

**Don't mock these**:

- When testing `auth.ts`, don't mock `@google/gemini-cli-core.getErrorMessage` -
  test the actual error formatting
- When testing `theme.ts`, don't mock the `LoadedSettings` parameter - pass
  real-like test objects

### Example test pattern

```typescript
import { vi } from 'vitest';
import { initializeApp } from './initializer.js';

vi.mock('./auth.js', () => ({
  performInitialAuth: vi.fn().mockResolvedValue(null), // success case
}));

// Test error case by:
vi.mocked(performInitialAuth).mockResolvedValue('Auth failed');
```
