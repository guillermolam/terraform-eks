#!/usr/bin/env bash

# Sanity‐check your config
trunk check --ci .trunk/trunk.yaml

# Auto‐format all changed files (this applies fixes)
trunk fmt --all

# Auto‐apply any remaining fixes from checkers
trunk check --ci --fix

trunk upgrade -y
