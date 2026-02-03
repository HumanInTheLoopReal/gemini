# Deployment

## Overview

Gemini CLI is a terminal-based AI assistant distributed as npm packages rather
than deployed as a traditional web service. The project uses GitHub Actions for
CI/CD with automated nightly releases and manual promotion workflows for preview
and stable channels.

- **CI/CD Platform**: GitHub Actions with custom reusable actions
- **Distribution**: npm registry (packages: `@google/gemini-cli`,
  `@google/gemini-cli-core`, `@google/gemini-cli-a2a-server`)
- **Container Support**: Docker sandbox image for secure code execution
- **Release Automation**: Nightly builds auto-publish; stable/preview require
  manual promotion

## Environments

| Environment    | Purpose                | npm Tag   | Auto-Deploy              | GitHub Release   |
| -------------- | ---------------------- | --------- | ------------------------ | ---------------- |
| **Local**      | Development            | N/A       | N/A                      | No               |
| **Dev**        | Internal testing       | `dev`     | Manual                   | No               |
| **Nightly**    | Daily snapshots        | `nightly` | Yes (cron: 0 0 \* \* \*) | Yes (prerelease) |
| **Preview**    | Pre-production testing | `preview` | Manual promotion         | Yes (prerelease) |
| **Production** | Stable release         | `latest`  | Manual promotion         | Yes              |

### Environment Details

**Local Development**

- **Purpose**: Developer workstation testing and feature development
- **How to Run**: `npm run build && npm start` or `npm run build-and-start`
- **Debug Mode**: `npm run debug` (enables `--inspect-brk`)

**Dev Environment**

- **Purpose**: Internal testing before public release
- **npm Tag**: `dev`
- **Installation**: `npm install -g @google/gemini-cli@dev`
- **Use Case**: Testing changes in isolation before nightly builds

**Nightly Environment**

- **Purpose**: Automated daily snapshots from main branch
- **npm Tag**: `nightly`
- **Installation**: `npm install -g @google/gemini-cli@nightly`
- **Version Format**: `X.Y.Z-nightly.YYYYMMDD.{short-sha}` (e.g.,
  `0.26.0-nightly.20260115.6cb3ae4e0`)
- **Auto-Deploy**: Daily at midnight UTC via `release-nightly.yml`
- **Use Case**: Early adopters testing latest features

**Preview Environment**

- **Purpose**: Pre-production validation before stable release
- **npm Tag**: `preview`
- **Installation**: `npm install -g @google/gemini-cli@preview`
- **Version Format**: `X.Y.Z-preview-N` (e.g., `0.26.0-preview-1`)
- **Trigger**: Manual via `release-promote.yml` workflow
- **Use Case**: Final testing before production release

**Production (Stable) Environment**

- **Purpose**: Public stable release for general users
- **npm Tag**: `latest`
- **Installation**: `npm install -g @google/gemini-cli` (default)
- **Version Format**: `X.Y.Z` (e.g., `0.26.0`)
- **Trigger**: Manual via `release-promote.yml` workflow
- **Use Case**: Production use by end users

## Deployment Flow

### Continuous Integration (Every Push/PR)

```
1. Developer pushes code or opens PR
2. CI workflow (ci.yml) triggers automatically
   ├─ Lint job: ESLint, Prettier, actionlint, shellcheck, yamllint
   ├─ Link Checker: Validates markdown links
   ├─ Test (Linux): Node 20.x, 22.x, 24.x × cli/others shards
   ├─ Test (Mac): Node 20.x, 22.x, 24.x × cli/others shards
   ├─ Test (Windows): Node 20.x (slow, continue-on-error)
   ├─ CodeQL: Security analysis
   └─ Bundle Size: Checks for bundle size regression
3. E2E tests (chained_e2e.yml) run in parallel
   ├─ E2E (Linux): sandbox:none, sandbox:docker
   ├─ E2E (macOS): sandbox:none
   ├─ E2E (Windows): sandbox:none (slow, continue-on-error)
   └─ Evals: Always-passing evaluation tests
4. All checks must pass before merge
```

### Nightly Release (Automatic)

```
1. Cron job triggers at 00:00 UTC daily (release-nightly.yml)
2. Checkout main branch
3. Run full test suite (build, unit tests, integration tests)
4. Calculate nightly version: X.Y.Z-nightly.YYYYMMDD.{sha}
5. Update package.json versions across monorepo
6. Build and bundle packages
7. Publish packages to npm with 'nightly' tag:
   ├─ @google/gemini-cli-core
   ├─ @google/gemini-cli
   └─ @google/gemini-cli-a2a-server
8. Verify npm release (install and run --version)
9. Create GitHub prerelease with bundled gemini.js
10. Create PR to merge version bump back to main
11. On failure: Auto-create GitHub issue with priority/p0 label
```

### Production Promotion (Manual)

```
1. Maintainer triggers release-promote.yml workflow manually
2. Calculate versions:
   ├─ Stable: Promote current preview to latest
   ├─ Preview: Promote current nightly to preview
   └─ Nightly: Prepare next nightly version
3. Run tests for all three channels in parallel
4. Publish preview release:
   ├─ Checkout preview SHA
   ├─ Publish packages with 'preview' tag
   └─ Create GitHub prerelease
5. Publish stable release:
   ├─ Checkout stable SHA
   ├─ Publish packages with 'latest' tag
   └─ Create GitHub release (not prerelease)
6. Create PR to bump main to next nightly version
7. On failure: Auto-create GitHub issue
```

### Manual Release (Ad-hoc)

```
1. Maintainer triggers release-manual.yml with:
   ├─ version: Target version (e.g., v0.26.0)
   ├─ ref: Branch/tag/SHA to release from
   ├─ npm_channel: Target channel (dev/preview/nightly/latest)
   └─ dry_run: Test mode flag
2. Run tests (unless force_skip_tests)
3. Build and publish to specified npm channel
4. Create GitHub release (unless skip_github_release)
```

## Quality Gates

### Before Any Deployment

<procedure>
Required CI checks (ci.yml):

- ✅ **Lint**: ESLint passes with zero errors
- ✅ **Format**: Prettier formatting verified
- ✅ **Lockfile**: package-lock.json integrity verified
- ✅ **NOTICES.txt**: License notices up to date
- ✅ **Settings docs**: Auto-generated docs match source
- ✅ **Sensitive keywords**: No leaked secrets/tokens
- ✅ **Unit tests**: All workspaces pass (cli, core, a2a-server, test-utils)
- ✅ **Bundle**: Successfully creates gemini.js bundle
- ✅ **Smoke test**: `node ./bundle/gemini.js --version` succeeds
- ✅ **CodeQL**: No security vulnerabilities detected
- ✅ **Bundle size**: No unexpected size increases (>1KB threshold) </procedure>

### Before E2E Tests

<procedure>
Required E2E checks (chained_e2e.yml):

- ✅ **E2E Linux (no sandbox)**: Integration tests pass
- ✅ **E2E Linux (Docker sandbox)**: Sandboxed tests pass
- ✅ **E2E macOS**: Integration tests pass
- ✅ **Evals**: Always-passing evaluation tests succeed </procedure>

### Before Release

<procedure>
Additional release checks:

- ✅ **Full test suite**: Unit + integration tests for target SHA
- ✅ **Integration tests (no sandbox)**: npm run test:integration:sandbox:none
- ✅ **Integration tests (docker sandbox)**: npm run
  test:integration:sandbox:docker
- ✅ **npm publish verification**: Installed package returns correct --version
- ✅ **GitHub release**: Bundle artifact uploaded successfully </procedure>

### Deployment Blockers

Deployment will be blocked if:

- ❌ CI workflow fails on any required job
- ❌ E2E tests fail (Linux or macOS)
- ❌ CodeQL detects high/critical vulnerabilities
- ❌ npm publish fails (auth, network, version conflict)
- ❌ Version verification fails (published version != expected)

## Rollback Procedures

### When to Rollback

Rollback immediately if:

- Critical bug discovered in released version
- Security vulnerability in released package
- Breaking changes that weren't intended
- npm package corruption or installation failures
- Regression in core functionality (file operations, shell execution)

### How to Rollback

**Method 1: GitHub Workflow Rollback** (Recommended)

<procedure>
1. Navigate to GitHub Actions → "Release: Rollback change"
2. Click "Run workflow" and configure:
   - `rollback_origin`: Version to rollback FROM (e.g., 0.26.0)
   - `rollback_destination`: Version to rollback TO (e.g., 0.25.0)
   - `channel`: npm tag to update (latest/preview/nightly)
   - `dry-run`: Set to false for actual rollback
   - `environment`: prod
3. Workflow will:
   - Change npm dist-tag to point to rollback_destination
   - Deprecate the rolled-back package version
   - Delete the GitHub release for rollback_origin
   - Create a rollback tag (e.g., v0.26.0-rollback)
4. Verify rollback succeeded by checking npm tags
</procedure>

**Method 2: Manual npm Tag Change**

```bash
# View current tags
npm dist-tag ls @google/gemini-cli

# Change 'latest' to point to previous version
npm dist-tag add @google/gemini-cli@0.25.0 latest

# Deprecate problematic version
npm deprecate "@google/gemini-cli@0.26.0" "This version has been rolled back due to critical issues"
```

**Method 3: Emergency Nightly Override**

```bash
# Trigger nightly release from specific SHA
# Use release-nightly.yml workflow with:
# - ref: <good-commit-sha>
# - dry_run: false
```

### Post-Rollback Verification

After rollback:

1. ✅ Verify npm tags point to correct versions:
   ```bash
   npm view @google/gemini-cli dist-tags
   ```
2. ✅ Test installation of rolled-back version:
   ```bash
   npm install -g @google/gemini-cli@latest
   gemini --version
   ```
3. ✅ Verify GitHub release page shows correct state
4. ✅ Confirm deprecated version shows warning on install
5. ✅ Document incident in GitHub issue

## Configuration Management

### Environment Variables

**CI/CD Variables (GitHub Actions)**

| Variable                      | Purpose                       | Where Set          |
| ----------------------------- | ----------------------------- | ------------------ |
| `GEMINI_API_KEY`              | API key for integration tests | Repository secret  |
| `GITHUB_TOKEN`                | GitHub API access             | Auto-provided      |
| `GEMINI_CLI_ROBOT_GITHUB_PAT` | Robot account PAT for PRs     | Repository secret  |
| `WOMBAT_TOKEN_CLI`            | npm publish token (CLI)       | Environment secret |
| `WOMBAT_TOKEN_CORE`           | npm publish token (Core)      | Environment secret |
| `WOMBAT_TOKEN_A2A_SERVER`     | npm publish token (A2A)       | Environment secret |

**Environment-specific Variables (vars)**

| Variable                   | Purpose                     |
| -------------------------- | --------------------------- |
| `NPM_REGISTRY_PUBLISH_URL` | npm registry for publishing |
| `NPM_REGISTRY_URL`         | npm registry for reading    |
| `NPM_REGISTRY_SCOPE`       | Package scope (@google)     |
| `CLI_PACKAGE_NAME`         | CLI package name            |
| `CORE_PACKAGE_NAME`        | Core package name           |
| `A2A_PACKAGE_NAME`         | A2A server package name     |

**Runtime Environment Variables**

| Variable             | Purpose                            |
| -------------------- | ---------------------------------- |
| `GEMINI_API_KEY`     | User's Gemini API key              |
| `GEMINI_SANDBOX`     | Sandbox mode (false/docker/podman) |
| `GEMINI_DEV_TRACING` | Enable development tracing         |
| `NODE_ENV`           | Node.js environment                |
| `DEBUG`              | Enable debug logging               |

### Secrets Management

**GitHub Environments**

The project uses two GitHub environments for releases:

- **prod**: Production npm registry (registry.npmjs.org)
- **dev**: Internal/testing npm registry

Secrets are environment-scoped, ensuring production tokens aren't used for dev
releases.

**npm Authentication**

npm tokens are stored as GitHub secrets and injected via the `npm-auth-token`
composite action, which selects the appropriate token based on package name.

**Local Development Secrets**

For local development, developers need:

```bash
# Set Gemini API key for testing
export GEMINI_API_KEY="your-api-key"

# For artifact registry auth (optional)
npm run auth:npm
npm run auth:docker
```

### Feature Flags

Feature flags are managed through:

1. **Environment variables**: Runtime behavior toggles
2. **Package.json config**: Build-time configuration (e.g., `sandboxImageUri`)
3. **Settings files**: User preferences in `~/.gemini/settings.json`

## Monitoring Post-Deploy

### After Nightly Release

<procedure>
**First 15 Minutes**

- ✅ Check GitHub Actions workflow completed successfully
- ✅ Verify npm package published: `npm view @google/gemini-cli@nightly`
- ✅ Test installation:
  `npm install -g @google/gemini-cli@nightly && gemini --version`
- ✅ Check GitHub release page for new prerelease
- ✅ Monitor GitHub issues for immediate bug reports

**First 24 Hours**

- ✅ Monitor GitHub issues for user-reported problems
- ✅ Check npm download stats for anomalies
- ✅ Review any automated issue creation (release-failure label)
- ✅ Verify PR to merge version bump was auto-merged </procedure>

### After Stable Release

<procedure>
**First 15 Minutes**

- ✅ Verify `@latest` tag points to new version
- ✅ Test clean installation: `npm install -g @google/gemini-cli`
- ✅ Run basic smoke test: `gemini --version && gemini --help`
- ✅ Check GitHub release is marked as "Latest"
- ✅ Verify all three packages published (core, cli, a2a-server)

**First 24-48 Hours**

- ✅ Monitor GitHub issues (filter by creation date)
- ✅ Watch for npm download spike followed by reports
- ✅ Check social media/community channels for feedback
- ✅ Monitor for security advisories </procedure>

### What to Watch

**Metrics to Monitor**

- npm download counts (sudden drops indicate install failures)
- GitHub issue velocity (spikes indicate regressions)
- Workflow failure rate (indicates CI/CD health)

**Common Post-Deploy Signals**

| Signal                   | Indicates                          |
| ------------------------ | ---------------------------------- |
| `npm ERR! 404` reports   | Package not published correctly    |
| Version mismatch reports | Tag pointing to wrong version      |
| Sandbox failures         | Docker image not pushed/accessible |
| Auth errors              | OAuth/API key integration issues   |

## Common Issues

### Issue: npm Publish Fails

**Symptoms**

- Workflow fails at "Publish CLI/Core/A2A" step
- Error: `npm ERR! 403 Forbidden` or `npm ERR! 401 Unauthorized`

**Where to Check**

1. GitHub Actions workflow logs
2. npm token validity (check Wombat token expiration)
3. Package version conflicts on npm registry

**Common Causes**

- Expired Wombat tokens
- Version already exists on npm
- Network connectivity issues
- Rate limiting

**Resolution**

1. Refresh Wombat tokens in GitHub secrets
2. If version exists, bump to next version
3. Retry workflow with same inputs
4. Contact npm support if persistent

### Issue: Version Verification Fails

**Symptoms**

- Workflow fails at "Verify NPM release by version" step
- Published version doesn't match expected version

**Where to Check**

```bash
# Check what was actually published
npm view @google/gemini-cli versions --json | tail -5

# Check dist-tags
npm view @google/gemini-cli dist-tags
```

**Common Causes**

- npm registry propagation delay
- Concurrent releases causing version conflicts
- Package.json version out of sync

**Resolution**

1. Wait 2-3 minutes for registry propagation
2. Re-run verification step
3. Manually verify:
   `npm install @google/gemini-cli@<version> && gemini --version`

### Issue: GitHub Release Creation Fails

**Symptoms**

- npm packages published but no GitHub release
- Error in "Create GitHub Release" step

**Where to Check**

1. GitHub Actions workflow logs
2. GitHub releases page for partial release
3. Git tags in repository

**Common Causes**

- `GITHUB_TOKEN` permission issues
- Release tag already exists
- Bundle artifact missing

**Resolution**

1. Manually create release via GitHub UI
2. Upload bundle/gemini.js as release asset
3. Set appropriate prerelease flag

### Issue: Nightly Cron Not Triggering

**Symptoms**

- No nightly release created
- Workflow not appearing in Actions history

**Where to Check**

1. GitHub Actions → release-nightly.yml
2. Repository settings → Actions → General
3. Recent repository activity (commits to main)

**Common Causes**

- Repository inactivity (GitHub disables crons after 60 days)
- Workflow file syntax error
- Branch protection preventing workflow

**Resolution**

1. Manually trigger workflow via workflow_dispatch
2. Make a commit to reactivate cron
3. Check workflow file for syntax errors

### Issue: Rollback Tag Already Exists

**Symptoms**

- Rollback workflow fails at "Add Rollback Tag" step
- Error: `tag already exists`

**Where to Check**

```bash
git tag -l "*rollback*"
git ls-remote --tags origin | grep rollback
```

**Common Causes**

- Previous rollback for same version
- Manual tag creation

**Resolution**

1. Delete existing rollback tag:
   ```bash
   git push origin :refs/tags/v0.26.0-rollback
   ```
2. Re-run rollback workflow

## Local Development

### Prerequisites

- Node.js 20.x or higher (see `.nvmrc`)
- npm 9.x or higher
- Git
- Docker (for sandbox testing)

### Running Locally

```bash
# 1. Clone repository
git clone https://github.com/google-gemini/gemini-cli.git
cd gemini-cli

# 2. Install dependencies
npm ci

# 3. Build all packages
npm run build

# 4. Run CLI
npm start

# OR build and start in one command
npm run build-and-start
```

### Development Workflow

```bash
# Run in development mode (with React DevTools)
DEV=true npm start

# Run with debugger attached
npm run debug

# Run specific package's tests
npm run test --workspace @google/gemini-cli
npm run test --workspace @google/gemini-cli-core

# Run all tests with coverage
npm run test:ci

# Run E2E tests (no sandbox)
npm run test:e2e
# OR
npm run test:integration:sandbox:none

# Run E2E tests (with Docker sandbox)
npm run test:integration:sandbox:docker
```

### Pre-commit Checks

```bash
# Run full preflight check (required before PRs)
npm run preflight

# Individual checks
npm run lint        # ESLint
npm run format      # Prettier
npm run typecheck   # TypeScript
npm run test        # Unit tests
```

### Docker Local Build

```bash
# Build sandbox container
npm run build:sandbox

# Build all (main + sandbox + VSCode extension)
npm run build:all

# Build Docker image manually
docker build -t gemini-cli:local .

# Run container
docker run -it --rm \
  -e GEMINI_API_KEY="$GEMINI_API_KEY" \
  gemini-cli:local
```

### Bundling

```bash
# Create production bundle
npm run bundle

# Test bundle
node ./bundle/gemini.js --version
node ./bundle/gemini.js --help
```

### Development Tracing

```bash
# Enable tracing
GEMINI_DEV_TRACING=true npm start

# Start trace viewer (Genkit)
npm run telemetry -- --target=genkit

# Start trace viewer (Jaeger)
npm run telemetry -- --target=local
```

## Related Documentation

- **Architecture**: See `.alfred/docs/architecture.md` for system components
- **Testing**: See `.alfred/docs/testing.md` for test execution details
- **Contributing**: See `CONTRIBUTING.md` in repository root
- **API Reference**: See `docs/` directory for user documentation
