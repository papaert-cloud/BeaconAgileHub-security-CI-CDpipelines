#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../terraform"
if command -v terraform >/dev/null 2>&1; then
  terraform fmt -recursive
else
  echo "terraform not found in PATH; please install terraform to run formatting"
  exit 1
fi
