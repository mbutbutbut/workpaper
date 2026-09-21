# Going live: Workpaper on Vercel + Supabase

You need two free accounts: Supabase (sign-in and data) and Vercel (hosting).
Nothing here stores documents; those stay in Hubdoc.

## 1. Create the database (about 10 minutes)

1. Sign in at supabase.com and create a new project. Pick a region near you and save the database password somewhere safe.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, and run it. It creates the tables and the rules for who can see and change what.
3. Open **Project Settings > API** and copy the **Project URL** and the **anon public key**.
4. Paste both into `config.js`. These two values are safe to publish; the rules from step 2 protect the data.

## 2. Set up sign-in

1. **Authentication > Providers > Email**: keep Email enabled. Turn **off** "Allow new users to sign up" (only people you add can sign in).
2. **Authentication > URL Configuration**: set Site URL to your Vercel address once you have it (step 4). While testing, `http://localhost:8000` works.
3. **Authentication > Users > Add user > Send invitation** (or "Create new user"): add yourself, Jeff, and the bookkeeper by email.

## 3. Give each person a role

In **SQL Editor**, run this once per person, using their email and one of `client`, `jeff` or `bookkeeper`:

```sql
insert into members (user_id, role)
select id, 'client' from auth.users where email = 'you@example.com';
```

Someone with no row in `members` is signed out with a "not set up" message, even if they have an account.

## 4. Put it on Vercel

Deploy this folder as a static site (no build step). `.vercelignore` keeps the design notes out of the upload. Then set the Supabase Site URL (step 2.2) to the Vercel address.

## 5. Check the rules

Paste `supabase/role-check.sql` into the SQL editor and run it. It acts as each person in turn, using the same database rules the app uses, then shows a PASS/FAIL table. Every row must say PASS, and it deletes its own test data.

Then confirm in the real app, signed in as each person:
- Jeff sees only his items and can change only status and note.
- The bookkeeper sees everything and can change nothing.
- You can import, reassign and edit.

## Locally

Leave `config.js` empty to run the prototype with sample data in your browser. To test with the real database, fill it in and serve the folder: `python3 -m http.server 8000`.
