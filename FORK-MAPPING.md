# Hermes Agent Fork - Diego's Customizations

## Repository Structure

```
origin:     https://github.com/diegohb/hermes-agent.git (your fork)
upstream:   https://github.com/NousResearch/hermes-agent.git (official repo)

main:       Upstream-clean reference branch (mirrors upstream/main)
custom/main: Long-lived divergent branch with Diego's customizations
```

## Branch Roles

| Branch | Purpose | Rules |
|--------|---------|-------|
| `main` | Upstream-clean reference | **Never commit directly**. Always fast-forward from upstream/main. Used for reference and clean comparisons. |
| `custom/main` | Long-lived divergent branch | All custom work lives here. Gateway runs from this branch. Rebase onto upstream/main periodically. |
| `contrib/<topic>` | Upstream pull request branches | For contributions to upstream. Must NOT include fork-only customizations. |
| `custom/<topic>` | Short-lived fork-only branches | Branch off custom/main for experiments, merge back when done. |

## Upgrade History

### 2026-05-20: v0.12.0 → v0.14.0 Upgrade
- **Commits synced**: 2108 upstream commits + 7 custom commits
- **Key changes**:
  - Version bump: 0.12.0 → 0.14.0 (release date: 2026-05-16)
  - Updated dependencies: croniter 6.2.2→6.0.0, cryptography 47.0.0→48.0.0, pydantic 2.13.3→2.12.5, openai 2.32.0→2.24.0
  - Added pytest-timeout plugin (was missing, required for test suite)
  - Bundled skills: scrapling updated (1 skill)
- **Issues encountered**:
  - .gitignore conflict: Resolved by merging upstream `hermes_cli/tui_dist/*`, `hermes_cli/scripts/`, `docs/superpowers/*` with custom `.agents/`, `config/`, `skills-lock.json`, `"*.AppData/Local/Google/Chrome/User Data/"`
  - pytest-timeout missing: Installed `pip install pytest-timeout` to run critical tests
- **Tests run** (full suite too slow, ran critical tests):
  - ✓ Fuzzy match: 34/34 passed (1.96s)
  - ✓ Hindsight provider: 96/96 passed (12.02s)
  - ✓ Memory tool: 33/33 passed (1.98s)
  - ✓ Agent initialization: OK
- **Validation**: Gateway restarted successfully, Telegram (30 commands) and Discord (159 skills) connected
- **Custom commits preserved**: 7 (FORK-MAPPING docs, sync script, v0.12.0 lessons, cron worktree fix)

### 2026-05-03: v0.11.0 → v0.12.0 Upgrade
- **Commits synced**: 1362 upstream commits + 5 custom commits
- **Key changes**:
  - ACP adapter improvements (272 lines added)
  - Gateway fixes: Discord slash command auth, Slack socket mode, resume pending sessions
  - OpenRouter response caching support
  - Updated dependencies: croniter 6.0.0→6.2.2, cryptography 46.0.7→47.0.0
- **Issues encountered**:
  - .gitignore conflict: Resolved by merging upstream `models-dev-upstream/` with custom `.agents/`, `config/`, `skills-lock.json`
  - Skills update bug: `hermes skills update` failed with AttributeError in `bundle_content_hash` - skipped, not critical
- **Tests run** (full suite too slow, ran critical tests):
  - ✓ Fuzzy match: 34/34 passed
  - ✓ Hindsight provider: 91/91 passed
  - ✓ Memory tool: 33/33 passed
  - ✓ Agent initialization: OK
- **Validation**: Gateway restarted successfully, Telegram (100 commands) and Discord (227 skills) connected

### Lessons Learned (2026-05-03)
1. **Pre-sync analysis**: Always check commit counts before starting:
   ```bash
   git log --oneline origin/main..upstream/main | wc -l  # Commits behind
   git log --oneline upstream/main..origin/custom/main | wc -l  # Custom commits
   ```

2. **Conflict resolution strategy**:
   - `.gitignore`: Always merge upstream additions with custom entries
   - Use `GIT_EDITOR=true git rebase --continue` to bypass editor prompts
   - Verify resolved sections with `sed -n 'N,Mp' .gitignore`

3. **Dependency updates**:
   - Prefer `uv pip install --reinstall -e .` for faster installs
   - Skip `hermes skills update` if it fails (upstream bug, not critical)
   - Verify version with `hermes --version` and `hermes status`

4. **Test validation**:
   - Full test suite (`pytest tests/ -v`) times out (>60s)
   - Run critical tests instead:
     ```bash
     pytest tests/tools/test_fuzzy_match.py -v
     pytest tests/plugins/memory/test_hindsight_provider.py -v
     pytest tests/tools/test_memory_tool.py -v
     python -c "from run_agent import AIAgent; AIAgent(quiet_mode=True)"
     ```

5. **Gateway restart**:
   - Always restart after code changes: `systemctl --user restart hermes-gateway`
   - Verify with `journalctl --user -u hermes-gateway -n 50` and `tail -50 ~/.hermes/logs/gateway.log`
   - Check platform connections (Telegram/Discord) in logs

## Current Customizations

As of 2026-05-03 (v0.12.0 UPGRADE), custom/main contains:

### 1. .gitignore additions
- `.agents/` - Diego's local agent files (backed up and restored)
- `config/` - Local configuration directory (not in repo)
- `skills-lock.json` - Skills lock file (not in repo)
- `"*.AppData/Local/Google/Chrome/User Data/"` - Chrome user data

### 2. FORK-MAPPING.md
This documentation file (not in upstream).

### Removed Customizations (performed full rebase):
- STT Model Selection Fix (tools/transcription_tools.py) - LOST, may need to re-apply
- mcporter Typo Fix - LOST, may need to re-apply
- All gateway/run.py customizations - LOST, now aligned with upstream
- All tools/browser_tool.py customizations - LOST, now aligned with upstream
- All agent/prompt_builder.py customizations - LOST, now aligned with upstream
- package.json changes - LOST, now aligned with upstream

### Preserved (external to repo):
- Hindsight memory integration (~/.hermes/hindsight/, ~/.hermes/config.yaml) - FULLY PRESERVED
- .agents/ directory with local skill customizations - PRESERVED
- All local configuration in ~/.hermes/ - PRESERVED

## Fork-Only Files

These files/directories are Diego's local configuration and should never be committed to upstream:
- `.agents/`
- `config/`
- `skills-lock.json`

## Daily Sync Workflow

### Automated (Cron: `hermes-fork-sync-analyze`)

Runs daily at 4 AM (schedule: `0 4 * * *`):

1. Sync `main` from upstream/main (fast-forward or hard reset)
2. Push main to origin
3. Analyze how many commits custom/main is behind upstream
4. If behind, notify requesting approval for rebase
5. Deliver to Discord: `discord:1474240216217944145` (meta_async-announce)

### Manual Full Sync (both `main` and `custom/main`)

When you want to update the entire fork with latest upstream:

**IMPORTANT**: Always update BOTH branches in this order:
1. First: Update `main` to mirror upstream/main (clean reference)
2. Then: Rebase `custom/main` onto upstream/main (preserve customizations)

```bash
cd /home/diegohb/.hermes/hermes-agent

# ==================================================
# PHASE 1: Update main branch (upstream-clean reference)
# ==================================================

# 1.1 Create main backup (optional, but recommended)
git branch main-backup-$(date +%Y%m%d-%H%M%S)

# 1.2 Checkout main
git checkout main

# 1.3 Fetch upstream
git fetch upstream

# 1.4 Fast-forward main to upstream/main (or hard reset if needed)
git merge --ff-only upstream/main
# OR if that fails:
# git reset --hard upstream/main

# 1.5 Push main to origin
git push origin main

# ==================================================
# PHASE 2: Update custom/main branch (with customizations)
# ==================================================

# 2.1 Create backup
git branch custom/main-backup-$(date +%Y%m%d-%H%M%S)

# 2.2 Create venv freeze snapshot (CRITICAL for rollback)
./venv/bin/pip freeze > ~/venv-freeze-$(date +%Y%m%d-%H%M%S).txt

# 2.3 Checkout custom/main
git checkout custom/main

# 2.4 Verify clean state
git status  # Should show nothing to commit

# 2.5 Check how many commits behind upstream
git log --oneline upstream/main --not custom/main | wc -l

# 2.6 Rebase onto upstream/main
git rebase upstream/main

# 2.7 Resolve conflicts (if any)
# - .gitignore: Merge both - keep upstream additions + your custom entries
# - FORK-MAPPING.md: Keep your version (not in upstream)
# - Core Python files: Prefer upstream unless it removes your specific fix
# - Use `git add <file>` to mark resolved
# - Use `GIT_EDITOR=true git rebase --continue` to proceed

# 2.8 If conflicts are too complex, abort and try cherry-pick approach:
#    git rebase --abort
#    git checkout upstream/main -b custom/main-new
#    git cherry-pick <commit-hash>  # One at a time

# 2.9 Force push to origin
git push --force-with-lease origin custom/main

# ==================================================
# PHASE 3: Update virtual environment (REQUIRED)
# ==================================================

# 3.1 Activate venv
source venv/bin/activate

# 3.2 Upgrade pip
pip install --upgrade pip

# 3.3 Clear stale Python bytecode cache (prevents ImportError after updates)
echo "→ Clearing stale __pycache__ directories..."
find . -type d -name "__pycache__" \
  -not -path "./venv/*" \
  -not -path "./.venv/*" \
  -not -path "./node_modules/*" \
  -not -path "./.git/*" \
  -not -path "./.worktrees/*" \
  -exec rm -rf {} + 2>/dev/null
echo "  ✓ Bytecode cache cleared"

# 3.4 Update Python dependencies
# Prefer uv if available, otherwise use pip
if command -v uv &> /dev/null; then
  echo "→ Using uv for dependency updates..."
  uv pip install --reinstall -e .
else
  echo "→ Using pip for dependency updates..."
  pip install --force-reinstall -e .
fi

# 3.5 Sync bundled skills to ~/.hermes/skills/
echo "→ Syncing bundled skills..."
hermes skills update

# 3.6 Reinstall hermes-agent to ensure editable install is fresh
pip install --force-reinstall -e .

# ==================================================
# PHASE 4: Verify and restart
# ==================================================

# 4.1 Verify installation
hermes --version  # Should show latest version
hermes --help     # Should work without errors

# 4.2 Restart gateway to use updated code
systemctl --user restart hermes-gateway

# 4.3 Monitor startup
journalctl --user -u hermes-gateway -f
```

### Quick Rebase (custom/main only, when main is already up-to-date)

If `main` is already synced with upstream/main (from cron or previous sync):

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Create backup
git branch custom/main-backup-$(date +%Y%m%d-%H%M%S)

# 2. Create venv freeze snapshot
./venv/bin/pip freeze > ~/venv-freeze-$(date +%Y%m%d-%H%M%S).txt

# 3. Checkout custom/main
git checkout custom/main

# 4. Fetch upstream
git fetch upstream

# 5. Rebase onto upstream/main
git rebase upstream/main

# 6. Force push to origin
git push --force-with-lease origin custom/main

# 7. Update venv
source venv/bin/activate

# 7.1 Clear stale Python bytecode cache
echo "→ Clearing stale __pycache__ directories..."
find . -type d -name "__pycache__" \
  -not -path "./venv/*" \
  -not -path "./.venv/*" \
  -not -path "./node_modules/*" \
  -not -path "./.git/*" \
  -not -path "./.worktrees/*" \
  -exec rm -rf {} + 2>/dev/null
echo "  ✓ Bytecode cache cleared"

# 7.2 Update dependencies (prefer uv if available)
if command -v uv &> /dev/null; then
  echo "→ Using uv for dependency updates..."
  uv pip install --reinstall -e .
else
  echo "→ Using pip for dependency updates..."
  pip install --upgrade pip
  pip install --force-reinstall -e .
fi

# 7.3 Sync bundled skills
echo "→ Syncing bundled skills..."
hermes skills update

# 8. Restart gateway
systemctl --user restart hermes-gateway
```

## Gateway Configuration

The Discord gateway runs from custom/main:

```bash
cd /home/diegohb/.hermes/hermes-agent
source venv/bin/activate
python -m hermes_cli.main gateway run --replace
```

**Always restart gateway after updating custom/main to pick up code changes.**

## Virtual Environment

- **venv/** - Python 3.11 (ACTIVE - used by gateway)
- **.venv/** - Python 3.12 (REMOVED - was broken, do not recreate)

**IMPORTANT**: The gateway service MUST use `venv/bin/python`, NOT `.venv/bin/python`.

After updating dependencies in `pyproject.toml` or `requirements.txt`:

```bash
cd /home/diegohb/.hermes/hermes-agent
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -e .  # For editable install
# OR
./venv/bin/pip install -r requirements.txt
```

## Conflict Resolution Strategy

| File Type | Strategy |
|-----------|----------|
| Core Python files | Prefer upstream unless it removes your specific fix |
| .gitignore | Merge both - keep upstream additions + your custom entries |
| FORK-MAPPING.md | Keep your version (not in upstream) |
| Package files (package.json, requirements.txt) | Usually prefer upstream |
| Config files | Manual merge - preserve your settings |
| Documentation | Prefer upstream, re-add custom notes if needed |

## Rollback Procedures

### Rollback Scenario A: Rebase Failed (Git Only)

Use this if the rebase encountered conflicts you couldn't resolve:

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Abort the rebase if still in progress
git rebase --abort

# 2. Reset to backup branch
git reset --hard custom/main-backup-YYYYMMDD-HHMMSS

# 3. Force push to origin to restore state
git push --force-with-lease origin custom/main
```

### Rollback Scenario B: Gateway Won't Start After Update

Use this if the gateway fails to start after a successful rebase (likely a venv dependency issue):

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Check gateway logs for errors
journalctl --user -u hermes-gateway -n 100 --no-pager
tail -50 ~/.hermes/logs/errors.log

# 2. Restore venv from freeze
source venv/bin/activate
pip install --force-reinstall -r ~/venv-freeze-YYYYMMDD-HHMMSS.txt

# 3. If that fails, try a clean reinstall
deactivate
rm -rf venv/
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r ~/venv-freeze-YYYYMMDD-HHMMSS.txt

# 4. Restart gateway
systemctl --user restart hermes-gateway

# 5. Monitor startup
journalctl --user -u hermes-gateway -f
```

### Rollback Scenario C: New Version Breaks Critical Feature

Use this for full rollback (both git code and venv):

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Roll back git to backup branch
git checkout custom/main-backup-YYYYMMDD-HHMMSS
git branch -f custom/main
git checkout custom/main

# 2. Force push to origin
git push --force-with-lease origin custom/main

# 3. Roll back venv
source venv/bin/activate
pip install --force-reinstall -r ~/venv-freeze-YYYYMMDD-HHMMSS.txt

# 4. Restart gateway
systemctl --user restart hermes-gateway

# 5. Verify operation
hermes --version  # Should show old version
journalctl --user -u hermes-gateway -f  # Check for errors
```

### Rollback Scenario D: Both `main` and `custom/main` Need Rollback

Use this if both branches were updated and need to be rolled back together:

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Roll back main branch
git checkout main-backup-YYYYMMDD-HHMMSS
git branch -f main
git checkout main
git push --force-with-lease origin main

# 2. Roll back custom/main branch
git checkout custom/main-backup-YYYYMMDD-HHMMSS
git branch -f custom/main
git checkout custom/main
git push --force-with-lease origin custom/main

# 3. Roll back venv
source venv/bin/activate
pip install --force-reinstall -r ~/venv-freeze-YYYYMMDD-HHMMSS.txt

# 4. Restart gateway
systemctl --user restart hermes-gateway
```

### Cleanup Old Backups (After Successful Sync)

Once you've verified the sync is working correctly, clean up old backups:

```bash
cd /home/diegohb/.hermes/hermes-agent

# List backup branches
git branch | grep backup

# Delete backup branches older than 7 days
git branch -D main-backup-20260402-*
git branch -D custom/main-backup-20260402-*

# List venv freeze files
ls -lh ~/venv-freeze-*.txt

# Delete freeze files older than 7 days
rm ~/venv-freeze-20260402-*.txt
```

## Gateway Troubleshooting

If the gateway service fails to start or platforms don't connect, use the `hermes-gateway-troubleshoot` skill for systematic diagnosis.

### Common Gateway Issues (2026-04-09)

#### Issue 1: Code Mismatch - Invalid `verbosity` Parameter
**Symptoms**: Service exits with `TypeError: start_gateway() got an unexpected keyword argument 'verbosity'`

**Fix**: Edit `hermes_cli/gateway.py` line 1305, remove the `verbosity` parameter:
```python
# BEFORE:
success = asyncio.run(start_gateway(replace=replace, verbosity=verbosity))

# AFTER:
success = asyncio.run(start_gateway(replace=replace))
```

Then reinstall: `./venv/bin/pip install -e .`

#### Issue 2: Wrong Virtual Environment
**Symptoms**: Service fails to start, logs show broken venv (missing pip)

**Fix**: Update systemd service to use `venv/`:
```bash
# Update service file
sed -i 's|/\.venv/|/venv/|g' ~/.config/systemd/user/hermes-gateway.service

# Reload and restart
systemctl --user daemon-reload
systemctl --user restart hermes-gateway
```

#### Issue 3: Missing Platform Dependencies
**Symptoms**: Logs show "discord.py not installed" or "python-telegram-bot not installed"

**Fix**: Install platform dependencies:
```bash
./venv/bin/pip install -r requirements.txt
```

Required: `discord.py>=2.0`, `python-telegram-bot[webhooks]>=22.6`

### Troubleshooting Commands

```bash
# Check service status
systemctl --user status hermes-gateway

# View recent errors
journalctl --user -u hermes-gateway -n 50 --no-pager

# Check gateway logs
tail -50 ~/.hermes/logs/gateway.log
tail -50 ~/.hermes/logs/errors.log

# Test gateway manually
cd ~/.hermes/hermes-agent
./venv/bin/python -m hermes_cli.main gateway run --replace
```

### Platform Connection Behavior

- **Telegram**: Connects immediately on startup
- **Discord**: May timeout on initial connection (30s), but auto-retries up to 20 times over 1-2 minutes
- Check logs for `✓ discord reconnected successfully` to confirm Discord is working

## Common Issues

### "hermes update shows N commits behind" on custom/main
This is expected - custom/main is divergent from main. Ignore or run the rebase workflow above.

### Gateway not using latest code after rebase
Gateway runs from the working directory. You MUST restart the service after code changes:
```bash
systemctl --user restart hermes-gateway
# Or if running manually, stop and restart the process
```

### Lost customizations during rebase
Restore from backup:
```bash
git diff custom/main-backup-YYYYMMDD-HHMMSS custom/main
# Or reset if rebase went badly
git reset --hard custom/main-backup-YYYYMMDD-HHMMSS
```

## Contribution to Upstream

If you want to contribute your customizations upstream:

1. Create a branch from upstream/main:
```bash
git checkout upstream/main -b feat/your-feature
```

2. Cherry-pick or manually copy your changes (remove fork-only files)

3. Test thoroughly

4. Push and create PR:
```bash
git push -u origin feat/your-feature
gh pr create --repo NousResearch/hermes-agent --title "feat: your feature" --body "..."
```

**Never include fork-only customizations in upstream PRs.**

## Pitfalls

### Never Modify Working Directory While Gateway is Running

The gateway has a **stale-code auto-restart feature** that detects when source files on disk are newer than the running process. It checks these sentinel files for modification times:

- `hermes_cli/config.py`
- `hermes_cli/__init__.py`
- `run_agent.py`
- `gateway/run.py`
- `pyproject.toml`

**Problem**: If any git operation (`git checkout`, `git merge`, `git rebase`, `git pull`) modifies the working directory while the gateway is running, the file mtimes change. On the next incoming message, the gateway detects the files are newer than its startup snapshot and triggers an auto-restart with the message:

```
⟳ Gateway code was updated in the background — restarting this gateway so your next message runs on the new code. Please retry in a moment.
```

This is **unauthorized and unexpected** - it conflicts with your controlled upgrade process via FORK-MAPPING.md.

**Root Cause**: The `sync-fork.sh` cron job (runs daily at 4 AM) was doing:
```bash
git checkout main
git merge --ff-only upstream/main
```

This modifies the working directory files, changing their mtimes and triggering gateway auto-restart.

**Solution**: Always use **git worktrees** for background operations that must not affect the running gateway's working directory. The updated `sync-fork.sh` now uses:
```bash
git worktree add /tmp/hermes-fork-sync-main main
git -C /tmp/hermes-fork-sync-main fetch upstream
git -C /tmp/hermes-fork-sync-main merge --ff-only upstream/main
git worktree remove /tmp/hermes-fork-sync-main --force
```

**Rule**: Any script, cron job, or automation that operates on the hermes-agent repo while the gateway is running MUST use worktrees. Never checkout branches or merge in the main working directory.

### Worktree Best Practices

1. **Always cleanup**: Use `trap` to ensure worktrees are removed even if the script exits early:
   ```bash
   cleanup() {
       git worktree remove /tmp/hermes-worktree --force 2>/dev/null || true
   }
   trap cleanup EXIT
   ```

2. **Use a consistent path**: `/tmp/hermes-fork-sync-main` (or similar) ensures you can find/inspect it if debugging is needed.

3. **Run all operations with `git -C`**: This ensures you never accidentally operate on the wrong directory:
   ```bash
   git -C "$WORKTREE_DIR" fetch upstream
   git -C "$WORKTREE_DIR" merge --ff-only upstream/main
   ```

4. **Verify the worktree is on the correct branch**:
   ```bash
   git -C "$WORKTREE_DIR" branch --show-current  # Should print "main"
   ```

## Last Updated

- 2026-05-20: **v0.14.0 UPGRADE COMPLETE**:
  - Synced 2108 upstream commits from v0.12.0 → v0.14.0
  - Preserved 7 custom commits (FORK-MAPPING docs, sync script, v0.12.0 lessons, cron worktree fix)
  - Resolved .gitignore conflict (merged upstream TUI/docs entries + custom Chrome data)
  - Added pytest-timeout plugin to run critical tests
  - Updated dependencies: croniter 6.2.2→6.0.0, cryptography 47.0.0→48.0.0
  - All critical tests passing (163/163)
  - Gateway restarted successfully (Telegram + Discord connected)
- 2026-05-03: **v0.12.0 UPGRADE COMPLETE**:
  - Synced 1362 upstream commits from v0.11.0 → v0.12.0
  - Preserved 5 custom commits (FORK-MAPPING docs, sync script)
  - Resolved .gitignore conflict (merged upstream + custom entries)
  - Updated dependencies: croniter 6.0.0→6.2.2, cryptography 46.0.7→47.0.0
  - All critical tests passing (158/158)
  - Gateway restarted successfully (Telegram + Discord connected)
  - Added Upgrade History section documenting this upgrade
  - Added Lessons Learned section for future upgrades
- 2026-05-02: Enhanced PHASE 3 with steps from `hermes update`:
  - Added bytecode cache clearing (prevents ImportError after updates)
  - Added bundled skills syncing via `hermes skills update`
  - Added uv support for faster dependency installation
  - Added comprehensive error handling for missing pip in venv
- 2026-04-13: Documented venv freeze as required step in sync process
- 2026-04-13: Added comprehensive rollback procedures for all failure scenarios
- 2026-04-13: Clarified that both `main` and `custom/main` must be updated during sync
- 2026-04-09: Fixed venv configuration (Python 3.11 venv/ now active, Python 3.12 .venv/ removed)
- 2026-04-09: Gateway running from: custom/main
- 2026-04-09: Virtual environment: venv/ (Python 3.11.15) - fully operational
- 2026-04-09: Cron job "hermes-fork-sync-analyze" active (runs daily at 4 AM)
- 2026-04-09: Initial documentation after custom/main rebase (640 commits synced)

## Process Comparison: FORK-MAPPING vs `hermes update`

The `hermes update` command is built into the official codebase and works well for upstream-first installations, but it's designed for a different use case. Our FORK-MAPPING process is specifically tailored for maintaining divergent customizations in a fork:

| Feature | FORK-MAPPING Process | `hermes update` |
|---------|---------------------|-----------------|
| **Branch strategy** | Two-branch (main + custom/main) | Single-branch (main only) |
| **Customizations** | Committed on custom/main, preserved via rebase | Only uncommitted changes (auto-stash) |
| **Update method** | Rebase custom/main onto upstream/main | Fast-forward or hard reset main |
| **Gateway runs from** | custom/main | main |
| **Bytecode cache clearing** | ✅ Added (from `hermes update`) | ✅ Built-in |
| **Skill syncing** | ✅ Added (from `hermes update`) | ✅ Built-in |
| **Dependency reinstallation** | ✅ Already present | ✅ Built-in |
| **Gateway restart** | ✅ Already present | ✅ Built-in |
| **Rollback procedures** | ✅ Comprehensive (venv freeze + backup branches) | ❌ Limited (stash only) |
| **Suitable for** | Fork maintainers with divergent customizations | Upstream-first users without custom commits |

### Steps Incorporated from `hermes update`

We've added the following improvements to FORK-MAPPING.md based on `hermes update`:

1. **Bytecode cache clearing**: Removes stale `__pycache__` directories to prevent `ImportError` when updated code references new/changed names
2. **Bundled skills syncing**: Runs `hermes skills update` to sync new/updated bundled skills to `~/.hermes/skills/`
3. **uv support**: Prefers `uv` for faster dependency installation if available, falls back to pip
4. **Comprehensive venv handling**: Includes pip bootstrapping if venv loses pip (from `ensurepip`)

These additions make our process more complete while maintaining the fork-specific workflow we need.
