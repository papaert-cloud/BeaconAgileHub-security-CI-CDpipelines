#!/bin/bash
# Periodic sync script - run via cron
cd "$(dirname "$0")/.."
git fetch --all
CURRENT_BRANCH=$(git branch --show-current)
git pull origin "$CURRENT_BRANCH" || echo "Pull failed"
git push origin "$CURRENT_BRANCH" || echo "Push failed"
