# DESIGN_SYSTEM.md — UI Design System

> The single source of truth for the look and feel of the app. Claude Code must
> follow this for every screen. Style direction: **bold & modern**, violet
> accent, light + dark mode. Built on shadcn/ui + Tailwind.

## Stack & tooling

- **shadcn/ui** (owned components in `frontend/components/ui/`) on top of Tailwind CSS.
- **next-themes** for light/dark toggling (class strategy, `darkMode: "class"`).
- **Framer Motion** for animation.
- **lucide-react** for icons (ships with shadcn).
- **next/font/google**: `Space Grotesk` for headings/display, `Inter` for body. Expose as CSS variables `--font-heading` and `--font-sans`.

## Design tokens (shadcn CSS variables, HSL)

Put these in `globals.css`. `--radius: 0.75rem` (bolder, softer corners).

```css
:root {
  --background: 0 0% 100%;
  --foreground: 222 47% 11%;
  --card: 0 0% 100%;
  --card-foreground: 222 47% 11%;
  --popover: 0 0% 100%;
  --popover-foreground: 222 47% 11%;
  --primary: 262 83% 58%;          /* violet */
  --primary-foreground: 0 0% 100%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222 47% 11%;
  --muted: 210 40% 96%;
  --muted-foreground: 215 16% 47%;
  --accent: 262 60% 96%;
  --accent-foreground: 262 83% 40%;
  --destructive: 0 84% 60%;
  --destructive-foreground: 0 0% 100%;
  --border: 214 32% 91%;
  --input: 214 32% 91%;
  --ring: 262 83% 58%;
  --radius: 0.75rem;

  /* extra semantic colors (not in stock shadcn) */
  --success: 142 71% 45%; --success-foreground: 0 0% 100%;
  --warning: 38 92% 50%;  --warning-foreground: 38 92% 12%;
  --info: 199 89% 48%;    --info-foreground: 0 0% 100%;

  /* sidebar (deep violet-black in BOTH modes) */
  --sidebar: 257 35% 12%;
  --sidebar-foreground: 257 15% 75%;
  --sidebar-primary: 262 83% 62%;
  --sidebar-primary-foreground: 0 0% 100%;
  --sidebar-accent: 257 30% 18%;
  --sidebar-accent-foreground: 0 0% 100%;
  --sidebar-border: 257 25% 20%;
}

.dark {
  --background: 257 24% 8%;
  --foreground: 210 40% 98%;
  --card: 257 22% 11%;
  --card-foreground: 210 40% 98%;
  --popover: 257 22% 11%;
  --popover-foreground: 210 40% 98%;
  --primary: 263 70% 65%;          /* lightened violet for dark */
  --primary-foreground: 0 0% 100%;
  --secondary: 257 20% 17%;
  --secondary-foreground: 210 40% 98%;
  --muted: 257 20% 17%;
  --muted-foreground: 257 12% 65%;
  --accent: 257 25% 20%;
  --accent-foreground: 210 40% 98%;
  --destructive: 0 72% 51%;
  --destructive-foreground: 0 0% 98%;
  --border: 257 20% 20%;
  --input: 257 20% 20%;
  --ring: 263 70% 65%;

  --success: 142 64% 45%; --success-foreground: 0 0% 100%;
  --warning: 38 92% 55%;  --warning-foreground: 38 92% 10%;
  --info: 199 89% 55%;    --info-foreground: 0 0% 100%;

  --sidebar: 257 30% 7%;
  --sidebar-foreground: 257 12% 70%;
  --sidebar-primary: 263 70% 62%;
  --sidebar-primary-foreground: 0 0% 100%;
  --sidebar-accent: 257 25% 14%;
  --sidebar-accent-foreground: 0 0% 100%;
  --sidebar-border: 257 22% 16%;
}
```

Map these in `tailwind.config.ts` under `theme.extend.colors` using
`hsl(var(--token))`, including `success`, `warning`, `info`, and the `sidebar.*`
group. Set `fontFamily.heading` and `fontFamily.sans` and `borderRadius` from
`--radius`. Use `tailwindcss-animate` (shadcn default).

## Typography

- Headings/display: `font-heading` (Space Grotesk), weight 600–700.
- Body/UI: `font-sans` (Inter), weight 400/500.
- Scale (bold, generous): page title `text-3xl`/`text-4xl` bold; section title `text-xl` semibold; card stat numbers `text-3xl` bold in Space Grotesk; body `text-base` (16px); meta/labels `text-sm` muted.
- Sentence case for everything. Comfortable line-height (1.6–1.7 body).

## Shape & depth

- Corners: `rounded-xl` for cards, `rounded-lg` for inputs/buttons.
- Elevation via soft shadows (`shadow-sm` default, `shadow-md` on hover for cards), not hard borders.
- Generous spacing/whitespace.

## Status colors (badges) — domain mapping

Use a single `<StatusBadge status="..." />` component that maps status → variant:

| Variant | Token | Used for statuses |
|---|---|---|
| success | `success` (emerald) | published, active, validated, accepted |
| warning | `warning` (amber) | pending, pending_academic_validation, submitted, changes_requested |
| info | `info` (sky) | informational / in-progress states |
| neutral | `muted` (slate) | draft, open, withdrawn |
| destructive | `destructive` (rose) | closed, rejected, cancelled |

Badges use a soft tinted background + same-family foreground; in dark mode use
translucent backgrounds so they read on dark surfaces.

## Components to install (shadcn/ui)

`button card input label form select dropdown-menu dialog sheet tabs table badge avatar sonner skeleton tooltip separator` — plus `command` (optional, for search). Use `sonner` for toasts.

## App shell (used by every authenticated page)

A single reusable layout: `components/layout/AppShell.tsx` composing:
- **Sidebar** (`components/layout/Sidebar.tsx`): deep violet-black background in both themes; logo at top; role-based nav (see below); active item uses `sidebar-primary`; hover uses `sidebar-accent`. Collapses into a shadcn `sheet` on mobile.
- **Topbar** (`components/layout/Topbar.tsx`): search field, theme toggle (next-themes), notifications bell with unread dot, user avatar + dropdown-menu (profile, logout).
- **Content area**: page container with consistent padding and max width.

### Role-based navigation

| Role | Nav items |
|---|---|
| student | Dashboard, Offers, My applications, My internship, Messages, Evaluations |
| company | Dashboard, My offers, Applications, Internships, Messages, Evaluations |
| teacher | Dashboard, Offers, Agreements (to validate), My students, Messages, Evaluations |
| admin | uses the Django admin site (no custom shell needed) |

## Animation (Framer Motion) — subtle & fast

- Durations 150–250ms, ease-out. Two weights of motion only: state feedback and entrance.
- Route/page transition: fade + small upward slide (8–12px).
- Lists/card grids: staggered entrance (`staggerChildren` ~0.05s).
- Cards: hover lift (`translateY(-3px)` + shadow), button press `scale(0.97)`.
- Loading: shadcn `skeleton` placeholders while React Query fetches — never a bare spinner for whole pages.
- Toasts (`sonner`) slide in for action confirmations.
- Always respect `prefers-reduced-motion`: wrap with a helper that disables transforms/animations when the user prefers reduced motion.

## Rules of thumb

- Restraint over decoration — motion communicates state, it isn't ornament.
- Consistency across roles: same shell, palette, and components everywhere; only nav and available actions differ.
- Reusable, presentational components live in `components/ui/`; data-aware components live in their feature folder (`features/<domain>/components/`).
- Every color comes from a token — never hardcode a hex that breaks in dark mode.
