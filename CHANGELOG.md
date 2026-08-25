# Changelog

## 0.1.0

- Add thin setup, connect, and status skills over the installed Swobu CLI.
- Require normal Claude Bash permission for every command.
- Validate explicit workspace names against Swobu's canonical slug grammar
  before shell execution.
- Require explicit confirmation and a separate permission decision before
  replacement.
- Include deterministic reviewer fixtures requiring no account, API key, or LLM
  request.
