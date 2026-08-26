# Swobu — Claude Code LLM Gateway & Provider Failover

**Keep Claude Code on one endpoint. Move routing and failover behind it.**

Swobu connects Claude Code to one stable local endpoint. Change supported capacity behind that endpoint without repeatedly rewiring Claude Code.

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt-BR.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Українська](README.uk.md)

## Install

```text
/plugin marketplace add swobuforge/swobu-claude-plugin
/plugin install swobu@swobu
```

Then:

```text
/swobu:setup
/swobu:connect
```

Install at user scope (the default) to make it available across projects.

Once Anthropic accepts the reviewed third-party plugin into the community marketplace, installation becomes:

```text
/plugin marketplace add anthropics/claude-plugins-community
/plugin install swobu@claude-community
```

The plugin is intentionally thin: it connects Claude Code to the installed Swobu CLI. It does not store provider keys, edit Claude settings itself, run a second gateway, or duplicate Swobu's routing logic.

## Why this instead of a provider-profile switcher?

Provider switchers usually change Claude Code's provider configuration or launch a new Claude process with provider-specific environment variables. Swobu keeps the Claude Code endpoint stable after initial connection and moves routing decisions behind that boundary.

| Capability | Provider-profile switcher | Swobu plugin + gateway |
| --- | --- | --- |
| Initial Claude setup | Change provider profile | Connect once to a Swobu workspace |
| Day-to-day backend changes | Change active profile/provider | Change Swobu route targets behind the same client endpoint |
| Provider credentials in plugin/switcher | Common | None in this plugin |
| Ordered fallback | Tool-specific | Swobu route tiers |
| Protocol/feature compatibility | Provider-specific | Swobu compatibility boundary |
| Claude plugin runtime | Often owns switching logic | Thin control surface; Swobu remains source of truth |

This is not a claim that every provider or model is equivalent. Swobu can only route a workload where the configured target can represent the required semantics.

## Requirements

- Claude Code with plugin support
- an existing Swobu workspace with at least one configured target
- `swobu` on `PATH`; `/swobu:setup` tells you how to install it when missing, but never executes an installer

Anthropic supports third-party gateways that expose a supported API format, but does not support routing Claude Code to non-Claude models through any gateway. This plugin does not claim otherwise. It also does not bypass Claude subscription billing or rate limits and does not change Claude credentials.

## Commands

### `/swobu:setup`

Checks whether Swobu is installed. When installed, it points you to `/swobu:connect`. When missing, it prints installation instructions for you to review and execute yourself.

### `/swobu:connect [workspace]`

Configures Claude Code through Swobu's existing `swobu connect claude` operation. With multiple workspaces, pass one explicitly:

```text
/swobu:connect work
```

If Claude Code points elsewhere, the plugin asks before invoking Swobu's `--replace` safety mechanism. A successful result means the external configuration was verified; send your next Claude request normally and use Swobu Activity as runtime proof.

### `/swobu:status`

Runs Swobu's existing headless status command and preserves its own output and exit semantics.

## Examples

### Existing Swobu setup

```text
/swobu:connect
```

If one workspace is eligible, Claude Code is configured to use it. Running the same command again is safe when it is already configured.

### Multiple workspaces

```text
/swobu:connect work
```

Workspace names must match Swobu's canonical lowercase slug grammar before any shell command runs. The plugin does not parse Swobu persistence or duplicate workspace selection rules.

### Existing non-Swobu endpoint

```text
/swobu:connect work
```

The first attempt stops if replacement is required. Only after explicit user confirmation does the plugin retry with Swobu's fixed `--replace` flag.

## Security and privacy

The plugin stores no API keys, prompts, conversation content, or telemetry. It uses Claude Code's normal Bash permission flow for local commands. It never executes the Swobu installer and never edits Claude configuration directly.

See [PRIVACY.md](./PRIVACY.md) and [SECURITY.md](./SECURITY.md).

## Development

Validate the plugin and marketplace:

```sh
make build
```

Run structural checks:

```sh
make check
```

For local Claude Code dogfood:

```sh
claude --plugin-dir .
```

For actual marketplace-install semantics:

```text
/plugin marketplace add .
/plugin install swobu@swobu
```

Then restart Claude Code without `--plugin-dir` and invoke `/swobu:setup` and `/swobu:status`.

### Release verification boundaries

`make release-verify` proves the source candidate with real Claude Code, a real model, and the released Swobu binary. It intentionally loads the candidate with `--plugin-dir`, so it remains runnable before publication.

After publishing a tag, prove the copied marketplace distribution separately:

```sh
ANTHROPIC_API_KEY=... make distribution-smoke TAG=v0.1.0
```

This starts a fresh container, adds `swobuforge/swobu-claude-plugin@TAG`, installs `swobu@swobu`, invokes Claude Code without `--plugin-dir`, checks for plugin loading errors, and runs `/swobu:setup`. The tag must already be public; this smoke is post-tag evidence and is not part of `release-verify`.

## Support

- Documentation: <https://swobu.com/docs>
- Main project: <https://github.com/swobuforge/swobu>
- Issues: <https://github.com/swobuforge/swobu-claude-plugin/issues>
- Security: `security@swobu.com`
