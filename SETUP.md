# Going live: Workpaper on Vercel + Supabase

You need two free accounts: Supabase (sign-in and data) and Vercel (hosting).
Nothing here stores documents; those stay in Hubdoc.

## 1. Create the database (about 10 minutes)

1. Sign in at supabase.com and create a new project. Pick a region near you and save the database password somewhere safe.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, and run it. It creates the tables and the rules for who can see and change what.
3. Open **Project Settings > API** and copy the **Project URL** and the **anon public key**.
4. Paste both into `config.js`. These two values are safe to publish; the rules from step 2 protect the data.

## 2. Set up sign-in

People sign in with their email and a password, so no email service is needed.

1. **Authentication > Sign In / Providers**: keep Email enabled. Turn **off** "Allow new users to sign up" (only people you add can sign in). In the Email settings, set the minimum password length to 10.
2. **Authentication > URL Configuration**: set Site URL to your Vercel address, and add `<your address>/**` under Redirect URLs.
3. **Authentication > Users > Add user > Create new user**: add yourself, Jeff, and the bookkeeper. Type each person's email and a first password, and tick **Auto Confirm User**. Do not use "Send invitation".
4. Give each person their first password directly. They can change it themselves inside the app (Account, top right).

**If someone forgets their password**, reset it in the SQL editor (then tell them the new one):

```sql
update auth.users set encrypted_password = crypt('NewPassword123', gen_salt('bf')) where email = 'person@example.com';
```

## 3. Give each person a role

In **SQL Editor**, run this once per person, using their email and one of `client`, `jeff` or `bookkeeper`:

```sql
insert into members (user_id, role)
select id, 'client' from auth.users where email = 'you@example.com';
```

Someone with no row in `members` is signed out with a "not set up" message, even if they have an account.

## 4. Put it on Vercel

Deploy this folder as a static site (no build step). `.vercelignore` keeps the design notes out of the upload. Then set the Supabase Site URL (step 2.2) to the Vercel address.

## 4b. Turn on the Team screen (managing people inside the app)

Admins can add, edit and remove people from the app (top right: **Team**). This runs a small function on Vercel (`api/team.js`) that holds Supabase's secret key, so the key never reaches anyone's browser.

1. In Supabase, open **Project Settings > API Keys** and copy the **secret key** (starts with `sb_secret_`). Keep it private.
2. In Vercel, open your project, then **Settings > Environment Variables**, and add two variables (mark both **Sensitive**):
   - `SUPABASE_URL` set to your project URL (the same value as `supabaseUrl` in `config.js`)
   - `SUPABASE_SECRET_KEY` set to the secret key
3. **Redeploy** (Deployments > the latest one > Redeploy), because new variables only apply to new deployments.

Roles are shown as **Admin**, **Bookkeeper** and **Team member** (the database names are `client`, `bookkeeper` and `jeff`). Only an admin can use the Team screen, and the function checks that on every request. You cannot remove or change yourself, and there must always be one admin.

## 4c. Turn on review and conversations

Run `supabase/review.sql` once in the SQL editor (after `schema.sql`). It adds the review marks, the conversation table, and two database actions (`accept_item`, `reopen_item`) that only the bookkeeper can use. Then run the role check below; it now tests these too.

### 4d. Edit, remove and delete

Run `supabase/messages.sql` once (after `review.sql`). It lets people edit or remove their own messages (removed ones keep a "Message removed" placeholder) and lets the admin delete transactions; deleting a transaction also deletes its conversation.

### 4e. Real names

Run `supabase/member-names.sql` once (after `schema.sql`; any time relative to the others). It adds a first and last name to each person, and lets everyone signed in see everyone's name and role, so the app can show "Jeff" or whoever holds that role today instead of the generic word "Team". Add names for existing people in the Team screen ("Edit name"); new people get a name when you add them.

### 4f. More than one team member

Run `supabase/per-person-assignment.sql` once (after `schema.sql` and `member-names.sql`). Until now, "With team" was one pooled inbox: every team-role account saw everything the role had ever been given. This records who specifically an item is assigned to, so each team member gets their own separate list. It backfills existing items to whichever team member already exists; if you add a second one, reassign items to them from the Owner column.

## 5. Check the rules

Paste `supabase/role-check.sql` into the SQL editor and run it (after `review.sql`, `messages.sql`, `member-names.sql` and `per-person-assignment.sql`). It acts as each person in turn, using the same database rules the app uses, then shows a PASS/FAIL table. Every row must say PASS, and it deletes its own test data.

Then confirm in the real app, signed in as each person:
- The team member sees only their own items and can change only status and note.
- The bookkeeper sees everything and can change nothing.
- You can import, reassign and edit.

## Locally

Leave `config.js` empty to run the prototype with sample data in your browser. To test with the real database, fill it in and serve the folder: `python3 -m http.server 8000`.

## 7. Let Claude read the checklist (optional, read-only)

`mcp/server.js` is a small MCP server with no dependencies. It signs in as a Workpaper user and can only read: `list_requests`, `list_items`, `summary`, `get_conversation`. The database rules decide what it sees, so use an Admin login to see everything.

Add it to your MCP client (for example Claude Desktop's config) with your own values, typed by you and never stored in the repo:

```json
{
  "mcpServers": {
    "workpaper": {
      "command": "node",
      "args": ["/full/path/to/this/folder/mcp/server.js"],
      "env": {
        "WORKPAPER_SUPABASE_URL": "https://YOUR-PROJECT.supabase.co",
        "WORKPAPER_SUPABASE_KEY": "your publishable key (same as config.js)",
        "WORKPAPER_EMAIL": "your admin email",
        "WORKPAPER_PASSWORD": "your admin password"
      }
    }
  }
}
```

Restart the client, then ask: "What's still open for Jeff?"

## 8. Automatic checks on pull requests

`.github/workflows/checks.yml` runs on every pull request: it checks that the app's scripts parse, that no secret keys are in the repo, and that the 24 Team-function tests pass. You can run the same checks yourself with `node scripts/check.js` and `node tests/team.test.js`.

To make them required: in GitHub, open Settings → Rules → Rulesets → New branch ruleset, target `main`, turn on "Require a pull request before merging" and "Require status checks to pass", and add the check named `checks`.

The checks cannot test the database rules. If a PR changes anything in `supabase/`, run that file and `role-check.sql` in the SQL editor before merging.
