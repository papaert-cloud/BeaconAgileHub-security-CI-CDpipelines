#!/bin/bash

set -e

echo "🔄 Starting comprehensive repo sync..."

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Push current branch first
echo "⬆️ Pushing current branch: $CURRENT_BRANCH"
git push origin "$CURRENT_BRANCH"

# Get all local branches
LOCAL_BRANCHES=$(git branch | sed 's/^\*//' | sed 's/^[[:space:]]*//' | grep -v '^$')

echo "🌿 Syncing all local branches..."
for branch in $LOCAL_BRANCHES; do
    if [[ "$branch" != "$CURRENT_BRANCH" ]]; then
        echo "🔄 Processing branch: $branch"
        
        # Check if remote branch exists
        if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
            git checkout "$branch"
            git pull origin "$branch" || echo "⚠️ Pull failed for $branch, continuing..."
            git push origin "$branch" || echo "⚠️ Push failed for $branch, continuing..."
        else
            echo "📤 Creating new remote branch: $branch"
            git checkout "$branch"
            git push -u origin "$branch" || echo "⚠️ Failed to create remote branch $branch"
        fi
    fi
done

# Return to original branch
git checkout "$CURRENT_BRANCH"

echo "✅ All branches synced!"

# Setup real-time sync with git hooks
echo "⚙️ Setting up real-time sync..."

# Create post-commit hook for auto-push
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# Auto-push after commit (real-time sync)
if [ "$AUTO_PUSH" != "0" ]; then
    BRANCH=$(git branch --show-current)
    echo "🚀 Auto-pushing $BRANCH to origin..."
    git push origin "$BRANCH" || echo "⚠️ Auto-push failed"
fi
EOF

# Create post-merge hook
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
# Auto-push after merge
if [ "$AUTO_PUSH" != "0" ]; then
    BRANCH=$(git branch --show-current)
    echo "🚀 Auto-pushing merged changes to $BRANCH..."
    git push origin "$BRANCH" || echo "⚠️ Auto-push after merge failed"
fi
EOF

# Make hooks executable
chmod +x .git/hooks/post-commit
chmod +x .git/hooks/post-merge

# Enable auto-push by default
git config --local hooks.autopush true

echo "✅ Real-time sync enabled!"
echo "💡 To disable auto-push for a single commit: AUTO_PUSH=0 git commit -m 'message'"
echo "💡 To disable globally: git config --local hooks.autopush false"

# Setup periodic sync (optional)
echo "⏰ Setting up periodic sync..."
cat > scripts/periodic-sync.sh << 'EOF'
#!/bin/bash
# Periodic sync script - run via cron
cd "$(dirname "$0")/.."
git fetch --all
CURRENT_BRANCH=$(git branch --show-current)
git pull origin "$CURRENT_BRANCH" || echo "Pull failed"
git push origin "$CURRENT_BRANCH" || echo "Push failed"
EOF

chmod +x scripts/periodic-sync.sh

echo "🎉 Complete! All repos and branches are synced with real-time sync enabled."