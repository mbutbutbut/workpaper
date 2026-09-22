---
name: pr-description
description: Create the GitHub pull request for the current branch, with a title and description written in the project's template and voice, using the gh CLI. Falls back to a paste-ready description if gh isn't authenticated. Use when the user asks to write, draft or help with a PR, or after pushing a branch.
---

# PR description

Writes the title and body for a pull request from `main` into the current branch, in the project's own template and voice, and opens the PR directly with `gh pr create`. The owner reviews and merges it; this skill does not merge.

## When to run this

- Right after pushing a branch (do this automatically, without being asked — see `CLAUDE.md`).
- The user asks to write, draft, or help with a PR.
- The user says a PR is missing a title and description, or asks to create one.

## Steps

1. Confirm `gh` is authenticated: `gh auth status`. If it fails, skip to **Fallback** below and say why.

2. Find the branch and its base.
   ```
   git rev-parse --abbrev-ref HEAD
   git merge-base main HEAD
   ```
   If the branch is not `main` and has commits ahead of `main`, continue. If it's already merged, has no diff, or already has an open PR (`gh pr view` for that branch), say so instead of creating another.

3. Gather what actually changed.
   ```
   git log main..HEAD --oneline
   git diff main...HEAD --stat
   ```
   Read the diff itself for anything not obvious from file names (new UI text, a changed default, a new SQL file). Do not guess at intent from file names alone.

4. Check whether anything needs a manual step after merging:
   - A new or changed file under `supabase/` → running it (and `role-check.sql`) in the Supabase SQL editor.
   - A new environment variable → setting it in Vercel.
   - A UI change with no way to verify from a diff → loading the live site once.
   - None of these → say "Nothing to do."

5. Write the title: a short, plain sentence describing the change from the owner's point of view, not the file names touched.

6. Write the body using the project's template, `.github/pull_request_template.md` — three headings, in this order: **What changed**, **How it was tested**, **After merging**. Follow `CLAUDE.md`'s rules for these:
   - **What changed:** 3 to 6 short bullets, plain words, each bolding the key phrase at the start. Say what the owner will notice, not which functions moved.
   - **How it was tested:** what was actually run or checked in this session (design checker, `node scripts/check.js`, `node tests/team.test.js`, a prototype-mode browser check, etc). State plainly what was **not** tested — the live database, the live deploy, a phone screen, another role's view. Never imply something was tested when it wasn't.
   - **After merging:** every manual step from step 4, or "Nothing to do."
   - End the body with the standard PR attribution line from the system reminder.

7. Create the PR:
   ```
   gh pr create --repo mbutbutbut/workpaper --base main --head <branch> --title "<title>" --body "<body>"
   ```
   Give the owner the URL it prints. If several branches are stacked (each built on the last, not yet merged), create each one's PR against `main` in the same way, in merge order, and list all the URLs.

## Fallback (gh not authenticated)

Do steps 2–6 the same way, but instead of step 7, output the title and body as one block the owner can copy, followed by the compare link `https://github.com/mbutbutbut/workpaper/compare/main...<branch>`, and say that `gh` isn't connected so they'll need to paste it in themselves.

## What this skill does not do

- It does not merge the PR. The owner reviews and merges it themselves.
- It does not invent testing that did not happen, or a manual step that isn't real.
