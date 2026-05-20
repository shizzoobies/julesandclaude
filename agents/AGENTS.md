# AGENTS.md

Shared rules for all AI coding agents working in this repository (Claude Code, Google Jules, and any future agents).

## Identity

This repo is part of the Kanda Designers ecosystem (Alex Anderson + Kristina). Treat all code as production-grade client work unless explicitly marked otherwise.

## Locked Style Rules

These are non-negotiable. Violating them is a build failure.

1. **No em dashes anywhere.** Not in code comments, not in docs, not in commit messages, not in PR descriptions, not in user-facing copy. Use commas, periods, parentheses, or rewrite the sentence.
2. **No en dashes in prose.** Hyphens only.
3. **Plain ASCII quotes in code.** Smart quotes are only allowed in rendered HTML or markdown content, never in source.

## Code Style

- Match the existing patterns in the file you are editing. Do not introduce new conventions without an issue discussing it.
- For HTML, CSS, and JS: no build step unless the repo already has one. Vanilla is the default.
- For React: functional components, hooks, no class components.
- Run the repo's existing lint and format before committing. If there is no config, do not add one.

## Brand Tokens (when applicable)

If the repo references the U-Haul EDGE program, use the EDGE palette already defined in the repo's CSS. Do not invent new colors.

If the repo is a Kanda Designers client site, use the brand tokens in `tokens.css` or the equivalent. Ask before introducing new design tokens.

## Commit and PR Conventions

- Commits: imperative mood, present tense. "Add login route" not "Added login route."
- PR title: short summary, no prefix tags.
- PR body: include a "What changed" section and a "How to verify" section. No marketing language.

## What to Never Do

- Never edit files matching: `.env*`, `secrets/**`, `*.key`, `*.pem`, `credentials.json`.
- Never commit API keys, tokens, or credentials. If you encounter one in the codebase, stop and flag it in the PR description.
- Never run destructive git operations (`force push`, `reset --hard` to a remote ref) without an explicit instruction in the issue body.
- Never modify CI or CD config (`.github/workflows/`, `wrangler.toml` deployment sections, `vercel.json`) without an explicit instruction.

## When You Are Stuck

- If the issue body is ambiguous: do not guess. Open the PR as a draft with a comment listing the ambiguities and add the `jules:blocked` label.
- If a test fails and you do not understand why: do not disable the test. Flag it and add `jules:blocked`.
- If your change touches more than 10 files and was not explicitly scoped to a refactor: stop, comment on the issue, and wait for confirmation.

## For Claude Code Specifically

You are the orchestrator. When you finish work on a feature with Alex, scan for follow-up tasks that match the "dispatch to Jules" criteria in `CLAUDE_CODE_HANDOFF.md` and file them via `jules-dispatch.ps1`.

## For Jules Specifically

Read this file in full before planning any task. Your plan must reference which rules from this file apply. If your plan would violate any rule, stop and add `jules:blocked`.
