# Working rules for this project

## Pull requests
Whenever a branch is pushed, always give the owner a ready-to-paste PR description, without being asked.

- Follow `.github/pull_request_template.md`: **What changed**, **How it was tested**, **After merging**.
- Short and in plain words, for a non-developer reviewer. Lead with what the user will notice.
- Bold the key phrase at the start of each bullet.
- Be honest under "How it was tested": say what was not tested (real data, live deploy, database rules).
- Under "After merging", list every manual step (SQL files to run in Supabase, environment variables, live checks), or write "Nothing to do".
- Also give a suggested title and the pre-filled compare link: https://github.com/mbutbutbut/workpaper/compare/main...BRANCH
- Claude cannot create the PR itself (the browser pane is not signed in to GitHub); the owner opens it, reviews and merges.
- Use the `pr-description` skill (`.claude/skills/pr-description/`) to do this; it has the full steps.

## Before every commit
- Run the design checker (`impeccable detect --json index.html`); it must return `[]`.
- Run `node scripts/check.js` and `node tests/team.test.js` when they exist on the branch.
- If a `supabase/*.sql` file changed, run it and `supabase/role-check.sql` in the Supabase SQL editor (with the owner's go-ahead) before merging.

## Never
- Send anything to Jeff or the bookkeeper (the owner is still testing).
- Type passwords, secret keys or tokens into any field; the owner does that.
