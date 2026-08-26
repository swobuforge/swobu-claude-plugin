#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
IMAGE=swobu-claude-plugin-e2e:latest
ARTIFACTS="$ROOT_DIR/.out/e2e"
MODE=${1:-all}

set -a
. "$ROOT_DIR/e2e/versions.env"
set +a

podman build \
  --build-arg CLAUDE_VERSION="$CLAUDE_VERSION" \
  --build-arg SWOBU_VERSION="$SWOBU_VERSION" \
  -t "$IMAGE" -f "$ROOT_DIR/e2e/Containerfile" "$ROOT_DIR"

run_case() {
  local name=$1 mode=$2
  local dir="$ARTIFACTS/$name"
  mkdir -p "$dir"
  rm -rf "$dir"
  mkdir -p "$dir"

  podman run --rm \
    --userns=keep-id \
    -e E2E_CONTROL_API_KEY \
    -e E2E_MODEL \
    -e SWOBU_E2E_TRACE=/tmp/e2e/trace.log \
    -v "$ROOT_DIR":/plugin:ro,Z \
    -v "$dir":/artifacts:Z \
    "$IMAGE" \
    bash -c 'mkdir -p /tmp/e2e-bin /tmp/e2e; cp /plugin/e2e/swobu-trace-or-inline-wrapper /tmp/e2e-bin/swobu; chmod +x /tmp/e2e-bin/swobu; export PATH=/tmp/e2e-bin:$PATH; set +e; /plugin/e2e/inside.sh '"$mode"'; rc=$?; tar -C /tmp/e2e -cf - . | tar -C /artifacts -xf -; exit $rc'

  echo "e2e passed: $name"
}

release_connect_replace() {
  local name=release-connect-replace
  local dir="$ARTIFACTS/$name"
  rm -rf "$dir"
  mkdir -p "$dir"

  : "${ANTHROPIC_API_KEY:?real Anthropic key required}"

  podman run --rm \
    --userns=keep-id \
    -e ANTHROPIC_API_KEY \
    -v "$ROOT_DIR":/plugin:ro,Z \
    -v "$dir":/artifacts:Z \
    "$IMAGE" \
    bash -c 'mkdir -p /tmp/e2e-bin /tmp/e2e; cp /plugin/e2e/swobu-trace-or-inline-wrapper /tmp/e2e-bin/swobu; chmod +x /tmp/e2e-bin/swobu; export PATH=/tmp/e2e-bin:$PATH SWOBU_E2E_TRACE=/tmp/e2e/trace.log; set +e; /plugin/e2e/inside.sh release-connect-replace; rc=$?; tar -C /tmp/e2e -cf - . | tar -C /artifacts -xf -; exit $rc'

  echo "release e2e passed: $name"
}

case "$MODE" in
  load | setup-absent | status-down | status-healthy | connect-multiple | \
  connect-unknown | connect-one | connect-idempotent | \
  connect-replacement-refused | request-smoke)
    run_case "$MODE" "$MODE"
    ;;
  release-connect-replace)
    release_connect_replace
    ;;
  all)
    run_case e1-load load
    run_case e3-setup-absent setup-absent
    run_case e4-status-down status-down
    run_case e5-status-healthy status-healthy
    run_case e6-connect-one connect-one
    run_case e7-multiple connect-multiple
    run_case e7-unknown connect-unknown
    run_case e8-idempotent connect-idempotent
    run_case e9-replacement-refused connect-replacement-refused
    run_case e10-request request-smoke
    ;;
  *)
    echo "unknown e2e mode: $MODE" >&2
    exit 2
    ;;
esac
