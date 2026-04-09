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

## Current Customizations

As of 2026-04-09 (FULL REBASE), custom/main is 1:1 with upstream/main except for:

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

### Manual Rebase of custom/main

When you want to update custom/main with latest upstream:

```bash
cd /home/diegohb/.hermes/hermes-agent

# 1. Create backup
git branch custom/main-backup-$(date +%Y%m%d-%H%M%S)

# 2. Checkout custom/main
git checkout custom/main

# 3. Fetch upstream
git fetch upstream

# 4. Rebase onto upstream/main
git rebase upstream/main

# 5. Resolve conflicts (if any)
# - Prefer upstream changes for core functionality
# - Preserve your customizations (STT fix, .gitignore, etc.)
# - Use `git add <file>` to mark resolved
# - Use `GIT_EDITOR=true git rebase --continue` to proceed

# 6. If conflicts are too complex, abort and try cherry-pick approach:
#    git rebase --abort
#    git checkout upstream/main -b custom/main-new
#    git cherry-pick <commit-hash>  # One at a time

# 7. Force push to origin
git push --force-with-lease origin custom/main

# 8. Update venv if pyproject.toml/requirements.txt changed
source venv/bin/activate
pip install --upgrade pip
pip install -e .

# 9. Restart gateway to use updated code
# (Gateway runs from CWD, so just restart the service)
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
| Package files (package.json, requirements.txt) | Usually prefer upstream |
| Config files | Manual merge - preserve your settings |
| Documentation | Prefer upstream, re-add custom notes if needed |

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

## Last Updated

- 2026-04-09: Fixed venv configuration (Python 3.11 venv/ now active, Python 3.12 .venv/ removed)
- 2026-04-09: Gateway running from: custom/main
- 2026-04-09: Virtual environment: venv/ (Python 3.11.15) - fully operational
- 2026-04-09: Cron job "hermes-fork-sync-analyze" active (runs daily at 4 AM)
- 2026-04-09: Initial documentation after custom/main rebase (640 commits synced)
