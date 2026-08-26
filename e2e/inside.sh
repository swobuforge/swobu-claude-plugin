#!/usr/bin/env bash
set -euo pipefail

MODE=$1

PLUGIN=/plugin
TRACE=/tmp/e2e/trace.log
CLAUDE_DIR=/tmp/e2e/claude-config
ADDR=127.0.0.1:17926
REAL_SWOBU=/opt/swobu/bin/swobu
export SWOBU_CONFIG_PATH=/tmp/e2e/fixtures/config.yaml
export SWOBU_ADDR=$ADDR
CONTROL_SETTINGS='{"env":{"ANTHROPIC_BASE_URL":"https://api.anthropic.com"}}'

mkdir -p /tmp/e2e "$CLAUDE_DIR"
: >"$TRACE"
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

claude_run() {
  local prompt=$1
  shift
  CLAUDE_CONFIG_DIR="$CLAUDE_DIR" ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:?}" \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1 \
    timeout 120 claude --bare --plugin-dir "$PLUGIN" -p "$prompt" \
      --settings "$CONTROL_SETTINGS" "$@" \
      --model "${E2E_MODEL:?}" --effort low --allowedTools Bash \
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

case "$MODE" in
  load)
    claude_run '/swobu:setup' >claude.out
    ! grep -q 'plugin_errors' claude.out
    ;;
  setup-absent)
  set +e
  PATH=/usr/local/bin:/usr/bin:/bin claude_run '/swobu:setup' >/tmp/e2e/claude.stdout 2>/tmp/e2e/claude.stderr
  set -e
  ! test -s "$TRACE"
  grep -Fq 'https://swobu.com/install.sh' /tmp/e2e/claude.stdout
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
  connect-invalid)
    start_daemon one.yaml
    cat >"$CLAUDE_DIR/settings.json" <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:9/c/work","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    before=$(sha256sum "$CLAUDE_DIR/settings.json" 2>/dev/null || true)
    stop_daemon
    claude_run "/swobu:connect 'team alpha;touch /tmp/PWNED' The complete workspace argument is exactly team alpha;touch /tmp/swobu-smoke-forbidden. It is invalid." >/tmp/e2e/claude.stdout 2>/tmp/e2e/claude.stderr || true
    test ! -e /tmp/PWNED
    ! grep -Fxq 'connect' "$TRACE"
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
  connect-replace)
    start_daemon one.yaml
    preseed_settings <<'JSON'
{"env":{"ANTHROPIC_BASE_URL":"http://127.0.0.1:9/c/foreign","KEEP_ME":"yes"},"unrelated":{"also":"yes"}}
JSON
    before=$(settings_sha)
    out=$(claude_run '/swobu:connect work')
    printf '%s\n' "$out" >claude.turn1
    session_id=$(printf '%s\n' "$out" | jq -rs 'map(select(.type == "result"))[-1].session_id')
    test -n "$session_id"
    grep -Fxq 'connect' "$TRACE"
    grep -Fxq 'work' "$TRACE"
    ! grep -Fxq -- '--replace' "$TRACE"
    assert_unchanged "$before"
    : >"$TRACE"
    out=$(claude_run 'Yes, replace it.' --resume "$session_id")
    printf '%s\n' "$out" >claude.turn2
    stop_daemon
    grep -Fxq -- '--replace' "$TRACE"
    assert_swobu_settings http://127.0.0.1:17926/c/work
    jq -e '.env.KEEP_ME == "yes" and .unrelated.also == "yes"' "$CLAUDE_DIR/settings.json" >/dev/null
    ;;
  request-smoke)
    python3 "$PLUGIN/e2e/upstream.py" 18080 >/tmp/e2e/upstream.out 2>/tmp/e2e/upstream.err &
    upstream_pid=$!
    start_daemon one.yaml
    rm -f "$CLAUDE_DIR/settings.json"
    claude_run '/swobu:connect' >claude.out
    assert_swobu_settings http://127.0.0.1:17926/c/work
    : >"$TRACE"
    out=$(CLAUDE_CONFIG_DIR="$CLAUDE_DIR" ANTHROPIC_API_KEY=dummy-client-key \
      timeout 120 claude --bare -p 'Reply with exactly the marker returned by the endpoint.' \
      --model "${E2E_MODEL:?}" --effort low --output-format stream-json --verbose)
    printf '%s\n' "$out" >request.out
    stop_daemon
    kill "$upstream_pid" 2>/dev/null || true
    grep -Fq 'SWOBU_E2E_OK' request.out
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
