# Reviewer Fixture

This deterministic configuration tests plugin acquisition and local connect
behavior without a Swobu account, provider account, API key, or LLM request.

```sh
swobu daemon --config ./review/swobu.yaml
claude --plugin-dir .
```

Run the three plugin workflows:

```text
/swobu:setup
/swobu:status
/swobu:connect review
```

`status` is expected to report the loopback target as unreachable. `connect` is
expected to configure Claude Code for the local `review` workspace. Neither
workflow needs the endpoint to serve inference.

Test account: not applicable. Swobu local use has no account.
