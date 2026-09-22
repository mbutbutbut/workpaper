-- Real first and last names for each person, so the app can show "Jeff" instead of "Team".
-- Run once in the Supabase SQL editor, after schema.sql. Safe to run again.

alter table members add column if not exists first_name text not null default '';
alter table members add column if not exists last_name text not null default '';

-- Everyone signed in may see everyone's name and role (there is nothing sensitive in this table
-- beyond who has which role, and the app needs every role to show the right name to the others).
-- This replaces the old "only your own row" policy, which was only ever used for that one lookup.
drop policy if exists members_self on members;
drop policy if exists members_read on members;
create policy members_read on members for select to authenticated using (true);

notify pgrst, 'reload schema';
