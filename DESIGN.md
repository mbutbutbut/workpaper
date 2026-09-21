---
name: Workpaper
description: A shared bookkeeping checklist drawn as a marked-up analysis-paper workpaper, with tickmark statuses and a pinned legend.
colors:
  paper: "#eaf1e2"
  paper-deep: "#dde8d2"
  ledger-rule: "#b7c6aa"
  ink: "#1f2933"
  ink-soft: "#4a5561"
  ink-hover: "#303c49"
  placeholder-grey: "#566270"
  field-white: "#ffffff"
  pencil-blue: "#2557a7"
  pencil-blue-wash: "#e4ebf6"
  pencil-red: "#b8322a"
  pencil-red-wash: "#f7e3df"
  red-on-ink: "#ffd9d4"
typography:
  display:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "clamp(1.6rem, 3vw + 0.5rem, 2.4rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "1.15rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  meta:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.08em"
  small:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.3
  legend-phone:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
  legend-narrow:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "10px"
    fontWeight: 400
    lineHeight: 1.2
  item-title:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "1.05rem"
    fontWeight: 600
    lineHeight: 1.3
  heading:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "1.4rem"
    fontWeight: 700
    lineHeight: 1.2
  login-title:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "2.2rem"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "-0.02em"
  pencil-note:
    fontFamily: "Caveat, Segoe Print, cursive"
    fontSize: "21px"
    fontWeight: 500
    lineHeight: 1.15
rounded:
  control: "3px"
  focus: "2px"
spacing:
  page: "clamp(16px, 4vw, 40px)"
  row: "12px"
  gap: "16px"
  touch: "44px"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    padding: "9px 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.ink-hover}"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "9px 16px"
    height: "40px"
  button-outline-hover:
    backgroundColor: "{colors.paper-deep}"
  month-band:
    backgroundColor: "{colors.paper-deep}"
    textColor: "{colors.ink}"
    padding: "8px 10px"
  bulk-bar:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    padding: "10px 14px"
  flagged-row:
    backgroundColor: "{colors.pencil-red-wash}"
  selected-row:
    backgroundColor: "{colors.pencil-blue-wash}"
  text-field:
    backgroundColor: "{colors.field-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    height: "44px"
---

# Design System: Workpaper

## Overview

**Creative North Star: "The Workpaper"**

The whole tool is one bookkeeper's working paper: pale green analysis stock, ruled in slate, marked in pencil. A request arrives as a list and is worked down the page, every line ending in a mark and, when it needs one, a note. Nothing decorates; everything is either ruled paper, a mark, or handwriting.

It is a task tool, so scanability outranks expression. Density is steady and the structure is predictable. The client, Jeff and the bookkeeper read the same page in three levels of detail, and the same marks mean the same thing in all three. Controls are plain and exact: hairline ink outlines and small square corners, with no shadow except where something floats.

**Key Characteristics:**
- Green analysis paper with slate ink; blue and red only as pencil marks.
- Status is a drawn tickmark with a label, never a coloured pill and never colour alone.
- Double rules open a section; hairlines separate rows; the legend is pinned to the foot.
- Notes are handwriting (blue pencil), everything else is a workhorse sans.
- One page structure for all three roles, phone-first for Jeff.

## Colors

A restrained, near-monochrome palette: paper and slate ink carry the page, and two pencil colours carry meaning.

### Primary
- **Pencil Blue** (#2557a7): the pencil. Handwritten notes, the In Hubdoc and Explained marks, links, focus rings and the selected-row wash.
- **Pencil Blue Wash** (#e4ebf6): the background of a selected row, and the field behind a note being edited.

### Secondary
- **Pencil Red** (#b8322a): the single warning colour. It means one thing, No document, and is used for that mark and the "problem" marker in the import review.
- **Pencil Red Wash** (#f7e3df): the tint behind a flagged row.
- **Pale Red on Ink** (#ffd9d4): error text on the dark bulk bar only.

### Neutral
- **Analysis Paper Green** (#eaf1e2): the page and the default surface.
- **Deep Paper Green** (#dde8d2): month bands, hover fills and the paper-coloured control background.
- **Ledger Rule Green** (#b7c6aa): hairlines between rows and dashed note underlines.
- **Slate Ink** (#1f2933): body text, heavy rules, outlines and the dark primary button and bulk bar.
- **Soft Slate** (#4a5561): secondary text, meta lines, column headings and the "Waiting" mark.
- **Pressed Slate** (#303c49): hover on the dark primary button.
- **Placeholder Slate** (#566270): placeholder text; measured at 5.0:1 or better on every surface it appears on.
- **Field White** (#ffffff): the fill of text inputs and the import textarea.

### Named Rules
**The Pencil Rule.** Blue and red appear only as marks and handwriting. A blue or red fill is a wash behind a row, never a button or a banner.
**The One Red Rule.** Red means "No document" and nothing else. Errors, warnings and destructive-looking actions do not get their own red.

## Typography

**Display and UI Font:** Public Sans (with system-ui, Segoe UI, sans-serif)
**Note Font:** Caveat (with Segoe Print, cursive), for handwritten notes only

**Character:** A plain, legible workhorse sans for everything the reader must trust, and one handwritten voice for what a person added by hand. The handwriting is never used for labels or controls.

### Hierarchy
- **Display** (700, clamp(1.6rem, 3vw + 0.5rem, 2.4rem), 1.1, -0.02em): the page title ("March request", "Your list").
- **Title** (700, 1.15rem, 1.2): month names in the month band.
- **Body** (400 and 500, 16px, 1.45): item descriptions and general text. Keep measure under about 66ch in prose.
- **Item title** (600, 1.05rem, 1.3): the description on each of Jeff's cards.
- **Heading** (700, 1.4rem, 1.2): the title of an empty or error state ("No request yet").
- **Login title** (700, 2.2rem, 1.05, -0.02em): the app name on the sign-in page only.
- **Meta** (400, 14px): dates, amounts, accounts and helper lines. Numbers use tabular figures so columns align.
- **Small** (500, 13px, 1.3): the top strip, the legend on desktop and the pinned-legend labels.
- **Phone legend** (11px) and **narrow legend** (10px, under 360px wide): the five short legend labels; nothing else uses these sizes.
- **Label** (700, 12px, 0.08em tracking, uppercase): column headings only.
- **Pencil note** (Caveat 500, 21px, 1.15): notes and reasons, always in Pencil Blue.

### Named Rules
**The One Hand Rule.** Handwriting appears only for notes and reasons. If a person did not write it, it is not in Caveat.
**The Sixteen Rule.** Inputs, selects and textareas are 16px on phones so the browser never zooms on focus.

## Layout

One column of ruled paper, up to 1320px wide, with a fluid side gutter (16px to 40px). The client and bookkeeper see a table per month: a month band, then a heading row (a select-all checkbox, No., Item, Date, Amount, Account, Owner, Status, Note), then ruled rows. Jeff sees the same structure, capped at 760px, as numbered rows with two large buttons.

Rhythm is tight inside a row and generous between rows: a 12px row padding, 16px between columns, and a heavier gap where a month begins, marked by a double rule. Summary counts sit directly under the page title in a double-ruled band, and the legend is pinned to the foot of the viewport.

**Phones (760px and narrower).** Columns fold: date, amount and account become one meta line under the item, and the heading row is hidden. Request, sort and order move behind one "Filters & sort" button. The legend becomes a single row of five short labels. The bulk bar docks above the legend. Everything a person touches is at least 44px in both directions, and nothing scrolls sideways down to 320px. Below 360px the legend text tightens to 10px.

Long lists stay fast because off-screen rows skip layout and paint; a row lets its status menu overflow while open.

## Elevation & Depth

Flat by default. Depth comes from rules and washes (double rules, hairlines, a tinted band), not shadows. Only two things float and carry a shadow.

### Shadow Vocabulary
- **Floating menu** (`box-shadow: 0 8px 20px -6px rgba(31, 41, 51, 0.28)`): the status menu.
- **Docked bar** (`box-shadow: 0 -8px 16px -10px rgba(31, 41, 51, 0.55)`): the bulk bar above the legend.

### Named Rules
**The Flat Paper Rule.** Surfaces never lift to signal importance. If something needs attention, it gets a mark or a wash, not a shadow.

## Shapes

Square-ish and exact: controls have 3px corners, focus rings have a 2px corner, and there are no pills, capsules or circles as containers. Outlines are 1px or 1.5px slate. Rules do the work of borders: a 3px double rule above a section and under the tally, a 1px slate rule under column headings, and a 1px green hairline between rows. Notes sit on a dashed underline. The marks are stroke drawings (2.4 stroke, round caps) in a 24-unit box.

## Components

### Review and conversation
Three extra marks and one panel, all drawn in the same stroke as the status marks: a **ring with a check** for Reviewed (the bookkeeper signed off), a **return arrow** for Sent back, and a **speech mark** with a count and a small blue dot when there is something new. A sent-back item shows a one-line "Sent back: \u201c...\u201d" under its title. The conversation opens inline under the row as a Deep Paper Green panel: messages oldest first, each with the person's role and time, text in Pencil Blue handwriting (it was written by a person), Sent back and Accepted as small outlined tags; a plain textarea and Send below. It is never a modal. Reopen and Accept never use red.

### Status marks (signature)
Five drawn glyphs, each a distinct shape, always shown with a label or the pinned legend:
- **Dashed circle** (Soft Slate): waiting on me.
- **Check** (Pencil Blue): in Hubdoc, and for Jeff, done.
- **Arrow** (Slate Ink): with Jeff.
- **X** (Pencil Red): no document.
- **Double bar** (Pencil Blue): explained; the client accepted the reason.
Marks draw in with a 0.45s pen stroke (ease-out), except the dashed circle. The animation is skipped under reduced motion; the mark simply appears.

### Buttons
- **Shape:** 3px corners, 1.5px slate outline, 600 weight.
- **Primary:** Slate Ink fill with paper text (9px by 16px padding, 40px high); Pressed Slate on hover.
- **Outline:** transparent with a slate outline; Deep Paper Green on hover.
- **Small:** 34px on desktop, 44px on phones and touch.
- **Focus:** a 2px Pencil Blue outline with a 2px offset.

### Month band and heading row
A Deep Paper Green band under a 3px double rule holds the month (Title), its counts, and on phones a checkbox. Beneath it, the heading row has Label-style column headings, with a 1px slate rule; Date and Amount are sort buttons and expose their direction.

### Item row
Hairline-ruled, 12px padding. A flagged row takes the Pencil Red Wash; a selected row takes the Pencil Blue Wash. The status is a 44px mark button that opens a menu; the note is a single-line handwritten field.

### Status menu
A paper-coloured floating list of five radio items with mark and label, 44px tall each on touch, 3px corners and the floating shadow. It opens on Enter or ArrowDown with focus on the current status, moves with arrow keys, and flips upward near the legend.

### Bulk bar
Slate Ink, docked above the legend, with the count and Clear on the first line. The primary action, Give to Jeff, is a paper-coloured button; the rest are outlined or plain.

### Jeff's action buttons
Two large outlined buttons (I have it, No document) with a mark above the label; a pressed state is a filled Slate Ink button.

### Team screen
An admin-only panel that opens at the top of the page, styled like the import panel: a plain ruled table of people (email, role, actions), then an "Add a person" form. Removing asks for a second click on the same row. Passwords are shown in plain text on purpose, so the admin can pass them on; destructive buttons use Pencil Red only for the confirm step.

### Inputs / Fields
Field White fill, 1px slate outline, 3px corners, 44px minimum height on touch. Notes are borderless with a dashed underline and a Pencil Blue wash while focused.

## Do's and Don'ts

### Do:
- **Do** show every status as a mark plus a label or the legend; the mark and the word must always agree.
- **Do** keep red for "No document" only, and keep blue for pencil marks and notes.
- **Do** separate sections with double rules and rows with hairlines instead of cards or boxes.
- **Do** use tabular figures for dates and amounts and right-align amounts.
- **Do** keep touch targets at 44px on phones, and check contrast of any new text at 4.5:1 (placeholders included).
- **Do** give one item number per row from the original file, so "item 8" means the same thing everywhere.

### Don't:
- **Don't** use coloured status pills, badges or icon-only status without a label.
- **Don't** use handwriting (Caveat) for labels, buttons or anything a person did not write.
- **Don't** add shadows to raise a surface; only the floating menu and the docked bar have them.
- **Don't** reuse a status mark for a different meaning (the import review has its own neutral markers).
- **Don't** hide a requirement in colour alone: flagged rows also carry the X mark and the "no document" word.
- **Don't** put a wide table on a phone; fold the columns into the meta line.
