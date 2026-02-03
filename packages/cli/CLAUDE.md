# @google/gemini-cli

Terminal UI package built with React 19 and Ink. Provides the interactive CLI
experience.

## Package Purpose

CLI is the user-facing terminal interface:

- Interactive terminal UI with React components
- Command parsing and execution
- User input handling and display
- Authentication flows and consent prompts

## Directory Structure

```
src/
├── __snapshots__/     # Test snapshots (auto-generated)
├── commands/          # CLI command definitions
├── config/            # CLI-specific configuration
├── core/              # Core CLI logic
├── generated/         # Auto-generated code (do not edit)
├── patches/           # Monkey patches for dependencies
├── services/          # CLI service integrations
├── test-utils/        # CLI testing utilities
├── ui/                # React/Ink components
│   ├── auth/          # Authentication UI
│   ├── components/    # Reusable UI components
│   │   ├── messages/  # Message display components
│   │   ├── shared/    # Shared primitives (TextInput, etc.)
│   │   └── views/     # View components (ChatList, etc.)
│   ├── contexts/      # React contexts (App, Settings, Scroll, etc.)
│   ├── hooks/         # Custom React hooks
│   ├── layouts/       # App layouts (Default, ScreenReader)
│   └── utils/         # UI utilities (markdown, table rendering)
├── utils/             # CLI utilities
├── zed-integration/   # Zed editor integration
├── gemini.tsx            # Main interactive app component
└── nonInteractiveCli.ts  # Non-interactive/headless mode
```

## Key Dependencies

- **UI Framework**: `react` (v19), `ink` (terminal React renderer)
- **Core**: `@google/gemini-cli-core` (backend functionality)
- **Styling**: `ink-gradient`, `ink-spinner`, `highlight.js`
- **CLI**: `yargs`, `prompts`

## Critical Patterns

### React/Ink Components

```tsx
// Use functional components with hooks
import { Box, Text } from 'ink';

export const MyComponent: React.FC<Props> = ({ data }) => {
  const [state, setState] = useState(initial);
  return (
    <Box flexDirection="column">
      <Text>{data}</Text>
    </Box>
  );
};
```

### Context Usage

```tsx
// Access app state via contexts
import { useAppContext } from './contexts/AppContext.js';
import { useSettings } from './contexts/SettingsContext.js';

const { session, dispatch } = useAppContext();
const { theme } = useSettings();
```

### File Naming

- `.tsx` files use PascalCase: `MyComponent.tsx`
- `.ts` files use kebab-case: `my-utility.ts`
- Test files: `MyComponent.test.tsx`

## Commands

```bash
npm run build --workspace=@google/gemini-cli     # Build
npm test --workspace=@google/gemini-cli          # Run tests
npm run start                                # Dev mode (from root)
```

## Testing Notes

- Use `ink-testing-library` for component tests
- Test files co-located with components
- Mock `@google/gemini-cli-core` when testing UI in isolation
- Snapshot tests for complex rendering

## Module Navigation

Each subdirectory has detailed guidance in its own CLAUDE.md:

| Module      | Purpose                    | Guide                               |
| ----------- | -------------------------- | ----------------------------------- |
| `commands/` | CLI command definitions    | [CLAUDE.md](src/commands/CLAUDE.md) |
| `config/`   | CLI-specific configuration | [CLAUDE.md](src/config/CLAUDE.md)   |
| `core/`     | Core CLI logic             | [CLAUDE.md](src/core/CLAUDE.md)     |
| `services/` | CLI service integrations   | [CLAUDE.md](src/services/CLAUDE.md) |
| `ui/`       | React/Ink components       | [CLAUDE.md](src/ui/CLAUDE.md)       |
| `utils/`    | CLI utilities              | [CLAUDE.md](src/utils/CLAUDE.md)    |
