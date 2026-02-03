# Policy Engine

Security policy enforcement system for AI tool execution and hook management.
Controls which tools can execute and under what conditions through a
priority-based rule system with multi-tier policy files.

## Architecture

The policy module implements a tiered, priority-based security system:

- **PolicyEngine**: Core decision engine that evaluates tool calls and hook
  executions against configured rules
- **TOML Loader**: Parses policy files from default/user/admin directories with
  validation and error reporting
- **Safety Checkers**: Pluggable validators (in-process and external) for
  additional security checks
- **Priority System**: Three-tier hierarchy (Default < User < Admin) with
  sub-priorities within each tier

Key types: `PolicyRule`, `SafetyCheckerRule`, `HookCheckerRule`,
`PolicyEngineConfig`, `PolicyDecision`

## Key Files

| File                  | Purpose                                                                                         | When to Modify                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `policy-engine.ts`    | Core policy evaluation logic, rule matching, safety checker orchestration                       | Add new decision logic, shell command handling, or checker integration           |
| `types.ts`            | Type definitions for rules, decisions, checkers, and hook contexts                              | Add new policy fields, decision types, or checker configurations                 |
| `config.ts`           | Policy initialization, tier management, TOML file loading, dynamic rule generation              | Modify policy loading sequence, tier priorities, or settings-based rule creation |
| `toml-loader.ts`      | TOML parsing, validation (Zod schemas), rule transformation                                     | Add new TOML syntax, validation rules, or expand tool/command patterns           |
| `stable-stringify.ts` | Deterministic JSON serialization for consistent args pattern matching                           | Modify JSON serialization behavior (rarely needed)                               |
| `policies/*.toml`     | Default policy definitions (agent.toml, read-only.toml, write.toml, yolo.toml, discovered.toml) | Add default policies for new tools or approval modes                             |

## Patterns

- **Priority-Based Matching**: Rules evaluated highest-to-lowest priority; first
  match wins. Reference `PolicyRule.priority`
- **Three-Tier Hierarchy**: Admin (3.x) > User (2.x) > Default (1.x) ensures
  organizational control. Tier calculated as `tier + priority/1000`
- **Wildcard MCP Tools**: Pattern `serverName__*` matches all tools from an MCP
  server. See `ruleMatches()` for implementation
- **Shell Command Recursion**: Compound shell commands (`;`, `&&`, `||`) are
  split and each sub-command evaluated separately. Reference `splitCommands()`
  in `shell-utils.ts`
- **Safety Checker Pipeline**: After rule matching, safety checkers can upgrade
  decisions from ALLOW to ASK_USER or DENY. See `SafetyCheckerRule`
- **Non-Interactive Mode**: `ASK_USER` decisions automatically become `DENY`
  when `nonInteractive` is true
- **Hook Source Validation**: Hooks denied in untrusted folders when
  `hookSource === 'project'`. Reference `HookExecutionContext`

## Boundaries

- **DO**: Use tiered policy files (default/user/admin) for organized security
  rules
- **DO**: Rely on stable-stringify for consistent args pattern matching across
  environments
- **DO**: Validate TOML syntax with Zod schemas before transforming rules
- **DO**: Use safety checkers for complex validation logic (path checking,
  external validators)
- **DO NOT**: Hard-code security decisions - use policy rules instead
- **DO NOT**: Bypass the priority system - it ensures admin policies always win
- **DO NOT**: Mutate `PolicyEngine` rules directly after construction (use
  `addRule`, `addChecker`)
- This module handles policy **evaluation**, NOT policy **UI** - UI components
  belong in `@google/gemini-cli`
- This module handles tool **authorization**, NOT tool **execution** - execution
  belongs in `../tools/`

## Relationships

- **Depends on**: `../safety/` - Safety checker protocol and runner
  implementation
- **Depends on**: `../confirmation-bus/` - Message bus for dynamic policy
  updates, hook execution requests
- **Depends on**: `../config/storage.ts` - User/system policy directory paths
- **Depends on**: `../utils/shell-utils.ts` - Shell command parsing for compound
  command handling
- **Used by**: `../core/coreToolScheduler.ts` - Tool authorization before
  execution
- **Used by**: `../agents/local-executor.ts` - Agent-level policy enforcement
- **Used by**: `@google/gemini-cli` - Policy configuration UI, user confirmation
  prompts

## Adding New Policy Rules

1. **For default policies**: Create/edit TOML file in `policies/` directory:

   ```toml
   [[rule]]
   toolName = "my_tool"
   decision = "allow"  # or "deny", "ask_user"
   priority = 50       # 0-999, higher wins
   modes = ["default"] # optional: filter by approval mode
   ```

2. **For MCP server tools**: Use `mcpName` field for automatic tool name
   prefixing:

   ```toml
   [[rule]]
   mcpName = "my-server"
   toolName = "my_tool"  # becomes "my-server__my_tool"
   decision = "allow"
   priority = 100
   ```

3. **For shell commands**: Use convenience syntax with `commandPrefix`:

   ```toml
   [[rule]]
   toolName = "run_shell_command"
   commandPrefix = "git status"  # auto-converts to argsPattern
   decision = "allow"
   priority = 75
   ```

4. **Update tier priorities** in `config.ts` if adding new dynamic rule sources

5. **Test**: Add test cases in `policy-engine.test.ts` for new rule matching
   logic

## Adding New Safety Checkers

1. Define checker in TOML with `[[safety_checker]]` section:

   ```toml
   [[safety_checker]]
   toolName = "run_shell_command"
   priority = 100

   [safety_checker.checker]
   type = "in-process"
   name = "allowed-path"
   required_context = ["cwd"]
   [safety_checker.checker.config]
   included_args = ["command"]
   ```

2. For in-process checkers: Add to `InProcessCheckerType` enum in `types.ts`

3. For external checkers: Use `type = "external"` with custom validator name

4. Implement checker logic in `../safety/checker-runner.ts`

5. Test with `runChecker()` mock in policy engine tests

## Testing

- **Unit tests**: `policy-engine.test.ts`, `toml-loader.test.ts`,
  `config.test.ts`
- **Test pattern**: Mock `CheckerRunner` with `vi.fn()` to control safety
  checker results
- **Shell safety**: `shell-safety.test.ts` validates compound command parsing
  and recursive evaluation
- **TOML validation**: `toml-loader.test.ts` covers schema validation, priority
  transformation, error handling
- **What to mock**: Safety checker responses (`SafetyCheckDecision`), file
  system for TOML loading
- **What NOT to mock**: Rule matching logic, priority sorting, stable-stringify
  (test determinism)
- **Test utilities**: Use `FunctionCall` type from `@google/genai` for tool call
  mocks

## Priority Reference Guide

### Tier System (Admin > User > Default)

- **Admin Tier (3.x)**: System-wide policies, highest precedence
- **User Tier (2.x)**: User preferences and CLI flags
- **Default Tier (1.x)**: Built-in policies from `policies/*.toml`

### Common Priority Values (Before Tier Transformation)

- `999`: YOLO mode allow-all (becomes 1.999 in default tier)
- `100-200`: Normal policy rules (e.g., 100 → 1.100, 200 → 1.200)
- `50`: Read-only tools (becomes 1.050)
- `15`: Auto-edit overrides (becomes 1.015)
- `10`: Write tools default (becomes 1.010)

### Dynamic Rule Priorities (User Tier 2.x)

- `2.95`: UI "Always Allow" selections
- `2.9`: MCP server exclusions (security blocks)
- `2.4`: CLI `--exclude-tools` flag
- `2.3`: CLI `--allowed-tools` flag
- `2.2`: Trusted MCP servers
- `2.1`: MCP server allow list

### Priority Calculation

```typescript
finalPriority = tier + priority / 1000;
// Example: User tier (2) with priority 100 → 2.100
// Example: Admin tier (3) with priority 50 → 3.050 (beats user 2.950)
```
