# julesandclaude

Central tracking and dispatch for AI agent work across Kanda Designers repos.

## What this repo is

A coordination layer between Claude Code (interactive, terminal) and Google Jules (async, cloud). Claude Code dispatches background tasks to Jules and logs them here so Alex has one place to see what is running.

## Files

- `STATUS.md` -- live dispatch log, auto-updated by `jules-dispatch.ps1`
- `agents/AGENTS.md` -- master copy of the shared rules, mirrored into each Kanda repo
- `runbooks/onboard-repo.ps1` -- onboard a new repo into the orchestration system
- `runbooks/sync-agents-md.ps1` -- push the master AGENTS.md to every connected repo
- `runbooks/connected-repos.txt` -- list of repos under orchestration (Phase 1 live, Phase 2 commented)
- `.jules/config.template.yml` -- template per-repo Jules config (rendered by onboard-repo.ps1)
- `labels.json` -- the 7 GitHub labels used by the orchestration system
- `jules-dispatch.ps1` -- the dispatch script (PowerShell port of jules-dispatch.sh)
- `setup.ps1` -- one-time machine setup (sets env var, adds dispatch to PATH)
- `NEXT_SESSION.md` -- Phase 1 rollout checklist for the next Claude Code session

## How to use

### First-time setup (one-time per machine)

```powershell
cd D:\Jules\julesandclaude
.\setup.ps1
# Open a fresh PowerShell session so PATH picks up jules-dispatch.ps1
```

### Check active work

```powershell
Get-Content STATUS.md
# or
gh issue list --search "label:jules:in-progress" --limit 50
```

### Update shared rules

1. Edit `agents/AGENTS.md`
2. Commit and push
3. Run `runbooks/sync-agents-md.ps1` to mirror it into every connected repo

### Add a new repo to the system

1. Add the `owner/repo` line to `runbooks/connected-repos.txt`
2. Run `runbooks/onboard-repo.ps1 -RepoName <owner/repo>`
3. Connect the repo at https://jules.google.com/ (trigger: `jules:ready` label, branch prefix `jules/`)

### Dispatch a task to Jules

The dispatch script wraps `jules new --repo <owner/repo> "<prompt>"` under the hood. Note that the target repo must already be connected at https://jules.google.com/.

```powershell
jules-dispatch.ps1 `
  -Repo shizzoobies/kandadesigners.com `
  -Task "Update README with current tech stack" `
  -Dod "Refresh the README to reflect Cloudflare Pages and GitHub Actions stack. Keep it brief, no em dashes."
```

The script files the task, caps active Jules tasks at 5 per repo, and appends an entry to `STATUS.md`.

## Architecture

```
Alex <-> Claude Code (orchestrator + live dev)
              |
              | dispatches via GitHub issues w/ jules:ready label
              v
         Jules (async worker in Google Cloud VM)
              |
              | opens PR back to repo
              v
         Alex reviews + merges
```

Division of labor lives in `agents/AGENTS.md` and in the original handoff package at `D:\Jules\handoff\kanda-jules-handoff\CLAUDE_CODE_HANDOFF.md`.
