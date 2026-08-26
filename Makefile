.DEFAULT_GOAL := help

.PHONY: help build check smoke verify e2e release-verify

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

verify: check build smoke ## Run fast plugin release checks
	@:

release-verify: verify e2e ## Run release-blocking checks including E2E
	@:
