-- Role check: proves the row rules do what SETUP.md says.
--
-- Run this once in the Supabase SQL editor AFTER schema.sql and after you have added
-- one member of each role (client, jeff, bookkeeper) to the `members` table.
--
-- It makes a temporary request with two items, acts as each person in turn using the
-- same database rules the app uses, records what each person can and cannot do, deletes
-- its test data, and shows a PASS/FAIL table as the last result. Nothing else is touched.
-- If it stops halfway, run it again: the first line clears any leftover test data.

delete from requests where name like 'ROLE CHECK%';
drop table if exists results;
create temp table results (check_name text, expected text, actual text);
grant all on results to authenticated, anon;

insert into requests (id, name) values ('00000000-0000-0000-0000-0000000000a1', 'ROLE CHECK (temporary)');
insert into items (request_id, no, description, owner, status, fingerprint) values
  ('00000000-0000-0000-0000-0000000000a1', 1, 'Client item', 'me',   'waiting', 'rolecheck-1'),
  ('00000000-0000-0000-0000-0000000000a1', 2, 'Jeff item',   'jeff', 'jeff',    'rolecheck-2');

-- ---------- CLIENT: full access ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'client' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'client' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'client sees both items', '2', count(*)::text from items where request_id = '00000000-0000-0000-0000-0000000000a1';
do $$ declare n int; begin
  update items set description = 'edited by client' where fingerprint = 'rolecheck-1';
  get diagnostics n = row_count;
  insert into results values ('client can edit any field', '1', n::text);
end $$;
reset role;

-- ---------- JEFF: only his items; only status and note ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'jeff' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'jeff' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'jeff sees only his item', '1', count(*)::text from items where request_id = '00000000-0000-0000-0000-0000000000a1';
do $$ declare n int; begin
  update items set status = 'hubdoc', note = 'uploaded' where fingerprint = 'rolecheck-2';
  get diagnostics n = row_count;
  insert into results values ('jeff can change status and note on his item', '1', n::text);
end $$;
do $$ declare n int; begin
  update items set note = 'not mine' where fingerprint = 'rolecheck-1';
  get diagnostics n = row_count;
  insert into results values ('jeff cannot touch the client''s item', '0', n::text);
end $$;
do $$ begin
  update items set description = 'sneaky edit' where fingerprint = 'rolecheck-2';
  insert into results values ('jeff cannot change the description', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot change the description', 'blocked', 'blocked');
end $$;
do $$ begin
  update items set owner = 'me' where fingerprint = 'rolecheck-2';
  insert into results values ('jeff cannot hand an item back', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot hand an item back', 'blocked', 'blocked');
end $$;
do $$ begin
  update items set status = 'waiting' where fingerprint = 'rolecheck-2';
  insert into results values ('jeff cannot set Waiting', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot set Waiting', 'blocked', 'blocked');
end $$;
do $$ begin
  insert into items (request_id, no, description, fingerprint) values ('00000000-0000-0000-0000-0000000000a1', 9, 'jeff made this', 'rolecheck-9');
  insert into results values ('jeff cannot add items', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot add items', 'blocked', 'blocked');
end $$;
do $$ begin
  insert into requests (name) values ('jeff made this request');
  insert into results values ('jeff cannot create requests', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot create requests', 'blocked', 'blocked');
end $$;
reset role;

-- ---------- BOOKKEEPER: reads everything, changes nothing ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'bookkeeper' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'bookkeeper' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'bookkeeper sees both items', '2', count(*)::text from items where request_id = '00000000-0000-0000-0000-0000000000a1';
do $$ declare n int; begin
  update items set note = 'bookkeeper edit' where fingerprint = 'rolecheck-1';
  get diagnostics n = row_count;
  insert into results values ('bookkeeper cannot edit items', '0', n::text);
end $$;
do $$ declare n int; begin
  delete from items where fingerprint = 'rolecheck-1';
  get diagnostics n = row_count;
  insert into results values ('bookkeeper cannot delete items', '0', n::text);
end $$;
do $$ begin
  insert into items (request_id, no, description, fingerprint) values ('00000000-0000-0000-0000-0000000000a1', 8, 'bookkeeper made this', 'rolecheck-8');
  insert into results values ('bookkeeper cannot add items', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('bookkeeper cannot add items', 'blocked', 'blocked');
end $$;
reset role;

-- ---------- NOT SIGNED IN: nothing ----------
select set_config('request.jwt.claim.sub', '', false), set_config('request.jwt.claims', '', false);
set role anon;
do $$ declare n int; begin
  select count(*) into n from items;
  insert into results values ('a visitor who is not signed in sees no items', '0', n::text);
exception when others then
  insert into results values ('a visitor who is not signed in sees no items', '0', '0');
end $$;
reset role;

-- ---------- clean up, then show the answer ----------
delete from requests where id = '00000000-0000-0000-0000-0000000000a1';
select check_name,
       expected,
       actual,
       case when expected = actual then 'PASS' else 'FAIL' end as result
from results
order by ctid;
