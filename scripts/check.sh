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
  scripts/distribution-smoke.sh \
  scripts/check-locales.py \
  locales.yaml \
  review/swobu.yaml \
  review/README.md \
  README.md SECURITY.md PRIVACY.md LICENSE
do
  if [ ! -f "$path" ]; then
    echo "missing required plugin file: $path" >&2
    exit 1
  fi
done

python3 scripts/check-locales.py

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

if [ ! -x scripts/distribution-smoke.sh ]; then
  echo "distribution smoke must be executable" >&2
  exit 1
fi

if grep -Eq -- '--plugin-dir|/plugin:' scripts/distribution-smoke.sh; then
  echo "distribution smoke must load only the marketplace-installed plugin" >&2
  exit 1
fi

if ! grep -Fq 'validate the entire' skills/connect/SKILL.md || \
   ! grep -Fq '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$' skills/connect/SKILL.md || \
   ! grep -Fq 'If it does not match exactly, do not invoke Bash.' skills/connect/SKILL.md; then
  echo "connect skill must structurally require exact workspace validation" >&2
  exit 1
fi

printf '%s\n' "plugin structural and distribution checks passed"
