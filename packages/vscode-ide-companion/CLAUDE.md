# gemini-vscode-ide-companion

VS Code extension enabling IDE integration with Gemini CLI.

## Extension Purpose

Provides seamless integration between Gemini CLI and VS Code:

- Diff viewing and acceptance workflow
- File editing coordination
- Workspace context sharing
- MCP server for IDE communication

## Directory Structure

```
src/
├── diff-manager.ts       # Diff view management
├── extension.ts          # VS Code extension entry point
├── ide-server.ts         # MCP/Express server for CLI communication
├── open-files-manager.ts # Track open files in workspace
└── utils/
    └── logger.ts         # Logging utility
```

## Key Dependencies

- **VS Code API**: `@types/vscode`
- **MCP**: `@modelcontextprotocol/sdk`
- **Server**: `express`, `cors`
- **Validation**: `zod`

## Extension Commands

| Command                   | Description              |
| ------------------------- | ------------------------ |
| `gemini.diff.accept`      | Accept diff changes      |
| `gemini.diff.cancel`      | Close diff editor        |
| `gemini-cli.runGeminiCLI` | Run Gemini CLI           |
| `gemini-cli.showNotices`  | View third-party notices |

## Development

```bash
cd packages/vscode-ide-companion
npm run build              # Development build (default)
npm run build:dev          # Development build with checks and linting
npm run build:prod         # Production build
npm run watch              # Watch mode (builds and typechecks on changes)
npm run package            # Create .vsix package
```

## Architecture

1. **Extension Activation**: On VS Code startup (`onStartupFinished`)
2. **IDE Server**: Express server listens for CLI requests
3. **Diff Manager**: Handles file diff display and acceptance
4. **Open Files Manager**: Tracks workspace file state

## Testing Notes

- Tests use Vitest
- Mock VS Code API for unit tests
- Integration tests require VS Code extension host
