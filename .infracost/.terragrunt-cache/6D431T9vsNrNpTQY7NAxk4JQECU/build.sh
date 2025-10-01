#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMPDIR=$(mktemp -d)
echo "Building lambda package in $TMPDIR"
pip install -r "$ROOT_DIR/lambda/requirements.txt" -t "$TMPDIR"
cp -r "$ROOT_DIR/lambda/"* "$TMPDIR/"
(cd "$TMPDIR" && zip -r9 /tmp/remediate.zip .)
echo "/tmp/remediate.zip created"
