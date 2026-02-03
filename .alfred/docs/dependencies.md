# Dependencies

<overview>
Gemini CLI is an npm monorepo consisting of 5 workspace packages with a clear separation between frontend (CLI/UI) and backend (Core) responsibilities. The project uses ES modules, TypeScript, and follows a functional programming style with plain objects over classes.
</overview>

## Internal Dependencies Map

<internal-dependency-graph>
The monorepo packages have the following dependency relationships:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ROOT (@google/gemini-cli)                     │
│  Dependencies: ink, latest-version, simple-git                          │
│  DevDependencies: esbuild, eslint, vitest, typescript, prettier         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
     ┌───────────────┬───────────────┼───────────────┬───────────────┐
     ▼               ▼               ▼               ▼               ▼
┌─────────┐   ┌─────────────┐  ┌───────────┐  ┌───────────┐  ┌─────────────────┐
│ cli     │   │   core      │  │ a2a-server│  │test-utils │  │vscode-companion │
│         │   │             │  │           │  │           │  │                 │
│@google/ │   │@google/     │  │@google/   │  │@google/   │  │gemini-cli-      │
│gemini-  │   │gemini-cli-  │  │gemini-cli-│  │gemini-cli-│  │vscode-ide-      │
│cli      │   │core         │  │a2a-server │  │test-utils │  │companion        │
└────┬────┘   └──────┬──────┘  └─────┬─────┘  └─────┬─────┘  └─────────────────┘
     │               │               │              │
     │    ┌─────────►│◄──────────────┘              │
     │    │          │◄────────────────────────────►│
     └────┘          │
                     │
```

</internal-dependency-graph>

<package-dependencies>

### @google/gemini-cli (packages/cli)

**Role**: Terminal UI frontend - handles user interaction, React/Ink rendering,
command parsing

**Internal Dependencies**:

- `@google/gemini-cli-core` (file:../core) - Backend functionality
- `@google/gemini-cli-test-utils` (file:../test-utils) - Testing utilities (dev)

**Key Imports from Core**:

- `Config`, `sessionId`, `logUserPrompt` - Configuration and telemetry
- `AuthType`, `getOauthClient` - Authentication
- `debugLogger`, `coreEvents`, `CoreEvent` - Logging and events
- `ExitCodes`, `SessionStartSource`, `SessionEndReason` - Session lifecycle
- `startupProfiler`, `recordSlowRender` - Performance monitoring
- Utility functions: `createWorkingStdio`, `patchStdio`, `writeToStdout`,
  `writeToStderr`

### @google/gemini-cli-core (packages/core)

**Role**: Backend - AI orchestration, tools, services, MCP integration

**Internal Dependencies**:

- `@google/gemini-cli-test-utils` (file:../test-utils) - Testing utilities (dev)

**No other internal package dependencies** - Core is the foundational layer

### @google/gemini-cli-a2a-server (packages/a2a-server)

**Role**: Experimental Agent-to-Agent server

**Internal Dependencies**:

- `@google/gemini-cli-core` (file:../core) - Core functionality

### @google/gemini-cli-test-utils (packages/test-utils)

**Role**: Shared testing utilities

**Internal Dependencies**:

- `@google/gemini-cli-core` (file:../core) - Core types and utilities

### gemini-cli-vscode-ide-companion (packages/vscode-ide-companion)

**Role**: VS Code extension for IDE integration

**Internal Dependencies**: None (standalone extension)

</package-dependencies>

<module-structure>

### Core Package Internal Module Dependencies

```
packages/core/src/
├── config/          → Entry point, depends on most other modules
│   └── config.ts    → Imports from: core/, tools/, services/, agents/, hooks/
├── core/            → AI orchestration
│   ├── geminiChat.ts    → Imports: config/, tools/, services/, telemetry/, fallback/
│   ├── client.ts        → Imports: config/, hooks/, telemetry/
│   └── contentGenerator.ts → Imports: config/, utils/
├── tools/           → Tool implementations (24+ tools)
│   └── tool-registry.ts → Imports: config/, confirmation-bus/, utils/
├── services/        → Business logic services
│   ├── shellExecutionService.ts
│   ├── fileSystemService.ts
│   ├── fileDiscoveryService.ts
│   └── gitService.ts
├── hooks/           → Hook system for extensibility
│   └── hookSystem.ts → Imports: config/, confirmation-bus/, telemetry/
├── mcp/             → Model Context Protocol integration
│   ├── oauth-provider.ts
│   └── oauth-token-storage.ts
├── agents/          → Agent definitions and execution
├── policy/          → Security policy engine
├── telemetry/       → OpenTelemetry integration
└── utils/           → Foundational utilities (no core imports)
```

</module-structure>

## External Libraries Analysis

<external-dependencies>

### AI and Model Integration

| Library                     | Version | Purpose                                  | Used In           |
| --------------------------- | ------- | ---------------------------------------- | ----------------- |
| `@google/genai`             | 1.30.0  | Google Gemini AI SDK - direct API client | core              |
| `@modelcontextprotocol/sdk` | ^1.23.0 | MCP protocol for tool integration        | core, cli, vscode |
| `@a2a-js/sdk`               | ^0.3.8  | Agent-to-Agent protocol SDK              | core, a2a-server  |
| `@agentclientprotocol/sdk`  | ^0.12.0 | Agent client protocol                    | cli               |

### UI and Terminal

| Library        | Version                 | Purpose                       | Used In   |
| -------------- | ----------------------- | ----------------------------- | --------- |
| `ink`          | npm:@jrichman/ink@6.4.7 | React renderer for CLI (fork) | root, cli |
| `react`        | ^19.2.0                 | UI component framework        | cli       |
| `ink-gradient` | ^3.0.0                  | Gradient text effects         | cli       |
| `ink-spinner`  | ^5.0.0                  | Loading spinners              | cli       |
| `highlight.js` | ^11.11.1                | Code syntax highlighting      | cli       |
| `lowlight`     | ^3.3.0                  | Syntax highlighting AST       | cli       |
| `yargs`        | ^17.7.2                 | CLI argument parsing          | cli, root |

### Telemetry and Observability

| Library                                                 | Version  | Purpose             | Used In |
| ------------------------------------------------------- | -------- | ------------------- | ------- |
| `@opentelemetry/api`                                    | ^1.9.0   | OpenTelemetry API   | core    |
| `@opentelemetry/sdk-node`                               | ^0.203.0 | Node.js SDK         | core    |
| `@opentelemetry/exporter-*-otlp-grpc`                   | ^0.203.0 | OTLP gRPC exporters | core    |
| `@opentelemetry/exporter-*-otlp-http`                   | ^0.203.0 | OTLP HTTP exporters | core    |
| `@google-cloud/opentelemetry-cloud-trace-exporter`      | ^3.0.0   | GCP trace export    | core    |
| `@google-cloud/opentelemetry-cloud-monitoring-exporter` | ^0.21.0  | GCP metrics         | core    |
| `@google-cloud/logging`                                 | ^11.2.1  | GCP logging         | core    |

### File System and Search

| Library                    | Version | Purpose                    | Used In         |
| -------------------------- | ------- | -------------------------- | --------------- |
| `glob`                     | ^12.0.0 | File pattern matching      | core, cli, root |
| `fdir`                     | ^6.4.6  | Fast directory crawler     | core            |
| `@joshua.litt/get-ripgrep` | ^0.0.3  | ripgrep binary installer   | core            |
| `ignore`                   | ^7.0.0  | gitignore pattern matching | core            |
| `picomatch`                | ^4.0.1  | Glob pattern matching      | core            |
| `simple-git`               | ^3.28.0 | Git operations             | core, cli, root |

### Validation and Schema

| Library       | Version  | Purpose                      | Used In           |
| ------------- | -------- | ---------------------------- | ----------------- |
| `zod`         | ^3.25.76 | Runtime type validation      | core, cli, vscode |
| `ajv`         | ^8.17.1  | JSON Schema validation       | core              |
| `ajv-formats` | ^3.0.0   | Additional format validators | core              |
| `@iarna/toml` | ^2.2.5   | TOML config parsing          | core, cli         |

### Networking and HTTP

| Library               | Version | Purpose                   | Used In            |
| --------------------- | ------- | ------------------------- | ------------------ |
| `undici`              | ^7.10.0 | HTTP client               | core, cli          |
| `https-proxy-agent`   | ^7.0.6  | HTTPS proxy support       | core               |
| `google-auth-library` | ^9.11.0 | Google OAuth              | core               |
| `express`             | ^5.1.0  | HTTP server (A2A, VSCode) | a2a-server, vscode |

### Text Processing

| Library        | Version  | Purpose                  | Used In               |
| -------------- | -------- | ------------------------ | --------------------- |
| `marked`       | ^15.0.12 | Markdown parsing         | core                  |
| `html-to-text` | ^9.0.5   | HTML to text conversion  | core                  |
| `diff`         | ^7.0.0   | Text diff generation     | core, cli             |
| `strip-ansi`   | ^7.1.0   | Remove ANSI escape codes | core, cli, test-utils |
| `shell-quote`  | ^1.8.3   | Shell command parsing    | core, cli             |

### Terminal and PTY

| Library            | Version | Purpose                    | Used In    |
| ------------------ | ------- | -------------------------- | ---------- |
| `@lydell/node-pty` | 1.1.0   | Pseudo-terminal (optional) | root, core |
| `node-pty`         | ^1.0.0  | Node.js PTY (fallback)     | root, core |
| `@xterm/headless`  | 5.5.0   | Headless terminal emulator | core       |
| `keytar`           | ^7.9.0  | Secure credential storage  | root, core |

### Parsing and AST

| Library            | Version  | Purpose             | Used In |
| ------------------ | -------- | ------------------- | ------- |
| `web-tree-sitter`  | ^0.25.10 | Code parsing (WASM) | core    |
| `tree-sitter-bash` | ^0.25.0  | Bash syntax parsing | core    |

### Utilities

| Library     | Version | Purpose                      | Used In          |
| ----------- | ------- | ---------------------------- | ---------------- |
| `uuid`      | ^13.0.0 | UUID generation              | core, a2a-server |
| `mnemonist` | ^0.40.3 | Data structures              | core, cli, root  |
| `fzf`       | ^0.5.2  | Fuzzy finder                 | core, cli        |
| `chardet`   | ^2.1.0  | Character encoding detection | core             |
| `open`      | ^10.1.2 | Open URLs/files in browser   | core, cli        |
| `dotenv`    | ^17.1.0 | Environment variable loading | cli              |

</external-dependencies>

<npm-overrides>

### Package Overrides

The root `package.json` contains overrides to resolve dependency conflicts:

```json
{
  "overrides": {
    "ink": "npm:@jrichman/ink@6.4.7",
    "wrap-ansi": "9.0.2",
    "cliui": {
      "wrap-ansi": "7.0.0"
    }
  }
}
```

**Rationale**:

- `ink` uses a forked version (`@jrichman/ink`) with fixes for CLI rendering
- `wrap-ansi` pinned to resolve version conflicts between dependencies
- `cliui` has its own `wrap-ansi` version pinned for compatibility

</npm-overrides>

## Service Integrations

<service-integrations>

### Google Cloud Platform

<gcp-integration>
**Authentication Methods**:
- `google-auth-library` for OAuth2 flows
- Support for API keys, service accounts, and ADC (Application Default Credentials)
- `keytar` for secure credential storage in system keychain

**Telemetry Services**:

- Google Cloud Trace via `@google-cloud/opentelemetry-cloud-trace-exporter`
- Google Cloud Monitoring via
  `@google-cloud/opentelemetry-cloud-monitoring-exporter`
- Google Cloud Logging via `@google-cloud/logging`

**AI Services**:

- Gemini API via `@google/genai` SDK
- Support for multiple model variants (flash, pro, preview) </gcp-integration>

### Model Context Protocol (MCP)

<mcp-integration>
**Purpose**: External tool integration and server discovery

**Components**:

- `mcp/oauth-provider.ts` - OAuth authentication for MCP servers
- `mcp/oauth-token-storage.ts` - Token persistence
- `mcp/google-auth-provider.ts` - Google-specific auth
- `mcp/sa-impersonation-provider.ts` - Service account impersonation

**Tool Discovery**:

- MCP servers can provide additional tools beyond built-in ones
- Tools are discovered via `ToolRegistry.discoverAllTools()`
- `DiscoveredMCPTool` wraps external tools with unified interface
  </mcp-integration>

### Agent-to-Agent (A2A) Protocol

<a2a-integration>
**Purpose**: Inter-agent communication (experimental)

**Components**:

- `@a2a-js/sdk` for protocol implementation
- Express server in `packages/a2a-server`
- `@google-cloud/storage` for artifact storage
- `winston` for logging

**Capabilities**:

- HTTP server for A2A communication
- Task execution via core package
- File archiving with `tar` </a2a-integration>

### IDE Integration

<ide-integration>
**VS Code Extension** (`packages/vscode-ide-companion`):
- MCP server for CLI-IDE communication
- Diff view management for file changes
- Open file tracking
- Express/CORS for local server

**CLI Detection**:

- Auto-detects IDE context (VS Code, Zed, terminal)
- `ide/detect-ide.ts` identifies IDE environment
- `ide/ide-client.ts` provides unified IDE interface </ide-integration>

</service-integrations>

## Dependency Injection Patterns

<dependency-injection>

### Config as Central DI Container

<config-di-pattern>
The `Config` class serves as the primary dependency injection container:

```typescript
// packages/core/src/config/config.ts
class Config {
  // Lazy-initialized services
  private fileDiscoveryService: FileDiscoveryService | null = null;
  private gitService: GitService | null = null;

  // Eager-initialized registries
  private toolRegistry: ToolRegistry;
  private agentRegistry: AgentRegistry;
  private hookSystem: HookSystem;

  // Factory methods for lazy services
  getFileService(): FileDiscoveryService {
    if (!this.fileDiscoveryService) {
      this.fileDiscoveryService = new FileDiscoveryService(this);
    }
    return this.fileDiscoveryService;
  }

  // Direct accessors for registries
  getToolRegistry(): ToolRegistry {
    return this.toolRegistry;
  }
  getPolicyEngine(): PolicyEngine {
    return this.policyEngine;
  }
  getMessageBus(): MessageBus {
    return this.messageBus;
  }
}
```

**Pattern Characteristics**:

- Two-phase initialization (constructor + `initialize()`)
- Lazy instantiation for expensive services
- Eager creation for lightweight registries
- Centralized access point for all dependencies </config-di-pattern>

### MessageBus for Tool Confirmation

<messagebus-pattern>
```typescript
// packages/core/src/confirmation-bus/message-bus.ts
class MessageBus {
  // Event-driven communication for tool confirmations
  async requestToolConfirmation(
    toolName: string,
    params: ToolParams
  ): Promise<ConfirmationResponse>;
}

// Usage in tools class ShellTool extends BaseDeclarativeTool {
constructor(config: Config, messageBus: MessageBus) { super(/_ ... _/,
messageBus); } }

````

**Pattern**: Mediator pattern for decoupling tool execution from user interaction
</messagebus-pattern>

### Registry Pattern for Tools, Agents, and Resources

<registry-pattern>
```typescript
// Tool Registry
class ToolRegistry {
  private allKnownTools: Map<string, AnyDeclarativeTool>;
  registerTool(tool: AnyDeclarativeTool): void;
  getTool(name: string): AnyDeclarativeTool | undefined;
  getFunctionDeclarations(): FunctionDeclaration[];
}

// Agent Registry
class AgentRegistry {
  private agents: Map<string, AgentDefinition>;
  register(agent: AgentDefinition): void;
  get(name: string): AgentDefinition | undefined;
}

// Resource Registry
class ResourceRegistry {
  private resources: Map<string, Resource>;
  register(resource: Resource): void;
}
````

**Pattern Characteristics**:

- Centralized lookup for named components
- Dynamic registration at runtime
- Schema generation for AI function calling </registry-pattern>

### Service Locator via Config

<service-locator-pattern>
Services access other services through Config:

```typescript
// In ShellExecutionService
class ShellExecutionService {
  constructor(private config: Config) {}

  async execute(command: string): Promise<ExecutionResult> {
    const policyEngine = this.config.getPolicyEngine();
    // Use policy engine for command validation
  }
}
```

**Boundary**: Low-level utils NEVER import Config (avoids circular deps)
</service-locator-pattern>

### Hook System for Extension Points

<hook-system-pattern>
```typescript
// packages/core/src/hooks/hookSystem.ts
class HookSystem {
  private registry: HookRegistry;
  private runner: HookRunner;
  private aggregator: HookAggregator;

async fireSessionStartEvent(source: SessionStartSource): Promise<HookResult>;
async fireBeforeToolEvent(tool: string, params: unknown): Promise<HookResult>;
async fireAfterModelEvent(response: LLMResponse): Promise<HookResult>; }

```

**Pattern**: Chain of Responsibility with result aggregation

**Hook Events** (11 lifecycle points):
- `SessionStart`, `SessionEnd`
- `BeforeModel`, `AfterModel`
- `BeforeTool`, `AfterTool`
- `BeforeToolSelection`
- `PreCompress`
- `UserPromptSubmit`
</hook-system-pattern>

</dependency-injection>

## Module Coupling Assessment

<coupling-assessment>

### Low Coupling (Good)

<low-coupling>
**Utils → No Core Imports**
- `packages/core/src/utils/` modules have no dependencies on core modules
- Can be reused independently
- Examples: `fileUtils.ts`, `textUtils.ts`, `shell-utils.ts`

**Test Utils → Core Types Only**
- `packages/test-utils/` depends only on core types
- No UI dependencies
- Clean interface for testing

**VS Code Extension → Standalone**
- No internal package dependencies
- Uses only MCP SDK and standard libraries
- Independent build and deployment
</low-coupling>

### Medium Coupling (Acceptable)

<medium-coupling>
**CLI → Core**
- CLI imports heavily from core for business logic
- Clear separation: CLI handles UI, Core handles logic
- One-way dependency (CLI → Core, never reverse)

**Services → Config**
- Services receive Config via constructor
- Access other services through Config getters
- Acceptable for application-level DI

**Tools → Services**
- Tools use services (FileSystemService, ShellExecutionService)
- Services are injected, not created by tools
- Testable via mocking
</medium-coupling>

### Tighter Coupling (Areas of Concern)

<tighter-coupling>
**Config → Everything**
- Config imports from nearly every core module
- Acts as God Object / Service Locator
- Mitigated by: single point of entry, two-phase init

**GeminiChat → Multiple Modules**
- Imports from: config, tools, services, telemetry, fallback, hooks
- Central orchestration requires broad access
- Acceptable for main coordinator

**Core/Turn.ts Dependencies**
- Complex interaction between turn management and tools
- Multiple concerns in single module
</tighter-coupling>

### Coupling Metrics

| Package | Internal Deps | External Deps | Coupling Level |
|---------|--------------|---------------|----------------|
| test-utils | 1 (core) | 3 | Low |
| vscode-companion | 0 | 5 | Very Low |
| a2a-server | 1 (core) | 7 | Low |
| cli | 2 (core, test-utils) | 38 | Medium |
| core | 1 (test-utils dev) | 50 | Medium-High |

</coupling-assessment>

## Dependency Graph

<dependency-graph>

### Package-Level Dependencies (ASCII)

```

                    ┌─────────────────────────────────────┐
                    │         ROOT package.json           │
                    │  (workspace: packages/*)            │
                    └───────────────┬─────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼

┌───────────────┐ ┌─────────────────┐ ┌─────────────────┐ │ CLI │ │ CORE │ │
A2A-SERVER │ │ @google/ │────────▶│ @google/ │◀────────│ @google/ │ │
gemini-cli │ │ gemini-cli- │ │ gemini-cli- │ │ │ │ core │ │ a2a-server │
└───────┬───────┘ └────────┬────────┘ └─────────────────┘ │ │ │ │ ▼ ▼
┌───────────────┐ ┌─────────────────┐ ┌─────────────────┐ │ TEST-UTILS
│◀────────│ (shared) │ │ VSCODE-COMPANION│ │ @google/ │ │ │ │ gemini-cli- │ │
gemini-cli- │ └─────────────────┘ │ vscode-ide- │ │ test-utils │ │ companion │
└───────────────┘ └─────────────────┘ ▲ │ │ │
└─────────────────────────────────────────────────────┘ (No dependency -
standalone)

```

### Core Module Dependencies (Simplified)

```

                    ┌─────────────────────────────────────┐
                    │              config/                │
                    │  (Config, Storage, Models)          │
                    └───────────────┬─────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼

┌───────────────┐ ┌─────────────────┐ ┌─────────────────┐ │ core/ │ │ tools/ │ │
services/ │ │ geminiChat │◄───────▶│ ToolRegistry │◄───────▶│ FileSystem │ │
client │ │ Built-in tools │ │ Shell │ │ turn │ │ MCP tools │ │ Git │
└───────┬───────┘ └────────┬────────┘ └────────┬────────┘ │ │ │ ▼ ▼ ▼
┌───────────────┐ ┌─────────────────┐ ┌─────────────────┐ │ hooks/ │ │ agents/ │
│ telemetry/ │ │ HookSystem │◄───────▶│ AgentRegistry │◄───────▶│
OpenTelemetry │ │ 11 events │ │ Execution │ │ GCP exporters │ └───────────────┘
└─────────────────┘ └─────────────────┘ │ │ │
└──────────────────────────┴───────────────────────────┘ │ ▼
┌─────────────────────────────────────┐ │ utils/ │ │ (NO circular deps -
foundation) │ └─────────────────────────────────────┘

````

</dependency-graph>

## Potential Dependency Issues

<potential-issues>

### Version Pinning Concerns

<version-concerns>
**Tightly Pinned**:
- `@google/genai: 1.30.0` - Exact version, may miss security updates
- `@xterm/headless: 5.5.0` - Exact version
- `@lydell/node-pty: 1.1.0` - Exact version across packages

**Recommendation**: Consider using caret ranges (^) for these dependencies with comprehensive integration tests to catch breaking changes.
</version-concerns>

### Duplicate Dependencies Across Packages

<duplicate-deps>
The following dependencies appear in multiple packages with potentially different versions:

| Dependency | cli | core | a2a-server | Concern |
|------------|-----|------|------------|---------|
| `zod` | ^3.23.8 | ^3.25.76 | - | Version mismatch |
| `vitest` | ^3.1.1 | ^3.1.1 | ^3.1.1 | OK (same version) |
| `typescript` | ^5.3.3 | ^5.3.3 | ^5.3.3 | OK (same version) |
| `diff` | ^7.0.0 | ^7.0.0 | - | OK (same version) |
| `dotenv` | ^17.1.0 | - | ^16.4.5 | Version mismatch |

**Recommendation**: Hoist shared dependencies to root package.json or ensure version alignment.
</duplicate-deps>

### Large Dependency Surface

<dependency-surface>
**Core package has 50+ production dependencies**:
- Increases bundle size
- More potential security vulnerabilities
- Higher maintenance burden

**High-Risk Dependencies** (native/binary):
- `@lydell/node-pty` - Platform-specific binaries
- `keytar` - Native module for keychain access
- `tree-sitter-bash` - WASM/native parsing

**Recommendation**: Audit dependencies quarterly, consider alternatives for large dependencies.
</dependency-surface>

### Circular Dependency Prevention

<circular-deps>
**Current Strategy** (working well):
- `utils/` modules never import from `config/` or `core/`
- Config is the central hub that imports from everywhere
- Services receive Config via constructor, not import

**Risk Areas**:
- `tools/tool-names.ts` exists specifically to avoid circular imports
- Adding new tools that need Config access requires careful design

**Pattern to Follow**:
```typescript
// GOOD: Utils are independent
// packages/core/src/utils/fileUtils.ts
import * as fs from 'node:fs/promises';
// No imports from ../config/ or ../core/

// GOOD: Tool names as constants
// packages/core/src/tools/tool-names.ts
export const SHELL_TOOL_NAME = 'shell';
// No imports from other tool files

// BAD: Would create circular dependency
// packages/core/src/utils/someUtil.ts
import { Config } from '../config/config.js'; // NEVER DO THIS
````

</circular-deps>

### Forked Dependencies

<forked-deps>
**Ink Fork**:
- Using `npm:@jrichman/ink@6.4.7` instead of official `ink`
- Creates maintenance burden
- May diverge from upstream fixes

**Reason**: Custom fixes for CLI rendering issues not yet merged upstream

**Recommendation**: Track upstream ink releases, consider contributing fixes
back. </forked-deps>

### Optional Dependencies

<optional-deps>
The following are optional and may cause runtime behavior changes:

```json
"optionalDependencies": {
  "@lydell/node-pty": "1.1.0",
  "node-pty": "^1.0.0",
  "keytar": "^7.9.0"
}
```

**Runtime Handling**:

- `getPty.ts` dynamically selects available PTY implementation
- Falls back gracefully when native modules unavailable
- May affect sandbox and shell execution capabilities

**Recommendation**: Ensure fallback paths are well-tested across platforms.
</optional-deps>

### Security Considerations

<security-concerns>
**Dependencies Accessing System Resources**:
- `node-pty` / `@lydell/node-pty` - Shell access
- `keytar` - System keychain
- `simple-git` - Git operations
- `child_process` (Node built-in) - Command execution

**Mitigations in Place**:

- PolicyEngine validates tool operations
- Sandbox mode available (Docker/Podman)
- User confirmation for destructive operations
- MessageBus mediates sensitive operations

**Recommendation**: Regular `npm audit` and dependency updates, especially for
these packages. </security-concerns>

</potential-issues>
