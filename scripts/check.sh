#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

for path in \
  .gitignore \
  .claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  skills/setup/SKILL.md \
  skills/connect/SKILL.md \
  skills/status/SKILL.md \
  CHANGELOG.md \
  review/swobu.yaml \
  review/README.md \
  README.md SECURITY.md PRIVACY.md LICENSE
do
  if [ ! -f "$path" ]; then
    echo "missing required plugin file: $path" >&2
    exit 1
  fi
done

skills=$(find skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
if [ "$skills" != "$(printf 'connect\nsetup\nstatus')" ]; then
  echo "V1 must contain exactly connect, setup, and status skills" >&2
  exit 1
fi

for forbidden in hooks agents commands .mcp.json
do
  if [ -e "$forbidden" ]; then
    echo "forbidden V1 component: $forbidden" >&2
    exit 1
  fi
done

if grep -q '^allowed-tools:' skills/setup/SKILL.md skills/connect/SKILL.md; then
  echo "skills must use Claude Code's normal permission flow" >&2
  exit 1
fi

if ! grep -Fxq '.out/' .gitignore; then
  echo "runtime smoke output must stay out of the published repository" >&2
  exit 1
fi

printf '%s\n' "plugin structural and distribution checks passed"
