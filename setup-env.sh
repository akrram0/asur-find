#!/usr/bin/env bash
# =============================================================================
# setup-env.sh - Safe Deep Cleaning Utility (POSIX variant)
# Dot-source FIRST in every script:   source ./setup-env.sh
# =============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PNPM_HOME="$PROJECT_ROOT/.tooling/pnpm-home"
export CARGO_HOME="$PROJECT_ROOT/.tooling/cargo"
export RUSTUP_HOME="$PROJECT_ROOT/.tooling/rustup"
export GOPATH="$PROJECT_ROOT/.tooling/go"
export GOMODCACHE="$PROJECT_ROOT/.tooling/go/pkg/mod"
export GOCACHE="$PROJECT_ROOT/.tooling/go-cache"
export GOBIN="$PROJECT_ROOT/src-go/bin"

export PATH="$PNPM_HOME:$CARGO_HOME/bin:$PROJECT_ROOT/.tooling/go/bin:$PROJECT_ROOT/node_modules/.bin:$PATH"

mkdir -p "$PNPM_HOME" "$CARGO_HOME" "$RUSTUP_HOME" "$GOPATH" "$GOCACHE" "$GOBIN"

echo "[setup-env] Tooling sandboxed under: $PROJECT_ROOT/.tooling"