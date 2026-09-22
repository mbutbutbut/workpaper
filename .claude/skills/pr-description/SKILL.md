---
name: pr-description
description: Write a ready-to-paste GitHub PR title and description for the current branch, following .github/pull_request_template.md and the PR rules in CLAUDE.md. Use when the user asks to write, draft or help with a PR description, or after pushing a branch.
---

# PR description

Writes the title and body for a pull request from `main` into the current branch, in the project's own template and voice. The owner (a non-developer) pastes this into GitHub themselves; this skill never opens or creates the PR.

## When to run this

- The user asks to write, draft, or help with a PR description.
- Right after pushing a branch (do this automatically, without being asked — see `CLAUDE.md`).
- The user says a PR "doesn't have a title and description" or similar.

## Steps

1. Find the branch and its base.
   ```
   git rev-parse --abbrev-ref HEAD
   git merge-base main HEAD
   ```
   If the branch is not `main` and has commits ahead of `main`, continue. If it's already merged or has no diff, say so instead of drafting.

2. Gather what actually changed.
   ```
   git log main..HEAD --oneline
   git diff main...HEAD --stat
   ```
   Read the diff itself for anything not obvious from file names (new UI text, a changed default, a new SQL file). Do not guess at intent from file names alone.

3. Check whether anything needs a manual step after merging:
   - A new or changed file under `supabase/` → running it (and `role-check.sql`) in the Supabase SQL editor.
   - A new environment variable → setting it in Vercel.
   - A UI change with no way to verify from a diff → loading the live site once.
   - None of these → say "Nothing to do."

4. Write the title: a short, plain sentence describing the change from the owner's point of view, not the file names touched.

5. Write the body using the project's template, `.github/pull_request_template.md` — three headings, in this order: **What changed**, **How it was tested**, **After merging**. Follow `CLAUDE.md`'s rules for these:
   - **What changed:** 3 to 6 short bullets, plain words, each bolding the key phrase at the start. Say what the owner will notice, not which functions moved.
   - **How it was tested:** what was actually run or checked in this session (design checker, `node scripts/check.js`, `node tests/team.test.js`, a prototype-mode browser check, etc). State plainly what was **not** tested — the live database, the live deploy, a phone screen, another role's view. Never imply something was tested when it wasn't.
   - **After merging:** every manual step from step 3, or "Nothing to do."

6. Output the title and body as one block, in a fenced section the user can copy, followed by the compare link:
   ```
   https://github.com/mbutbutbut/workpaper/compare/main...<branch>
   ```
   If several branches are stacked (each built on the last, not yet merged), list them in merge order and give each its own title, body and compare link — do not merge them into one description.

## What this skill does not do

- It does not open, create, or merge the PR. GitHub has no API access from here (see `CLAUDE.md`); the owner opens the link, pastes the text, and merges it themselves.
- It does not invent testing that did not happen, or a manual step that isn't real.
