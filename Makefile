# variables --------------------------------------------------------->8---------
SHELL     := /usr/bin/env zsh
HOST      ?= $(shell hostname)
HOST      := $(HOST)
SYSTEM    ?= x86_64-linux
TEST_NAME ?=
INPUT     ?=


# phony ------------------------------------------------------------->8---------
.PHONY: help \
        format lint check \
        test test-filter list-checks \
        dry-run build \
        update


# default target ---------------------------------------------------->8---------
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_.-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Quick Start:"
	@echo "  make format             # Format Nix, Nim and Markdown files"
	@echo "  make lint               # Run the formatting and lint checks"
	@echo "  make check              # Evaluate the flake without building"
	@echo "  make dry-run            # Show what a build of this host would do"


# quality targets --------------------------------------------------->8---------
format: ## Format Nix, Nim and Markdown files (nix fmt)
	@echo "Formatting Nix, Nim and Markdown files..."
	nix fmt -- --no-cache

lint: ## Run the formatting, nix-lint and markdown-lint checks
	@echo "Running lint checks..."
	nix build --no-link \
		'.#checks.$(SYSTEM).formatting' \
		'.#checks.$(SYSTEM).nix-lint' \
		'.#checks.$(SYSTEM).markdown-lint'

check: ## Evaluate the flake and its checks without building
	@echo "Evaluating flake..."
	nix flake check --no-build


# test targets ------------------------------------------------------>8---------
test: ## Run every flake check (lint, Nim tests, ax integration)
	@echo "Running all flake checks..."
	nix flake check

test-filter: ## Run a single check by name (usage: make test-filter TEST_NAME=<check>)
	@test -n "$(TEST_NAME)" || (echo "TEST_NAME is not set — usage: make test-filter TEST_NAME=<check> (see make list-checks)" >&2 && exit 1)
	@echo "Running check: $(TEST_NAME)..."
	nix build --no-link '.#checks.$(SYSTEM).$(TEST_NAME)'

list-checks: ## List flake check names (for test-filter)
	@nix eval --raw '.#checks.$(SYSTEM)' --apply 'checks: builtins.concatStringsSep "\n" (builtins.attrNames checks) + "\n"'


# lifecycle targets ------------------------------------------------->8---------
dry-run: ## Dry-run a build of HOST (default: this host)
	@echo "Dry-running build of $(HOST)..."
	nh os build . -H $(HOST) --dry

build: ## Build HOST without switching (default: this host)
	@echo "Building $(HOST)..."
	nh os build . -H $(HOST)


# maintenance targets ----------------------------------------------->8---------
update: ## Update flake inputs (all, or INPUT=<name>)
	@echo "Updating flake inputs$(if $(INPUT), ($(INPUT)),)..."
	nix flake update $(INPUT)
