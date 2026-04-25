#!/bin/bash

# Hermes fork sync and analysis script
# This script:
# 1. Syncs main branch with upstream/main
# 2. Analyzes how many commits custom/main is behind upstream
# 3. Exits with code 0 if everything is up to date
# 4. Exits with code 1 if custom/main needs rebase

set -e

REPO_DIR="/home/diegohb/.hermes/hermes-agent"
cd "$REPO_DIR"

echo "=== Hermes Fork Sync and Analysis ==="
echo "Repository: $REPO_DIR"
echo "Date: $(date)"
echo ""

# Step 1: Fetch all remotes
echo "Step 1: Fetching all remotes..."
git fetch --all --prune

# Step 2: Check current branch and save it
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"
echo ""

# Step 3: Sync main branch with upstream/main
echo "Step 2: Syncing main branch with upstream/main..."
git checkout main
git reset --hard origin/main
git fetch upstream
git merge upstream/main --no-edit
git push origin main
echo "Main branch synced successfully."
echo ""

# Step 4: Analyze custom/main vs upstream/main
echo "Step 3: Analyzing custom/main vs upstream/main..."

# Check if custom branch exists
if ! git show-ref --verify --quiet refs/heads/custom/main; then
    echo "ERROR: custom/main branch does not exist!"
    exit 1
fi

# Get commit counts
UPSTREAM_COMMIT=$(git rev-parse upstream/main)
CUSTOM_COMMIT=$(git rev-parse custom/main)

# Count commits custom/main is behind upstream/main
BEHIND_COUNT=$(git rev-list --count "$UPSTREAM_COMMIT"..."$CUSTOM_COMMIT" 2>/dev/null || echo "0")

# Count commits custom/main is ahead of upstream/main
AHEAD_COUNT=$(git rev-list --count "$CUSTOM_COMMIT"..."$UPSTREAM_COMMIT" 2>/dev/null || echo "0")

echo ""
echo "=== Analysis Results ==="
echo "Upstream/main commit: $UPSTREAM_COMMIT"
echo "Custom/main commit: $CUSTOM_COMMIT"
echo "Custom/main is $AHEAD_COUNT commits ahead of upstream/main"
echo "Custom/main is $BEHIND_COUNT commits behind upstream/main"
echo ""

# Step 5: Determine if rebase is needed
if [ "$AHEAD_COUNT" -eq "0" ] && [ "$BEHIND_COUNT" -eq "0" ]; then
    echo "✓ custom/main is up to date with upstream/main"
    echo "No action needed."

    # Restore original branch
    git checkout "$CURRENT_BRANCH" 2>/dev/null || true
    exit 0
else
    echo "⚠ custom/main needs to be rebased onto upstream/main"
    echo ""
    echo "Summary:"
    echo "  - $AHEAD_COUNT commits ahead (your custom work)"
    echo "  - $BEHIND_COUNT commits behind (upstream changes)"
    echo ""
    echo "To rebase, run:"
    echo "  git checkout custom/main"
    echo "  git rebase upstream/main"
    echo "  git push origin custom/main --force-with-lease"

    # Restore original branch
    git checkout "$CURRENT_BRANCH" 2>/dev/null || true
    exit 1
fi
