# API

<overview>
Gemini CLI is a terminal-based AI assistant. The project has a dual API surface:

1. **A2A Server (Agent-to-Agent)** - An experimental HTTP server implementing
   the A2A protocol for inter-agent communication
2. **External API Dependencies** - Gemini CLI consumes multiple Google Cloud and
   external APIs for AI generation, telemetry, and tool integrations </overview>

## APIs Served by This Project

<section name="a2a-server">
The `packages/a2a-server` package provides an HTTP API implementing the A2A (Agent-to-Agent) protocol. This server enables external agents to interact with Gemini CLI as a backend service.

### Endpoints

<endpoint>
<method>GET</method>
<path>/.well-known/agent-card.json</path>
<description>Returns the A2A agent card describing server capabilities. This is a standard A2A protocol endpoint provided by the `@a2a-js/sdk` library.</description>
<response>
```json
{
  "name": "Gemini SDLC Agent",
  "description": "An agent that generates code based on natural language instructions and streams file outputs.",
  "url": "http://localhost:{port}/",
  "provider": {
    "organization": "Google",
    "url": "https://google.com"
  },
  "protocolVersion": "0.3.0",
  "version": "0.0.2",
  "capabilities": {
    "streaming": true,
    "pushNotifications": false,
    "stateTransitionHistory": true
  },
  "defaultInputModes": ["text"],
  "defaultOutputModes": ["text"],
  "skills": [
    {
      "id": "code_generation",
      "name": "Code Generation",
      "description": "Generates code snippets or complete files based on user requests, streaming the results.",
      "tags": ["code", "development", "programming"],
      "inputModes": ["text"],
      "outputModes": ["text"]
    }
  ]
}
```
</response>
</endpoint>

<endpoint>
<method>POST</method>
<path>/tasks</path>
<description>Creates a new task for the agent executor. Returns the task ID for subsequent operations.</description>
<request>
```json
{
  "agentSettings": {
    // Optional agent configuration settings
  },
  "contextId": "uuid-optional-context-id"
}
```
</request>
<response>
- **201 Created**: Returns task ID as JSON string
- **500 Internal Server Error**: Returns `{ "error": "error message" }`
</response>
</endpoint>

<endpoint>
<method>GET</method>
<path>/tasks/metadata</path>
<description>Lists metadata for all tasks. Only supported when using InMemoryTaskStore (not GCS).</description>
<response>
- **200 OK**: Array of task metadata objects
- **204 No Content**: No tasks exist
- **501 Not Implemented**: When using GCS task store
- **500 Internal Server Error**: Returns `{ "error": "error message" }`
</response>
</endpoint>

<endpoint>
<method>GET</method>
<path>/tasks/:taskId/metadata</path>
<description>Retrieves metadata for a specific task by ID.</description>
<params>
- `taskId` (path parameter): The unique task identifier
</params>
<response>
- **200 OK**: `{ "metadata": { ... task metadata ... } }`
- **404 Not Found**: `{ "error": "Task not found" }`
</response>
</endpoint>

<endpoint>
<method>POST</method>
<path>/executeCommand</path>
<description>Executes a registered command. Supports both streaming (SSE) and non-streaming responses based on command configuration.</description>
<request>
```json
{
  "command": "string (required)",
  "args": ["array", "of", "arguments (optional)"]
}
```
</request>
<response>
**Non-streaming:**
- **200 OK**: Command result as JSON
- **400 Bad Request**: Invalid command or args format
- **404 Not Found**: `{ "error": "Command not found: {command}" }`
- **500 Internal Server Error**: `{ "error": "error message" }`

**Streaming (when command.streaming = true):**

- **Content-Type**: `text/event-stream`
- Format: `data: { "jsonrpc": "2.0", "id": "...", "result": {...} }\n`
  </response> </endpoint>

<endpoint>
<method>GET</method>
<path>/listCommands</path>
<description>Lists all available top-level commands with their descriptions and arguments.</description>
<response>
```json
{
  "commands": [
    {
      "name": "command-name",
      "description": "Command description",
      "arguments": [
        {
          "name": "arg-name",
          "description": "Argument description",
          "required": true
        }
      ],
      "subCommands": [...]
    }
  ]
}
```
</response>
</endpoint>

### A2A Protocol Endpoints

The A2A server also exposes standard A2A protocol endpoints via
`A2AExpressApp.setupRoutes()`. These include task management, message sending,
and event subscription endpoints as defined by the A2A protocol specification.

### Authentication & Security

<security>
- **No built-in authentication**: The A2A server runs on localhost by default
- **Port Configuration**: Set via `CODER_AGENT_PORT` environment variable (defaults to dynamic port)
- **Workspace Requirement**: Some commands require `CODER_AGENT_WORKSPACE_PATH` to be set
</security>

### Rate Limiting & Constraints

<constraints>
- No explicit rate limiting implemented
- Task storage can be in-memory (InMemoryTaskStore) or Google Cloud Storage (GCSTaskStore via `GCS_BUCKET_NAME` env var)
- Maximum concurrent tasks limited by memory when using InMemoryTaskStore
</constraints>
</section>

## External API Dependencies

<section name="external-apis">

### Google Gemini API (Primary AI Provider)

<service>
<name>Google Gemini API / Generative AI API</name>
<purpose>Core AI content generation, streaming responses, token counting, and embeddings</purpose>
<sdk>`@google/genai` (GoogleGenAI class)</sdk>

<base-urls>
- **Gemini API**: `https://generativelanguage.googleapis.com` (via SDK)
- **Vertex AI**: `https://{region}-aiplatform.googleapis.com` (via SDK with vertexai: true)
</base-urls>

<endpoints-used>
1. **generateContent** - Generate text content from prompts
2. **generateContentStream** - Stream text content generation
3. **countTokens** - Count tokens in content
4. **embedContent** - Generate embeddings for text
</endpoints-used>

<authentication>
| Auth Type | Configuration |
|-----------|---------------|
| `gemini-api-key` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` environment variable |
| `vertex-ai` | Google Cloud credentials with `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` |
| `oauth-personal` | OAuth2 flow via Google auth library |
| `compute-default-credentials` | Application Default Credentials (ADC) |
</authentication>

<retry-configuration>
- Exponential backoff with jitter
- Retries on 5xx errors, 429 (rate limit), and network errors
- Never retries 400 Bad Request
- Quota-aware fallback to different models on persistent 429
</retry-configuration>

<headers>
```
User-Agent: GeminiCLI/{version}/{model} ({platform}; {arch})
x-gemini-api-privileged-user-id: {installation_id}  // When usage statistics enabled
Authorization: Bearer {token}  // When using bearer auth mechanism
```
</headers>
</service>

### Google Cloud Code Assist API (OAuth Flow)

<service>
<name>Cloud Code Assist / Code PA API</name>
<purpose>User onboarding, tier management, quota tracking, and telemetry for OAuth-authenticated users</purpose>
<base-url>`https://cloudcode-pa.googleapis.com/v1internal`</base-url>

<endpoints-used>
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `:generateContent` | POST | Content generation (streaming and non-streaming) |
| `:streamGenerateContent` | POST | Streaming content generation with SSE |
| `:countTokens` | POST | Token counting |
| `:onboardUser` | POST | User onboarding and tier selection |
| `:loadCodeAssist` | POST | Load user tier and project info |
| `:fetchAdminControls` | POST | Fetch admin controls (MCP settings, secure mode) |
| `:getCodeAssistGlobalUserSetting` | GET | Get user settings |
| `:setCodeAssistGlobalUserSetting` | POST | Update user settings |
| `:listExperiments` | POST | Fetch A/B experiment assignments |
| `:retrieveUserQuota` | POST | Get user quota information |
| `:recordCodeAssistMetrics` | POST | Record usage telemetry |
</endpoints-used>

<authentication>
OAuth2 via `google-auth-library` (AuthClient)
</authentication>

<streaming>
Uses Server-Sent Events (SSE) with `alt=sse` query parameter for streaming responses
</streaming>

<error-handling>
- VPC Service Controls errors return default STANDARD tier
- Checks for `SECURITY_POLICY_VIOLATED` in error details
</error-handling>
</service>

### Google Play Clearcut (Telemetry)

<service>
<name>Clearcut Logging Service</name>
<purpose>Usage analytics and telemetry (when enabled by user)</purpose>
<base-url>`https://play.googleapis.com/log?format=json&hasfast=true`</base-url>

<endpoints-used>
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/log` | POST | Batch log event submission |
</endpoints-used>

<authentication>
None (anonymous logging with installation ID or hashed email)
</authentication>

<request-format>
```json
[{
  "log_source_name": "CONCORD",
  "request_time_ms": 1234567890,
  "log_event": [[{
    "event_time_ms": 1234567890,
    "source_extension_json": "{\"console_type\":\"GEMINI_CLI\",...}",
    "exp": { "gws_experiment": [12345] }
  }]]
}]
```
</request-format>

<batching>
- Events buffered in memory (max 1000 events)
- Flushed every 60 seconds or on session end
- Failed events re-queued for retry (max 100 retry events)
</batching>

<events-logged>
`start_session`, `new_prompt`, `tool_call`, `api_request`, `api_response`, `api_error`, `end_session`, `loop_detected`, `slash_command`, `chat_compression`, `extension_install/uninstall/enable/disable`, `model_routing`, `agent_start/finish`, `hook_call`
</events-logged>
</service>

### Model Context Protocol (MCP) Servers

<service>
<name>MCP Protocol Integration</name>
<purpose>External tool and resource discovery via Model Context Protocol</purpose>
<sdk>`@modelcontextprotocol/sdk`</sdk>

<transports>
| Transport | Configuration |
|-----------|---------------|
| **Stdio** | `command` + `args` - Spawns subprocess |
| **SSE** | `url` with `type: "sse"` - Server-Sent Events |
| **HTTP** | `url` with `type: "http"` or `httpUrl` - Streamable HTTP |
</transports>

<protocol-methods-used>
- `tools/list` - Discover available tools
- `tools/call` - Execute tool
- `prompts/list` - Discover prompts
- `prompts/get` - Get prompt content
- `resources/list` - Discover resources
- `resources/read` - Read resource content
- `notifications/roots/list_changed` - Notify workspace changes
</protocol-methods-used>

<authentication>
| Provider | Configuration |
|----------|---------------|
| OAuth | Standard OAuth2 with PKCE, auto-discovery from `www-authenticate` header |
| Google Credentials | `authProviderType: "google-credentials"` |
| Service Account Impersonation | `authProviderType: "service-account-impersonation"` |
</authentication>

<timeout>Default: 10 minutes per operation (configurable via `timeout`
setting)</timeout> </service>

### Web Content Fetching

<service>
<name>HTTP Fetch</name>
<purpose>Fetching web content for the web-fetch tool</purpose>

<endpoints-used>
- Any HTTP/HTTPS URL provided by user
- GitHub raw content URLs (auto-converted from blob URLs)
</endpoints-used>

<constraints>
- Timeout: 10 seconds
- Max content length: 100,000 characters
- HTML content converted to text via `html-to-text`
- Private IP addresses handled via fallback mechanism
</constraints>

<fallback>
If primary URL context fetch fails:
1. Fetch raw content directly
2. Process via Gemini API with user's prompt
</fallback>
</service>

### Integration Patterns

<patterns>
<pattern name="retry-with-backoff">
All external API calls use centralized retry logic in `packages/core/src/utils/retry.ts`:
- Exponential backoff with jitter
- Max 10 attempts by default
- AbortSignal support for cancellation
- Separate handling for rate limits (429) vs server errors (5xx)
- Model fallback on persistent quota errors
</pattern>

<pattern name="streaming">
Streaming responses use AsyncGenerators:
```typescript
async function* generateContentStream(): AsyncGenerator<GenerateContentResponse> {
  for await (const chunk of stream) {
    yield chunk;
  }
}
```
</pattern>

<pattern name="circuit-breaker">
Model availability tracking in `packages/core/src/availability/`:
- Tracks model health states
- Automatic fallback to alternative models
- Configurable retry policies per model
</pattern>

<pattern name="content-generator-abstraction">
All AI API calls go through `ContentGenerator` interface:
```typescript
interface ContentGenerator {
  generateContent(request, userPromptId): Promise<GenerateContentResponse>;
  generateContentStream(request, userPromptId): Promise<AsyncGenerator<GenerateContentResponse>>;
  countTokens(request): Promise<CountTokensResponse>;
  embedContent(request): Promise<EmbedContentResponse>;
}
```
This allows swapping between Gemini API, Code Assist API, and fake generators for testing.
</pattern>
</patterns>
</section>

## Available Documentation

<section name="documentation">

### API Specifications

<documentation>
<item>
<path>`packages/a2a-server/src/http/app.ts`</path>
<type>Source code</type>
<description>Defines all A2A server HTTP endpoints using Express.js</description>
<quality>Good - well-documented code with clear endpoint definitions</quality>
</item>

<item>
<path>`packages/core/src/code_assist/types.ts`</path>
<type>TypeScript interfaces</type>
<description>Request/response types for Cloud Code Assist API</description>
<quality>Comprehensive - includes all request/response structures with Zod schemas</quality>
</item>

<item>
<path>`packages/core/src/code_assist/server.ts`</path>
<type>Source code</type>
<description>Code Assist API client implementation with all endpoints</description>
<quality>Well-documented with clear method signatures</quality>
</item>

<item>
<path>`packages/core/src/core/contentGenerator.ts`</path>
<type>TypeScript interfaces</type>
<description>ContentGenerator interface and factory functions for API clients</description>
<quality>Good abstraction layer for API interactions</quality>
</item>
</documentation>

### Integration Guides

<documentation>
<item>
<path>`packages/core/src/tools/mcp-client.ts`</path>
<type>Source code</type>
<description>Complete MCP client implementation including OAuth, transport configuration, and tool discovery</description>
<quality>Comprehensive - includes all transport types and authentication patterns</quality>
</item>

<item>
<path>`packages/core/src/telemetry/clearcut-logger/clearcut-logger.ts`</path>
<type>Source code</type>
<description>Clearcut telemetry implementation with all event types</description>
<quality>Well-structured with clear event definitions</quality>
</item>

<item>
<path>`CLAUDE.md`</path>
<type>Markdown</type>
<description>Project overview including architecture, configuration, and API interaction patterns</description>
<quality>Excellent - comprehensive documentation of all systems</quality>
</item>

<item>
<path>`packages/core/CLAUDE.md`</path>
<type>Markdown</type>
<description>Core package documentation with tool implementation patterns and API integration details</description>
<quality>Good - detailed module-level documentation</quality>
</item>
</documentation>

### Configuration Reference

<documentation>
<item>
<path>Environment Variables</path>
<type>Configuration</type>
<content>
| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Gemini API authentication |
| `GOOGLE_API_KEY` | Google API key (Vertex AI) |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID |
| `GOOGLE_CLOUD_LOCATION` | GCP region |
| `CODE_ASSIST_ENDPOINT` | Override Code Assist API endpoint |
| `GCS_BUCKET_NAME` | GCS bucket for A2A task persistence |
| `CODER_AGENT_PORT` | A2A server port |
| `CODER_AGENT_WORKSPACE_PATH` | Workspace path for A2A commands |
</content>
</item>
</documentation>
</section>
