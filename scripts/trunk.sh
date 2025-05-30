#!/bin/bash
trunk check --ci

# Check for any remaining config errors
trunk check ../.trunk/trunk.yaml

# Test basic functionality
trunk fmt
trunk check
