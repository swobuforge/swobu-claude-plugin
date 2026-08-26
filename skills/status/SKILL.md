---
name: status
description: Show the current Swobu status using its existing headless command. Run only when the user explicitly invokes /swobu:status.
disable-model-invocation: true
user-invocable: true
---

# Swobu Status

Run only:

```sh
swobu status
```

Use Claude Code's normal Bash permission flow. If Swobu is absent, report that
it is not installed and point to `/swobu:setup`.

Preserve Swobu's own output and exit semantics. Report its own state vocabulary,
including `healthy`, `uninitialized`, `degraded`, and `down`, exactly as Swobu
classifies it. Do not probe upstreams, infer additional health claims, edit
configuration, inspect persistence, send requests, or collect credentials or
conversation content.
