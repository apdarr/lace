---
name: styling
description: Use when styling Rails views with Tailwind CSS — utility classes, responsive design, component patterns, dark mode, accessibility
---

# Tailwind CSS Styling

Style Rails views using Tailwind CSS v3 utility classes. Lace uses plain Tailwind with `@tailwindcss/forms`, `@tailwindcss/typography`, and `@tailwindcss/container-queries` plugins. No component libraries.

<when-to-use>
- Styling any Rails view, partial, or layout
- Building responsive layouts (mobile-first)
- Creating reusable UI component patterns (cards, buttons, badges, modals)
- Applying hover, focus, and active states
- Ensuring accessible color contrast (WCAG 2.1 AA)
- Working with Lace's design system classes in `application.tailwind.css`
</when-to-use>

<benefits>
- **Consistency** — Tailwind's constrained design tokens prevent ad-hoc values
- **Responsive** — Mobile-first breakpoints built into every utility
- **Performance** — Unused classes purged at build time
- **Maintainability** — Styles live next to markup; no separate CSS files to sync
- **Accessibility** — Focus-visible, sr-only, and contrast utilities built in
</benefits>

<standards>
- Use Tailwind utilities first; extract components with `@apply` only when truly needed
- Follow mobile-first responsive design (base → sm → md → lg → xl)
- Avoid inline styles (`style=`) — use Tailwind classes instead
- Use responsive breakpoints consistently (sm:640px, md:768px, lg:1024px, xl:1280px)
- Ensure 4.5:1 color contrast ratio for text (WCAG 2.1 AA)
- Extract repeated utility combinations into partials or view helpers, not CSS classes
- Use Tailwind's built-in color palette (slate, sky, emerald, red, amber) for consistency
- Prefer Lace's existing design system classes (`.card`, `.btn-primary`, `.badge-accent`, etc.) over ad-hoc utilities when they exist
- Use `focus-visible:` instead of `focus:` for keyboard-only focus rings
- Always include `disabled:opacity-50 disabled:cursor-not-allowed` on interactive elements
</standards>

<verification-checklist>
Before completing styling work:
- ✅ No inline `style=` attributes used
- ✅ Responsive at all breakpoints (mobile → desktop)
- ✅ Color contrast meets WCAG 2.1 AA (4.5:1 for text, 3:1 for large text)
- ✅ Focus states visible for keyboard navigation
- ✅ Existing design system classes used where applicable
- ✅ No hardcoded color hex values — use Tailwind palette
- ✅ Interactive elements have hover, focus, and disabled states
</verification-checklist>

## 1. Core Utilities

### Spacing & Layout

Tailwind uses a consistent spacing scale based on `0.25rem` (4px) increments.

```erb
<%# Padding %>
<div class="p-4">All sides</div>
<div class="px-4 py-2">Horizontal / vertical</div>
<div class="pt-6 pb-4 pl-3 pr-3">Individual sides</div>

<%# Margin %>
<div class="m-4">All sides</div>
<div class="mx-auto">Center horizontally</div>
<div class="mt-8 mb-4">Top / bottom</div>

<%# Negative margin %>
<div class="-mt-2">Pull up by 0.5rem</div>

<%# Space between children (preferred over margin on each child) %>
<div class="space-y-4">
  <p>First</p>
  <p>Second — 1rem gap above</p>
  <p>Third — 1rem gap above</p>
</div>

<%# Gap (for flex/grid) %>
<div class="flex gap-3">
  <span>A</span>
  <span>B</span>
</div>
```

#### Flexbox

```erb
<%# Row layout (default) %>
<div class="flex items-center justify-between">
  <h2 class="text-lg font-semibold">Title</h2>
  <button class="btn-primary">Action</button>
</div>

<%# Column layout %>
<div class="flex flex-col gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

<%# Wrap + responsive %>
<div class="flex flex-wrap gap-3">
  <div class="w-full sm:w-auto">Full on mobile, auto on sm+</div>
  <div class="w-full sm:w-auto">Same</div>
</div>

<%# Centering %>
<div class="flex items-center justify-center min-h-screen">
  <p>Vertically and horizontally centered</p>
</div>

<%# Grow / shrink %>
<div class="flex">
  <nav class="w-64 shrink-0">Sidebar</nav>
  <main class="flex-1 min-w-0">Content grows to fill</main>
</div>
```

#### CSS Grid

```erb
<%# Fixed columns %>
<div class="grid grid-cols-3 gap-4">
  <div>1</div>
  <div>2</div>
  <div>3</div>
</div>

<%# Responsive columns %>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
  <%= render partial: "activities/activity_card", collection: @activities %>
</div>

<%# Spanning columns %>
<div class="grid grid-cols-4 gap-4">
  <div class="col-span-3">Wide column</div>
  <div class="col-span-1">Narrow column</div>
</div>

<%# Auto-fit grid (responsive without breakpoints) %>
<div class="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-6">
  <div>Card</div>
  <div>Card</div>
  <div>Card</div>
</div>
```

#### Container

Lace defines container classes in its design system:

```erb
<%# Standard container — max-w-7xl with responsive padding %>
<div class="app-container">
  <%# Content %>
</div>

<%# Wide container — 95vw %>
<div class="app-container-wide">
  <%# Calendar or wide content %>
</div>

<%# Form container — max-w-4xl %>
<div class="app-container-form">
  <%# Form content %>
</div>
```

### Responsive Design

Tailwind uses mobile-first breakpoints. Base styles apply to all screens; breakpoint prefixes apply at that width **and above**.

| Prefix | Min-width | Typical device     |
|--------|----------:|---------------------|
| (none) |      0px  | Mobile (default)    |
| `sm:`  |    640px  | Large phone         |
| `md:`  |    768px  | Tablet              |
| `lg:`  |   1024px  | Laptop              |
| `xl:`  |   1280px  | Desktop             |
| `2xl:` |   1536px  | Large desktop       |

```erb
<%# Mobile-first: stack on mobile, side-by-side on md+ %>
<div class="flex flex-col md:flex-row gap-6">
  <aside class="w-full md:w-64 shrink-0">
    Sidebar — full width on mobile, fixed width on tablet+
  </aside>
  <main class="flex-1">
    Main content
  </main>
</div>

<%# Responsive text sizing %>
<h1 class="text-2xl sm:text-3xl md:text-4xl font-semibold text-slate-900">
  Scales up with screen size
</h1>

<%# Responsive padding %>
<div class="p-4 sm:p-6 lg:p-8">
  More breathing room on larger screens
</div>

<%# Show/hide elements by breakpoint %>
<nav class="hidden md:flex items-center gap-4">
  Desktop navigation
</nav>
<button class="md:hidden" aria-label="Open menu">
  Mobile menu toggle
</button>

<%# Responsive grid — real example from Lace %>
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
  <% @plans.each do |plan| %>
    <div class="card card-section">
      <h3 class="card-title"><%= plan.name %></h3>
      <p class="text-muted"><%= plan.race_date.strftime("%B %-d, %Y") %></p>
    </div>
  <% end %>
</div>
```

### Typography & Colors

#### Typography

```erb
<%# Font sizes (Tailwind scale) %>
<p class="text-xs">Extra small — 0.75rem</p>
<p class="text-sm">Small — 0.875rem</p>
<p class="text-base">Base — 1rem</p>
<p class="text-lg">Large — 1.125rem</p>
<p class="text-xl">Extra large — 1.25rem</p>
<p class="text-2xl">2XL — 1.5rem</p>
<p class="text-3xl">3XL — 1.875rem</p>

<%# Font weight %>
<p class="font-normal">Normal (400)</p>
<p class="font-medium">Medium (500)</p>
<p class="font-semibold">Semibold (600)</p>
<p class="font-bold">Bold (700)</p>

<%# Tracking (letter-spacing) %>
<span class="text-[11px] font-medium uppercase tracking-wide text-slate-500">
  Label text
</span>

<%# Leading (line-height) %>
<p class="text-base leading-relaxed">Comfortable reading line height</p>

<%# Lace design system text classes %>
<h1 class="heading-page">Page Heading</h1>        <%# 3xl → 4xl, semibold, slate-900 %>
<h2 class="heading-section">Section Heading</h2>  <%# xl, semibold, slate-800 %>
<span class="text-label">SMALL LABEL</span>        <%# 11px, uppercase, tracking-wide %>
<p class="text-muted">Secondary text</p>           <%# sm, slate-500 %>

<%# Custom fonts (configured in tailwind.config.js) %>
<p class="font-sans">Inter var (default body)</p>
<p class="font-borel">Borel (decorative, cursive)</p>
```

#### Colors

Lace uses Tailwind's default palette, primarily `slate`, `sky`, `emerald`, `red`, and `amber`.

```erb
<%# Text colors %>
<p class="text-slate-900">Primary text — highest contrast</p>
<p class="text-slate-800">Headings and body</p>
<p class="text-slate-600">Secondary text</p>
<p class="text-slate-500">Muted / helper text</p>

<%# Background colors %>
<div class="bg-slate-50">Page background</div>
<div class="bg-white">Card / surface background</div>
<div class="bg-slate-100">Subtle highlight</div>
<div class="bg-sky-100">Accent background</div>

<%# Semantic colors %>
<span class="bg-emerald-100 text-emerald-700">Success</span>
<span class="bg-amber-100 text-amber-700">Warning</span>
<span class="bg-red-100 text-red-700">Danger</span>
<span class="bg-sky-100 text-sky-700">Info / accent</span>

<%# Borders %>
<div class="border border-slate-200">Standard border</div>
<div class="border border-slate-300">Emphasized border</div>

<%# Opacity variants %>
<div class="bg-white/90">90% opaque white</div>
<div class="bg-slate-900/50">50% opaque dark overlay</div>

<%# ❌ BAD — hardcoded hex color %>
<p class="text-[#334155]">Don't use arbitrary hex values</p>

<%# ✅ GOOD — use the palette %>
<p class="text-slate-700">Use Tailwind's color scale</p>
```

### Interactive States

```erb
<%# Hover %>
<button class="bg-slate-900 text-white hover:bg-slate-800">
  Darkens on hover
</button>

<%# Focus (keyboard accessibility) %>
<input class="border border-slate-300 focus:border-slate-500 focus:ring-slate-500
             focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-1" />

<%# Active (pressed) %>
<button class="bg-sky-600 hover:bg-sky-700 active:bg-sky-800">
  Deepens on press
</button>

<%# Disabled %>
<button class="bg-slate-900 text-white disabled:opacity-50 disabled:cursor-not-allowed"
        disabled>
  Cannot click
</button>

<%# Group hover (parent hover affects children) %>
<div class="group rounded-lg border border-slate-200 p-4 hover:shadow-md transition">
  <h3 class="text-slate-800 group-hover:text-slate-900">Title</h3>
  <p class="text-slate-500 group-hover:text-slate-600">Description</p>
</div>

<%# Transitions %>
<div class="transition-colors duration-200">Smooth color change</div>
<div class="transition-all duration-300 ease-in-out">Animate everything</div>
<div class="transition shadow-sm hover:shadow-md">Shadow transition</div>

<%# Combined interactive states — real example %>
<a href="#"
   class="inline-flex items-center gap-1.5 rounded-md px-3 py-2
          text-sm font-medium text-slate-600
          hover:text-slate-900 hover:bg-slate-100
          focus:outline-none focus-visible:ring-2 focus-visible:ring-slate-600
          transition-colors">
  Navigation Link
</a>
```

## 2. Component Patterns

These patterns are built with plain Tailwind utilities. When Lace's design system already provides a class (e.g., `.card`, `.btn-primary`), prefer the design system class.

### Card

```erb
<%# Using Lace's design system classes %>
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Activity Summary</h3>
    <span class="badge-accent">This Week</span>
  </div>
  <div class="card-section">
    <p class="text-muted">8 activities scheduled</p>
  </div>
</div>

<%# Card with accent top bar %>
<div class="card card-accent-top">
  <div class="card-section">
    <h3 class="card-title">Featured Plan</h3>
    <p class="text-sm text-slate-600 mt-2">
      Marathon training — 18 weeks
    </p>
  </div>
</div>

<%# Card built from utilities (when design system class doesn't fit) %>
<article class="rounded-lg bg-white/90 backdrop-blur border border-slate-200 shadow-sm
                overflow-hidden transition hover:shadow-md">
  <div class="p-4 md:p-5">
    <div class="flex items-start justify-between">
      <div>
        <h3 class="text-base font-semibold text-slate-800">Long Run</h3>
        <p class="mt-1 text-sm text-slate-500">16 miles at easy pace</p>
      </div>
      <span class="inline-flex items-center rounded-md px-2 py-0.5
                   text-[11px] font-medium bg-emerald-100 text-emerald-700">
        Completed
      </span>
    </div>
    <div class="mt-4 flex items-center gap-4 text-sm text-slate-600">
      <span>📅 March 15</span>
      <span>🏃 16.2 mi</span>
      <span>⏱ 2h 15m</span>
    </div>
  </div>
</article>

<%# Metric card %>
<div class="card card-section">
  <div class="metric">
    <span class="metric-label">Weekly Mileage</span>
    <span class="metric-value">42.3 mi</span>
  </div>
</div>
```

### Buttons

```erb
<%# Lace design system button classes %>
<button class="btn-primary">Primary Action</button>
<button class="btn-secondary">Secondary</button>
<button class="btn-soft">Soft</button>
<button class="btn-outline">Outline</button>
<button class="btn-danger">Delete</button>
<button class="btn-ghost">Ghost</button>

<%# Navigation button %>
<a href="#" class="btn-nav">Dashboard</a>
<a href="#" class="btn-nav btn-nav-active">Plans</a>

<%# Button with icon %>
<button class="btn-primary">
  <svg class="h-4 w-4" aria-hidden="true" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
  </svg>
  Add Activity
</button>

<%# Small button variant (override padding) %>
<button class="btn-outline px-2 py-1 text-xs">
  Small
</button>

<%# Full-width button on mobile, auto on desktop %>
<button class="btn-primary w-full sm:w-auto">
  Save Plan
</button>

<%# Button built from utilities %>
<button class="inline-flex items-center gap-1.5 rounded-md px-3 py-2
               text-sm font-medium bg-slate-900 text-white
               hover:bg-slate-800 transition-colors
               focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-1
               focus-visible:ring-slate-600
               disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer">
  Custom Button
</button>

<%# Link styled as button %>
<%= link_to "View Plan", plan_path(@plan), class: "btn-primary" %>

<%# Destructive action with confirmation %>
<%= button_to "Delete", plan_path(@plan),
    method: :delete,
    class: "btn-danger",
    form: { data: { turbo_confirm: "Are you sure?" } } %>
```

### Form Inputs

```erb
<%# Using Lace design system form classes %>
<%= form_with(model: @activity, class: "space-y-6") do |f| %>
  <div class="form-field">
    <%= f.label :description, class: "form-label" %>
    <%= f.text_field :description, class: "form-input", required: true %>
  </div>

  <div class="form-field">
    <%= f.label :description, class: "form-label" %>
    <%= f.text_area :description, class: "form-textarea" %>
  </div>

  <div>
    <%= f.submit "Save Activity", class: "btn-primary" %>
  </div>
<% end %>

<%# Form input with error state %>
<div class="form-field">
  <%= f.label :description, class: "form-label" %>
  <%= f.text_field :description,
      class: "form-input #{'border-red-500 focus:border-red-500 focus:ring-red-500' if @activity.errors[:description].any?}",
      required: true,
      aria: { describedby: @activity.errors[:description].any? ? "description-error" : nil } %>
  <% if @activity.errors[:description].any? %>
    <p id="description-error" class="mt-1 text-sm text-red-600" role="alert">
      <%= @activity.errors[:description].to_sentence %>
    </p>
  <% end %>
</div>

<%# Select field %>
<div class="form-field">
  <%= f.label :activity_type, class: "form-label" %>
  <%= f.select :activity_type,
      options_for_select(%w[easy tempo interval long_run recovery].map { |t| [t.titleize, t] }),
      { include_blank: "Select type" },
      class: "form-input" %>
</div>

<%# Checkbox %>
<div class="flex items-center gap-2">
  <%= f.check_box :completed,
      class: "h-4 w-4 rounded border-slate-300 text-sky-600 focus:ring-sky-500" %>
  <%= f.label :completed, "Mark as completed", class: "text-sm text-slate-700" %>
</div>

<%# Input built from utilities (when design system doesn't fit) %>
<input type="text"
       class="w-full rounded-md border border-slate-300 bg-white px-3 py-2
              text-sm text-slate-800 shadow-inner placeholder-slate-400
              focus:border-slate-500 focus:ring-slate-500 focus:outline-none" />
```

### Alert / Notification

```erb
<%# Success alert %>
<div role="alert" class="rounded-md bg-emerald-50 border border-emerald-200 p-4">
  <div class="flex items-start gap-3">
    <svg class="h-5 w-5 text-emerald-600 shrink-0 mt-0.5" aria-hidden="true"
         fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
            clip-rule="evenodd" />
    </svg>
    <div>
      <h3 class="text-sm font-medium text-emerald-800">Plan created</h3>
      <p class="mt-1 text-sm text-emerald-700">Your 18-week marathon plan is ready.</p>
    </div>
  </div>
</div>

<%# Warning alert %>
<div role="alert" class="rounded-md bg-amber-50 border border-amber-200 p-4">
  <div class="flex items-start gap-3">
    <svg class="h-5 w-5 text-amber-600 shrink-0 mt-0.5" aria-hidden="true"
         fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd"
            d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 6a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 6zm0 9a1 1 0 100-2 1 1 0 000 2z"
            clip-rule="evenodd" />
    </svg>
    <div>
      <h3 class="text-sm font-medium text-amber-800">Strava sync delayed</h3>
      <p class="mt-1 text-sm text-amber-700">Recent activities may not appear yet.</p>
    </div>
  </div>
</div>

<%# Error alert %>
<div role="alert" class="rounded-md bg-red-50 border border-red-200 p-4">
  <div class="flex items-start gap-3">
    <svg class="h-5 w-5 text-red-600 shrink-0 mt-0.5" aria-hidden="true"
         fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
            clip-rule="evenodd" />
    </svg>
    <div>
      <h3 class="text-sm font-medium text-red-800">Upload failed</h3>
      <p class="mt-1 text-sm text-red-700">Could not parse the training plan image.</p>
    </div>
  </div>
</div>

<%# Info alert %>
<div role="status" class="rounded-md bg-sky-50 border border-sky-200 p-4">
  <div class="flex items-start gap-3">
    <svg class="h-5 w-5 text-sky-600 shrink-0 mt-0.5" aria-hidden="true"
         fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd"
            d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z"
            clip-rule="evenodd" />
    </svg>
    <p class="text-sm text-sky-700">
      Tip: Upload a photo of your training plan to auto-generate activities.
    </p>
  </div>
</div>

<%# Dismissible flash (with Stimulus) %>
<div role="alert"
     data-controller="dismissible"
     class="rounded-md bg-emerald-50 border border-emerald-200 p-4 fade-in">
  <div class="flex items-center justify-between">
    <p class="text-sm font-medium text-emerald-800"><%= flash[:notice] %></p>
    <button type="button"
            data-action="click->dismissible#dismiss"
            class="text-emerald-600 hover:text-emerald-800"
            aria-label="Dismiss">
      <svg class="h-4 w-4" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20">
        <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
      </svg>
    </button>
  </div>
</div>
```

### Badge / Pill

```erb
<%# Lace design system badges %>
<span class="badge-neutral">Draft</span>
<span class="badge-accent">Active</span>
<span class="badge-warning">Upcoming</span>
<span class="badge-danger">Missed</span>

<%# Badge built from utilities %>
<span class="inline-flex items-center rounded-md px-2 py-0.5
             text-[11px] font-medium bg-slate-100 text-slate-700">
  Custom Badge
</span>

<%# Rounded pill %>
<span class="inline-flex items-center rounded-full px-2.5 py-0.5
             text-xs font-medium bg-sky-100 text-sky-700">
  5K
</span>

<%# Badge with dot indicator %>
<span class="inline-flex items-center gap-1.5 rounded-md px-2 py-0.5
             text-[11px] font-medium bg-emerald-100 text-emerald-700">
  <span class="h-1.5 w-1.5 rounded-full bg-emerald-500" aria-hidden="true"></span>
  Synced
</span>

<%# Accent chip (Lace design system) %>
<span class="accent-chip">Marathon</span>
<span class="accent-chip accent-chip-alt">Recovery</span>

<%# Removable badge %>
<span class="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2 py-0.5
             text-[11px] font-medium text-slate-700">
  Interval
  <button type="button" class="text-slate-400 hover:text-slate-600" aria-label="Remove tag">
    <svg class="h-3 w-3" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20">
      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
    </svg>
  </button>
</span>

<%# Badge helper for dynamic status (use in view helpers) %>
<%# See views SKILL.md for the status_badge helper pattern %>
```

### Modal (using `<dialog>`)

```erb
<%# Modal trigger %>
<button type="button"
        data-action="click->modal#open"
        class="btn-primary">
  Delete Activity
</button>

<%# Modal dialog %>
<dialog data-controller="modal"
        data-modal-target="dialog"
        aria-labelledby="modal-title"
        class="rounded-lg bg-white p-0 shadow-xl backdrop:bg-slate-900/50
               w-full max-w-md mx-auto">
  <div class="p-6">
    <h2 id="modal-title" class="text-lg font-semibold text-slate-900">
      Confirm Delete
    </h2>
    <p class="mt-2 text-sm text-slate-600">
      Are you sure you want to delete this activity? This action cannot be undone.
    </p>

    <div class="mt-6 flex justify-end gap-3">
      <button type="button"
              data-action="click->modal#close"
              class="btn-outline">
        Cancel
      </button>
      <%= button_to "Delete", activity_path(@activity),
          method: :delete,
          class: "btn-danger" %>
    </div>
  </div>
</dialog>

<%# Stimulus controller for the modal %>
<%#
  // app/javascript/controllers/modal_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["dialog"]

    open() { this.dialogTarget.showModal() }
    close() { this.dialogTarget.close() }
  }
%>

<%# Full-screen modal for mobile, centered on desktop %>
<dialog data-controller="modal"
        data-modal-target="dialog"
        aria-labelledby="plan-modal-title"
        class="rounded-none sm:rounded-lg bg-white p-0 shadow-xl backdrop:bg-slate-900/50
               w-full h-full sm:h-auto sm:max-w-lg sm:mx-auto">
  <div class="flex flex-col h-full sm:h-auto">
    <%# Header %>
    <div class="flex items-center justify-between border-b border-slate-200 px-4 py-3 sm:px-6">
      <h2 id="plan-modal-title" class="text-base font-semibold text-slate-900">
        Edit Plan
      </h2>
      <button type="button"
              data-action="click->modal#close"
              class="text-slate-400 hover:text-slate-600"
              aria-label="Close">
        <svg class="h-5 w-5" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
        </svg>
      </button>
    </div>

    <%# Body %>
    <div class="flex-1 overflow-y-auto p-4 sm:p-6">
      <%# Form content %>
    </div>

    <%# Footer %>
    <div class="border-t border-slate-200 px-4 py-3 sm:px-6 flex justify-end gap-3">
      <button type="button" data-action="click->modal#close" class="btn-outline">
        Cancel
      </button>
      <button type="submit" class="btn-primary">Save Changes</button>
    </div>
  </div>
</dialog>
```

## 3. Anti-Patterns

### ❌ Inline Styles Instead of Tailwind

```erb
<%# ❌ BAD — inline styles bypass Tailwind's design system %>
<div style="padding: 16px; margin-bottom: 24px; background-color: #f1f5f9;">
  <h3 style="font-size: 18px; font-weight: 600; color: #1e293b;">Title</h3>
  <p style="font-size: 14px; color: #64748b;">Description</p>
</div>

<%# ✅ GOOD — Tailwind utilities %>
<div class="p-4 mb-6 bg-slate-100">
  <h3 class="text-lg font-semibold text-slate-800">Title</h3>
  <p class="text-sm text-slate-500">Description</p>
</div>

<%# ✅ BEST — Lace design system classes %>
<div class="card card-section">
  <h3 class="card-title">Title</h3>
  <p class="text-muted">Description</p>
</div>
```

### ❌ Hardcoded Colors Instead of Theme Values

```erb
<%# ❌ BAD — arbitrary hex colors %>
<button class="bg-[#1e40af] text-[#ffffff] hover:bg-[#1e3a8a]">
  Submit
</button>
<p class="text-[#94a3b8]">Muted text</p>

<%# ✅ GOOD — Tailwind palette colors %>
<button class="bg-slate-900 text-white hover:bg-slate-800">
  Submit
</button>
<p class="text-slate-400">Muted text</p>

<%# ❌ BAD — inconsistent one-off values %>
<div class="p-[13px] mt-[7px] text-[15px]">
  Arbitrary values break the spacing/sizing system
</div>

<%# ✅ GOOD — use the design scale %>
<div class="p-3 mt-2 text-sm">
  Consistent spacing and sizing
</div>
```

### ❌ Extracting Too Early with @apply

```erb
<%# ❌ BAD — unnecessary @apply for one-off usage %>
<%# In application.tailwind.css: %>
<%# .special-card { @apply rounded-lg bg-white p-4 shadow-md border border-slate-200; } %>

<%# ✅ GOOD — inline utilities for one-off patterns %>
<div class="rounded-lg bg-white p-4 shadow-md border border-slate-200">
  Only used once — keep it inline
</div>

<%# ✅ GOOD — extract to @apply only for frequently reused patterns %>
<%# The design system classes (.card, .btn-primary, .badge-accent) are good %>
<%# examples of justified @apply extraction %>
```

### ❌ Non-Mobile-First Breakpoints

```erb
<%# ❌ BAD — desktop-first (overriding down) %>
<div class="flex flex-row sm:flex-col">
  This breaks the mobile-first convention
</div>

<%# ✅ GOOD — mobile-first (building up) %>
<div class="flex flex-col sm:flex-row">
  Stacks on mobile, rows on sm+
</div>

<%# ❌ BAD — hiding by default, showing on mobile %>
<div class="hidden sm:hidden md:block">
  Confusing override chain
</div>

<%# ✅ GOOD — clear mobile-first visibility %>
<div class="hidden md:block">
  Hidden on mobile, visible on md+
</div>
```

## 4. Testing

### Responsive Layout Tests

```ruby
# test/system/responsive_layout_test.rb
require "application_system_test_case"

class ResponsiveLayoutTest < ApplicationSystemTestCase
  test "navigation collapses on mobile" do
    sign_in users(:runner)

    # Mobile viewport
    page.driver.browser.manage.window.resize_to(375, 812)
    visit root_path

    # Desktop nav should be hidden
    assert_no_selector "nav.hidden.md\\:flex", visible: true

    # Mobile menu toggle should be visible
    assert_selector "[aria-label='Open menu']", visible: true
  end

  test "activity cards stack on mobile and grid on desktop" do
    sign_in users(:runner)
    visit plan_path(plans(:marathon))

    # Mobile: single column
    page.driver.browser.manage.window.resize_to(375, 812)
    # Cards should fill the width
    cards = all(".card")
    assert cards.any?

    # Desktop: grid layout
    page.driver.browser.manage.window.resize_to(1280, 800)
    visit plan_path(plans(:marathon))
    assert_selector ".grid"
  end
end
```

### Color Contrast and Accessibility

```ruby
# test/system/accessibility_styling_test.rb
require "application_system_test_case"

class AccessibilityStylingTest < ApplicationSystemTestCase
  test "buttons have visible focus indicators" do
    sign_in users(:runner)
    visit new_plan_path

    # Tab to the submit button
    find("body").send_keys(:tab)

    # Active element should have focus ring
    active = page.evaluate_script("document.activeElement.tagName")
    assert active.present?
  end

  test "text meets minimum contrast requirements" do
    sign_in users(:runner)
    visit root_path

    # Primary text should use high-contrast classes
    assert_no_selector "p.text-slate-300", visible: true
    assert_no_selector "p.text-slate-200", visible: true
  end

  test "interactive elements have hover and focus states" do
    sign_in users(:runner)
    visit plans_path

    # Buttons should have cursor-pointer
    buttons = all("button.btn-primary, a.btn-primary")
    buttons.each do |btn|
      assert_includes btn[:class], "cursor-pointer" if btn[:class].include?("btn")
    end
  end

  test "alerts have proper ARIA roles" do
    sign_in users(:runner)
    visit new_plan_path

    # Submit invalid form to trigger error
    click_button "Create Plan"

    # Error messages should have role="alert"
    assert_selector "[role='alert']"
  end
end
```

### Design System Consistency

```ruby
# test/system/design_system_test.rb
require "application_system_test_case"

class DesignSystemTest < ApplicationSystemTestCase
  test "cards use design system classes" do
    sign_in users(:runner)
    visit plans_path

    # Cards should use the .card class, not ad-hoc styles
    cards = all(".card")
    assert cards.any?, "Expected .card class usage on plan cards"
  end

  test "badges render with correct variant classes" do
    sign_in users(:runner)
    visit plan_path(plans(:marathon))

    # At least one badge variant should be present
    badge_classes = %w[badge-neutral badge-accent badge-warning badge-danger]
    has_badge = badge_classes.any? { |cls| page.has_css?(".#{cls}") }
    assert has_badge, "Expected at least one badge variant on the page"
  end
end
```

## 5. Lace Design System Reference

Lace defines reusable component classes in `app/assets/stylesheets/application.tailwind.css`. Always prefer these over raw utilities for consistency.

| Category   | Classes                                                                 |
|------------|-------------------------------------------------------------------------|
| Layout     | `.app-container`, `.app-container-wide`, `.app-container-form`          |
| Spacing    | `.stack-xs`, `.stack-sm`, `.stack-md`, `.stack-lg`                      |
| Typography | `.heading-page`, `.heading-section`, `.text-label`, `.text-muted`       |
| Cards      | `.card`, `.card-section`, `.card-header`, `.card-title`, `.card-accent-top` |
| Metrics    | `.metric`, `.metric-label`, `.metric-value`                             |
| Buttons    | `.btn-primary`, `.btn-secondary`, `.btn-soft`, `.btn-outline`, `.btn-danger`, `.btn-ghost`, `.btn-nav` |
| Badges     | `.badge-neutral`, `.badge-accent`, `.badge-warning`, `.badge-danger`    |
| Forms      | `.form-field`, `.form-label`, `.form-input`, `.form-textarea`           |
| Accents    | `.accent-chip`, `.accent-chip-alt`, `.mono-kicker`, `.heading-bracket`  |
| Decorative | `.pixel-frame`, `.dot-grid`, `.subtle-panel`, `.heading-decor`          |
| Dividers   | `.divider`                                                              |
| Nav        | `.app-nav`, `.nav-bar`, `.nav-pill`, `.nav-pill-active`                 |
| Animation  | `.fade-in`                                                              |

## 6. Resources

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Tailwind CSS Cheat Sheet](https://tailwindcomponents.com/cheatsheet/)
- [Tailwind CSS Forms Plugin](https://github.com/tailwindlabs/tailwindcss-forms)
- [Tailwind CSS Typography Plugin](https://github.com/tailwindlabs/tailwindcss-typography)
- [Tailwind CSS Container Queries Plugin](https://github.com/tailwindlabs/tailwindcss-container-queries)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Heroicons (Tailwind-compatible SVG icons)](https://heroicons.com/)
- [Tailwind UI Patterns](https://tailwindui.com/) (design inspiration)
- [HTML `<dialog>` Element (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog)

<related-skills>
- **views** — Partials, helpers, forms, nested forms, accessibility (WCAG 2.1 AA)
- **controllers** — Controller patterns, strong parameters, before_action filters
- **models** — Validations, associations, scopes, callbacks
</related-skills>
