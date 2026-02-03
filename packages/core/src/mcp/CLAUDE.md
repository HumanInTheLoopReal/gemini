# MCP OAuth Authentication Module

OAuth 2.0 authentication provider for Model Context Protocol (MCP) servers.
Implements RFC 8414/9728 standards with PKCE flow, dynamic client registration,
secure token storage, and automatic refresh.

## Architecture

This module follows a layered architecture:

1. **Provider Layer**: `MCPOAuthProvider` orchestrates OAuth flows
   (authorization code + PKCE)
2. **Utility Layer**: `OAuthUtils` handles discovery, metadata fetching, and RFC
   compliance
3. **Storage Layer**: `MCPOAuthTokenStorage` manages token persistence via
   pluggable backends
4. **Token Storage Backends**: Hybrid keychain/file storage with encryption

Key interfaces: `McpAuthProvider`, `OAuthToken`, `OAuthCredentials`,
`TokenStorage`

## Key Files

| File                                      | Purpose                                                       | When to Modify                                  |
| ----------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| `oauth-provider.ts`                       | OAuth flow orchestration (authorize, token exchange, refresh) | When adding OAuth grant types or modifying flow |
| `oauth-utils.ts`                          | RFC 8414/9728 discovery, metadata parsing, JWT parsing        | When supporting new discovery mechanisms        |
| `oauth-token-storage.ts`                  | Token storage facade with hybrid backend                      | When changing token storage strategy            |
| `auth-provider.ts`                        | MCP-specific interface extending OAuthClientProvider          | When adding MCP transport header injection      |
| `google-auth-provider.ts`                 | Google ADC (Application Default Credentials) provider         | When modifying Google credential flow           |
| `sa-impersonation-provider.ts`            | Service account impersonation provider via IAM API            | When updating service account impersonation     |
| `token-storage/hybrid-token-storage.ts`   | Auto-selects keychain or encrypted file storage               | When adding new storage backends                |
| `token-storage/file-token-storage.ts`     | AES-256-GCM encrypted file storage                            | When modifying encryption or file format        |
| `token-storage/keychain-token-storage.ts` | macOS Keychain integration                                    | When updating keychain security policies        |
| `token-storage/base-token-storage.ts`     | Abstract base for storage implementations                     | When adding shared storage behavior             |
| `token-storage/types.ts`                  | Core type definitions                                         | When modifying token schema                     |

## Patterns

- **PKCE Flow**: All OAuth flows use Proof Key for Code Exchange (S256) per
  OAuth 2.0 for Public Clients
- **Auto-Discovery**: Supports RFC 8414 (OAuth 2.0 Authorization Server
  Metadata) and OpenID Connect Discovery
- **Dynamic Registration**: RFC 7591 client registration when client credentials
  not provided
- **Token Refresh**: Automatic refresh when `expiresAt` within 5-minute buffer,
  reference `FIVE_MIN_BUFFER_MS`
- **Hybrid Storage**: Auto-selects macOS Keychain if available, falls back to
  AES-256-GCM encrypted file storage
- **Resource Parameter**: Includes MCP server URL as `resource` parameter per
  MCP OAuth spec
- **WWW-Authenticate Discovery**: Parses `WWW-Authenticate` header for protected
  resource metadata

## Boundaries

- **DO**: Use `MCPOAuthProvider.authenticate()` for full OAuth flow with
  discovery
- **DO**: Use `MCPOAuthProvider.getValidToken()` to get access tokens (handles
  refresh)
- **DO**: Let `OAuthUtils` handle all metadata discovery and parsing
- **DO NOT**: Store tokens in plain text - always use `MCPOAuthTokenStorage`
- **DO NOT**: Skip PKCE parameters - all flows must use code challenge
- **DO NOT**: Bypass token expiry checks - use `isTokenExpired()` with buffer
- This module handles **OAuth authentication**, NOT authorization decisions -
  authorization belongs in policy layer
- This module handles **token storage**, NOT MCP transport - transport belongs
  in `tools/mcp-client.ts`

## Relationships

- **Depends on**:
  - `../config/storage.ts` - token file path resolution
  - `../utils/secure-browser-launcher.ts` - browser opening for auth flows
  - `../utils/events.ts` - error reporting via `coreEvents`
  - `../utils/debugLogger.ts` - debug logging
- **Used by**:
  - `../tools/mcp-client.ts` - MCP server OAuth authentication
  - `../config/config.ts` - OAuth config loading
  - CLI - Token management commands

## Adding New OAuth Features

### Adding a New Token Storage Backend

1. Extend `BaseTokenStorage` in `token-storage/`
2. Implement required methods: `getCredentials`, `setCredentials`,
   `deleteCredentials`, `listServers`, `getAllCredentials`, `clearAll`
3. Add logic to `HybridTokenStorage.initializeStorage()` for backend selection
4. Update `TokenStorageType` enum in `token-storage/types.ts`

### Adding a New Discovery Mechanism

1. Add new discovery method to `OAuthUtils` (e.g., `discoverFromXyz()`)
2. Parse discovered metadata into `MCPOAuthConfig` format
3. Call from `MCPOAuthProvider.authenticate()` discovery chain
4. Add metadata interface extending `OAuthAuthorizationServerMetadata` if needed

### Adding a New Grant Type

1. Add token exchange method to `MCPOAuthProvider` (e.g.,
   `exchangeDeviceCode()`)
2. Create request parameters per OAuth spec
3. Handle response parsing (JSON and form-urlencoded)
4. Add `resource` parameter if MCP-specific flow
5. Update authentication flow in `authenticate()` method

## Testing

### Running Tests

```bash
npm test --workspace=@google/gemini-cli-core -- oauth
```

### Key Test Utilities

- Mock `fetch` for OAuth endpoints (metadata, token exchange)
- Mock `openBrowserSecurely` to avoid actual browser launches
- Mock HTTP server for callback testing
- Use `vi.hoisted()` for OAuth provider mocks needed in factories

### What to Mock

- **Mock**: All `fetch` calls to authorization/token/registration endpoints
- **Mock**: `openBrowserSecurely` browser launcher
- **Mock**: File system operations for token storage
- **DO NOT Mock**: `OAuthUtils` utility methods (test actual parsing logic)
- **DO NOT Mock**: Token validation/expiry logic (critical security path)

### Test Coverage Focus

- OAuth discovery with multiple well-known endpoints
- PKCE parameter generation and validation
- Token expiry with 5-minute buffer
- Dynamic client registration flow
- Token refresh with expired access tokens
- Error handling: invalid state, missing code, malformed responses
- Storage backend selection (keychain vs file)
- Encrypted file storage (AES-256-GCM)
