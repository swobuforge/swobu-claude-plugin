#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK_DIR=${SWOBU_PLUGIN_SMOKE_DIR:-"$ROOT_DIR/.out/runtime-smoke-$$"}
FAKE_BIN="$WORK_DIR/bin"
CLAUDE=$(command -v claude)
CONTROL_PORT=${SWOBU_PLUGIN_SMOKE_CONTROL_PORT:-18190}
mkdir -p "$FAKE_BIN"

cat >"$FAKE_BIN/swobu" <<'FAKE'
#!/bin/sh
set -eu
printf '%s\n' "$#" >"$SWOBU_SMOKE_LOG"
for arg do printf '<%s>\n' "$arg" >>"$SWOBU_SMOKE_LOG"; done
case "$SWOBU_SMOKE_SCENARIO" in
  status) echo 'unreachable' ;;
  default)
    case "$*" in
      *' --workspace '*'') echo configured ;;
      *) echo configured ;;
    esac ;;
  multiple) echo 'Multiple Swobu workspaces exist.' >&2; exit 1 ;;
  unknown) echo 'Workspace does not exist.' >&2; exit 1 ;;
  replace)
    case " $* " in
      *' --replace '*) echo 'configured' ;;
      *) echo 'Existing client configuration would be replaced. Run again with --replace.' >&2; exit 1 ;;
    esac ;;
  *) echo 'configured' ;;
esac
FAKE
chmod +x "$FAKE_BIN/swobu"

python3 "$ROOT_DIR/e2e/control-upstream.py" "$CONTROL_PORT" \
  "$WORK_DIR/control-request.json" >"$WORK_DIR/control.out" 2>"$WORK_DIR/control.err" &
control_pid=$!
trap 'kill "${control_pid:-}" 2>/dev/null || true' EXIT
sleep 1
if ! kill -0 "$control_pid" 2>/dev/null; then
  cat "$WORK_DIR/control.err" >&2
  exit 1
fi

run_case() {
  name=$1
  scenario=$2
  prompt=$3
  path_mode=${4:-fake}
  case_config_dir="$WORK_DIR/claude-$name"
  mkdir -p "$case_config_dir"
  if [ "$path_mode" = absent ]; then
    case_path="/usr/bin:/bin"
  else
    case_path="$FAKE_BIN:$PATH"
  fi
  settings=$(printf '{"env":{"PATH":"%s","ANTHROPIC_BASE_URL":"http://127.0.0.1:%s"}}' "$case_path" "$CONTROL_PORT")
  SWOBU_SMOKE_LOG="$WORK_DIR/$name.argv" \
  SWOBU_SMOKE_SCENARIO="$scenario" \
  ANTHROPIC_API_KEY="${SWOBU_PLUGIN_SMOKE_API_KEY:-control-e2e-key}" \
  CLAUDE_CONFIG_DIR="$case_config_dir" \
  PATH="$case_path" \
  python3 -c 'import subprocess, sys
try:
    result = subprocess.run(sys.argv[2:], timeout=float(sys.argv[1]))
except subprocess.TimeoutExpired:
    sys.exit(124)
sys.exit(result.returncode)' 90 "$CLAUDE" --plugin-dir "$ROOT_DIR" \
    --bare \
    --no-session-persistence \
    --max-turns 2 \
    --permission-mode bypassPermissions \
    --settings "$settings" \
    --model claude-haiku-4-5 --effort low --max-budget-usd 0.30 -p \
    "$prompt" \
    >"$WORK_DIR/$name.out" 2>"$WORK_DIR/$name.err"
}

retry_empty_cases() {
  for name in setup-absent setup-installed no-workspace one-workspace \
    multiple unknown status already
  do
    if [ ! -s "$WORK_DIR/$name.out" ]; then
      echo "empty runtime smoke response: retrying $name" >&2
      case "$name" in
        setup-absent) run_case "$name" configured '/swobu:setup' absent ;;
        setup-installed) run_case "$name" configured '/swobu:setup' ;;
        no-workspace) run_case "$name" default '/swobu:connect' ;;
        one-workspace) run_case "$name" configured '/swobu:connect' ;;
        multiple) run_case "$name" multiple '/swobu:connect' ;;
        status) run_case "$name" configured '/swobu:status' ;;
        unknown) run_case "$name" unknown '/swobu:connect missing' ;;
        already) run_case "$name" configured '/swobu:connect' ;;
      esac
    fi
  done
}

pids=""
run_case setup-absent configured '/swobu:setup' absent & pids="$pids $!"
run_case setup-installed configured '/swobu:setup' & pids="$pids $!"
run_case status configured '/swobu:status' & pids="$pids $!"
run_case no-workspace default '/swobu:connect' & pids="$pids $!"
run_case one-workspace configured '/swobu:connect' & pids="$pids $!"
run_case multiple multiple '/swobu:connect' & pids="$pids $!"
run_case unknown unknown '/swobu:connect missing' & pids="$pids $!"
run_case already configured '/swobu:connect' & pids="$pids $!"

failed=0
for job in $pids; do
  wait "$job" || failed=1
done

retry_empty_cases || true

if [ "$failed" -ne 0 ]; then
  echo "one or more Claude smoke cases failed; inspect $WORK_DIR" >&2
  exit 1
fi

test ! -e /tmp/swobu-smoke-forbidden
test ! -s "$WORK_DIR/setup-absent.argv"
test ! -s "$WORK_DIR/setup-installed.argv"
expected_one=$(printf '2\n<connect>\n<claude>')
test "$(cat "$WORK_DIR/one-workspace.argv")" = "$expected_one"

# The absent-binary branch is owned by the containerized E2E. On hosts with
# sandbox restrictions, Claude may report a restricted command result, so this
# smoke only proves that setup did not execute Swobu and produced a response.
test -s "$WORK_DIR/setup-absent.out"
test -s "$WORK_DIR/status.argv"
grep -Eqi 'configured|already' "$WORK_DIR/already.out"
if grep -Eqi 'healthy|failover is active|requests are now using' "$WORK_DIR"/*.out; then
  echo "runtime smoke emitted an unsupported health claim" >&2
  exit 1
fi

echo "plugin runtime smoke passed: $WORK_DIR"
