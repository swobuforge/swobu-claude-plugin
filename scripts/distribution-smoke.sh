#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TAG=${1:-}
IMAGE=swobu-claude-plugin-e2e:latest
ARTIFACTS="$ROOT_DIR/.out/distribution-smoke"
MARKETPLACE=swobuforge/swobu-claude-plugin

if [[ -z "$TAG" || "$TAG" == -* || "$TAG" =~ [[:space:]] || "$TAG" == *..* || "$TAG" == */ ]]; then
  echo "usage: $0 <published-plugin-tag>" >&2
  exit 2
fi

: "${ANTHROPIC_API_KEY:?real Anthropic key required}"

set -a
. "$ROOT_DIR/e2e/versions.env"
set +a

rm -rf "$ARTIFACTS"
mkdir -p "$ARTIFACTS"

podman build \
  --build-arg CLAUDE_VERSION="$CLAUDE_VERSION" \
  --build-arg SWOBU_VERSION="$SWOBU_VERSION" \
  -t "$IMAGE" -f "$ROOT_DIR/e2e/Containerfile" "$ROOT_DIR"

podman run --rm \
  --userns=keep-id \
  -e ANTHROPIC_API_KEY \
  -e DISTRIBUTION_MODEL="${DISTRIBUTION_MODEL:-haiku}" \
  -e MARKETPLACE \
  -e TAG \
  -v "$ARTIFACTS":/artifacts:Z \
  "$IMAGE" \
  bash -c '
    set -euo pipefail
    export CLAUDE_CONFIG_DIR=/tmp/claude-config
    export DISABLE_AUTOUPDATER=1
    export DISABLE_TELEMETRY=1
    export DISABLE_ERROR_REPORTING=1
    export CLAUDE_CODE_DISABLE_SESSION_TITLE_GENERATION=1
    mkdir -p "$CLAUDE_CONFIG_DIR" /tmp/distribution-smoke
    cd /tmp/distribution-smoke
    copy_artifacts() {
      find . -maxdepth 1 -type f -exec cp {} /artifacts/ \;
    }
    trap copy_artifacts EXIT

    claude plugin marketplace add "$MARKETPLACE@$TAG" \
      >marketplace-add.out 2>marketplace-add.err
    claude plugin marketplace list --json >marketplaces.json
    jq -e --arg tag "$TAG" '\''
      any(.[]; .name == "swobu" and .repo == "swobuforge/swobu-claude-plugin" and .ref == $tag)
    '\'' marketplaces.json >/dev/null

    claude plugin install swobu@swobu --scope user \
      >plugin-install.out 2>plugin-install.err
    claude plugin list --json >plugins.json
    jq -e '\''
      any(.[];
        (.id == "swobu@swobu" or
         .name == "swobu@swobu" or
         (.name == "swobu" and .marketplace == "swobu")) and
        (.enabled != false)
      )
    '\'' plugins.json >/dev/null

    timeout 120 claude -p "/swobu:setup" \
      --tools Bash \
      --model "$DISTRIBUTION_MODEL" \
      --effort low \
      --permission-mode bypassPermissions \
      --no-session-persistence \
      --output-format stream-json \
      --verbose \
      --debug-file claude.debug \
      >claude.out 2>claude.err

    jq -e -s '\''
      map(select(.type == "result")) | last |
      .subtype == "success" and .is_error == false
    '\'' claude.out >/dev/null
    jq -r '\''
      select(.type == "assistant") |
      .message.content[]? |
      select(.type == "tool_use" and .name == "Bash") |
      .input.command
    '\'' claude.out >bash-commands.txt
    test "$(cat bash-commands.txt)" = "command -v swobu"
    jq -r '\''
      select(.type == "assistant") |
      .message.content[]? |
      select(.type == "text") |
      .text
    '\'' claude.out >claude.final-text
    grep -Fq "/swobu:connect" claude.final-text

    if grep -Eqi \
      "failed to load plugin|plugin error|invalid plugin|plugin.*failed|marketplace.*error" \
      claude.err claude.debug; then
      echo "Claude reported a plugin loading error" >&2
      exit 1
    fi

  '

echo "distribution smoke passed for $MARKETPLACE@$TAG: $ARTIFACTS"
