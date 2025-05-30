#!/usr/bin/env bash

# Upgrade trunk itself
# trunk upgrade -y

# Non-interactive checks on changed files
trunk check --ci # runs linters/checkers, no prompts

# Sanity‐check your config
trunk check --ci .trunk/trunk.yaml

# Auto‐format all changed files (this applies fixes)
trunk fmt

# Optionally verify formatting only:
# trunk fmt --check

# Auto‐apply any remaining fixes from checkers
trunk check --ci --fix

# Final all‐green check
trunk check --ci

trunk upgrade -y
