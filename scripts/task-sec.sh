#!/usr/bin/env bash

task security-scan

# Run specific security tools
trunk check --filter=checkov,trivy,tfsec

# Update Trunk and all tools
task update-trunk
