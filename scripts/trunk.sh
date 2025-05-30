#!/usr/bin/env bash

# Upgrade trunk itself
trunk upgrade -y

# All checks in CI mode (no prompts)
trunk check --ci

# Config sanity-check
trunk check --ci .trunk/trunk.yaml

# Autofix and skip its prompt
trunk fix --yes

# Formatting check (non-interactive)
trunk fmt --check

# Final lint & test pass (non-interactive)
trunk check --ci
