---
name: setup
description: Check whether Swobu is installed and show the next setup instruction. Run only when the user explicitly invokes /swobu:setup.
disable-model-invocation: true
user-invocable: true
---

# Prepare Swobu

Prepare the machine to use an existing Swobu workspace from Claude Code.

1. Run `command -v swobu` using Claude Code's normal Bash permission flow.
2. If Swobu exists, do not run another Swobu command. Offer
   `/swobu:connect`; that command owns workspace truth and errors.
3. If Swobu is absent, run `uname -s` using the normal Bash permission flow.
4. On Linux or macOS, show:

   ```text
   Swobu is not installed.

   Official install command:

   curl -fsSL https://swobu.com/install.sh | sh
   ```

   Tell the user to review and execute the command themselves.
5. On any other platform, do not suggest the POSIX installer. Point the user to
   `https://swobu.com/docs` for current installation instructions.

Never execute an installer. Do not inspect Swobu or Claude configuration files.
Do not collect or echo credentials, prompts, or conversation content.
