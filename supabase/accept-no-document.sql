-- Let the bookkeeper accept a "No document" item too, the same way they accept a
-- resolved (In Hubdoc) or Explained one. Run once in the Supabase SQL editor, after review.sql.
-- Safe to run again.

create or replace function accept_item(p_item uuid) returns void
language plpgsql security definer set search_path = public as $$
declare it items%rowtype;
begin
  if my_role() is distinct from 'bookkeeper' then raise exception 'Only the bookkeeper can accept an item'; end if;
  select * into it from items where id = p_item;
  if not found then raise exception 'Item not found'; end if;
  if it.status not in ('hubdoc', 'explained', 'missing') then raise exception 'Only a resolved item can be accepted'; end if;
  perform set_config('app.review_fn', 'on', true);
  update items set reviewed = true, sent_back = false where id = p_item;
  perform set_config('app.review_fn', 'off', true); -- never leave the switch on for the rest of the transaction
  insert into comments (fingerprint, author_id, role, kind, body) values (it.fingerprint, auth.uid(), 'bookkeeper', 'accept', 'Accepted');
end $$;

notify pgrst, 'reload schema';
