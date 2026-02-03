# Configuration Module

Centralized configuration management for Gemini CLI including application
settings, model configurations, storage paths, and runtime options. This module
is the single source of truth for all configuration state across the
application.

## Architecture

The module is organized around several key responsibilities:

- **Config**: The main `Config` class (1967 lines) holds all application state
  and provides access to registries, services, and configuration values
- **Storage**: Path resolution for user data, settings, and workspace-specific
  files
- **Models**: Model name constants, aliases, and resolution logic (e.g., `auto`
  to concrete model names)
- **DefaultModelConfigs**: Hierarchical model configurations with inheritance
  (base configs, overrides, specialized configs)
- **Constants**: Shared constants like file filtering defaults

The `Config` class follows a two-phase initialization pattern:

1. Constructor sets up basic state and creates synchronous dependencies
2. `initialize()` async method loads registries, starts MCP servers, and
   initializes the AI client

## Key Files

| File                     | Purpose                                                           | When to Modify                                                          |
| ------------------------ | ----------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `config.ts`              | Main Config class with 1967 lines of state and accessors          | When adding new configuration parameters or runtime state               |
| `storage.ts`             | Path resolution for global/workspace settings, temp dirs, history | When adding new storage locations or changing directory structure       |
| `models.ts`              | Model name constants, aliases, resolution functions               | When adding new models or changing model selection logic                |
| `defaultModelConfigs.ts` | Hierarchical model configs with base/chat/specialized settings    | When changing default model parameters or adding model-specific configs |
| `constants.ts`           | File filtering options and shared constants                       | When adding new shared constants                                        |

## Patterns

- **Lazy Initialization**: Services like `FileDiscoveryService` and `GitService`
  are created on first access, not in constructor
- **Two-Phase Init**: Constructor is synchronous, `initialize()` is async - this
  allows Config to be passed around before full initialization
- **Centralized State**: All application state flows through Config - no global
  variables, everything is accessed via getters
- **Immutable After Init**: Most config values are `readonly` and set in
  constructor from `ConfigParameters`
- **Storage Abstraction**: `Storage` class centralizes all path resolution
  logic - never construct paths directly, always use `Storage` methods
- **Model Resolution**: Models use alias system (`auto`, `pro`, `flash`)
  resolved to concrete names via `resolveModel()` considering preview features

## Boundaries

- **DO**: Add new configuration parameters via `ConfigParameters` interface
- **DO**: Use `Storage` class methods for all path resolution
- **DO**: Access services through Config getters (e.g., `getFileService()`,
  `getGitService()`)
- **DO NOT**: Mutate config state after initialization - use setters only where
  explicitly provided
- **DO NOT**: Import Config in utils or low-level modules - causes circular
  dependencies
- This module handles **configuration and state management**, NOT **business
  logic** - business logic belongs in `services/` or `core/`
- This module provides **access to registries**, NOT **registry
  implementation** - registry logic belongs in their respective modules

## Relationships

- **Depends on**: `../core/contentGenerator` (AI SDK setup), `../services/`
  (FileDiscoveryService, GitService, ModelConfigService),
  `../tools/tool-registry` (tool discovery), `../agents/registry` (agent
  loading)
- **Used by**: Nearly every module in core - Config is the central dependency
  injection container
- **Dependency Management**: Config imports from `../utils/`, `../tools/`,
  `../agents/`, and other modules, but those low-level modules should never
  import Config back (to keep them reusable). Config is the central hub that
  aggregates dependencies without creating circular imports.

## Adding New Configuration Parameters

1. Add parameter to `ConfigParameters` interface with optional default
2. Add corresponding private readonly field to `Config` class
3. Initialize field in constructor with default value if needed
4. Add public getter method (and setter if mutable)
5. Update tests in `config.test.ts` to verify new parameter

Example:

```typescript
// In ConfigParameters interface
experimentalFeature?: boolean;

// In Config class
private readonly experimentalFeature: boolean;

constructor(params: ConfigParameters) {
  // ...
  this.experimentalFeature = params.experimentalFeature ?? false;
}

getExperimentalFeature(): boolean {
  return this.experimentalFeature;
}
```

## Adding New Storage Paths

1. Add static method to `Storage` class for global paths (e.g.,
   `getUserCommandsDir()`)
2. Add instance method for project-specific paths (e.g.,
   `getProjectCommandsDir()`)
3. Use `path.join()` with existing base paths (`getGlobalGeminiDir()`,
   `getGeminiDir()`)
4. Add test in `storage.test.ts`

## Adding New Models

1. Add model constant to `models.ts` (e.g.,
   `export const NEW_MODEL = 'gemini-4-pro'`)
2. Update `VALID_GEMINI_MODELS` Set if it's a Gemini model
3. Add alias if needed and update `resolveModel()` function
4. Add model config to `defaultModelConfigs.ts` with appropriate base config
5. Add tests in `models.test.ts`

## Testing

- Mock heavy dependencies: Use `vi.mock()` for tool registry, MCP clients, AI
  services
- Two-phase init: Test constructor separately from `initialize()` method
- Lazy loading: Test that getters create services on first access
- Model resolution: Test all alias combinations and preview feature interactions
- Storage paths: Verify paths are correctly constructed across platforms

Key test patterns:

```typescript
// Mock expensive dependencies
vi.mock('../tools/tool-registry');
vi.mock('../core/contentGenerator.js');

// Test lazy initialization
const config = new Config(params);
expect(config['fileDiscoveryService']).toBeNull();
config.getFileService();
expect(config['fileDiscoveryService']).toBeDefined();

// Test model resolution
expect(getEffectiveModel('auto', false)).toBe(DEFAULT_GEMINI_MODEL);
expect(resolveModel('pro', true)).toBe(PREVIEW_GEMINI_MODEL);
```
