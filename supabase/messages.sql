-- Edit or remove your own messages, and clean up a conversation when its transaction is deleted.
-- Run once in the Supabase SQL editor, after review.sql. Safe to run again.

alter table comments add column if not exists edited_at timestamptz;
alter table comments add column if not exists removed boolean not null default false;

-- You may change only messages you wrote yourself, by hand, that are not already removed.
-- (Accept and send-back entries are written by the system and can never be edited.)
drop policy if exists comments_edit on comments;
create policy comments_edit on comments for update to authenticated
  using (author_id = auth.uid() and kind = 'message' and removed = false)
  with check (author_id = auth.uid() and kind = 'message');

-- Only the text can change. Editing stamps the time; removing erases the text and leaves a placeholder.
create or replace function comments_guard() returns trigger
language plpgsql as $$
begin
  if (new.fingerprint, new.author_id, new.role, new.kind, new.created_at)
     is distinct from (old.fingerprint, old.author_id, old.role, old.kind, old.created_at) then
    raise exception 'Only the text of a message can change';
  end if;
  if old.removed then raise exception 'A removed message cannot be changed'; end if;
  if new.removed then
    new.body := 'Message removed';
    new.edited_at := now();
  elsif new.body is distinct from old.body then
    new.edited_at := now();
  end if;
  return new;
end $$;
drop trigger if exists comments_guard_trg on comments;
create trigger comments_guard_trg before update on comments for each row execute function comments_guard();

-- Deleting the last transaction with a given fingerprint deletes its conversation too.
create or replace function items_cleanup() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from items where fingerprint = old.fingerprint) then
    delete from comments where fingerprint = old.fingerprint;
  end if;
  return old;
end $$;
drop trigger if exists items_cleanup_trg on items;
create trigger items_cleanup_trg after delete on items for each row execute function items_cleanup();

notify pgrst, 'reload schema';
