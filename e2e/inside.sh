#!/usr/bin/env bash
set -euo pipefail

MODE=$1

PLUGIN=/plugin
TRACE=/tmp/e2e/trace.log
STATE_DIR=/tmp/e2e-state
CLAUDE_DIR=$STATE_DIR/claude-config
ADDR=127.0.0.1:17926
REAL_SWOBU=/opt/swobu/bin/swobu
export SWOBU_CONFIG_PATH=/tmp/e2e/fixtures/config.yaml
export SWOBU_ADDR=$ADDR
CONTROL_PORT=${CONTROL_PORT:-18090}
CONTROL_SETTINGS="{\"env\":{\"ANTHROPIC_BASE_URL\":\"http://127.0.0.1:${CONTROL_PORT}\"}}"
RELEASE_CONTROL_SETTINGS='{"env":{"ANTHROPIC_BASE_URL":"https://api.anthropic.com"}}'

mkdir -p /tmp/e2e "$CLAUDE_DIR"
: >"$TRACE"
if [[ "$MODE" != "release-connect-replace" ]]; then
  python3 "$PLUGIN/e2e/control-upstream.py" "$CONTROL_PORT" \
    "/tmp/e2e/control-${CONTROL_PORT}-request.json" \
    >/tmp/e2e/control.out 2>/tmp/e2e/control.err &
  control_pid=$!
  sleep .1
  kill -0 "$control_pid"
fi
cd /tmp/e2e

start_daemon() {
  local fixture=$1
  rm -rf /tmp/e2e/fixtures
  mkdir -p /tmp/e2e/fixtures
  chmod 700 /tmp/e2e/fixtures
  cp "$PLUGIN/e2e/fixtures/$fixture" /tmp/e2e/fixtures/config.yaml
  chmod 600 /tmp/e2e/fixtures/config.yaml
  SWOBU_ADDR="$ADDR" "$REAL_SWOBU" daemon --addr "$ADDR" --config /tmp/e2e/fixtures/config.yaml \
    >/tmp/e2e/swobu-daemon.out 2>/tmp/e2e/swobu-daemon.err &
  daemon_pid=$!
  sleep .1
  for _ in $(seq 1 50); do
    if "$REAL_SWOBU" status >/tmp/e2e/status.json 2>/dev/null && jq -e '.state == "healthy"' /tmp/e2e/status.json >/dev/null; then
      return
    fi
    sleep .1
  done
  echo "-- daemon stdout --" >&2
  cat /tmp/e2e/swobu-daemon.out >&2
  echo "-- daemon stderr --" >&2
  cat /tmp/e2e/swobu-daemon.err >&2
  echo "daemon did not become healthy" >&2
  return 1
}

stop_daemon() {
  kill "${daemon_pid:-}" 2>/dev/null || true
  wait "${daemon_pid:-}" 2>/dev/null || true
}

cleanup() {
  kill "${upstream_pid:-}" "${daemon_pid:-}" "${control_pid:-}" 2>/dev/null || true
}
trap cleanup EXIT

claude_run() {
  local prompt=$1
  shift
  CLAUDE_CONFIG_DIR="$CLAUDE_DIR" ANTHROPIC_API_KEY="${E2E_CONTROL_API_KEY:-control-e2e-key}" \
    DISABLE_AUTOUPDATER=1 \
      CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1 \
      DISABLE_TELEMETRY=1 \
      DISABLE_ERROR_REPORTING=1 \
      CLAUDE_CODE_DISABLE_SESSION_TITLE_GENERATION=1 \
    timeout 30 claude --bare --plugin-dir "$PLUGIN" -p "$prompt" \
      --settings "$CONTROL_SETTINGS" "$@" \
      --tools Bash --no-session-persistence \
      --model "${E2E_MODEL:?}" --effort low --permission-mode bypassPermissions \
      --output-format stream-json --verbose
}

preseed_settings() {
  cat >"$CLAUDE_DIR/settings.json"
}

settings_sha() {
  sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true
}

assert_unchanged() {
  local before=$1
  test "$before" = "$(settings_sha)"
}

assert_swobu_settings() {
  jq -e '.env.ANTHROPIC_BASE_URL == "'"$1"'" and .env.CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY == "1"' \
    "$CLAUDE_DIR/settings.json" >/dev/null
}

assert_trace() {
  local expected=/tmp/e2e/expected-trace
  cat >"$expected"
  diff -u "$expected" "$TRACE"
}

assert_allowed_bash_commands() {
  local output=$1
  local phase=$2
  local commands=/tmp/e2e/bash-commands-$phase.txt
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Bash")
    | .input.command
  ' "$output" >"$commands"
  test -s "$commands"
  while IFS= read -r command; do
    case "$phase:$command" in
      'turn1:command -v swobu' | \
      'turn1:swobu connect claude --workspace work' | \
      'turn2:command -v swobu' | \
      'turn2:swobu connect claude --workspace work --replace')
        ;;
      *)
        echo "unexpected Bash command in $phase: $command" >&2
        return 1
        ;;
    esac
  done <"$commands"
}

case "$MODE" in
  load)
    claude_run '/swobu:setup' >claude.out
    ! grep -q 'plugin_errors' claude.out
    ;;
  setup-absent)
  set +e
  CLAUDE_PATH=$(command -v claude)
  PATH="$(dirname "$CLAUDE_PATH"):/usr/bin:/bin" claude_run '/swobu:setup' >/tmp/e2e/claude.stdout 2>/tmp/e2e/claude.stderr
  set -e
  ! test -s "$TRACE"
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "text")
    | .text
  ' /tmp/e2e/claude.stdout >/tmp/e2e/claude.final-text
  grep -Fq 'curl -fsSL https://swobu.com/install.sh | sh' /tmp/e2e/claude.final-text
  ;;
  status-down)
    set +e
    claude_run '/swobu:status' >/tmp/e2e/claude.stdout 2>/tmp/e2e/claude.stderr
    echo "claude_rc=$?" >&2
    set -e
    grep -Fxq 'status' "$TRACE"
    ;;
  status-healthy)
    start_daemon one.yaml
    claude_run '/swobu:status' >claude.out
    stop_daemon
    grep -Fxq 'status' "$TRACE"
    grep -Fq '"state":"healthy"' /tmp/e2e/status.json
    ;;
  connect-multiple)
    start_daemon many.yaml
    before=$(sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true)
    claude_run '/swobu:connect' >claude.out
    stop_daemon
    grep -Fxq 'connect' "$TRACE"
    after=$(sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true)
    test "$before" = "$after"
    ;;
  connect-unknown)
    start_daemon one.yaml
    cat >"$CLAUDE_DIR/settings.json" <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:9/c/work","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    before=$(sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true)
    claude_run '/swobu:connect missing' >claude.out
    stop_daemon
    grep -Fxq -- '--workspace' "$TRACE"
    grep -Fxq 'missing' "$TRACE"
    after=$(sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true)
    test "$before" = "$after"
    ;;
  connect-idempotent)
    start_daemon one.yaml
    preseed_settings <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:17926/c/work","CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY":"1","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    before=$(settings_sha)
    claude_run '/swobu:connect work' >claude.out
    stop_daemon
    grep -Fxq 'connect' "$TRACE"
    ! grep -Fxq -- '--replace' "$TRACE"
    assert_unchanged "$before"
    ;;
  connect-replacement-refused)
    start_daemon one.yaml
    preseed_settings <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:9/c/foreign","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    before=$(settings_sha)
    out=$(claude_run '/swobu:connect work')
    printf '%s\n' "$out" >claude.turn1
    assert_trace <<'TRACE'
BEGIN
connect
claude
--workspace
work
END
TRACE
    assert_unchanged "$before"
    stop_daemon
    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' claude.turn1 \
      >claude.final-text
    grep -Eqi 'replace|replacement|existing endpoint' claude.final-text
    ;;
  release-connect-replace)
    start_daemon one.yaml
    preseed_settings <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:9/c/foreign","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    cp "$CLAUDE_DIR/settings.json" settings.before.json
    before=$(settings_sha)
    set +e
    out=$(CLAUDE_CONFIG_DIR="$CLAUDE_DIR" ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:?}" \
      DISABLE_AUTOUPDATER=1 DISABLE_TELEMETRY=1 DISABLE_ERROR_REPORTING=1 \
      timeout 120 claude --bare --plugin-dir "$PLUGIN" -p '/swobu:connect work' \
      --settings "$RELEASE_CONTROL_SETTINGS" \
      --tools Bash --model haiku --effort low --permission-mode bypassPermissions \
      --output-format stream-json --verbose 2>claude.turn1.err)
    turn1_rc=$?
    set -e
    printf '%s\n' "$out" >claude.turn1
    test "$turn1_rc" -eq 0
    assert_allowed_bash_commands claude.turn1 turn1
    session_id=$(printf '%s\n' "$out" | jq -er -s '
      map(select(.type == "result"))
      | last
      | .session_id
      | select(type == "string" and length > 0)
    ')
    assert_trace <<'TRACE'
BEGIN
connect
claude
--workspace
work
END
TRACE
    assert_unchanged "$before"
    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' claude.turn1 >claude.ask-text
    grep -Eqi 'replace|replacement|existing endpoint' claude.ask-text
    : >"$TRACE"
    set +e
    out=$(CLAUDE_CONFIG_DIR="$CLAUDE_DIR" ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:?}" \
      DISABLE_AUTOUPDATER=1 DISABLE_TELEMETRY=1 DISABLE_ERROR_REPORTING=1 \
      timeout 120 claude --bare --plugin-dir "$PLUGIN" -p 'Yes, replace it.' --resume "$session_id" \
      --settings "$RELEASE_CONTROL_SETTINGS" \
      --tools Bash --model haiku --effort low --permission-mode bypassPermissions \
      --output-format stream-json --verbose 2>claude.turn2.err)
    turn2_rc=$?
    set -e
    printf '%s\n' "$out" >claude.turn2
    test "$turn2_rc" -eq 0
    assert_allowed_bash_commands claude.turn2 turn2
    stop_daemon
    assert_trace <<'TRACE'
BEGIN
connect
claude
--workspace
work
--replace
END
TRACE
    assert_swobu_settings http://127.0.0.1:17926/c/work
    jq -e '.env.KEEP_ME == "yes" and .unrelated.also == "yes"' "$CLAUDE_DIR/settings.json" >/dev/null
    cp "$CLAUDE_DIR/settings.json" settings.after.json
    ;;
  request-smoke)
    python3 "$PLUGIN/e2e/upstream.py" 18080 >/tmp/e2e/upstream.out 2>/tmp/e2e/upstream.err &
    upstream_pid=$!
    start_daemon one.yaml
    rm -f "$CLAUDE_DIR/settings.json"
    set +e
    connect_out=$(claude_run '/swobu:connect')
    connect_rc=$?
    set -e
    printf '%s\n' "$connect_out" >claude.out
    echo "connect_rc=$connect_rc" >&2
    tail -3 claude.out >&2
    test "$connect_rc" -eq 0
    assert_swobu_settings http://127.0.0.1:17926/c/work
    : >"$TRACE"
    set +e
    out=$(CLAUDE_CONFIG_DIR="$CLAUDE_DIR" \
      ANTHROPIC_API_KEY="${E2E_CONTROL_API_KEY:-control-e2e-key}" \
      DISABLE_AUTOUPDATER=1 \
      CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1 \
      DISABLE_TELEMETRY=1 \
      DISABLE_ERROR_REPORTING=1 \
      CLAUDE_CODE_DISABLE_SESSION_TITLE_GENERATION=1 \
      timeout 30 claude --bare -p 'Reply with exactly the marker returned by the endpoint.' \
      --model claude-local --effort low --output-format stream-json --verbose 2>/tmp/e2e/request.err)
    rc=$?
    set -e
    printf '%s\n' "$out" >request.out
    stop_daemon
    kill "$upstream_pid" 2>/dev/null || true
    echo "request_rc=$rc" >&2
    echo '-- request stderr --' >&2
    cat /tmp/e2e/request.err >&2 2>/dev/null || true
    tail -3 request.out >&2 || true
    test "$rc" -eq 0
    jq -se 'map(select(.type == "result")) | last | .subtype == "success" and .result == "SWOBU_E2E_OK"' request.out
    ! grep -q 'unrecognized_model' request.out
    ;;
  connect-one)
    start_daemon one.yaml
    rm -f "$CLAUDE_DIR/settings.json"
    claude_run '/swobu:connect' >claude.out
    stop_daemon
    grep -Fxq 'connect' "$TRACE"
    grep -Fxq 'claude' "$TRACE"
    grep -Fq 'http://127.0.0.1:17926/c/work' "$CLAUDE_DIR/settings.json"
    ;;
esac
