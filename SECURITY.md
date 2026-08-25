# Security Policy

Do not report vulnerabilities in public issues.

Report privately to `security@swobu.com` with the affected plugin version,
impact, reproduction steps, and a proof of concept when safe to share.

The plugin may request Swobu discovery/connect commands through Claude Code's
normal Bash permission flow. It never executes the installer. It must not read
Claude or Swobu configuration files, collect credentials or prompts, call
telemetry, or persist plugin-specific user data.
