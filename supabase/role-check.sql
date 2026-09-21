-- Role check: proves the row rules do what SETUP.md says, including review and conversations.
--
-- Run this in the Supabase SQL editor AFTER schema.sql and review.sql, and after you have
-- added one member of each role (client, jeff, bookkeeper) to the `members` table.
--
-- It makes a temporary request with three items and a few messages, acts as each person in
-- turn using the same database rules the app uses, records what each person can and cannot
-- do, deletes its test data, and shows a PASS/FAIL table as the last result. Nothing else is
-- touched. If it stops halfway, run it again: the first lines clear any leftover test data.

delete from comments where fingerprint like 'rolecheck-%';
delete from requests where name like 'ROLE CHECK%';
drop table if exists results;
create temp table results (check_name text, expected text, actual text);
grant all on results to authenticated, anon;

insert into requests (id, name) values ('00000000-0000-0000-0000-0000000000a1', 'ROLE CHECK (temporary)');
insert into items (request_id, no, description, owner, status, fingerprint) values
  ('00000000-0000-0000-0000-0000000000a1', 1, 'Client item',   'me',   'waiting', 'rolecheck-1'),
  ('00000000-0000-0000-0000-0000000000a1', 2, 'Jeff item',     'jeff', 'jeff',    'rolecheck-2'),
  ('00000000-0000-0000-0000-0000000000a1', 3, 'Resolved item', 'me',   'hubdoc',  'rolecheck-3');
insert into comments (fingerprint, role, kind, body) values
  ('rolecheck-1', 'client', 'message', 'thread on the client item'),
  ('rolecheck-2', 'client', 'message', 'thread on the Jeff item');

-- ---------- CLIENT: full access ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'client' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'client' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'client sees all three items', '3', count(*)::text from items where request_id = '00000000-0000-0000-0000-0000000000a1';
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
  update items set reviewed = true where fingerprint = 'rolecheck-2';
  insert into results values ('jeff cannot mark an item reviewed', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot mark an item reviewed', 'blocked', 'blocked');
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
-- conversations, as Jeff
insert into results select 'jeff sees the thread on his item only', '1', count(*)::text from comments where fingerprint in ('rolecheck-1', 'rolecheck-2');
do $$ begin
  insert into comments (fingerprint, author_id, role, body) values ('rolecheck-2', auth.uid(), 'jeff', 'Uploaded to Hubdoc');
  insert into results values ('jeff can message on his item', 'allowed', 'allowed');
exception when others then
  insert into results values ('jeff can message on his item', 'allowed', 'BLOCKED');
end $$;
do $$ begin
  insert into comments (fingerprint, author_id, role, body) values ('rolecheck-1', auth.uid(), 'jeff', 'reading the client item');
  insert into results values ('jeff cannot message on an item that is not his', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot message on an item that is not his', 'blocked', 'blocked');
end $$;
do $$ begin
  perform accept_item((select id from items where fingerprint = 'rolecheck-2'));
  insert into results values ('jeff cannot accept an item', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot accept an item', 'blocked', 'blocked');
end $$;
do $$ begin
  perform reopen_item((select id from items where fingerprint = 'rolecheck-2'), 'nope');
  insert into results values ('jeff cannot send an item back', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('jeff cannot send an item back', 'blocked', 'blocked');
end $$;
do $$ declare n int; begin
  update comments set body = 'changed by jeff' where fingerprint = 'rolecheck-2' and role = 'client';
  get diagnostics n = row_count;
  insert into results values ('jeff cannot edit someone else''s message', '0', n::text);
end $$;
do $$ declare n int; begin
  delete from items where fingerprint = 'rolecheck-2';
  get diagnostics n = row_count;
  insert into results values ('jeff cannot delete items', '0', n::text);
end $$;
reset role;

-- ---------- BOOKKEEPER: reads everything; reviews; changes nothing else ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'bookkeeper' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'bookkeeper' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'bookkeeper sees all three items', '3', count(*)::text from items where request_id = '00000000-0000-0000-0000-0000000000a1';
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
do $$ declare n int; begin
  update items set reviewed = true where fingerprint = 'rolecheck-3';
  get diagnostics n = row_count;
  insert into results values ('bookkeeper cannot set the review mark directly', '0', n::text);
end $$;
do $$ begin
  perform accept_item((select id from items where fingerprint = 'rolecheck-1'));
  insert into results values ('bookkeeper cannot accept an item that is still open', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('bookkeeper cannot accept an item that is still open', 'blocked', 'blocked');
end $$;
do $$ declare r text; begin
  perform accept_item((select id from items where fingerprint = 'rolecheck-3'));
  select reviewed::text into r from items where fingerprint = 'rolecheck-3';
  insert into results values ('bookkeeper can accept a resolved item', 'true', r);
exception when others then
  insert into results values ('bookkeeper can accept a resolved item', 'true', 'error');
end $$;
do $$ begin
  perform reopen_item((select id from items where fingerprint = 'rolecheck-3'), '   ');
  insert into results values ('sending an item back needs a message', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('sending an item back needs a message', 'blocked', 'blocked');
end $$;
do $$ declare r text; begin
  perform reopen_item((select id from items where fingerprint = 'rolecheck-3'), 'Please attach the invoice, not the receipt');
  select status || '/' || owner || '/' || sent_back::text || '/' || reviewed::text into r from items where fingerprint = 'rolecheck-3';
  insert into results values ('bookkeeper can send an item back to the client', 'waiting/me/true/false', r);
exception when others then
  insert into results values ('bookkeeper can send an item back to the client', 'waiting/me/true/false', 'error');
end $$;
do $$ begin
  perform reopen_item((select id from items where fingerprint = 'rolecheck-3'), 'again');
  insert into results values ('an open item cannot be sent back again', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('an open item cannot be sent back again', 'blocked', 'blocked');
end $$;
insert into results select 'accept and send-back are written into the thread', '2', count(*)::text from comments where fingerprint = 'rolecheck-3';
do $$ begin
  insert into comments (fingerprint, author_id, role, body) values ('rolecheck-3', auth.uid(), 'bookkeeper', 'Thanks');
  insert into results values ('bookkeeper can message', 'allowed', 'allowed');
exception when others then
  insert into results values ('bookkeeper can message', 'allowed', 'BLOCKED');
end $$;
do $$ begin
  insert into comments (fingerprint, author_id, role, kind, body) values ('rolecheck-3', auth.uid(), 'bookkeeper', 'reopen', 'forged');
  insert into results values ('a message cannot pretend to be a send-back', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('a message cannot pretend to be a send-back', 'blocked', 'blocked');
end $$;
do $$ begin
  insert into comments (fingerprint, author_id, role, body) values ('rolecheck-3', gen_random_uuid(), 'bookkeeper', 'as someone else');
  insert into results values ('nobody can message as someone else', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('nobody can message as someone else', 'blocked', 'blocked');
end $$;
reset role;

-- ---------- CLIENT again: answering a send-back, and the review marks ----------
select set_config('request.jwt.claim.sub', (select user_id::text from members where role = 'client' limit 1), false),
       set_config('request.jwt.claims', json_build_object('sub', (select user_id from members where role = 'client' limit 1), 'role', 'authenticated')::text, false);
set role authenticated;
insert into results select 'the client sees every message on an item', '3', count(*)::text from comments where fingerprint = 'rolecheck-3';
do $$ begin
  update items set reviewed = true where fingerprint = 'rolecheck-1';
  insert into results values ('the client cannot mark an item reviewed', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('the client cannot mark an item reviewed', 'blocked', 'blocked');
end $$;
do $$ begin
  perform accept_item((select id from items where fingerprint = 'rolecheck-3'));
  insert into results values ('the client cannot accept an item', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('the client cannot accept an item', 'blocked', 'blocked');
end $$;
do $$ declare r text; begin
  update items set status = 'hubdoc' where fingerprint = 'rolecheck-3';
  select sent_back::text || '/' || reviewed::text into r from items where fingerprint = 'rolecheck-3';
  insert into results values ('resolving a sent-back item again clears the send-back mark', 'false/false', r);
end $$;
do $$ begin
  insert into comments (fingerprint, author_id, role, body) values ('rolecheck-3', auth.uid(), 'client', 'Attached the invoice');
  insert into results values ('the client can reply', 'allowed', 'allowed');
exception when others then
  insert into results values ('the client can reply', 'allowed', 'BLOCKED');
end $$;
do $$ declare n int; e text; begin
  update comments set body = 'Attached the corrected invoice' where fingerprint = 'rolecheck-3' and author_id = auth.uid() and kind = 'message';
  get diagnostics n = row_count;
  select (edited_at is not null)::text into e from comments where fingerprint = 'rolecheck-3' and author_id = auth.uid();
  insert into results values ('the client can edit their own message (and it is stamped)', '1/true', n::text || '/' || e);
end $$;
do $$ declare n int; begin
  update comments set body = 'not yours' where fingerprint = 'rolecheck-3' and role = 'bookkeeper' and kind = 'message';
  get diagnostics n = row_count;
  insert into results values ('the client cannot edit someone else''s message', '0', n::text);
end $$;
do $$ declare n int; begin
  update comments set body = 'rewritten' where fingerprint = 'rolecheck-3' and kind in ('accept', 'reopen');
  get diagnostics n = row_count;
  insert into results values ('nobody can edit the automatic accept and send-back entries', '0', n::text);
end $$;
do $$ begin
  update comments set role = 'bookkeeper' where fingerprint = 'rolecheck-3' and author_id = auth.uid();
  insert into results values ('a message cannot change who wrote it', 'blocked', 'ALLOWED');
exception when others then
  insert into results values ('a message cannot change who wrote it', 'blocked', 'blocked');
end $$;
do $$ declare n int; b text; begin
  update comments set removed = true where fingerprint = 'rolecheck-3' and author_id = auth.uid() and kind = 'message';
  get diagnostics n = row_count;
  select body into b from comments where fingerprint = 'rolecheck-3' and author_id = auth.uid();
  insert into results values ('the client can remove their own message (text is erased)', '1/Message removed', n::text || '/' || b);
end $$;
do $$ declare n int; begin
  update comments set body = 'bring it back' where fingerprint = 'rolecheck-3' and author_id = auth.uid();
  get diagnostics n = row_count;
  insert into results values ('a removed message cannot be edited again', '0', n::text);
end $$;
do $$ declare n int; begin
  delete from items where fingerprint = 'rolecheck-3';
  get diagnostics n = row_count;
  insert into results values ('the client can delete a transaction', '1', n::text);
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
do $$ declare n int; begin
  select count(*) into n from comments;
  insert into results values ('a visitor who is not signed in sees no messages', '0', n::text);
exception when others then
  insert into results values ('a visitor who is not signed in sees no messages', '0', '0');
end $$;
reset role;

-- ---------- clean up, then show the answer ----------
insert into results select 'deleting a transaction deletes its conversation', '0', count(*)::text from comments where fingerprint = 'rolecheck-3';
delete from comments where fingerprint like 'rolecheck-%';
delete from requests where id = '00000000-0000-0000-0000-0000000000a1';
select check_name,
       expected,
       actual,
       case when expected = actual then 'PASS' else 'FAIL' end as result
from results
order by ctid;
