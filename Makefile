.DEFAULT_GOAL := help

.PHONY: help build check smoke verify e2e release-e2e release-verify distribution-smoke

help: ## Show plugin entrypoints
	@awk 'BEGIN {FS = ":.*## "; print "swobu-claude-plugin entrypoints:"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Validate the distributable plugin and marketplace
	@claude plugin validate . --strict

check: ## Run structural and distribution contract checks
	@./scripts/check.sh

smoke: ## Exercise skills through claude --plugin-dir and fake swobu
	@./scripts/runtime-smoke.sh

e2e: ## Run real Claude and released Swobu in rootless Podman
	@./e2e/run.sh all

release-e2e: e2e ## Run deterministic E2E plus real-model replacement confirmation
	@ANTHROPIC_API_KEY="$${ANTHROPIC_API_KEY:?}" ./e2e/run.sh release-connect-replace

verify: check build smoke ## Run fast plugin release checks
	@:

release-verify: verify release-e2e ## Run release-blocking checks including E2E
	@:

distribution-smoke: ## Verify an installed public tag; usage: make distribution-smoke TAG=vX.Y.Z
	@./scripts/distribution-smoke.sh "$${TAG:?set TAG to the published plugin tag}"
