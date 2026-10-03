---
name: Koin Flow
colors:
  surface: '#101417'
  surface-dim: '#101417'
  surface-bright: '#363a3d'
  surface-container-lowest: '#0b0f12'
  surface-container-low: '#181c1f'
  surface-container: '#1c2023'
  surface-container-high: '#262a2e'
  surface-container-highest: '#313539'
  on-surface: '#e0e3e7'
  on-surface-variant: '#bcc9c6'
  inverse-surface: '#e0e3e7'
  inverse-on-surface: '#2d3134'
  outline: '#879391'
  outline-variant: '#3d4947'
  surface-tint: '#6bd8cb'
  primary: '#6bd8cb'
  on-primary: '#003732'
  primary-container: '#29a195'
  on-primary-container: '#00302b'
  inverse-primary: '#006a61'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#f7be1d'
  on-tertiary: '#3f2e00'
  tertiary-container: '#b68a00'
  on-tertiary-container: '#372700'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#89f5e7'
  primary-fixed-dim: '#6bd8cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#005049'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdf9a'
  tertiary-fixed-dim: '#f7be1d'
  on-tertiary-fixed: '#251a00'
  on-tertiary-fixed-variant: '#5a4300'
  background: '#101417'
  on-background: '#e0e3e7'
  surface-variant: '#313539'
typography:
  headline-display:
    fontFamily: Manrope
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-display-mobile:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
  currency-stat:
    fontFamily: Manrope
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  currency-stat-sm:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 26px
    letterSpacing: -0.015em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style

This design system embodies high-conviction financial stewardship. It departs from the saturated neons of speculative crypto apps and the rigid, uninviting bureaucracy of legacy retail banking. The aesthetic is anchored in an elevated modern iOS sensibility: tactile obsidian surfaces, micro-textured translucent layers, and crisp financial data hierarchy.

The brand targets discerning individuals, executives, and high-agency households tracking multi-account cashflow, liquidity, and recurring obligations denominated in Pakistani Rupee (PKR / Rs.). The emotional signature is calm mastery, discretion, and effortless precision.

The design movement balances iOS Human Interface guidelines with refined tactile glassmorphism:
- Deep slate-tinted obsidian base tones instead of flat pitch black, preserving surface warmth and depth.
- Restrained, authoritative emerald and sea-glass greens communicating organic growth, solvency, and precision.
- Warm champagne gold highlights reserved strictly for milestones, yield indicators, and tier status.
- Rich tactile feedback through subtle hairline borders, ambient back-glows, and deliberate typographic rhythm.

## Colors

The palette is engineered specifically for low-fatigue dark mode environments with exceptional legibility across varying ambient lighting conditions.

### Palette Architecture
- **Primary (`#0D9488` - Deep Sea Teal):** Used for primary CTAs, active segmented control states, key balance highlights, and major positive inflection points.
- **Secondary (`#10B981` - Lustrous Mint Emerald):** Utilized for positive net-flow deltas, cash inflows, success validation badges, and liquid asset visualization charts.
- **Tertiary (`#EAB308` - Champagne Gold):** Serves as an accent for investment yields, high-value alerts, targets, savings goals, and premium account badges.
- **Neutral Core (`#0B0F12` - Obsidian Slate):** The lowest layer canvas. It avoids harsh `#000000` to prevent OLED shearing while maintaining rich, deep contrast against elevated cards (`#131920`) and active rows (`#1B242D`).

### Functional Tints & Semantic Roles
- **Negative Cashflow / Expense:** `#F43F5E` (Warm Crimson) ensures clear differentiation without clashing with the teal primary.
- **Surface Elevation Hierarchy:**
  - `surface-canvas`: `#0B0F12`
  - `surface-elevated`: `#12181F`
  - `surface-card`: `#161F28`
  - `surface-overlay`: `rgba(22, 31, 40, 0.75)` with 20px background blur.
  - `border-hairline`: `rgba(255, 255, 255, 0.08)` on cards; `rgba(13, 148, 136, 0.25)` on active focused nodes.

## Typography

Typographic hierarchy prioritizes rapid scanning of currency volumes, transaction states, and ledger records. Manrope delivers geometric balance with open counters, rendering numerals with immediate clarity.

### Number & Currency Representation Rules
- Always render the Pakistani Rupee prefix as `Rs.` or `PKR` with optical separation:
  - In display titles: `Rs.` uses `label-md` or `headline-sm` with a lighter font weight (`500`) or secondary opacity (`70%`) immediately preceding the bold balance figures.
  - Comma separation follows the standard South Asian or International format based on user settings (defaulting to standard tri-digit groupings `1,500,000` or Lakh/Crore systems `15,00,000`).
- Tabular figures (`font-variant-numeric: tabular-nums`) must be enforced across all ledger items, balance histories, and balance cards to ensure vertically aligned decimal decimals and values.

## Layout & Spacing

The layout system is tailored for single-handed iOS interaction, utilizing a dynamic 4-column layout on iPhone screens expanding to an 8-column layout on iPad in split/full mode.

### Layout Principles
- **Screen Margins:** Fixed `1.25rem` (20px) outer padding on mobile devices guarantees thumb-reach comfort while preserving safe-area clearances around the iOS Dynamic Island and Home Indicator.
- **Rhythm & Baseline:** Built on an 8pt architectural grid with 4pt micro-increments. `space-xs` (4px) isolates tags and indicators within cells; `space-sm` (8px) separates related metadata pairs; `space-md` (16px) governs internal card padding; `space-lg` (24px) spaces grouped sections.
- **Bottom Navigation Dock:** Floating navigation surfaces must feature safe-area bottom insets of at least `2rem` (32px) to prevent collision with iOS gestures.

## Elevation & Depth

Visual hierarchy leverages tonal stratification and back-lit ambient diffusions rather than muddy, high-spread drop shadows.

### Surface Tiers
- **Tier 0 (Base Canvas):** Background tone (`#0B0F12`) ground layer.
- **Tier 1 (Surface Cards & Groups):** Tone `#12181F` layered with a subtle, inward-facing white hairline border (`rgba(255, 255, 255, 0.06)`).
- **Tier 2 (Floating Action Panels & Sheets):** Backdrop blur filter (`blur(24px) saturate(180%)`) with fill `rgba(22, 31, 40, 0.82)`. Outlined with a top-lit gradient border (`rgba(255, 255, 255, 0.12)` falling to `rgba(255, 255, 255, 0.02)`).
- **Tier 3 (Modals & Alerts):** Tone `#1A232D` with an ambient drop glow: `0px 16px 36px rgba(0, 0, 0, 0.45)`, accented with a soft deep teal halo `0px 0px 48px rgba(13, 148, 136, 0.12)`.

## Shapes

The shape system adopts Apple's continuous curve (squircle) design language. Corner rounding uses `roundedness: 2` (0.5rem base) with specific component scaling:

- **Outer App Cards / Transaction Modules:** 1rem (16px) to 1.5rem (24px) matching standard iOS widget continuity.
- **Primary Interactive Elements (Buttons, Inputs):** 0.75rem (12px) to 1rem (16px) for an approachable, tactile profile.
- **Status Pills, Tags, and Chips:** Full concentric pill radiuses (`9999px`) to distinguish actionable labels from static contextual tiles.

## Components

### Buttons
- **Primary:** Background tinted with Deep Sea Teal (`#0D9488`), text in absolute white, height of 50px for touch target optimization. Subtle inset top border `rgba(255, 255, 255, 0.2)` creating a tactile bevel effect.
- **Secondary / Ghost:** Translucent slate (`rgba(255, 255, 255, 0.06)`), border `rgba(255, 255, 255, 0.08)`, text in high-contrast neutral `#E2E8F0`.
- **Haptic Feedback:** All primary and transaction-authorizing buttons trigger standard medium iOS haptics on release.

### Cards & Ledger Modules
- **Net Flow Master Card:** Rich gradient surface from `#132227` to `#10171D`, bounded by a hairline emerald rim (`rgba(16, 185, 129, 0.2)`). Displays overall liquidity, secondary change metrics, and micro sparklines.
- **Transaction Item Rows:** Flat neutral backing with dividing hairlines inset by 56px to accommodate transaction category icons. Icon containers are 40x40px rounded squircles with 12% opacity category tints.

### Chips & Filter Pills
- Inactive state: Border `1px solid rgba(255, 255, 255, 0.1)`, fill `transparent`, text `rgba(255, 255, 255, 0.6)`.
- Active state: Fill `rgba(13, 148, 136, 0.18)`, border `1px solid #0D9488`, text `#2DD4BF`.

### Inputs & Currency Entry
- Pinched field architecture: Numeric amount entry fields showcase prominent typography (`currency-stat`) accompanied by a static `Rs.` prefix in subdued mint (`#0D9488`).
- Bottom sheet inputs use blurred surfaces with integrated custom numpads featuring low-friction tactile buttons.

### Specialized Cashflow Components
- **Liquid Burn Meter:** Segmented horizontal gauge demonstrating budget depletion; transitions from Mint (`#10B981`) to Gold (`#EAB308`) and Crimson (`#F43F5E`) as variance thresholds shift.
- **Account Aggregation Selector:** Horizontally scrolling pill-carousel displaying linked institutional accounts and local cash vaults, decorated with bank favicon badges and live balance snippets.