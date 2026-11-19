---
name: Koin Flow
direction: Brass ledger
colors:
  ledger: '#0C1A16'      # app background
  felt: '#13261F'        # cards
  felt-high: '#1B3229'   # inputs, raised controls
  seam: '#26443A'        # tracks, dividers
  brass: '#E8B95A'       # brand, primary action, the coin
  brass-deep: '#3A2A06'  # text/icons on brass
  parchment: '#F1EADA'   # primary text
  sage: '#9DB3A8'        # secondary text
  mint: '#84E2B8'        # money in, healthy, paid
  rose: '#F2848F'        # money out over limit, late, destructive
typography:
  display: Bricolage Grotesque (headings and every amount, tabular figures)
  body: Figtree
radii:
  hero: 30   # the budget ring panel, budget card, sheets
  card: 22   # panels
  tile: 18   # list groups, small cards
  input: 16  # fields, buttons
  pill: 40   # chips, segmented controls, add button
---

# Koin Flow design system

Source of truth for tokens is `lib/theme.dart` (class `K`). This file explains intent.

## Idea

A banker's-green leather ledger with a brass coin on it. Dark, warm and calm, never
neon. Brass is the only loud colour and it always means "your money / do this".
Mint and rose appear only when money moves in or goes wrong.

## The one bold element

The Overview hero: a milled brass coin ring. The filled arc is what you've spent
(plus money lent out), the faint arc is cash set aside for unpaid bills, and the
parchment tick is how far through the month you are. If the arc is behind the tick,
you're on pace. Centre shows what's left; below it, **safe to spend per day**.
Everything else on screen stays quiet so this reads first.

## Motion

- One orchestrated moment: the ring sweeps and the amounts count up on open.
- Everything else answers the user: tab cross-fade, press-to-shrink on tappables,
  bars that grow in, sheets, toasts that slide up with Undo, a shake on invalid input.
- Light haptics on selection, medium on save/pay/settle, heavy on errors.
- All durations go through `K.motion()`, which returns zero when the system asks
  for reduced motion.

## Copy

Sentence case, plain verbs, no all-caps labels. A button says what happens
("Add expense", "Mark paid") and the toast echoes it ("Internet paid · logged as an
expense"). Empty states invite the next action. Errors say what to fix.

## Structure

- Overview — ring, pace vs last month, coming up (bills and balances due ≤ 7 days),
  Insights card (Spending bars with category filter and stats · Pace line vs budget ·
  Calendar heatmap · Categories donut with change vs previous period), recent, people.
- Expenses — iOS large title, search, filter sheet, category pills, list grouped by day.
  Tap to edit, swipe to delete (with Undo).
- People — owed to you / you owe, settle (with Undo), swipe to delete.
- Plan — budget card (tap to change; breakdown of spent / lent / bills / free),
  monthly bills, settings, danger zone. No slider.
- iOS-native pieces: Cupertino alerts and action sheets, wheel date picker,
  CupertinoSwitch, collapsing large-title nav bars, native `CNTabBar` on device.
  Other platforms get a matching floating glass tab bar (`GlassTabBar`).

## Data safety

Storage keys are unchanged from v1 (`expenses`, `debts`, `budget`,
`budgetExpenseStart`, `privacyLock`), so existing data loads as-is. Records are read
one by one; anything unreadable is kept verbatim and written back. Nothing is saved
until loading finishes. Restoring a backup asks before replacing data.

## Preview

`flutter build web --dart-define=DEMO=true` builds a preview with sample data inside
an iPhone frame (`IPhoneFrame`). Normal builds never include sample data or the frame.

## App icon

Drawn in code by `KoinMarkPainter` (`lib/logo.dart`). Regenerate all iOS sizes with
`flutter test tool/make_icons_test.dart`.
