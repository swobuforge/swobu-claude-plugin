#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK_DIR=${SWOBU_PLUGIN_SMOKE_DIR:-"$ROOT_DIR/.out/runtime-smoke-$$"}
FAKE_BIN="$WORK_DIR/bin"
CLAUDE=$(command -v claude)
TIMEOUT=$(command -v timeout)
mkdir -p "$FAKE_BIN"

cat >"$FAKE_BIN/swobu" <<'FAKE'
#!/bin/sh
set -eu
printf '%s\n' "$#" >"$SWOBU_SMOKE_LOG"
for arg do printf '<%s>\n' "$arg" >>"$SWOBU_SMOKE_LOG"; done
case "$SWOBU_SMOKE_SCENARIO" in
  status) echo 'unreachable' ;;
  no-workspace) echo 'No Swobu workspace is configured.' >&2; exit 1 ;;
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

run_case() {
  name=$1
  scenario=$2
  prompt=$3
  path_mode=${4:-fake}
  if [ "$path_mode" = absent ]; then
    case_path="/usr/bin:/bin"
  else
    case_path="$FAKE_BIN:$PATH"
  fi
  settings=$(printf '{"env":{"PATH":"%s"}}' "$case_path")
  SWOBU_SMOKE_LOG="$WORK_DIR/$name.argv" \
  SWOBU_SMOKE_SCENARIO="$scenario" \
  PATH="$case_path" \
  "$TIMEOUT" 75 "$CLAUDE" --plugin-dir "$ROOT_DIR" --allowedTools Bash \
    --settings "$settings" \
    --model haiku --effort low --max-budget-usd 0.30 -p \
    "$prompt Do exactly one skill workflow, report the result, and stop. Do not retry a failed command unless this prompt explicitly confirms replacement." \
    >"$WORK_DIR/$name.out" 2>"$WORK_DIR/$name.err"
}

retry_empty_cases() {
  for name in setup-absent setup-installed no-workspace one-workspace \
    unknown status already replace-declined replace-accepted invalid-workspace
  do
    if [ ! -s "$WORK_DIR/$name.out" ]; then
      echo "empty runtime smoke response: retrying $name" >&2
      case "$name" in
        setup-absent) run_case "$name" configured '/swobu:setup' absent ;;
        setup-installed | no-workspace | one-workspace | multiple | already)
          run_case "$name" configured "/${name#setup-installed}" ;;
        status) run_case "$name" configured '/swobu:status' ;;
        unknown) run_case "$name" unknown '/swobu:connect missing' ;;
        replace-declined)
          run_case "$name" replace '/swobu:connect "work" Decline replacement. The complete workspace argument is exactly work without punctuation.' ;;
        replace-accepted)
          run_case "$name" replace '/swobu:connect "work" Replacement is explicitly confirmed. The complete workspace argument is exactly work without punctuation.' ;;
        invalid-workspace)
          run_case "$name" configured "/swobu:connect 'team alpha;touch /tmp/swobu-smoke-forbidden' The complete workspace argument is exactly team alpha;touch /tmp/swobu-smoke-forbidden" ;;
      esac
    fi
  done
}

pids=""
run_case setup-absent configured '/swobu:setup' absent & pids="$pids $!"
run_case setup-installed configured '/swobu:setup' & pids="$pids $!"
run_case status configured '/swobu:status' & pids="$pids $!"
run_case no-workspace no-workspace '/swobu:connect' & pids="$pids $!"
run_case one-workspace configured '/swobu:connect' & pids="$pids $!"
run_case multiple multiple '/swobu:connect' & pids="$pids $!"
run_case unknown unknown '/swobu:connect missing' & pids="$pids $!"
run_case already configured '/swobu:connect' & pids="$pids $!"
run_case replace-declined replace '/swobu:connect "work" Decline replacement. The complete workspace argument is exactly work without punctuation.' & pids="$pids $!"
run_case replace-accepted replace '/swobu:connect "work" Replacement is explicitly confirmed. The complete workspace argument is exactly work without punctuation.' & pids="$pids $!"
run_case invalid-workspace configured "/swobu:connect 'team alpha;touch /tmp/swobu-smoke-forbidden' The complete workspace argument is exactly team alpha;touch /tmp/swobu-smoke-forbidden" & pids="$pids $!"

failed=0
for job in $pids; do
  wait "$job" || failed=1
done

retry_empty_cases

if [ "$failed" -ne 0 ]; then
  echo "one or more Claude smoke cases failed; inspect $WORK_DIR" >&2
  exit 1
fi

test ! -e /tmp/swobu-smoke-forbidden
test ! -s "$WORK_DIR/setup-absent.argv"
test ! -s "$WORK_DIR/setup-installed.argv"
test ! -s "$WORK_DIR/invalid-workspace.argv"
expected_one=$(printf '2\n<connect>\n<claude>')
expected_declined=$(printf '4\n<connect>\n<claude>\n<--workspace>\n<work>')
test "$(cat "$WORK_DIR/one-workspace.argv")" = "$expected_one"
test "$(cat "$WORK_DIR/replace-declined.argv")" = "$expected_declined"
grep -qx '<--replace>' "$WORK_DIR/replace-accepted.argv"

grep -Fq 'curl -fsSL https://swobu.com/install.sh | sh' "$WORK_DIR/setup-absent.out"
grep -Fq '<status>' "$WORK_DIR/status.argv"
grep -Eqi 'multiple|which workspace' "$WORK_DIR/multiple.out"
grep -Eqi 'does not exist|unknown' "$WORK_DIR/unknown.out"
grep -Eqi 'configured|already' "$WORK_DIR/already.out"
if grep -Eqi 'healthy|failover is active|requests are now using' "$WORK_DIR"/*.out; then
  echo "runtime smoke emitted an unsupported health claim" >&2
  exit 1
fi

echo "plugin runtime smoke passed: $WORK_DIR"
