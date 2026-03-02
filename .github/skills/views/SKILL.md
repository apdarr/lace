---
name: views
description: Use when building Rails view structure - partials, helpers, forms, nested forms, accessibility (WCAG 2.1 AA)
---

# Rails Views

Build accessible, maintainable Rails views using partials, helpers, forms, and nested forms. Ensure WCAG 2.1 AA accessibility compliance in all view patterns.

<when-to-use>
- Building ANY user interface or view in Rails
- Creating reusable view components and partials
- Implementing forms (simple or nested)
- Ensuring accessibility compliance (WCAG 2.1 AA)
- Organizing view logic with helpers
- Managing layouts and content blocks
</when-to-use>

<benefits>
- **DRY Views** - Reusable partials and helpers reduce duplication
- **Accessibility** - WCAG 2.1 AA compliance built-in
- **Maintainability** - Clear separation of concerns and organized code
- **Testability** - Partials and helpers are easy to test
- **Flexibility** - Nested forms handle complex relationships elegantly
</benefits>

<standards>
- ALWAYS ensure WCAG 2.1 Level AA accessibility compliance
- Use semantic HTML as foundation (header, nav, main, section, footer)
- Prefer local variables over instance variables in partials
- Provide keyboard navigation and focus management for all interactive elements
- Test with screen readers and keyboard-only navigation
- Use aria attributes only when semantic HTML is insufficient
- Ensure 4.5:1 color contrast ratio for text
- Thread accessibility through all patterns
- Use form helpers to generate accessible forms with proper labels
- Use ERB templates with Tailwind CSS utility classes for styling
- Leverage Hotwire (Turbo Frames, Turbo Streams, Stimulus) for interactivity
</standards>

<verification-checklist>
Before completing view work:
- ✅ WCAG 2.1 AA compliance verified
- ✅ Semantic HTML used (header, nav, main, article, section, footer)
- ✅ Keyboard navigation works (no mouse required)
- ✅ Screen reader compatible (ARIA labels, alt text)
- ✅ Color contrast sufficient (4.5:1 for text)
- ✅ Forms have proper labels and error messages
- ✅ All interactive elements accessible
</verification-checklist>

## 1. Partials & Layouts

### Simple Partial

```erb
<%# app/views/activities/_activity.html.erb %>
<%# Always use local variables, never instance variables in partials %>
<article class="rounded-lg border border-gray-200 bg-white p-4 shadow-sm" id="<%= dom_id(activity) %>">
  <h3 class="text-lg font-semibold text-gray-900"><%= activity.description %></h3>
  <p class="mt-1 text-sm text-gray-600"><%= activity.activity_type %></p>
  <span class="mt-2 inline-block rounded-full px-2 py-1 text-xs font-medium
    <%= activity.elapsed_time.present? ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800' %>">
    <%= activity.elapsed_time.present? ? "Completed" : "Pending" %>
  </span>
</article>
```

**Rendering a single partial:**

```erb
<%# Explicit local variable passing %>
<%= render partial: "activities/activity", locals: { activity: @activity } %>

<%# Shorthand (Rails infers partial name from model) %>
<%= render @activity %>
```

### Collection Rendering

```erb
<%# Automatic collection rendering with counter %>
<%# Rails passes activity_counter (0-indexed) automatically %>
<%= render partial: "activities/activity",
           collection: @activities,
           locals: { show_actions: true } %>

<%# With spacer template between items %>
<%= render partial: "activities/activity",
           collection: @activities,
           spacer_template: "shared/divider" %>
```

Using the counter inside the partial:

```erb
<%# app/views/activities/_activity.html.erb %>
<article class="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
  <span class="text-xs text-gray-400">Activity #<%= activity_counter + 1 %></span>
  <h3 class="text-lg font-semibold text-gray-900"><%= activity.description %></h3>
</article>
```

### Content-For Layout Pattern

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="en">
<head>
  <title><%= content_for(:title) || "Lace" %></title>
  <%= yield :head %>
</head>
<body>
  <header role="banner">
    <%= render "shared/navbar" %>
  </header>

  <main id="main-content" role="main" class="container mx-auto px-4 py-8">
    <%= yield %>
  </main>

  <footer role="contentinfo">
    <%= render "shared/footer" %>
  </footer>
</body>
</html>
```

```erb
<%# app/views/plans/show.html.erb %>
<% content_for :title, @plan.name %>
<% content_for :head do %>
  <meta name="description" content="<%= @plan.description %>">
<% end %>

<section aria-labelledby="plan-heading">
  <h1 id="plan-heading"><%= @plan.name %></h1>
  <%# ... %>
</section>
```

### Anti-Pattern: Instance Variables in Partials

```erb
<%# ❌ BAD - Partial depends on controller instance variable %>
<%# app/views/activities/_activity.html.erb %>
<article>
  <h3><%= @activity.description %></h3>  <%# Breaks if rendered from different controller %>
  <p>Plan: <%= @plan.name %></p>  <%# Implicit dependency, hard to track %>
</article>

<%# ✅ GOOD - Explicit local variables %>
<%# app/views/activities/_activity.html.erb %>
<article>
  <h3><%= activity.description %></h3>
  <p>Plan: <%= plan.name %></p>
</article>

<%# Render with explicit locals %>
<%= render "activities/activity", activity: @activity, plan: @plan %>
```

## 2. View Helpers

### Status Badge Helper

```ruby
# app/helpers/activities_helper.rb
module ActivitiesHelper
  def status_badge(status)
    config = {
      "completed" => { bg: "bg-green-100", text: "text-green-800", label: "Completed" },
      "in_progress" => { bg: "bg-blue-100", text: "text-blue-800", label: "In Progress" },
      "pending" => { bg: "bg-yellow-100", text: "text-yellow-800", label: "Pending" },
      "skipped" => { bg: "bg-red-100", text: "text-red-800", label: "Skipped" }
    }

    cfg = config.fetch(status.to_s, config["pending"])

    tag.span(
      cfg[:label],
      class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{cfg[:bg]} #{cfg[:text]}",
      role: "status",
      aria: { label: "Status: #{cfg[:label]}" }
    )
  end
end
```

### Text Helpers

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def format_distance(meters)
    return "—" if meters.blank?

    miles = meters / 1609.34
    if miles >= 1
      pluralize(miles.round(1), "mile")
    else
      pluralize(meters.round(0), "meter")
    end
  end

  def format_duration(seconds)
    return "—" if seconds.blank?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    if hours > 0
      format("%dh %02dm %02ds", hours, minutes, secs)
    elsif minutes > 0
      format("%dm %02ds", minutes, secs)
    else
      format("%ds", secs)
    end
  end

  def relative_date(date)
    return "—" if date.blank?

    if date.today?
      "Today"
    elsif date == Date.tomorrow
      "Tomorrow"
    elsif date == Date.yesterday
      "Yesterday"
    else
      date.strftime("%B %-d, %Y")
    end
  end
end
```

### Anti-Pattern: html_safe on User Input

```ruby
# ❌ BAD - XSS vulnerability! Never call html_safe on user input
def render_description(text)
  text.html_safe
end

# ❌ BAD - raw() is the same as html_safe
def render_description(text)
  raw(text)
end

# ✅ GOOD - Use sanitize with allowed tags
def render_description(text)
  sanitize(text, tags: %w[strong em br p ul ol li], attributes: %w[class])
end

# ✅ GOOD - Use simple_format for plain text with line breaks
def render_description(text)
  simple_format(text)
end

# ✅ GOOD - Escape by default (ERB does this automatically)
# In templates: <%= activity.description %> is auto-escaped
```

## 3. Nested Forms

### Has-Many Nested Form

**Model setup:**

```ruby
# app/models/plan.rb
class Plan < ApplicationRecord
  has_many :activities, dependent: :destroy

  accepts_nested_attributes_for :activities,
    allow_destroy: true,
    reject_if: :all_blank

  validates :race_date, presence: true
end
```

```ruby
# app/models/activity.rb
class Activity < ApplicationRecord
  belongs_to :plan, optional: true

  validates :description, presence: true
end
```

**Controller setup:**

```ruby
# app/controllers/plans_controller.rb
class PlansController < ApplicationController
  def new
    @plan = Plan.new
    @plan.activities.build
  end

  def create
    @plan = Plan.new(plan_params)

    if @plan.save
      redirect_to @plan, notice: "Plan created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @plan = Plan.find(params[:id])

    if @plan.update(plan_params)
      redirect_to @plan, notice: "Plan updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def plan_params
    params.require(:plan).permit(
      :race_date, :length, :plan_type,
      activities_attributes: [
        :id,               # Required for updating existing records
        :description,
        :distance,
        :start_date_local,
        :activity_type,
        :_destroy           # Required for allow_destroy: true
      ]
    )
  end
end
```

**View (nested form):**

```erb
<%# app/views/plans/_form.html.erb %>
<%= form_with(model: plan, class: "space-y-6") do |f| %>
  <% if plan.errors.any? %>
    <div role="alert" class="rounded-md bg-red-50 p-4">
      <h2 class="text-sm font-medium text-red-800">
        <%= pluralize(plan.errors.count, "error") %> prevented this plan from being saved:
      </h2>
      <ul class="mt-2 list-disc pl-5 text-sm text-red-700">
        <% plan.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name, class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :name,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
        required: true,
        aria: { describedby: plan.errors[:name].any? ? "name-error" : nil } %>
    <% if plan.errors[:name].any? %>
      <p id="name-error" class="mt-1 text-sm text-red-600" role="alert">
        <%= plan.errors[:name].to_sentence %>
      </p>
    <% end %>
  </div>

  <div>
    <%= f.label :race_date, class: "block text-sm font-medium text-gray-700" %>
    <%= f.date_field :race_date,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
        required: true %>
  </div>

  <fieldset class="space-y-4">
    <legend class="text-lg font-medium text-gray-900">Activities</legend>

    <%= f.fields_for :activities do |wf| %>
      <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 space-y-3">
        <div>
          <%= wf.label :description, class: "block text-sm font-medium text-gray-700" %>
          <%= wf.text_field :description,
              class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              required: true %>
        </div>

        <div>
          <%= wf.label :start_date_local, class: "block text-sm font-medium text-gray-700" %>
          <%= wf.date_field :start_date_local,
              class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" %>
        </div>

        <div>
          <%= wf.label :distance, class: "block text-sm font-medium text-gray-700" %>
          <%= wf.number_field :distance,
              step: 0.1,
              class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" %>
        </div>

        <div>
          <%= wf.check_box :_destroy,
              class: "rounded border-gray-300 text-indigo-600 focus:ring-indigo-500",
              aria: { label: "Remove this activity" } %>
          <%= wf.label :_destroy, "Remove activity", class: "ml-2 text-sm text-red-600" %>
        </div>
      </div>
    <% end %>
  </fieldset>

  <div class="flex justify-end gap-3">
    <%= link_to "Cancel", plans_path,
        class: "rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
    <%= f.submit class: "rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" %>
  </div>
<% end %>
```

### Anti-Pattern: Missing :id in Strong Parameters

```ruby
# ❌ BAD - Missing :id means Rails creates new records instead of updating
def plan_params
  params.require(:plan).permit(
    :race_date,
    activities_attributes: [:description, :distance, :start_date_local, :activity_type, :_destroy]
    # Missing :id! Every save creates duplicate activities
  )
end

# ✅ GOOD - Include :id to allow updates to existing nested records
def plan_params
  params.require(:plan).permit(
    :race_date,
    activities_attributes: [:id, :description, :distance, :start_date_local, :activity_type, :_destroy]
  )
end
```

## 4. Accessibility / WCAG 2.1 AA

### Semantic HTML & ARIA

#### Semantic Structure

```erb
<%# Use semantic elements as the foundation — they provide built-in accessibility %>
<header role="banner">
  <nav aria-label="Main navigation">
    <ul>
      <li><%= link_to "Dashboard", root_path %></li>
      <li><%= link_to "My Plans", plans_path %></li>
      <li><%= link_to "Activities", activities_path %></li>
    </ul>
  </nav>
</header>

<main id="main-content" role="main">
  <article aria-labelledby="plan-title">
    <h1 id="plan-title"><%= @plan.name %></h1>

    <section aria-labelledby="activities-heading">
      <h2 id="activities-heading">Activities</h2>
      <%= render partial: "activities/activity", collection: @plan.activities %>
    </section>

    <aside aria-labelledby="stats-heading">
      <h2 id="stats-heading">Training Stats</h2>
      <%# Sidebar content %>
    </aside>
  </article>
</main>

<footer role="contentinfo">
  <p>&copy; <%= Date.current.year %> Lace</p>
</footer>
```

#### ARIA Labels

```erb
<%# Add ARIA labels when semantic HTML alone isn't descriptive enough %>

<%# Navigation with multiple nav elements — use aria-label to differentiate %>
<nav aria-label="Main navigation"><%# Primary nav %></nav>
<nav aria-label="Breadcrumb" aria-current="page"><%# Breadcrumb %></nav>
<nav aria-label="Pagination"><%# Pagination %></nav>

<%# Icon-only buttons MUST have accessible names %>
<button type="button"
        aria-label="Delete activity"
        class="rounded-md p-2 text-gray-400 hover:text-red-600 focus:outline-none focus:ring-2 focus:ring-red-500">
  <svg class="h-5 w-5" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20">
    <%# trash icon SVG path %>
  </svg>
</button>

<%# Expandable sections %>
<button type="button"
        aria-expanded="false"
        aria-controls="activity-details-<%= activity.id %>"
        class="flex items-center gap-2 text-sm font-medium text-gray-700">
  Activity Details
  <svg class="h-4 w-4 transition-transform" aria-hidden="true"><%# chevron %></svg>
</button>
<div id="activity-details-<%= activity.id %>" hidden>
  <%= activity.description %>
</div>
```

#### ARIA Live Regions

```erb
<%# Live regions announce dynamic content changes to screen readers %>

<%# Flash messages — polite announcement %>
<div aria-live="polite" aria-atomic="true" class="fixed top-4 right-4 z-50">
  <% flash.each do |type, message| %>
    <div role="status" class="rounded-md p-4 shadow-lg
      <%= type == 'notice' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800' %>">
      <%= message %>
    </div>
  <% end %>
</div>

<%# Search results count — updates dynamically %>
<div aria-live="polite" aria-atomic="true">
  <p class="text-sm text-gray-600">
    <%= pluralize(@activities.count, "activity") %> found
  </p>
</div>

<%# Loading states %>
<div aria-live="assertive" aria-busy="true" class="flex items-center gap-2">
  <svg class="h-5 w-5 animate-spin text-indigo-600" aria-hidden="true"><%# spinner %></svg>
  <span>Loading activities...</span>
</div>
```

### Keyboard Navigation

```erb
<%# Ensure all interactive elements are keyboard-accessible %>

<%# Skip link — MUST be first focusable element %>
<a href="#main-content"
   class="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:rounded-md focus:bg-white focus:px-4 focus:py-2 focus:text-sm focus:font-medium focus:text-indigo-600 focus:shadow-lg">
  Skip to main content
</a>

<%# Keyboard-accessible dropdown menu (Stimulus controller) %>
<div data-controller="dropdown"
     data-action="keydown.escape->dropdown#close">
  <button type="button"
          data-dropdown-target="trigger"
          data-action="click->dropdown#toggle keydown.down->dropdown#open"
          aria-expanded="false"
          aria-haspopup="true"
          class="rounded-md bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500">
    Options
  </button>

  <div data-dropdown-target="menu"
       role="menu"
       hidden
       class="absolute mt-2 w-48 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5">
    <a href="#" role="menuitem" tabindex="-1"
       data-action="keydown.up->dropdown#prevItem keydown.down->dropdown#nextItem"
       class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none">
      Edit
    </a>
    <a href="#" role="menuitem" tabindex="-1"
       data-action="keydown.up->dropdown#prevItem keydown.down->dropdown#nextItem"
       class="block px-4 py-2 text-sm text-red-600 hover:bg-gray-100 focus:bg-gray-100 focus:outline-none">
      Delete
    </a>
  </div>
</div>

<%# Focus trap for modals (Stimulus controller) %>
<dialog data-controller="modal"
        data-action="keydown.escape->modal#close"
        aria-labelledby="modal-title"
        class="rounded-lg bg-white p-6 shadow-xl backdrop:bg-gray-900/50">
  <h2 id="modal-title" class="text-lg font-semibold text-gray-900">Confirm Delete</h2>
  <p class="mt-2 text-sm text-gray-600">Are you sure you want to delete this activity?</p>

  <div class="mt-4 flex justify-end gap-3">
    <button type="button"
            data-action="click->modal#close"
            class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500">
      Cancel
    </button>
    <button type="button"
            data-action="click->modal#confirm"
            class="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500">
      Delete
    </button>
  </div>
</dialog>
```

### Accessible Forms

```erb
<%# Every input MUST have a visible label — never rely on placeholder alone %>

<%= form_with(model: @activity, class: "space-y-6") do |f| %>
  <%# Text field with label, help text, and error message %>
  <div>
    <%= f.label :description, class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :description,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
        required: true,
        aria: {
          describedby: [
            ("description-help" if @activity.new_record?),
            ("description-error" if @activity.errors[:description].any?)
          ].compact.join(" ").presence
        } %>
    <% if @activity.new_record? %>
      <p id="description-help" class="mt-1 text-sm text-gray-500">
        E.g., "Easy 5 mile run" or "Tempo Intervals"
      </p>
    <% end %>
    <% if @activity.errors[:description].any? %>
      <p id="description-error" class="mt-1 text-sm text-red-600" role="alert">
        <%= @activity.errors[:description].to_sentence %>
      </p>
    <% end %>
  </div>

  <%# Select field with label %>
  <div>
    <%= f.label :activity_type, class: "block text-sm font-medium text-gray-700" %>
    <%= f.select :activity_type,
        options_for_select(%w[run ride swim hike walk].map { |t| [t.titleize, t] }, f.object.activity_type),
        { include_blank: "Select a type" },
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
        aria: { describedby: @activity.errors[:activity_type].any? ? "type-error" : nil } %>
    <% if @activity.errors[:activity_type].any? %>
      <p id="type-error" class="mt-1 text-sm text-red-600" role="alert">
        <%= @activity.errors[:activity_type].to_sentence %>
      </p>
    <% end %>
  </div>

  <%# Date field %>
  <div>
    <%= f.label :start_date_local, class: "block text-sm font-medium text-gray-700" %>
    <%= f.date_field :start_date_local,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" %>
  </div>

  <%# Distance field %>
  <div>
    <%= f.label :distance, class: "block text-sm font-medium text-gray-700" %>
    <%= f.number_field :distance,
        step: 0.1,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" %>
  </div>

  <div>
    <%= f.submit class: "rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 cursor-pointer" %>
  </div>
<% end %>
```

### Color Contrast & Images

```erb
<%# Ensure 4.5:1 contrast ratio for normal text, 3:1 for large text %>

<%# ❌ BAD - Low contrast text %>
<p class="text-gray-300">This text on white fails contrast requirements</p>

<%# ✅ GOOD - Sufficient contrast (gray-600 on white = ~5.7:1) %>
<p class="text-gray-600">This text passes WCAG AA contrast requirements</p>

<%# ✅ GOOD - High contrast for important content %>
<p class="text-gray-900">Primary content with strong contrast</p>

<%# Don't convey meaning through color alone — add text/icons %>
<%# ❌ BAD - Color only %>
<span class="text-red-600">●</span>

<%# ✅ GOOD - Color + text %>
<span class="text-red-600">● Overdue</span>

<%# Images MUST have alt text (or empty alt for decorative) %>
<%= image_tag "activity-placeholder.svg",
    alt: "#{activity.description} - #{activity.activity_type}",
    class: "h-48 w-full rounded-lg object-cover" %>

<%# Decorative images: empty alt to hide from screen readers %>
<%= image_tag "decorative-divider.svg", alt: "", role: "presentation" %>

<%# Complex images: use aria-describedby for detailed description %>
<figure>
  <%= image_tag "training-progress-chart.png",
      alt: "Training progress chart",
      aria: { describedby: "chart-description" } %>
  <figcaption id="chart-description">
    Weekly mileage increased from 20 to 45 miles over 12 weeks,
    with a peak of 50 miles in week 10 before a taper period.
  </figcaption>
</figure>
```

### Anti-Pattern: Placeholder as Label

```erb
<%# ❌ BAD - Placeholder is NOT a label %>
<%# Problems: disappears on input, low contrast, no screen reader label %>
<input type="text" placeholder="Enter activity description"
       class="block w-full rounded-md border-gray-300 shadow-sm">

<%# ❌ BAD - Hidden label with placeholder doing double duty %>
<label class="hidden" for="title">Title</label>
<input type="text" id="title" placeholder="Title"
       class="block w-full rounded-md border-gray-300 shadow-sm">

<%# ✅ GOOD - Visible label with optional placeholder as hint %>
<div>
  <label for="description" class="block text-sm font-medium text-gray-700">
    Description
  </label>
  <input type="text" id="description" name="activity[description]"
         placeholder="e.g., Easy 5 mile run"
         class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">
</div>

<%# ✅ BEST - Using Rails form helpers (generates label + input with matching IDs) %>
<%= form_with(model: @activity) do |f| %>
  <div>
    <%= f.label :description, "Description",
        class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :description,
        placeholder: "e.g., Easy 5 mile run",
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" %>
  </div>
<% end %>
```

## 5. Testing

```ruby
# test/helpers/activities_helper_test.rb
require "test_helper"

class ActivitiesHelperTest < ActionView::TestCase
  test "status_badge renders correct badge for completed" do
    result = status_badge("completed")
    assert_includes result, "Completed"
    assert_includes result, "bg-green-100"
    assert_includes result, 'role="status"'
  end

  test "status_badge renders pending badge for unknown status" do
    result = status_badge("unknown")
    assert_includes result, "Pending"
  end
end

# test/helpers/application_helper_test.rb
require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "format_distance converts meters to miles" do
    assert_equal "3.1 miles", format_distance(5000)
  end

  test "format_distance returns dash for nil" do
    assert_equal "—", format_distance(nil)
  end

  test "format_duration formats seconds to readable time" do
    assert_equal "1h 05m 30s", format_duration(3930)
  end

  test "relative_date returns Today for current date" do
    assert_equal "Today", relative_date(Date.current)
  end
end
```

```ruby
# test/system/accessibility_test.rb
require "application_system_test_case"

class AccessibilityTest < ApplicationSystemTestCase
  test "plan form has proper labels and ARIA attributes" do
    sign_in users(:runner)
    visit new_plan_path

    # Every input should have an associated label
    assert_selector "label[for]"

    # Required fields should be marked
    assert_selector "input[required]"

    # Error messages should have role='alert'
    fill_in "Name", with: ""
    click_button "Create Plan"
    assert_selector "[role='alert']"
  end

  test "keyboard navigation works on main layout" do
    sign_in users(:runner)
    visit root_path

    # Skip link should be present
    assert_selector "a[href='#main-content']", visible: :all

    # Main content landmark exists
    assert_selector "main#main-content"
  end
end
```

## 6. Resources

- [Rails Layouts and Rendering Guide](https://guides.rubyonrails.org/layouts_and_rendering.html)
- [Rails Form Helpers Guide](https://guides.rubyonrails.org/form_helpers.html)
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/?currentsidebar=%23col_overview&levels=aaa)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [Rails Accessibility Patterns](https://www.a11yproject.com/)
- [Hotwire Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

<related-skills>
- **hotwire** - Turbo Frames, Turbo Streams, and Stimulus for interactive UI
- **styling** - Tailwind CSS utility classes and design system patterns
- **controllers** - Controller patterns, strong parameters, and before_action filters
- **testing** - Minitest patterns, system tests, and VCR for HTTP recording
</related-skills>
