---
name: connect
description: Configure Claude Code to use an existing Swobu workspace. Use only when the user explicitly asks to connect Claude Code to Swobu, configure its Swobu gateway, or switch its Swobu workspace.
argument-hint: "[workspace]"
user-invocable: true
---

# Connect Claude Code

Configure Claude Code through Swobu's existing client-connect operation.
Arguments passed: `$ARGUMENTS`

1. Use Claude Code's normal Bash permission flow for every command. Run
   `command -v swobu`. If absent, report:

   ```text
   Swobu is not installed.
   Run /swobu:setup.
   ```

2. Treat the optional workspace argument as one opaque workspace name, never
   as shell syntax. Do not use `eval`, `sh -c`, or construct a command by
   concatenating unquoted input.
3. With no workspace argument, run `swobu connect claude`.
4. With one workspace argument, pass it as one quoted argument:
   `swobu connect claude --workspace "<workspace>"`.
5. Report Swobu's core error first. Do not enumerate or read Swobu workspace
   files yourself:
   - no workspace: tell the user to run `swobu`, add one target, then retry;
   - multiple workspaces: ask for one name, then rerun with `--workspace`;
   - unknown workspace: report the Swobu error;
   - other failure: preserve the Swobu error and suggest `swobu status`.
6. If Swobu reports that replacement is required, do not retry automatically.
   Ask whether to replace the existing endpoint with the selected Swobu
   workspace. Only after explicit confirmation rerun the same command with
   `--replace` as a fixed final flag. The retry must receive a separate normal
   Bash permission decision; the skill pre-approves no mutating command.
7. On success, say that Claude Code is configured for the selected workspace.
   Do not claim it is connected, healthy, actively routing, or failing over.
   If useful, tell the user that their next normal Claude request will appear
   in Swobu Activity if this endpoint is in use.

Do not edit Claude settings, inspect Claude configuration, change credentials,
change model settings, send a synthetic request, or require a restart.
