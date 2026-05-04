#!/bin/bash
# Hermes Agent Fork Sync and Analysis Script
# Syncs main with upstream, analyzes custom/main delta, requests approval for rebase
#
# IMPORTANT: This script uses git worktrees to avoid modifying the working directory
# of the main checkout. This prevents triggering the gateway's stale-code detection
# which auto-restarts when files on disk are newer than the running process.
# See FORK-MAPPING.md "Pitfalls" section for details.

set -e

REPO_DIR="/home/diegohb/.hermes/hermes-agent"
WORKTREE_DIR="/tmp/hermes-fork-sync-main"
cd "$REPO_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hermes Fork Sync and Analysis ===${NC}"
echo

# Cleanup function to remove worktree on exit
cleanup() {
    if [ -d "$WORKTREE_DIR" ]; then
        git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Step 1: Sync main with upstream/main using a worktree
echo -e "${YELLOW}[1/4] Syncing main with upstream/main (via worktree)...${NC}"

# Create worktree for main branch
git worktree add "$WORKTREE_DIR" main >/dev/null 2>&1

# Fetch upstream
git -C "$WORKTREE_DIR" fetch upstream >/dev/null 2>&1

# Check if main can fast-forward
if git -C "$WORKTREE_DIR" merge-base --is-ancestor HEAD upstream/main 2>/dev/null; then
    git -C "$WORKTREE_DIR" merge --ff-only upstream/main
    echo -e "${GREEN}✓ main fast-forwarded to upstream/main${NC}"
else
    echo -e "${YELLOW}⚠ main has diverged, using hard reset${NC}"
    git -C "$WORKTREE_DIR" reset --hard upstream/main
    echo -e "${GREEN}✓ main reset to upstream/main${NC}"
fi

# Push main to origin
git -C "$WORKTREE_DIR" push origin main -f >/dev/null 2>&1
echo -e "${GREEN}✓ main pushed to origin${NC}"
echo

# Step 2: Analyze custom/main vs upstream/main
echo -e "${YELLOW}[2/4] Analyzing custom/main vs upstream/main...${NC}"

# Count commits behind
COMMITS_BEHIND=$(git rev-list --count origin/custom/main..upstream/main 2>/dev/null || echo "0")
COMMITS_AHEAD=$(git rev-list --count upstream/main..origin/custom/main 2>/dev/null || echo "0")

echo -e "  Commits behind upstream: ${RED}${COMMITS_BEHIND}${NC}"
echo -e "  Commits ahead of upstream: ${GREEN}${COMMITS_AHEAD}${NC}"
echo

# Step 3: Check if rebase is needed
if [ "$COMMITS_BEHIND" -eq 0 ]; then
    echo -e "${GREEN}✓ custom/main is up to date with upstream/main${NC}"
    echo
    echo -e "${BLUE}=== Summary ===${NC}"
    echo "main: ✓ synced with upstream"
    echo "custom/main: ✓ already up to date"
    echo
    echo "No action needed."
    exit 0
fi

# Step 4: Show preview of upstream changes
echo -e "${YELLOW}[3/4] Preview of upstream changes:${NC}"
git log --oneline origin/custom/main..upstream/main | head -20
if [ "$COMMITS_BEHIND" -gt 20 ]; then
    echo -e "... and $((COMMITS_BEHIND - 20)) more commits"
fi
echo

# Step 5: Show custom commits not in upstream
if [ "$COMMITS_AHEAD" -gt 0 ]; then
    echo -e "${YELLOW}[4/4] Custom commits that will be rebased:${NC}"
    git log --oneline upstream/main..origin/custom/main
    echo
fi

# Decision point
echo -e "${BLUE}=== Action Required ===${NC}"
echo -e "${YELLOW}custom/main is ${COMMITS_BEHIND} commits behind upstream/main.${NC}"
echo
echo "To rebase custom/main onto upstream/main, run:"
echo -e "${GREEN}  cd $REPO_DIR${NC}"
echo -e "${GREEN}  git checkout custom/main${NC}"
echo -e "${GREEN}  git rebase upstream/main${NC}"
echo -e "${GREEN}  # Resolve conflicts if any${NC}"
echo -e "${GREEN}  git push --force-with-lease origin custom/main${NC}"
echo
echo "After rebase, update venv and restart gateway:"
echo -e "${GREEN}  source venv/bin/activate${NC}"
echo -e "${GREEN}  pip install -e .${NC}"
echo -e "${GREEN}  systemctl --user restart hermes-gateway${NC}"
echo

# Exit with code 1 to signal action needed
exit 1
