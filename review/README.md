# Reviewer Fixture

This deterministic configuration tests plugin acquisition and local connect
behavior without a Swobu account, provider account, API key, LLM request, or
reachable upstream.

Use two terminals so the reviewer port does not collide with an existing Swobu.

## Terminal A: start the review daemon

```sh
SWOBU_ADDR=127.0.0.1:17926 \
  swobu daemon --addr 127.0.0.1:17926 --config ./review/swobu.yaml
```

## Terminal B: run Claude with this plugin source

```sh
SWOBU_ADDR=127.0.0.1:17926 claude --plugin-dir .
```

Run:

```text
/swobu:setup
/swobu:status
/swobu:connect review
```

Expected:

| Workflow | Result |
| --- | --- |
| `/swobu:setup` | finds installed Swobu |
| `/swobu:status` | daemon reports `healthy` with `workspace_count: 1` |
| `/swobu:connect review` | configures Claude Code for workspace `review` |

No LLM request, API key, provider account, or reachable upstream is required.
