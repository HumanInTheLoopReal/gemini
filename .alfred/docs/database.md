# Database

## Database Overview

This project does **not use traditional SQL/NoSQL databases**. Instead, Gemini
CLI employs a file-based persistence strategy with multiple storage mechanisms
tailored to different data types:

| Storage Mechanism    | Type        | Purpose                                         | Location                                           |
| -------------------- | ----------- | ----------------------------------------------- | -------------------------------------------------- |
| JSON Files           | File        | Settings, session history, conversation records | `~/.gemini/`, project `.gemini/`                   |
| TOML Files           | File        | Security policies, agent definitions            | `~/.gemini/policies/`, project `.gemini/policies/` |
| Keychain (macOS)     | OS Keystore | OAuth tokens, API keys (secure)                 | System Keychain                                    |
| Encrypted JSON       | File        | OAuth tokens fallback (AES-256-GCM)             | `~/.gemini/mcp-oauth-tokens-v2.json`               |
| In-Memory Cache      | Memory      | File crawl results (TTL-based)                  | Runtime only                                       |
| Google Cloud Storage | Cloud       | A2A server task persistence (experimental)      | GCS bucket                                         |

<important>
The absence of a traditional database is intentional—Gemini CLI is a terminal application designed to run without external database dependencies. All persistence uses the local filesystem or OS-provided secure storage.
</important>

---

## Schema Definitions

### Configuration Storage

#### Global Settings (`~/.gemini/settings.json`)

**Purpose**: User-level configuration for Gemini CLI

**Location**: `packages/core/src/config/storage.ts:38`

**Schema**:

```json
{
  "api": {
    "key": "string (optional)",
    "provider": "string (gemini|vertex|etc)"
  },
  "theme": "string (dark|light|auto)",
  "editor": "string (vim|emacs|none)",
  "sandbox": {
    "enabled": "boolean",
    "type": "string (docker|podman|none)"
  }
}
```

**Notes**: Schema defined via Zod in
`packages/cli/src/config/settingsSchema.ts`. Settings are validated on load and
merged from multiple scopes (system defaults < user < workspace < system).

---

#### Workspace Settings (`.gemini/settings.json`)

**Purpose**: Project-specific configuration overrides

**Location**: `packages/core/src/config/storage.ts:126-128`

**Schema**: Same structure as global settings but applied per-project.

---

#### Persistent State (`~/.gemini/state.json`)

**Purpose**: Cross-session UI state (e.g., banner display counts)

**Location**: `packages/cli/src/utils/persistentState.ts:10-16`

**Schema**:

```typescript
interface PersistentStateData {
  defaultBannerShownCount?: Record<string, number>;
}
```

---

### Session & Conversation Storage

#### Conversation Records (`~/.gemini/tmp/<project_hash>/chats/session-*.json`)

**Purpose**: Complete conversation history for session restore and browsing

**Location**: `packages/core/src/services/chatRecordingService.ts:84-91`

**Schema**:

```typescript
interface ConversationRecord {
  sessionId: string; // UUID for the session
  projectHash: string; // SHA-256 hash of project root path
  startTime: string; // ISO 8601 timestamp
  lastUpdated: string; // ISO 8601 timestamp
  messages: MessageRecord[]; // Array of conversation messages
  summary?: string; // AI-generated session summary
}

interface MessageRecord {
  id: string; // UUID
  timestamp: string; // ISO 8601
  type: 'user' | 'gemini' | 'info' | 'error' | 'warning';
  content: PartListUnion; // Message content (text, tool calls, etc.)
  toolCalls?: ToolCallRecord[];
  thoughts?: ThoughtSummary[];
  tokens?: TokensSummary;
  model?: string;
}

interface ToolCallRecord {
  id: string;
  name: string;
  args: Record<string, unknown>;
  result?: PartListUnion | null;
  status: 'pending' | 'approved' | 'denied' | 'complete' | 'failed';
  timestamp: string;
  displayName?: string;
  description?: string;
}

interface TokensSummary {
  input: number; // promptTokenCount
  output: number; // candidatesTokenCount
  cached: number; // cachedContentTokenCount
  thoughts?: number;
  tool?: number;
  total: number;
}
```

---

### Credential Storage

#### OAuth Credentials (Hybrid Storage)

**Purpose**: Store OAuth tokens for MCP servers and API authentication

**Location**: `packages/core/src/mcp/token-storage/types.ts:10-28`

**Schema**:

```typescript
interface OAuthCredentials {
  serverName: string; // MCP server identifier
  token: OAuthToken; // Token data
  clientId?: string; // OAuth client ID
  tokenUrl?: string; // Token endpoint URL
  mcpServerUrl?: string; // MCP server URL
  updatedAt: number; // Unix timestamp (ms)
}

interface OAuthToken {
  accessToken: string;
  refreshToken?: string;
  expiresAt?: number; // Unix timestamp (ms)
  tokenType: string; // "Bearer", "ApiKey", etc.
  scope?: string;
}
```

**Storage Backends**:

| Backend        | Location                             | Security               |
| -------------- | ------------------------------------ | ---------------------- |
| macOS Keychain | System Keychain via `keytar`         | OS-level encryption    |
| Encrypted File | `~/.gemini/mcp-oauth-tokens-v2.json` | AES-256-GCM encryption |

**Encryption Details**
(`packages/core/src/mcp/token-storage/file-token-storage.ts:26-29`):

```typescript
// Key derivation using scrypt
const salt = `${os.hostname()}-${os.userInfo().username}-gemini-cli`;
const encryptionKey = crypto.scryptSync('gemini-cli-oauth', salt, 32);
// Cipher: AES-256-GCM with random IV and auth tag
```

---

#### API Key Storage

**Purpose**: Store Gemini API keys securely

**Location**: `packages/core/src/core/apiKeyCredentialStorage.ts`

**Storage**: Uses `HybridTokenStorage` with service name `gemini-cli-api-key`

**Schema**: API keys stored as `OAuthCredentials` with `tokenType: "ApiKey"`

---

#### Google Accounts (`~/.gemini/google_accounts.json`)

**Purpose**: Cached Google account information for OAuth flows

**Location**: `packages/core/src/config/storage.ts:13, 45-47`

---

### Policy Storage

#### Security Policies (`~/.gemini/policies/*.toml`, `.gemini/policies/*.toml`)

**Purpose**: Define tool permissions and security rules

**Location**: `packages/core/src/policy/toml-loader.ts:207-233`

**Schema** (TOML format):

```toml
[[rule]]
toolName = "run_shell_command"
decision = "allow"          # "allow" | "deny" | "ask_user"
priority = 100              # 0-999, higher wins
modes = ["default"]         # Optional: filter by approval mode
commandPrefix = "git"       # For shell commands: auto-converts to argsPattern
argsPattern = "..."         # JSON pattern for argument matching

[[safety_checker]]
toolName = "run_shell_command"
priority = 100
[safety_checker.checker]
type = "in-process"
name = "allowed-path"
```

**Tier Hierarchy**:

- Admin (3.x): System-wide policies
- User (2.x): User preferences
- Default (1.x): Built-in policies from
  `packages/core/src/policy/policies/*.toml`

---

### Extension Storage

#### Extension Configuration (`~/.gemini/extensions/<name>/gemini-extension.json`)

**Purpose**: Extension metadata and configuration

**Location**: `packages/cli/src/config/extensions/storage.ts`

**Schema**: Defined by extension authors, validated on load

---

### Memory Storage

#### Global Memory (`~/.gemini/memory.md`)

**Purpose**: Persistent context/notes available across all sessions

**Location**: `packages/core/src/config/storage.ts:57-59`

**Format**: Markdown file, user-editable

---

### Shell History

#### Command History (`~/.gemini/tmp/<project_hash>/shell_history`)

**Purpose**: Stores shell command history for the project

**Location**: `packages/core/src/config/storage.ts:158-160`

**Format**: Line-delimited text file

---

### A2A Server Storage (Experimental)

#### GCS Task Store

**Purpose**: Persist agent tasks and workspace state for A2A server

**Location**: `packages/a2a-server/src/persistence/gcs.ts:33-298`

**Schema**:

| Object    | Path                              | Format       | Content                    |
| --------- | --------------------------------- | ------------ | -------------------------- |
| Metadata  | `tasks/<taskId>/metadata.tar.gz`  | Gzipped JSON | Task state, agent settings |
| Workspace | `tasks/<taskId>/workspace.tar.gz` | Gzipped tar  | Complete workspace files   |

---

## Relationships & References

### Storage Path Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                    Storage.getGlobalGeminiDir()                  │
│                        (~/.gemini/)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ settings.json   │  │ google_accounts │  │ memory.md       │ │
│  │                 │  │     .json       │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ mcp-oauth-      │  │ state.json      │  │ installation_id │ │
│  │ tokens-v2.json  │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ policies/       │  │ commands/       │  │ skills/         │ │
│  │   *.toml        │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │ agents/         │  │ extensions/     │                      │
│  │                 │  │   <name>/       │                      │
│  └─────────────────┘  └─────────────────┘                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ tmp/                                                    │   │
│  │   bin/                                                  │   │
│  │   <project_hash>/                                       │   │
│  │     chats/session-*.json                                │   │
│  │     shell_history                                       │   │
│  │     logs/                                               │   │
│  │     checkpoints/                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ history/                                                │   │
│  │   <project_hash>/                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Project-Level Storage

```
┌─────────────────────────────────────────────────────────────────┐
│                    Project .gemini/ Directory                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ settings.json   │  │ policies/*.toml │  │ commands/       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ skills/         │  │ agents/         │  │ extensions/     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Token Storage Selection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    HybridTokenStorage                            │
│             packages/core/src/mcp/token-storage/                 │
│                  hybrid-token-storage.ts                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ Is GEMINI_FORCE_FILE_STORAGE=true?                      │   │
│   └─────────────────────────────────────────────────────────┘   │
│            │ No                      │ Yes                      │
│            ▼                         ▼                          │
│   ┌─────────────────┐       ┌─────────────────┐                │
│   │ Try Keychain    │       │ FileTokenStorage│                │
│   │ (keytar module) │       │ (AES-256-GCM)   │                │
│   └─────────────────┘       └─────────────────┘                │
│            │                                                    │
│   ┌────────┴────────┐                                          │
│   │ isAvailable()?  │                                          │
│   └────────┬────────┘                                          │
│      Yes   │   No                                               │
│      ▼     ▼                                                    │
│   Keychain FileTokenStorage                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Indexes & Performance

### In-Memory Caching

#### File Crawl Cache

**Location**: `packages/core/src/utils/filesearch/crawlCache.ts`

**Purpose**: Cache file discovery results to avoid repeated filesystem scans

**Implementation**:

```typescript
// In-memory Map with TTL-based eviction
const crawlCache = new Map<string, string[]>();
const cacheTimers = new Map<string, NodeJS.Timeout>();

// Cache key generation (SHA-256 hash)
const getCacheKey = (directory, ignoreContent, maxDepth?) => {
  const hash = crypto.createHash('sha256');
  hash.update(directory);
  hash.update(ignoreContent);
  if (maxDepth) hash.update(String(maxDepth));
  return hash.digest('hex');
};
```

**Eviction**: Timer-based TTL eviction per entry

---

#### Conversation Data Caching

**Location**: `packages/core/src/services/chatRecordingService.ts:114`

**Purpose**: Avoid redundant file I/O when updating conversations

**Implementation**: `cachedLastConvData` string stores last-read JSON to skip
writes when unchanged

---

### Path Hashing

**Purpose**: Create unique identifiers for project-specific storage

**Location**: `packages/core/src/utils/paths.ts`,
`packages/core/src/config/storage.ts:116-118`

**Implementation**:

```typescript
// SHA-256 hash of project root path
const getFilePathHash = (filePath: string): string => {
  return crypto.createHash('sha256').update(filePath).digest('hex');
};
```

---

## Data Access Patterns

### Settings Access Pattern

**Location**: `packages/cli/src/config/settings.ts`

**Pattern**: Multi-scope loading with merge

```typescript
// 1. Load from all scopes
const systemDefaults = await loadSettingsFromPath(systemDefaultsPath);
const userSettings = await loadSettingsFromPath(userSettingsPath);
const workspaceSettings = await loadSettingsFromPath(workspaceSettingsPath);
const systemSettings = await loadSettingsFromPath(systemSettingsPath);

// 2. Merge with precedence (later wins)
const merged = customDeepMerge(
  systemDefaults,
  userSettings,
  workspaceSettings,
  systemSettings,
);

// 3. Resolve environment variables
const resolved = resolveEnvVarsInObject(merged);

// 4. Validate with Zod schema
const validated = SETTINGS_SCHEMA.parse(resolved);
```

---

### Conversation Recording Pattern

**Location**: `packages/core/src/services/chatRecordingService.ts`

**Pattern**: Atomic read-modify-write with caching

```typescript
// Read
private readConversation(): ConversationRecord {
  this.cachedLastConvData = fs.readFileSync(this.conversationFile, 'utf8');
  return JSON.parse(this.cachedLastConvData);
}

// Write (only if changed)
private writeConversation(conversation: ConversationRecord): void {
  if (this.cachedLastConvData !== JSON.stringify(conversation, null, 2)) {
    conversation.lastUpdated = new Date().toISOString();
    fs.writeFileSync(this.conversationFile, JSON.stringify(conversation, null, 2));
  }
}

// Update helper
private updateConversation(updateFn: (conv: ConversationRecord) => void) {
  const conversation = this.readConversation();
  updateFn(conversation);
  this.writeConversation(conversation);
}
```

---

### Token Storage Pattern

**Location**: `packages/core/src/mcp/token-storage/`

**Pattern**: Strategy pattern with fallback

```typescript
// HybridTokenStorage delegates to available backend
class HybridTokenStorage extends BaseTokenStorage {
  private async initializeStorage(): Promise<TokenStorage> {
    // Try keychain first (if not forced to file)
    if (!forceFileStorage) {
      const keychainStorage = new KeychainTokenStorage(this.serviceName);
      if (await keychainStorage.isAvailable()) {
        return keychainStorage;
      }
    }
    // Fallback to encrypted file storage
    return new FileTokenStorage(this.serviceName);
  }
}
```

---

### Policy Loading Pattern

**Location**: `packages/core/src/policy/toml-loader.ts`

**Pattern**: Directory scan with validation

```typescript
// Scan directory for .toml files
const entries = await fs.readdir(directory, { withFileTypes: true });
const tomlFiles = entries.filter((e) => e.isFile() && e.name.endsWith('.toml'));

// Parse and validate each file
for (const file of tomlFiles) {
  const content = await fs.readFile(path.join(directory, file.name), 'utf-8');
  const parsed = TOML.parse(content);
  const validated = PolicyFileSchema.safeParse(parsed);
  if (validated.success) {
    rules.push(...validated.data.rule);
  } else {
    errors.push({ fileName: file.name, error: validated.error });
  }
}
```

---

## Migrations & Schema Evolution

### Settings Migration (V1 → V2)

**Location**: `packages/cli/src/config/settings.ts`

**Purpose**: Migrate flat V1 settings structure to nested V2 format

**Implementation**:

```typescript
const MIGRATION_MAP: Record<string, string> = {
  apiKey: 'api.key',
  modelName: 'model.name',
  // ... more mappings
};

function migrateSettingsToV2(v1Settings: unknown): Settings {
  const result = {};
  for (const [oldKey, newPath] of Object.entries(MIGRATION_MAP)) {
    if (oldKey in v1Settings) {
      setNestedValue(result, newPath, v1Settings[oldKey]);
    }
  }
  return result;
}

function needsMigration(settings: unknown): boolean {
  return Object.keys(MIGRATION_MAP).some((key) => key in settings);
}
```

---

### Token Storage Migration (V1 → V2)

**Location**: `packages/core/src/mcp/token-storage/file-token-storage.ts:22`

**Purpose**: Previous version used `mcp-oauth-tokens.json`, now uses
`mcp-oauth-tokens-v2.json`

**Change**: V2 uses AES-256-GCM encryption; V1 was less secure

---

## Connection Management

### File System Operations

**Pattern**: Synchronous for critical paths, async where possible

```typescript
// Synchronous (for settings, state that blocks startup)
fs.readFileSync(path, 'utf-8');
fs.writeFileSync(path, content);
fs.mkdirSync(dir, { recursive: true });

// Asynchronous (for non-blocking operations)
await fs.promises.readFile(path, 'utf-8');
await fs.promises.writeFile(path, content);
await fs.promises.mkdir(dir, { recursive: true });
```

---

### Directory Creation

**Pattern**: Recursive creation with error handling

**Location**: Multiple files use `fs.mkdirSync(dir, { recursive: true })`

```typescript
// Ensure directory exists before write
fs.mkdirSync(path.dirname(filePath), { recursive: true });
fs.writeFileSync(filePath, content);
```

---

### Keychain Access

**Location**: `packages/core/src/mcp/token-storage/keychain-token-storage.ts`

**Pattern**: Lazy loading with availability check

```typescript
// Dynamic import (keytar is optional dependency)
async getKeytar(): Promise<Keytar | null> {
  if (this.keytarLoadAttempted) return this.keytarModule;
  this.keytarLoadAttempted = true;
  try {
    const module = await import('keytar');
    this.keytarModule = module.default || module;
  } catch { /* optional, ignore failure */ }
  return this.keytarModule;
}

// Availability check with test write/read/delete cycle
async checkKeychainAvailability(): Promise<boolean> {
  const keytar = await this.getKeytar();
  if (!keytar) return false;

  const testAccount = `__keychain_test__${crypto.randomBytes(8).toString('hex')}`;
  await keytar.setPassword(this.serviceName, testAccount, 'test');
  const retrieved = await keytar.getPassword(this.serviceName, testAccount);
  const deleted = await keytar.deletePassword(this.serviceName, testAccount);
  return deleted && retrieved === 'test';
}
```

---

### GCS Connection (A2A Server)

**Location**: `packages/a2a-server/src/persistence/gcs.ts`

**Pattern**: Lazy bucket initialization

```typescript
class GCSTaskStore implements TaskStore {
  private storage: Storage;
  private bucketInitialized: Promise<void>;

  constructor(bucketName: string) {
    this.storage = new Storage();
    this.bucketInitialized = this.initializeBucket();
  }

  private async ensureBucketInitialized(): Promise<void> {
    await this.bucketInitialized;
  }

  async save(task: SDKTask): Promise<void> {
    await this.ensureBucketInitialized();
    // ... save logic
  }
}
```

---

## Seed Data & Fixtures

### Default Policies

**Location**: `packages/core/src/policy/policies/`

**Files**:

| File              | Purpose                                           |
| ----------------- | ------------------------------------------------- |
| `agent.toml`      | Rules for agent tool execution                    |
| `read-only.toml`  | Rules for read-only tools (file read, grep, etc.) |
| `write.toml`      | Rules for file write/edit tools                   |
| `yolo.toml`       | Permissive rules for YOLO mode                    |
| `discovered.toml` | Auto-generated rules for discovered tools         |

**Example** (`read-only.toml`):

```toml
[[rule]]
toolName = "read_file"
decision = "allow"
priority = 50

[[rule]]
toolName = "list_directory"
decision = "allow"
priority = 50

[[rule]]
toolName = "grep"
decision = "allow"
priority = 50
```

---

### Test Fixtures

**Location**: Various test files use inline fixtures

**Pattern**: Test files create mock data structures matching schemas

```typescript
// Example from chatRecordingService.test.ts
const mockConversation: ConversationRecord = {
  sessionId: 'test-session-id',
  projectHash: 'test-hash',
  startTime: new Date().toISOString(),
  lastUpdated: new Date().toISOString(),
  messages: [],
};
```

---

### Integration Test Utilities

**Location**: `packages/test-utils/`

**Purpose**: Shared testing utilities for temp file management

```typescript
// Create temporary directories for test isolation
import { createTempDir, cleanupTempDir } from '@google/gemini-cli-test-utils';
```
