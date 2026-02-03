# UI Module

React 19 + Ink terminal UI layer providing interactive terminal interface,
component hierarchy, state management contexts, and custom hooks for user
interaction and display.

## Architecture

The UI module implements a layered React/Ink architecture with:

- **App Container** (`AppContainer.tsx`) - main orchestrator managing UI state,
  session lifecycle, command processing
- **Contexts** - React contexts for app state, settings, keyboard input,
  scrolling, UI actions, streaming state, mouse events
- **Layouts** - top-level layout components (default and screen reader
  accessible)
- **Components** - reusable Ink-based UI components organized into
  subdirectories (messages/, shared/, views/)
- **Commands** - slash command handlers and types (internal to UI module)
- **Hooks** - custom React hooks for input handling, streaming, command
  processing, auto-completion
- **Utils** - shared utilities for markdown rendering, table formatting, UI
  sizing, colors, highlighting
- **Auth** - authentication UI components and hooks
- **Themes** - color themes and styling configurations
- **State** - state management utilities for extensions and other features

Key principle: Components are **presentational only** - state management and
side effects handled by contexts and hooks. App state flows down via contexts,
actions flow up via dispatch functions.

## Key Files

| File                                | Purpose                                                                                     | When to Modify                                                    |
| ----------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `App.tsx`                           | Top-level app component - conditional routing based on quitting state and accessibility     | When adding new top-level screens or modifying quit flow          |
| `AppContainer.tsx`                  | Main orchestrator - manages UI state, session lifecycle, tool execution, command processing | When adding new features that affect global state or UI actions   |
| `types.ts`                          | Central type definitions - `HistoryItem`, `StreamingState`, `AuthState`, message types      | When adding new history item types, message kinds, or auth states |
| `contexts/UIStateContext.tsx`       | Core UI state context - history, dialogs, streaming, confirmation requests                  | When adding new UI state or dialog requirements                   |
| `contexts/UIActionsContext.tsx`     | Actions dispatcher - exposes methods to update UI state                                     | When adding new actions that modify UI state                      |
| `contexts/AppContext.tsx`           | App metadata context - version, startup warnings                                            | When adding global app metadata                                   |
| `contexts/ConfigContext.tsx`        | Configuration state - provides access to config values                                      | When config state needs to be accessed in components              |
| `contexts/StreamingContext.tsx`     | Streaming state context - manages AI streaming state                                        | When modifying streaming behavior                                 |
| `contexts/KeypressContext.tsx`      | Keyboard input handling - key events, command matching, vim mode integration                | When modifying keybinding logic or adding new keyboard handlers   |
| `contexts/SettingsContext.tsx`      | User settings context - theme, editor preferences, vim mode                                 | When adding new user-facing settings                              |
| `contexts/VimModeContext.tsx`       | Vim mode state - vim enabled flag, mode tracking (NORMAL/INSERT)                            | When modifying vim integration or keyboard modes                  |
| `contexts/SessionContext.tsx`       | Session state tracking - duration, stats, token counts, quotas                              | When tracking new session metrics                                 |
| `contexts/ScrollProvider.tsx`       | Scroll state management - vertical/horizontal scrolling, batched updates, mouse support     | When modifying scroll behavior or adding scroll features          |
| `contexts/MouseContext.tsx`         | Mouse event handling - click events, drag operations                                        | When adding mouse interaction features                            |
| `contexts/ShellFocusContext.tsx`    | Shell input focus state - tracks if shell input area is focused                             | When modifying shell command input behavior                       |
| `contexts/OverflowContext.tsx`      | Overflow state tracking - manages overflowing element IDs for rendering                     | When adding new overflow detection or handling logic              |
| `layouts/DefaultAppLayout.tsx`      | Standard interactive layout - header, main content, composer, dialogs                       | When restructuring main layout or adding layout sections          |
| `components/MainContent.tsx`        | Main scrollable content area - renders message history with infinite scroll                 | When modifying history display or scrolling behavior              |
| `components/Composer.tsx`           | Input composition area - text buffer, autocomplete, shell command mode                      | When modifying input handling or composer features                |
| `components/HistoryItemDisplay.tsx` | History item renderer - dispatches to specific message renderers based on type              | When adding new history item types or modifying display           |
| `hooks/useGeminiStream.ts`          | AI streaming integration - handles tool calls, confirmations, streaming chunks              | When modifying AI integration or tool execution                   |
| `hooks/useKeypress.ts`              | Low-level keyboard input - reads stdin, emits key events with modifiers                     | When adding new keyboard input detection                          |

## Patterns

- **Context + Dispatch Pattern**: State held in context (e.g.,
  `UIStateContext`), updated via dispatch functions passed through
  `UIActionsContext`. Example: `uiActions.addHistoryItem(item)` updates
  `uiState.history`.

- **Custom Hooks for Side Effects**: Use custom hooks to encapsulate complex
  logic - keyboard input (`useKeypress`), streaming (`useGeminiStream`),
  scrolling (`useAnimatedScrollbar`). Hooks manage their own state and effects,
  expose clean API.

- **Ink Component Props**: Components receive Ink layout props (`width`,
  `height`, `flexDirection`, `flexGrow`) directly. Measure elements with
  `useElement()` from Ink when size-dependent logic needed.

- **TextBuffer Abstraction**: Input text managed through `TextBuffer` interface
  (`useTextBuffer()` hook) - provides insertion, deletion, cursor movement.
  Isolates text logic from UI component tree.

- **Message History as Union Types**: `HistoryItem` is discriminated union of
  specific message types (e.g., `HistoryItemGemini`, `HistoryItemToolGroup`,
  `HistoryItemInfo`). Use `type` field for narrowing.

- **Confirmation Request Pattern**: Dialogs (shell confirmation, settings
  confirmation) use callback pattern - request object passed to context,
  consumer renders dialog and calls `onConfirm()` with result.

- **Streaming State Machine**: `StreamingState` enum (`Idle`, `Responding`,
  `WaitingForConfirmation`) tracks AI response lifecycle. Tool calls buffered
  and displayed as `HistoryItemToolGroup` when streaming ends.

- **Shell Command Processing**: Commands prefixed with `~` parsed by
  `shellCommandProcessor` hook, executed via shell integration, results streamed
  back as special history items.

- **At Command Processing**: Commands prefixed with `@` parsed by
  `atCommandProcessor` hook for special command handling (e.g., `@file.txt` to
  reference files).

- **Alternate Buffer Mode**: Terminal's alternate screen buffer
  (`useAlternateBuffer()`) used for infinite scroll and mouse support.
  Non-alternate mode for simpler headless compatibility.

## Boundaries

- **DO**: Keep components presentational - render UI based on props, call
  actions on events
- **DO NOT**: Put async logic directly in components - use hooks to manage side
  effects (keyboard input, streaming, timers)
- **DO**: Use contexts for any state accessed by multiple components - avoid
  prop drilling
- **DO NOT**: Modify context state directly - go through dispatch in
  `UIActionsContext`

This module handles **terminal UI rendering and user interaction**, NOT
**backend logic** (that's `@google/gemini-cli-core`), NOT **configuration
storage** (that's in CLI config layer at `../config/`). Note: slash command
handlers ARE defined in `./commands/` subdirectory within this UI module.

## Relationships & Context Hierarchy

**Context Provider Order** (from `AppContainer.tsx` outward):

1. `UIStateContext` - Core UI state (history, dialogs, streaming)
2. `UIActionsContext` - Dispatch actions to modify UI state
3. `ConfigContext` - Configuration values
4. `AppContext` - App metadata (version, startup warnings)
5. `ShellFocusContext` - Shell input focus state
6. `StreamingContext` - AI streaming state (provided in `App.tsx`)
7. `OverflowProvider` - Overflow tracking (local to `MainContent` and
   `Composer`)

**External Dependencies**:

- **Depends on**: `@google/gemini-cli-core` - AI orchestration, tool execution,
  config schemas
- **Depends on**: `./commands/` - slash command definitions and types (internal
  to ui module)
- **Depends on**: `../config/` - Settings and authentication configuration
- **Uses**: `ink` - Terminal React renderer
- **Uses**: `react` - React 19 library

**Used by**:

- `AppContainer.tsx` - Imports entire UI subtree and provides all contexts
- `packages/cli/src/gemini.tsx` - Main CLI entry point

## Directory Structure Details

```
ui/
├── auth/              # Authentication UI components and hooks
├── commands/          # Slash command handlers and types
├── components/        # UI components (70+ components, organized in subdirectories)
│   ├── messages/      # History message renderers (GeminiMessage, ErrorMessage, etc.)
│   ├── shared/        # Reusable primitives (TextInput, Scrollable, Table, etc.)
│   └── views/         # Full-screen views (ChatList, ToolsList, etc.)
├── constants/         # UI constants and text constants
├── contexts/          # React contexts for state management (18 context files)
├── editors/           # Editor-specific integrations (Zed, etc.)
├── hooks/             # Custom React hooks (50+ hooks for various features)
├── layouts/           # Top-level app layouts (DefaultAppLayout, ScreenReaderAppLayout)
├── noninteractive/    # Non-interactive/headless mode components
├── privacy/           # Privacy-related components and utilities
├── state/             # State management utilities
├── themes/            # Color themes and styling
├── utils/             # Utility functions (markdown, tables, colors, syntax highlighting, etc.)
├── keyMatchers.ts     # Key binding matchers for keyboard input handling
├── App.tsx            # Top-level app component
├── AppContainer.tsx   # Main app container and context provider orchestrator
├── types.ts           # Central type definitions for UI layer
└── CLAUDE.md          # This file
```

## Adding New Component

1. Create component file in appropriate subdirectory:
   - `components/` - standalone feature components (e.g., `NewFeature.tsx`)
   - `components/messages/` - history message renderers (e.g.,
     `NewMessageType.tsx`)
   - `components/shared/` - reusable primitives (e.g., `NewPrimitive.tsx`)
   - `components/views/` - full-screen views (e.g., `ListView.tsx`)

2. Create component with TypeScript interface for props:

   ```tsx
   import type React from 'react';
   import { Box, Text } from 'ink';

   export interface MyComponentProps {
     title: string;
     onAction?: () => void;
   }

   export const MyComponent: React.FC<MyComponentProps> = ({
     title,
     onAction,
   }) => {
     return (
       <Box flexDirection="column">
         <Text>{title}</Text>
       </Box>
     );
   };
   ```

3. Create test file co-located: `MyComponent.test.tsx`

4. If component needs state: use hook pattern or access via context

5. If component needs layout control: use Ink's `Box`, `Text`, layout props

## Adding New History Item Type

1. Add type to `types.ts`:

   ```typescript
   export type HistoryItemMyFeature = HistoryItemBase & {
     type: 'my_feature';
     data: string;
   };
   ```

2. Add to `HistoryItemWithoutId` union in `types.ts`

3. Add `MessageType.MY_FEATURE` enum value if needed

4. Create message renderer in `components/messages/MyFeatureMessage.tsx`

5. Import and render in `MainContent.tsx` using type guard

## Adding New Context

1. Create context file: `contexts/MyContext.tsx`

   ```typescript
   import { createContext, useContext } from 'react';

   export interface MyContextValue {
     // state and methods
   }

   export const MyContext = createContext<MyContextValue | null>(null);

   export const useMyContext = () => {
     const ctx = useContext(MyContext);
     if (!ctx) throw new Error('useMyContext must be used within provider');
     return ctx;
   };
   ```

2. Create provider in `AppContainer.tsx` or parent component

3. Export and document in this file

4. Use via custom hook throughout app

## Testing

- Test files co-located with components: `MyComponent.test.tsx`
- Use `ink-testing-library` for rendering and assertion
- Mock contexts using `vi.mock()` for isolated component tests
- Mock `@google/gemini-cli-core` imports when testing UI without backend
- Snapshot tests for complex rendering (history items, tables)
- Use `vi.hoisted()` for mocks needed at module load time

Key utilities available in `packages/cli/src/test-utils/`:

- `render.tsx` - Provides custom render function with context setup
  (UIStateContext, UIActionsContext, etc.)
- `mockCommandContext.ts` - Mock command context for testing slash commands
- `createExtension.ts` - Helper for creating test extension objects
- `customMatchers.ts` - Custom Vitest matchers for assertions
- `createMockConfig.ts` - Helper for creating mock config objects
- `createMockSettings.ts` - Helper for creating mock settings objects

Example test:

```typescript
import { render } from 'ink-testing-library';
import { MyComponent } from './MyComponent.js';

describe('MyComponent', () => {
  it('renders title', () => {
    const { output } = render(<MyComponent title="Test" />);
    expect(output).toContain('Test');
  });
});
```

## Common Tasks

**Add a new slash command that affects UI state**:

1. Create command handler in `commands/` directory (e.g., `myCommand.ts`)
2. Define command metadata and handler function
3. Register in command list
4. Add to `slashCommandProcessor` chain in `hooks/slashCommandProcessor.ts`

**Display new type of message**:

1. Add history item type to `types.ts` (extend `HistoryItemWithoutId` union)
2. Create message renderer in `components/messages/`
3. Import and handle in `components/HistoryItemDisplay.tsx`

**Add new keyboard shortcut**:

1. Hook into `KeypressContext`
2. Add matcher to `keyMatchers.ts`
3. Dispatch action via `UIActionsContext`

**Modify app layout**:

- Edit `layouts/DefaultAppLayout.tsx` for standard layout
- Edit `layouts/ScreenReaderAppLayout.tsx` for accessibility mode

**Handle new streaming event**:

- Modify `useGeminiStream.ts` to detect event type
- Update streaming state and buffer for display
- Add corresponding history item type if needed

**Add new context**:

1. Create in `contexts/` directory
2. Provide in `AppContainer.tsx`
3. Use via custom hook in components
