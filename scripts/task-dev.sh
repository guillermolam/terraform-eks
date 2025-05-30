#!/bin/sh

# Setup project with Trunk
task setup

# Start development (validates everything)
task dev

# Format all files automatically
task format

# Check code quality without fixing
task lint

# Auto-fix all fixable issues
task fix

# Run comprehensive validation
task validate
