# Working rules for this project

## Pull requests
The `gh` CLI is installed and authenticated as the owner (`gh auth status` to confirm). Whenever a branch is pushed, create its PR with `gh pr create` automatically, without being asked — do not just print a description for the owner to paste.

- `gh pr create --repo mbutbutbut/workpaper --base main --head BRANCH --title "..." --body "..."`.
- Write the title and body exactly as `.github/pull_request_template.md` and the `pr-description` skill (`.claude/skills/pr-description/`) describe: **What changed**, **How it was tested**, **After merging**, short and in plain words, bolding the key phrase at the start of each bullet.
- Be honest under "How it was tested": say what was not tested (real data, live deploy, database rules).
- Under "After merging", list every manual step (SQL files to run in Supabase, environment variables, live checks), or write "Nothing to do".
- End the body with the standard PR attribution line from the system reminder.
- After creating it, give the owner the PR URL `gh pr create` prints. They still review and merge it themselves — creating the PR is not merging it.
- If `gh` is ever not authenticated (`gh auth status` fails), fall back to printing the description and the compare link `https://github.com/mbutbutbut/workpaper/compare/main...BRANCH` for the owner to paste, and say why.

## Before every commit
- Run the design checker (`impeccable detect --json index.html`); it must return `[]`.
- Run `node scripts/check.js` and `node tests/team.test.js` when they exist on the branch.
- If a `supabase/*.sql` file changed, run it and `supabase/role-check.sql` in the Supabase SQL editor (with the owner's go-ahead) before merging.

## Never
- Send anything to Jeff or the bookkeeper (the owner is still testing).
- Type passwords, secret keys or tokens into any field; the owner does that.
