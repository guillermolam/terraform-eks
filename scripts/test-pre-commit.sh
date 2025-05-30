#!/usr/bin/env bash
# scripts/test-pre-commit.sh — create venv (if needed), install pre-commit, then run all hooks

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$REPO_ROOT/.venv"
ACTIVATE="$VENV_DIR/bin/activate"

# 1) Create venv if missing
if [ ! -f "$ACTIVATE" ]; then
  echo "Creating virtual environment in $VENV_DIR"
  if ! python3 -m venv "$VENV_DIR"; then
    echo "Error: Failed to create virtual environment. Ensure python3-venv is installed:" \
         "sudo apt install python3-venv" >&2
    exit 1
  fi
fi

# 2) Verify venv actually has activate
if [ ! -f "$ACTIVATE" ]; then
  echo "Error: venv activation script not found at $ACTIVATE" >&2
  echo "Make sure python3-venv is installed: sudo apt install python3-venv" >&2
  exit 1
fi

# 3) Activate venv
# shellcheck disable=SC1090
source "$ACTIVATE"

# 4) Install or upgrade pre-commit
if ! command -v pre-commit >/dev/null; then
  echo "Installing pre-commit into $VENV_DIR"
  pip install --upgrade pip
  pip install pre-commit==3.5.0
fi

# 5) Install Git hook if not already present
if [ ! -f "$REPO_ROOT/.git/hooks/pre-commit" ]; then
  echo "Installing Git pre-commit hook"
  pre-commit install --install-hooks
fi

# 6) Run all hooks
echo "Running all pre-commit hooks on every file..."
pre-commit run --all-files --show-diff-on-failure

echo "All hooks passed!"
