# Config Module

Manages CLI configuration loading, validation, migration, and persistence across
multiple scopes (user, workspace, system). Handles settings schema, environment
variables, trusted folders, extensions, and sandbox configuration.

## Architecture

The config module uses a multi-scope settings model with environmental variable
resolution and legacy migration support. Settings are loaded from four scopes
with specific precedence (System Defaults < User < Workspace < System), then
validated against a Zod schema. Trusted folder checks prevent untrusted
workspaces from loading sensitive settings.

Key interfaces:

- `Settings` - Inferred TypeScript type from `SETTINGS_SCHEMA`
- `LoadedSettings` - Container for settings across all scopes with merge
  strategy
- `SettingDefinition` - Schema entry describing a single setting
- `SettingsSchema` - Complete schema object defining all valid settings

## Key Files

| File                                | Purpose                                                                               | When to Modify                                                                |
| ----------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `settings.ts`                       | Core settings loading, merging, saving, V1-to-V2 migration, `LoadedSettings` class    | When adding/changing settings structure, merge strategies, or migration logic |
| `settingsSchema.ts`                 | Canonical settings schema with Zod inference                                          | When adding new settings, categories, defaults, or validation rules           |
| `settings-validation.ts`            | Zod schema builder and validation functions                                           | When changing validation logic or error formatting                            |
| `settingPaths.ts`                   | Setting path constants (dot-notation keys)                                            | When standardizing setting paths used elsewhere                               |
| `config.ts`                         | CLI argument parsing and config assembly (combines settings + CLI args into `Config`) | When adding CLI flags or changing how settings map to core Config             |
| `auth.ts`                           | API key validation for AI providers                                                   | When adding new providers or changing auth validation                         |
| `trustedFolders.ts`                 | Workspace trust management via local config or IDE integration                        | When updating trust rules, adding trust levels, or changing trust checks      |
| `extension.ts`                      | Extension config loading from gemini-extension.json files                             | When parsing extension metadata or install information                        |
| `extension-manager.ts`              | Extension lifecycle management (install, uninstall, enable, disable, update)          | When changing extension loading or management logic                           |
| `sandboxConfig.ts`                  | Sandbox command resolution (docker, podman, sandbox-exec)                             | When adding sandbox backends or changing detection logic                      |
| `keyBindings.ts`                    | Keyboard shortcut command definitions and key mappings                                | When adding new keyboard shortcuts or commands                                |
| `policy.ts`                         | Policy engine configuration wrapper                                                   | When changing policy settings mapping                                         |
| `extensions/consent.ts`             | Extension user consent tracking and management                                        | When changing consent prompts or consent storage logic                        |
| `extensions/extensionEnablement.ts` | Extension enable/disable state management                                             | When changing how extension enablement is stored or retrieved                 |
| `extensions/extensionSettings.ts`   | Per-extension configuration settings                                                  | When changing extension settings schema or storage                            |
| `extensions/extensionUpdates.ts`    | Extension update checking and download logic                                          | When updating extension update mechanisms                                     |
| `extensions/github.ts`              | GitHub API integration for extension discovery and installation                       | When changing GitHub-based extension sourcing                                 |
| `extensions/github_fetch.ts`        | HTTP fetch utilities for GitHub API calls                                             | When updating GitHub API communication                                        |
| `extensions/storage.ts`             | Extension data persistence layer                                                      | When changing extension storage mechanisms                                    |
| `extensions/update.ts`              | Extension update execution and versioning                                             | When changing update behavior or version handling                             |
| `extensions/variables.ts`           | Extension environment variables and templating                                        | When adding extension variable features                                       |
| `extensions/variableSchema.ts`      | Schema for extension variables validation                                             | When changing extension variable validation rules                             |

## Patterns

- **Multi-scope merging**: `loadSettings()` loads from System Defaults, User,
  Workspace, System in order, then merges with `customDeepMerge()` respecting
  per-setting merge strategies
- **Migration support**: `needsMigration()` checks for V1 keys,
  `migrateSettingsToV2()` normalizes old flat structure to nested,
  `MIGRATION_MAP` defines key transformations
- **Environment variable resolution**: `resolveEnvVarsInObject()` substitutes
  `${VAR}` patterns after loading, before merging
- **Validation**: `validateSettings()` uses Zod schema to validate loaded
  settings before use
- **Lazy loading**: `loadTrustedFolders()` caches result in module-level
  variable to avoid repeated I/O
- **Format preservation**: `updateSettingsFilePreservingFormat()` maintains
  comments/whitespace when saving

## Boundaries

- **DO**: Use `LoadedSettings` API for runtime access (`merged`, `setValue()`,
  `forScope()`)
- **DO**: Call `loadSettings()` once during app init, pass result through
  dependency injection
- **DO NOT**: Directly read/write settings files outside of `settings.ts` - use
  `LoadedSettings` API
- **DO NOT**: Add new settings without updating `SETTINGS_SCHEMA` and providing
  migration path
- **This module handles**: Settings loading, validation, merging, persistence,
  workspace trust, environment variable loading (.env files), API key
  validation, CLI argument parsing, extension management, sandbox configuration,
  keyboard bindings, policy configuration
- **This does NOT**: Handle extension loading/execution (that's
  `@google/gemini-cli-core`'s ExtensionLoader), theme rendering (that's
  `ui/themes/`), or the main CLI app logic (that's `gemini.tsx`)

## Relationships

- **Depends on**:
  - `@google/gemini-cli-core` - Config types, Storage, validation, error types,
    ExtensionLoader, PolicyEngine, etc.
  - `strip-json-comments` - Parse JSON with comments
  - `dotenv` - Parse .env files
  - `yargs` - CLI argument parsing
  - `../ui/themes/` - Theme definitions for settings
  - `../utils/` - envVarResolver, deepMerge, commentJson, sessionCleanup
    utilities
- **Used by**: CLI app initialization (`gemini.tsx`, `nonInteractiveCli.ts`),
  settings UI components, extension manager, any code that needs runtime config

## Adding New Settings

1. **Define in schema**: Add entry to `SETTINGS_SCHEMA` in `settingsSchema.ts`
   with type, label, category, default, description
2. **Add merge strategy**: If array/object, specify `mergeStrategy` (REPLACE,
   CONCAT, UNION, SHALLOW_MERGE)
3. **Add migration**: If V1 key exists, add entry to `MIGRATION_MAP` in
   `settings.ts`
4. **Add type inference**: The `Settings` type is auto-inferred from schema, no
   manual changes needed
5. **Document**: Add comment explaining when setting requires restart if
   `requiresRestart: true`
6. **Test**: Add test case to `settings.test.ts` covering load, merge,
   validation, save

## Testing

- **Test files**: `settings.test.ts`, `settings-validation.test.ts`,
  `settings_repro.test.ts`, `settings_validation_warning.test.ts`,
  `config.test.ts`, `config.integration.test.ts`,
  `policy-engine.integration.test.ts`, `trustedFolders.test.ts`,
  `extension.test.ts`, `auth.test.ts`, `sandboxConfig.test.ts`,
  `keyBindings.test.ts`, `settingPaths.test.ts`, `settingsSchema.test.ts`
- **Extension manager tests**: `extension-manager-agents.test.ts`,
  `extension-manager-scope.test.ts`, `extension-manager-skills.test.ts`
- **Extension subdirectory tests**: `extensions/consent.test.ts`,
  `extensions/extensionEnablement.test.ts`,
  `extensions/extensionSettings.test.ts`, `extensions/extensionUpdates.test.ts`,
  `extensions/github.test.ts`, `extensions/github_fetch.test.ts`,
  `extensions/storage.test.ts`, `extensions/update.test.ts`,
  `extensions/variables.test.ts`
- **Key test utilities**: `settings_repro.test.ts` for reproduction scenarios
- **Mocking**: Mock `@google/gemini-cli-core` modules (Storage, validation,
  Config) when unit testing config logic
- **Integration tests**: Use real file I/O with temporary directories
- **Migration testing**: Test migration paths by creating V1 settings and
  verifying V2 conversion
- **Settings changes verification**: Schema validation passes, merge produces
  correct result, environment variables are resolved, file is saved correctly
