# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

A static single-page front end (`index.html`) hosted on Vercel, with Supabase for sign-in (emailed one-time links, no open signups) and Postgres data, and role rules enforced in the database (`supabase/schema.sql`). With `config.js` empty the app runs as a local prototype with sample data.

## Users

Three roles, each behind a login:

- **Client (owner and coordinator):** receives the bookkeeper's request, uploads documents to Hubdoc, works through the full checklist, and assigns the remainder to Jeff. Primary user.
- **Jeff (contributor):** sees only a short list of the items assigned to him (his purchases), takes action on them, and sets each item's status himself.
- **Bookkeeper (reviewer):** sees the full checklist with statuses and notes, and reviews what has been resolved: they can accept an item, send it back to the client with a required reason, and reply in the item's conversation. They cannot edit statuses, owners or notes.

## Product Purpose

A shared checklist for a bookkeeper's document request. Today the request arrives as an emailed spreadsheet, the client re-creates it in a Google Sheet, tracks it against Hubdoc and against what Jeff must supply, and then reports back by email and a shared sheet. The product replaces that with one list everyone works from. Success means nothing is tracked in more than one place and the bookkeeper always sees current status without being sent an update.

## Positioning

The request is imported once and becomes a single live checklist with per-item status and notes, shared by three roles with different views. A spreadsheet plus email gives no shared, current picture.

## Operating Context

Bookkeeping runs on recurring cycles (month-end, quarter-end, tax season). Requests arrive as a spreadsheet by email. Documents are uploaded to Hubdoc. Jeff's purchases must be uploaded by Jeff himself. Documents are sensitive financial records.

## Capabilities and Constraints

- Confirmed: the bookkeeper reviews (Accept, or Reopen with a required message that returns the item to the admin as Waiting on me); every item has a small conversation, tied to the transaction so it survives re-imports; the one-line note stays as the item's current reason; admins manage people in the app (add, change role, reset password, remove); everyone signs in with email and password and can change their own; import the bookkeeper's spreadsheet as checklist items; per-item status and a short note; assign items to Jeff; Jeff has his own filtered list and updates his own statuses; bookkeeper has a live shared view; user login for all roles.
- Documents stay in Hubdoc. The product stores no files.
- Statuses: Waiting on me, In Hubdoc, With Jeff, No document (red flag, always with a note; set by Jeff or the client), Explained (the client has accepted the reason and closed the item).
- Undecided: authentication method, stack, exact import format, whether the bookkeeper can reply or reopen items, reminders (out of scope for v1).

## Evidence on Hand

None. The project folder holds no sample spreadsheet, copy, or brand assets. Future work must not invent firm names, customers, or compliance claims.

## Product Principles

- One list, three views: the checklist is the single source of truth for every role.
- Each role sees only what it needs: Jeff a short action list, the bookkeeper a status overview, the client everything.
- Keep documents out: the product tracks status and context, and Hubdoc stays the home for files.
- Security first: access is behind login, since the checklist describes sensitive financial activity.

## Accessibility & Inclusion

No product-specific requirement established. Jeff may update items on his phone while out purchasing, so mobile legibility and easy one-handed status changes are worth treating as baseline.
