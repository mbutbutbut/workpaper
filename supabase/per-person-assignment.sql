-- Assign a "With team" item to a specific person, not just the role as a whole, so each
-- team member gets their own list instead of one pooled inbox.
-- Run once in the Supabase SQL editor, after schema.sql. Safe to run again.

alter table items add column if not exists assignee_id uuid references auth.users(id) on delete set null;
create index if not exists items_assignee_idx on items (assignee_id);

-- Backfill: until now there was normally exactly one team-role account, so anything already
-- "With team" almost certainly belongs to them. If there is more than one, this assigns them
-- all to the first (by user id) -- reassign the rest afterwards from the Owner column.
update items set assignee_id = (select user_id from members where role = 'jeff' order by user_id limit 1)
where owner = 'jeff' and assignee_id is null;

-- A team member now sees only the items assigned to them, not everyone the role has ever held.
drop policy if exists items_read on items;
create policy items_read on items for select to authenticated
  using (my_role() in ('client', 'bookkeeper') or (my_role() = 'jeff' and owner = 'jeff' and assignee_id = auth.uid()));
drop policy if exists items_update on items;
create policy items_update on items for update to authenticated
  using (my_role() = 'client' or (my_role() = 'jeff' and owner = 'jeff' and assignee_id = auth.uid()))
  with check (my_role() = 'client' or (my_role() = 'jeff' and owner = 'jeff' and assignee_id = auth.uid()));

-- A team member may still change only status and note -- not who the item is assigned to.
-- This re-creates items_guard whole, so it must carry forward review.sql's review-mark
-- protection and its "a new resolution clears the review marks" step too, not just add
-- assignee_id to the older, simpler version from schema.sql.
create or replace function items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at = now();
  if (new.reviewed is distinct from old.reviewed or new.sent_back is distinct from old.sent_back)
     and coalesce(current_setting('app.review_fn', true), '') <> 'on' then
    raise exception 'Review marks change only through accept and reopen';
  end if;
  if my_role() = 'jeff' then
    if (new.request_id, new.no, new.item_date, new.description, new.memo, new.amount, new.source, new.fingerprint, new.owner, new.assignee_id)
       is distinct from
       (old.request_id, old.no, old.item_date, old.description, old.memo, old.amount, old.source, old.fingerprint, old.owner, old.assignee_id) then
      raise exception 'A team member can only change status and note';
    end if;
    if new.status not in ('jeff', 'hubdoc', 'missing', 'explained') then
      raise exception 'That status is not theirs to set';
    end if;
  end if;
  if new.status is distinct from old.status and new.status <> 'waiting' then
    new.reviewed := false;
    new.sent_back := false;
  end if;
  return new;
end $$;

notify pgrst, 'reload schema';
