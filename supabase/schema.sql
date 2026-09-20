-- Workpaper: tables, role rules, and live updates.
-- Run once in the Supabase SQL editor (Dashboard > SQL Editor > New query).

create table if not exists members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('client', 'jeff', 'bookkeeper'))
);

create table if not exists requests (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  imported_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references requests(id) on delete cascade,
  no int not null,
  item_date text not null default '',
  description text not null,
  memo text not null default '',
  amount text not null default '',
  source text not null default '',
  fingerprint text not null,
  owner text not null default 'me' check (owner in ('me', 'jeff')),
  status text not null default 'waiting' check (status in ('waiting', 'hubdoc', 'jeff', 'missing', 'explained')),
  note text not null default '',
  is_new boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (request_id, fingerprint)
);
create index if not exists items_request_idx on items (request_id);
create index if not exists items_fp_idx on items (fingerprint);

-- Who am I? (bypasses RLS on members so policies can call it)
create or replace function my_role() returns text
language sql stable security definer set search_path = public as $$
  select role from members where user_id = auth.uid()
$$;

alter table members enable row level security;
alter table requests enable row level security;
alter table items enable row level security;

drop policy if exists members_self on members;
create policy members_self on members for select to authenticated using (user_id = auth.uid());

drop policy if exists requests_read on requests;
create policy requests_read on requests for select to authenticated using (my_role() is not null);
drop policy if exists requests_write on requests;
create policy requests_write on requests for all to authenticated
  using (my_role() = 'client') with check (my_role() = 'client');

-- Client and bookkeeper see everything; Jeff sees only items owned by Jeff.
drop policy if exists items_read on items;
create policy items_read on items for select to authenticated
  using (my_role() in ('client', 'bookkeeper') or (my_role() = 'jeff' and owner = 'jeff'));
drop policy if exists items_insert on items;
create policy items_insert on items for insert to authenticated with check (my_role() = 'client');
drop policy if exists items_delete on items;
create policy items_delete on items for delete to authenticated using (my_role() = 'client');
drop policy if exists items_update on items;
create policy items_update on items for update to authenticated
  using (my_role() = 'client' or (my_role() = 'jeff' and owner = 'jeff'))
  with check (my_role() = 'client' or (my_role() = 'jeff' and owner = 'jeff'));

-- Jeff may change only status and note, and only to statuses he can set.
create or replace function items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at = now();
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
  return new;
end $$;
drop trigger if exists items_guard_trg on items;
create trigger items_guard_trg before update on items for each row execute function items_guard();

-- Live updates so the bookkeeper sees changes as they happen.
do $$ begin
  alter publication supabase_realtime add table items;
exception when duplicate_object then null; end $$;
