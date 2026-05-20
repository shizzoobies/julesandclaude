# Phase 1 Rollout Checklist

The orchestration repo is built and pushed. Next session: roll out the Jules scaffold to the Phase 1 client repos.

## Before starting

Confirm the exact GitHub repo names for the Phase 1 targets. Placeholders used throughout this repo:

- Kanda Designers main site: `shizzoobies/kandadesigners.com`
- Daily prompt generator app: `shizzoobies/daily-prompt-generator`

If either differs, update `runbooks/connected-repos.txt` and `STATUS.md` first.

## Steps

For each Phase 1 repo:

1. From `D:\Jules\julesandclaude`, run:
   ```powershell
   .\runbooks\onboard-repo.ps1 -RepoName shizzoobies/kandadesigners.com
   .\runbooks\onboard-repo.ps1 -RepoName shizzoobies/daily-prompt-generator
   ```
   Each invocation will:
   - Clone the repo to `D:\Jules\<repo-name-only>` if not already present
   - Copy `agents/AGENTS.md` into the repo root
   - Render `.jules/config.yml` from the template
   - Create the 7 GitHub labels from `labels.json`
   - Commit and push the scaffold

2. Open https://jules.google.com/, sign in with Alex's Google account, and for each connected repo set:
   - Trigger: issues labeled `jules:ready`
   - Branch prefix: `jules/`
   - Default reviewer: `shizzoobies`

3. Smoke test the loop. From the orchestration repo dir:
   ```powershell
   jules-dispatch.ps1 `
     -Repo shizzoobies/kandadesigners.com `
     -Title "Refresh README with current tech stack" `
     -Body "Update the README to reflect Cloudflare Pages and GitHub Actions. Keep it brief."
   ```

4. Verify:
   - Issue is created with `jules:ready` label
   - Within ~5 min, Jules picks it up and the label flips to `jules:in-progress`
   - A PR opens on a `jules/` branch
   - `STATUS.md` in this repo has an entry under `## Active Dispatches`

## After Phase 1 is verified

Do not start Phase 2 without explicit confirmation. Targets when greenlit:

- `shizzoobies/pbjsa.com`
- `shizzoobies/mbsdoc.com`
- `shizzoobies/computersolutionskeystone.com`

Other follow-ups noted in the original handoff:

- Webhook listener for Jules PR status posted to Alex's preferred channel
- Auto-generated weekly audio changelogs per client repo
