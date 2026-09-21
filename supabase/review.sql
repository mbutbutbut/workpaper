-- Review and conversation: the bookkeeper can accept an item, send it back with a reason,
-- and everyone can talk about an item. Run once in the Supabase SQL editor, after schema.sql.
-- Safe to run again.

-- Two marks on every item. Only accept_item and reopen_item may change them (see items_guard).
alter table items add column if not exists reviewed boolean not null default false;
alter table items add column if not exists sent_back boolean not null default false;

-- The conversation. Tied to an item's fingerprint, not its id, so a thread survives
-- when the bookkeeper sends the same transaction again in a new sheet.
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  fingerprint text not null,
  author_id uuid references auth.users(id) on delete set null,
  role text not null check (role in ('client', 'jeff', 'bookkeeper')),
  kind text not null default 'message' check (kind in ('message', 'reopen', 'accept')),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists comments_fp_idx on comments (fingerprint, created_at);

alter table comments enable row level security;

-- You can read a thread if you can see the item it is about (so Jeff sees only his items' threads).
drop policy if exists comments_read on comments;
create policy comments_read on comments for select to authenticated
  using (exists (select 1 from items i where i.fingerprint = comments.fingerprint));

-- Anyone who can see the item can add a message as themselves. Accept and reopen entries
-- are written only by the two functions below.
drop policy if exists comments_write on comments;
create policy comments_write on comments for insert to authenticated
  with check (
    author_id = auth.uid()
    and role = my_role()
    and kind = 'message'
    and exists (select 1 from items i where i.fingerprint = comments.fingerprint)
  );

-- items_guard, extended: the review marks change only through the functions, Jeff still
-- edits only status and note, and a new resolution ends the current review.
create or replace function items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at = now();
  if (new.reviewed is distinct from old.reviewed or new.sent_back is distinct from old.sent_back)
     and coalesce(current_setting('app.review_fn', true), '') <> 'on' then
    raise exception 'Review marks change only through accept and reopen';
  end if;
  if my_role() = 'jeff' then
    if (new.request_id, new.no, new.item_date, new.description, new.memo, new.amount, new.source, new.fingerprint, new.owner)
       is distinct from
       (old.request_id, old.no, old.item_date, old.description, old.memo, old.amount, old.source, old.fingerprint, old.owner) then
      raise exception 'Jeff can only change status and note';
    end if;
    if new.status not in ('jeff', 'hubdoc', 'missing', 'explained') then
      raise exception 'Jeff cannot set that status';
    end if;
  end if;
  if new.status is distinct from old.status and new.status <> 'waiting' then
    new.reviewed := false;
    new.sent_back := false;
  end if;
  return new;
end $$;

-- Bookkeeper signs off a resolved item.
create or replace function accept_item(p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare it items%rowtype;
begin
  if my_role() is distinct from 'bookkeeper' then raise exception 'Only the bookkeeper can accept an item'; end if;
  select * into it from items where id = p_item;
  if not found then raise exception 'Item not found'; end if;
  if it.status not in ('hubdoc', 'explained') then raise exception 'Only a resolved item can be accepted'; end if;
  perform set_config('app.review_fn', 'on', true);
  update items set reviewed = true, sent_back = false where id = p_item;
  insert into comments (fingerprint, author_id, role, kind, body) values (it.fingerprint, auth.uid(), 'bookkeeper', 'accept', 'Accepted');
end $$;

-- Bookkeeper sends an item back to the client, with a reason.
create or replace function reopen_item(p_item uuid, p_message text) returns void
language plpgsql security definer set search_path = public as $$
declare it items%rowtype; m text := btrim(coalesce(p_message, ''));
begin
  if my_role() is distinct from 'bookkeeper' then raise exception 'Only the bookkeeper can send an item back'; end if;
  if char_length(m) = 0 then raise exception 'A message is required'; end if;
  if char_length(m) > 1000 then raise exception 'That message is too long'; end if;
  select * into it from items where id = p_item;
  if not found then raise exception 'Item not found'; end if;
  if it.status in ('waiting', 'jeff') then raise exception 'That item is already open'; end if;
  perform set_config('app.review_fn', 'on', true);
  update items set status = 'waiting', owner = 'me', reviewed = false, sent_back = true where id = p_item;
  insert into comments (fingerprint, author_id, role, kind, body) values (it.fingerprint, auth.uid(), 'bookkeeper', 'reopen', m);
end $$;

revoke all on function accept_item(uuid) from public, anon;
revoke all on function reopen_item(uuid, text) from public, anon;
grant execute on function accept_item(uuid) to authenticated;
grant execute on function reopen_item(uuid, text) to authenticated;

-- Live updates for conversations.
do $$ begin
  alter publication supabase_realtime add table comments;
exception when duplicate_object then null; end $$;

notify pgrst, 'reload schema';
