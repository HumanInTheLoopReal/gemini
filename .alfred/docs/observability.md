# Observability

## Overview

Gemini CLI provides comprehensive observability through OpenTelemetry
integration, offering traces, metrics, and logs that can be exported to various
backends including Google Cloud, Jaeger, and file-based storage. The telemetry
system is built on the vendor-neutral OpenTelemetry framework, enabling
standardized data collection across all components.

**Key observability tools:**

- **OpenTelemetry SDK** — Distributed tracing, metrics, and structured logging
- **Google Cloud Monitoring** — Pre-configured dashboards for GCP deployments
- **Jaeger** — Local trace visualization for development
- **Debug Logger** — Developer-facing debug output via `debugLogger`
- **Core Events** — Real-time feedback through `coreEvents.emitFeedback()`

**Access points:**

- **GCP Console**: Cloud Trace, Cloud Logging, Cloud Monitoring
- **Local Jaeger UI**: `http://localhost:16686` (when running local telemetry)
- **File output**: `.gemini/telemetry.log` (configurable)
- **Debug logs**: Set `GEMINI_DEBUG_LOG_FILE` environment variable

## Metrics

### Accessing Metrics

**Local Development**:

- File-based: Configure `telemetry.outfile` in `.gemini/settings.json`
- Console: Default output when telemetry enabled without endpoint

**Production (GCP)**:

- Google Cloud Monitoring:
  `https://console.cloud.google.com/monitoring/metrics-explorer`
- Pre-configured dashboard: "Gemini CLI Monitoring" in Dashboard Templates

**Local Collector**:

```bash
npm run telemetry -- --target=local
# Metrics logged to ~/.gemini/tmp/<projectHash>/otel/collector.log
```

### Key Metrics to Monitor

<metrics_table>

| Metric Name                      | Type           | Description                    | Attributes                                          |
| -------------------------------- | -------------- | ------------------------------ | --------------------------------------------------- |
| `gemini_cli.session.count`       | Counter        | CLI sessions started           | Common attributes                                   |
| `gemini_cli.api.request.count`   | Counter        | API requests by model/status   | `model`, `status_code`, `error_type`                |
| `gemini_cli.api.request.latency` | Histogram (ms) | API request latency            | `model`                                             |
| `gemini_cli.tool.call.count`     | Counter        | Tool calls by function/success | `function_name`, `success`, `decision`, `tool_type` |
| `gemini_cli.tool.call.latency`   | Histogram (ms) | Tool call latency              | `function_name`                                     |
| `gemini_cli.token.usage`         | Counter        | Token consumption              | `model`, `type` (input/output/thought/cache/tool)   |
| `gemini_cli.agent.run.count`     | Counter        | Agent runs                     | `agent_name`, `terminate_reason`                    |
| `gemini_cli.agent.duration`      | Histogram (ms) | Agent run durations            | `agent_name`                                        |

</metrics_table>

### Performance Metrics

<performance_metrics>

| Metric Name                                   | Type              | Description                        | Alert Threshold                       |
| --------------------------------------------- | ----------------- | ---------------------------------- | ------------------------------------- |
| `gemini_cli.startup.duration`                 | Histogram (ms)    | CLI startup time by phase          | -                                     |
| `gemini_cli.memory.usage`                     | Histogram (bytes) | Memory usage (heap, RSS, external) | -                                     |
| `gemini_cli.cpu.usage`                        | Histogram (%)     | CPU usage percentage               | -                                     |
| `gemini_cli.tool.queue.depth`                 | Histogram         | Tools in execution queue           | -                                     |
| `gemini_cli.ui.flicker.count`                 | Counter           | UI frames that flicker             | High count indicates rendering issues |
| `gemini_cli.chat.content_retry_failure.count` | Counter           | All retries failed for request     | Any count indicates API instability   |

</performance_metrics>

### OpenTelemetry GenAI Semantic Conventions

<genai_metrics>

| Metric Name                        | Type                | Description                                     |
| ---------------------------------- | ------------------- | ----------------------------------------------- |
| `gen_ai.client.token.usage`        | Histogram (tokens)  | Token usage per operation (semantic convention) |
| `gen_ai.client.operation.duration` | Histogram (seconds) | Operation duration (semantic convention)        |

**Common GenAI Attributes:**

- `gen_ai.operation.name`: Operation type (e.g., "generate_content")
- `gen_ai.provider.name`: Provider ("gcp.gen_ai" or "gcp.vertex_ai")
- `gen_ai.request.model`, `gen_ai.response.model`: Model identifiers
- `gen_ai.token.type`: Token type ("input" or "output")

</genai_metrics>

## Logging

### Log System

**System**: OpenTelemetry Logs API with multiple exporters

**Access Points**:

- **GCP**: `https://console.cloud.google.com/logs/`
- **Local file**: Configure `telemetry.outfile` in settings
- **Debug output**: `GEMINI_DEBUG_LOG_FILE` environment variable

**Configuration** (`.gemini/settings.json`):

```json
{
  "telemetry": {
    "enabled": true,
    "target": "local",
    "outfile": ".gemini/telemetry.log",
    "logPrompts": true
  }
}
```

### Structured Logging Fields

<log_fields>

| Field Name        | Description                     | Example Value                 |
| ----------------- | ------------------------------- | ----------------------------- |
| `session.id`      | Unique session identifier       | UUID                          |
| `installation.id` | CLI installation identifier     | UUID                          |
| `user.email`      | User email (when authenticated) | `user@example.com`            |
| `prompt_id`       | Identifies the prompt/request   | UUID                          |
| `model`           | Model used for request          | `gemini-2.0-flash`            |
| `auth_type`       | Authentication method           | `USE_GEMINI`, `USE_VERTEX_AI` |

</log_fields>

### Log Categories

**Session Events:**

- `gemini_cli.config` — Startup configuration (emitted once)
- `gemini_cli.user_prompt` — User prompt submissions

**Tool Events:**

- `gemini_cli.tool_call` — Tool executions with timing/success
- `gemini_cli.tool_output_truncated` — Output truncation events
- `gemini_cli.edit_strategy` — Edit strategy selection
- `gemini_cli.edit_correction` — Edit correction results

**API Events:**

- `gemini_cli.api_request` — Requests to Gemini API
- `gemini_cli.api_response` — API responses with token counts
- `gemini_cli.api_error` — API failures with error details

**Agent Events:**

- `gemini_cli.agent.start` — Agent run started
- `gemini_cli.agent.finish` — Agent run completed with metrics

**Resilience Events:**

- `gemini_cli.flash_fallback` — Switched to flash model
- `gemini_cli.chat.content_retry` — Retry triggered
- `gemini_cli.chat.content_retry_failure` — All retries failed

### Debug Logging

<debug_logging>

For developer-facing debug output, use `debugLogger` from
`@google/gemini-cli-core`:

```typescript
import { debugLogger } from '@google/gemini-cli-core';

debugLogger.log('Operation started');
debugLogger.warn('Potential issue detected');
debugLogger.error('Error occurred', error);
debugLogger.debug('Detailed debug info');
```

**File-based debug logging:**

```bash
GEMINI_DEBUG_LOG_FILE=/path/to/debug.log npm start
```

Format: `[timestamp] [level] message`

</debug_logging>

### User Feedback Events

<user_feedback>

For user-facing feedback, use `coreEvents` from `@google/gemini-cli-core`:

```typescript
import { coreEvents } from '@google/gemini-cli-core';

coreEvents.emitFeedback('info', 'Operation completed');
coreEvents.emitFeedback('warning', 'Rate limit approaching');
coreEvents.emitFeedback('error', 'Operation failed', errorObject);
```

</user_feedback>

## Distributed Tracing

### Tracing Provider

**System**: OpenTelemetry with multiple exporter options

**Access Points**:

- **GCP Cloud Trace**: `https://console.cloud.google.com/traces/list`
- **Local Jaeger**: `http://localhost:16686`

### Configuration

**Direct export to GCP** (recommended):

```json
{
  "telemetry": {
    "enabled": true,
    "target": "gcp"
  }
}
```

**Local development with Jaeger**:

```bash
npm run telemetry -- --target=local
# Jaeger UI at http://localhost:16686
```

**Collector-based export**:

```json
{
  "telemetry": {
    "enabled": true,
    "target": "gcp",
    "useCollector": true
  }
}
```

### Dev Tracing

<dev_tracing>

Enable development tracing with detailed spans:

```bash
GEMINI_DEV_TRACING=true npm start
```

The `runInDevTraceSpan` function creates spans with input/output attributes:

```typescript
import { runInDevTraceSpan } from '@google/gemini-cli-core';

await runInDevTraceSpan({ name: 'my-operation' }, async ({ metadata }) => {
  metadata.input = { foo: 'bar' };
  // ... do work ...
  metadata.output = { result: 'success' };
  metadata.attributes['custom.attribute'] = 'value';
});
```

</dev_tracing>

### Key Span Names

<span_names>

**API Operations:**

- Gemini API requests with model, token counts, duration
- Response processing and streaming

**Tool Execution:**

- Tool calls with function name, arguments, success status
- File operations (read, write, edit)
- Shell command execution

**Agent Operations:**

- Agent start/finish with turn counts
- Recovery attempts

</span_names>

### Trace Search Tips

**In Jaeger UI:**

- Service: `gemini-cli`
- Filter by operation name or tags

**In GCP Cloud Trace:**

- Filter by service name: `gemini-cli`
- Filter by session ID in attributes

## Health Checks

### Application Health

<health_checks>

Gemini CLI is a terminal application without traditional HTTP health endpoints.
Application health is monitored through:

**Startup Profiler** (`packages/core/src/telemetry/startupProfiler.ts`):

- Tracks initialization phases
- Records CPU and memory usage during startup
- Emits `gemini_cli.startup.duration` metrics

**Memory Monitor** (`packages/core/src/telemetry/memory-monitor.ts`):

- Continuous memory monitoring (configurable interval)
- High-water mark tracking with 5% threshold
- Heap, RSS, and external memory tracking

**Activity Monitor** (`packages/core/src/telemetry/activity-monitor.ts`):

- Tracks user activity events
- Triggers memory snapshots on significant events
- Rate-limited to avoid excessive metrics

</health_checks>

### Monitoring Startup

<startup_monitoring>

Startup phases tracked by `StartupProfiler`:

```typescript
import { startupProfiler } from '@google/gemini-cli-core';

// Mark phase start
const handle = startupProfiler.start('my-phase');

// ... initialization work ...

// Mark phase end
handle?.end({ custom_detail: 'value' });

// Flush all metrics (called after telemetry initialized)
startupProfiler.flush(config);
```

Startup metrics include:

- Phase duration (ms)
- CPU usage (user/system)
- Platform details (os, arch, docker)

</startup_monitoring>

### Memory Health Checks

<memory_health>

Check memory thresholds programmatically:

```typescript
import { getMemoryMonitor } from '@google/gemini-cli-core';

const monitor = getMemoryMonitor();
if (monitor) {
  // Get current memory summary in MB
  const summary = monitor.getMemoryUsageSummary();
  console.log(`Heap: ${summary.heapUsedMB}MB / ${summary.heapTotalMB}MB`);

  // Check against threshold
  if (monitor.checkMemoryThreshold(512)) {
    console.warn('Memory usage exceeds 512MB');
  }

  // Get high-water marks
  const hwm = monitor.getHighWaterMarkStats();
  console.log('Peak RSS:', hwm.rss);
}
```

</memory_health>

## Alerts & Monitors

### Google Cloud Monitoring

<gcp_monitoring>

**Pre-configured Dashboard**: "Gemini CLI Monitoring" available in GCP Dashboard
Templates

**Dashboard Sections:**

- Session and usage overview
- API request metrics and latency
- Token consumption by model
- Error rates and retry patterns

**Access**: Google Cloud Console → Monitoring → Dashboards → Dashboard Templates
→ "Gemini CLI Monitoring"

</gcp_monitoring>

### Key Metrics for Alerting

<alert_metrics>

| Metric                                           | Condition       | Priority | Action                                        |
| ------------------------------------------------ | --------------- | -------- | --------------------------------------------- |
| `gemini_cli.api.request.count` with `error_type` | Error rate > 5% | High     | Check API connectivity, authentication        |
| `gemini_cli.chat.content_retry_failure.count`    | Any increment   | High     | Investigate API errors, check quotas          |
| `gemini_cli.memory.usage` (RSS)                  | > 1GB           | Medium   | Check for memory leaks, large file operations |
| `gemini_cli.tool.call.latency`                   | p99 > 30s       | Medium   | Check tool timeouts, external dependencies    |
| `gemini_cli.ui.flicker.count`                    | High rate       | Low      | Terminal rendering issues                     |

</alert_metrics>

### Setting Up GCP Alerts

<gcp_alerts>

1. Navigate to Cloud Monitoring → Alerting
2. Create policy using Gemini CLI metrics
3. Example alert condition:
   - Resource type: `generic_task`
   - Metric: `custom.googleapis.com/gemini_cli/api/request/count`
   - Filter: `error_type != ""`
   - Condition: > 0 for 5 minutes

**Required IAM roles for telemetry:**

- Cloud Trace Agent
- Monitoring Metric Writer
- Logs Writer

</gcp_alerts>

## Troubleshooting Guide

### Quick Diagnosis

<diagnosis_table>

| Symptom            | Where to Look                           | Common Cause                           |
| ------------------ | --------------------------------------- | -------------------------------------- |
| API errors         | Logs with `gemini_cli.api_error`        | Authentication issues, quota exceeded  |
| Slow responses     | `gemini_cli.api.request.latency` metric | Network latency, large token counts    |
| High memory        | Memory monitor stats                    | Large file reads, long sessions        |
| Tool failures      | Logs with `gemini_cli.tool_call`        | Permission issues, file not found      |
| Retries happening  | `gemini_cli.chat.content_retry` logs    | API rate limiting, transient errors    |
| All retries failed | `gemini_cli.chat.content_retry_failure` | Persistent API issues, invalid content |

</diagnosis_table>

### Common Issues

#### Issue: Telemetry Not Working

**Symptoms:**

- No data in GCP Console or Jaeger
- No telemetry.log file created

**Where to Look:**

1. Check settings: `.gemini/settings.json`
2. Verify environment variables: `GEMINI_TELEMETRY_ENABLED`
3. Check debug output for SDK initialization errors

**Common Causes:**

- `telemetry.enabled` not set to `true`
- Missing GCP credentials for `target: "gcp"`
- Invalid `otlpEndpoint` configuration

**Resolution:**

```json
{
  "telemetry": {
    "enabled": true,
    "target": "local",
    "outfile": ".gemini/telemetry.log"
  }
}
```

#### Issue: High Memory Usage

**Symptoms:**

- CLI becomes slow or unresponsive
- Memory metrics show continuous growth

**Where to Look:**

1. Memory monitor: `getMemoryMonitor().getMemoryUsageSummary()`
2. Memory metrics: `gemini_cli.memory.usage`
3. High-water marks: `getMemoryMonitor().getHighWaterMarkStats()`

**Common Causes:**

- Large file operations
- Long conversation sessions
- Unclosed file handles or streams

**Resolution:**

- Start new session with `/clear`
- Use file filtering to reduce context
- Check for large binary files in workspace

#### Issue: API Errors and Retries

**Symptoms:**

- Frequent retry events in logs
- `content_retry_failure` events

**Where to Look:**

1. API error logs: `gemini_cli.api_error`
2. Retry logs: `gemini_cli.chat.content_retry`
3. Error metrics by type

**Common Causes:**

- Rate limiting (429 errors)
- Invalid content (safety filters)
- Network connectivity issues
- Authentication expiration

**Resolution:**

- Check quota in GCP Console
- Verify authentication status
- Check network connectivity
- Review content for safety violations

#### Issue: Slow Tool Execution

**Symptoms:**

- Long delays during tool calls
- High `tool.call.latency` values

**Where to Look:**

1. Tool call logs with `duration_ms`
2. Tool latency histogram
3. Specific tool breakdown metrics

**Common Causes:**

- Large file reads
- Complex glob/grep patterns
- Shell commands with large output
- MCP server latency

**Resolution:**

- Use more specific file patterns
- Limit shell command output
- Check MCP server health
- Review tool execution breakdown

### Diagnostic Commands

<diagnostic_commands>

**View telemetry settings:**

```bash
cat ~/.gemini/settings.json | jq '.telemetry'
```

**Enable debug logging:**

```bash
GEMINI_DEBUG_LOG_FILE=debug.log npm start
```

**Start local telemetry viewer:**

```bash
npm run telemetry -- --target=local
# Then open http://localhost:16686
```

**Check GCP telemetry setup:**

```bash
# Verify authentication
gcloud auth application-default print-access-token

# Check required APIs
gcloud services list --filter="name:(cloudtrace|monitoring|logging)"
```

**Tail telemetry file:**

```bash
tail -f .gemini/telemetry.log
```

</diagnostic_commands>

### Environment Variables Reference

<env_variables>

| Variable                         | Description                | Example                 |
| -------------------------------- | -------------------------- | ----------------------- |
| `GEMINI_TELEMETRY_ENABLED`       | Enable telemetry           | `true`                  |
| `GEMINI_TELEMETRY_TARGET`        | Export target              | `gcp`, `local`          |
| `GEMINI_TELEMETRY_OTLP_ENDPOINT` | OTLP endpoint              | `http://localhost:4317` |
| `GEMINI_TELEMETRY_OTLP_PROTOCOL` | Transport protocol         | `grpc`, `http`          |
| `GEMINI_TELEMETRY_OUTFILE`       | File output path           | `.gemini/telemetry.log` |
| `GEMINI_TELEMETRY_LOG_PROMPTS`   | Include prompts in logs    | `true`                  |
| `GEMINI_TELEMETRY_USE_COLLECTOR` | Use external collector     | `true`                  |
| `GEMINI_TELEMETRY_USE_CLI_AUTH`  | Use CLI credentials        | `true`                  |
| `GEMINI_DEV_TRACING`             | Enable dev trace spans     | `true`                  |
| `GEMINI_DEBUG_LOG_FILE`          | Debug log file path        | `/path/to/debug.log`    |
| `GOOGLE_CLOUD_PROJECT`           | GCP project ID             | `my-project`            |
| `OTLP_GOOGLE_CLOUD_PROJECT`      | Separate telemetry project | `telemetry-project`     |

</env_variables>

## Related Documentation

**Architecture**: See `.alfred/docs/architecture.md` for system components and
structure

**Dependencies**: See `.alfred/docs/dependencies.md` for external service
details

**Testing**: See `.alfred/docs/testing.md` for testing practices and
observability testing

**Official Documentation**: See `docs/cli/telemetry.md` for complete telemetry
configuration guide
