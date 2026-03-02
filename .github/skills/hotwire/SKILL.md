---
name: hotwire
description: Use when adding interactivity to Rails views - Hotwire Turbo (Drive, Frames, Streams, Morph) and Stimulus controllers
---

# Hotwire (Turbo + Stimulus)

Build fast, interactive, SPA-like experiences using server-rendered HTML with Hotwire. Turbo provides navigation and real-time updates without writing JavaScript. Stimulus enhances HTML with lightweight JavaScript controllers.

Lace uses Importmap (not esbuild/webpack) and SortableJS for drag-and-drop activity reordering.

<related-skills>
- `controllers` — Rails controller conventions and patterns
</related-skills>

<when-to-use>
- Adding interactivity without heavy JavaScript frameworks
- Building real-time, SPA-like experiences with server-rendered HTML
- Implementing live updates, infinite scroll, or dynamic content
- Creating modals, inline editing, or interactive UI components
- Replacing traditional AJAX with modern, declarative patterns
- Adding drag-and-drop with SortableJS + Stimulus
</when-to-use>

<benefits>
- **SPA-Like Speed** — Turbo Drive accelerates navigation without full page reloads
- **Real-time Updates** — Turbo Streams deliver live changes via ActionCable
- **Progressive Enhancement** — Works without JavaScript, enhanced with it
- **Simpler Architecture** — Server-rendered HTML reduces client-side complexity
- **Turbo Morph** — Intelligent DOM updates preserve scroll, focus, form state
- **Less JavaScript** — Stimulus provides just enough JS for interactivity
</benefits>

<standards>
- Prefer Turbo Morph over Turbo Frames for general CRUD operations
- Use Turbo Frames ONLY for: modals, inline editing, tabs, pagination, lazy loading
- Ensure progressive enhancement (works without JavaScript)
- Use Turbo Drive for automatic page acceleration
- Use Turbo Streams for real-time updates via ActionCable
- Use Stimulus for client-side interactions (dropdowns, character counters, dynamic forms)
- Always clean up in Stimulus `disconnect()` to prevent memory leaks (clear intervals, remove listeners, destroy library instances)
- Test with JavaScript disabled to verify progressive enhancement
- Use Importmap for JS dependency management — pin packages in `config/importmap.rb`
- Prefer `data-*` attributes to bridge Rails HTML with Stimulus controllers
- Use `data-turbo-track: "reload"` on stylesheet and script tags for cache-aware asset reloading
- Keep Stimulus controllers small and focused on a single responsibility
- Use Stimulus values and targets (not DOM queries) for controller state and element references
</standards>

<verification-checklist>
Before completing Hotwire features:
- ✅ Works without JavaScript (progressive enhancement verified)
- ✅ Turbo Morph used for CRUD operations (not Frames)
- ✅ Turbo Frames only for: modals, inline editing, pagination, tabs, lazy loading
- ✅ Stimulus controllers clean up in `disconnect()`
- ✅ All interactive features tested
- ✅ All tests passing
</verification-checklist>

---

## 1. Turbo Drive

Turbo Drive intercepts link clicks and form submissions, replacing full page reloads with fetch requests and DOM swaps. It is enabled by default when `@hotwired/turbo-rails` is imported.

### Data attributes for control

```erb
<%# Disable Turbo Drive on a specific link %>
<%= link_to "External Site", "https://example.com", data: { turbo: false } %>

<%# Disable Turbo Drive on an entire form %>
<%= form_with model: @plan, data: { turbo: false } do |f| %>
  ...
<% end %>

<%# Advance browser history (default) %>
<%= link_to "Plans", plans_path, data: { turbo_action: "advance" } %>

<%# Replace current history entry instead of pushing %>
<%= link_to "Plans", plans_path, data: { turbo_action: "replace" } %>

<%# Track assets for cache-busting reloads (used in Lace layout) %>
<%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>

<%# Prefetch links on hover for faster navigation %>
<%= link_to "Plan", plan_path(@plan), data: { turbo_prefetch: true } %>
```

---

## 2. Turbo Morphing / Page Refresh (PREFERRED for CRUD)

Turbo Morph uses idiomorph to intelligently diff and patch the DOM, preserving scroll position, focus, and form state. **This is the preferred approach for CRUD operations** — use it instead of Turbo Frames for create/update/delete flows.

### Enable morphing in your layout

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Lace" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <%# Enable morph refreshes across the entire layout %>
  <body>
    <%= turbo_refreshes_with method: :morph, scroll: :preserve %>

    <main class="flex-1 py-12 relative">
      <%= yield %>
    </main>
  </body>
</html>
```

### Controller redirects trigger morph automatically

```ruby
# app/controllers/plans_controller.rb
class PlansController < ApplicationController
  def update
    @plan = current_user.plans.find(params[:id])

    if @plan.update(plan_params)
      # Redirect triggers a morph refresh — scroll, focus, form state preserved
      redirect_to @plan, notice: "Plan updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

### Mark elements to preserve across morphs

```erb
<%# Preserve elements that should not be re-rendered during morph %>
<div data-turbo-permanent id="flash-messages">
  <%= render "shared/flash" %>
</div>

<%# Preserve a media player, map, or complex widget %>
<div data-turbo-permanent id="activity-map">
  ...
</div>
```

---

## 3. Turbo Frames

Use Turbo Frames **only** for scoped, independent UI regions: modals, inline editing, tabs, pagination, and lazy loading. Do NOT use Frames for general CRUD — use Morph instead.

### Modal pattern

```erb
<%# app/views/plans/show.html.erb %>
<%= turbo_frame_tag "plan_modal" %>

<%= link_to "Edit Plan",
    edit_plan_path(@plan),
    data: { turbo_frame: "plan_modal" } %>
```

```erb
<%# app/views/plans/edit.html.erb %>
<%= turbo_frame_tag "plan_modal" do %>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg shadow-xl p-6 max-w-lg w-full">
      <h2 class="text-lg font-semibold mb-4">Edit Plan</h2>

      <%= form_with model: @plan do |f| %>
        <%= f.text_field :name, class: "w-full border rounded px-3 py-2" %>
        <div class="mt-4 flex justify-end gap-2">
          <%= link_to "Cancel", plan_path(@plan), class: "btn-secondary" %>
          <%= f.submit "Save", class: "btn-primary" %>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

### Inline editing pattern

```erb
<%# app/views/activities/_activity.html.erb %>
<%= turbo_frame_tag dom_id(activity) do %>
  <div class="flex items-center justify-between p-2">
    <span><%= activity.description %></span>
    <%= link_to "Edit", edit_activity_path(activity), class: "text-blue-600" %>
  </div>
<% end %>
```

```erb
<%# app/views/activities/edit.html.erb %>
<%= turbo_frame_tag dom_id(@activity) do %>
  <%= form_with model: @activity do |f| %>
    <%= f.text_field :description, class: "border rounded px-2 py-1" %>
    <%= f.submit "Save", class: "btn-primary" %>
    <%= link_to "Cancel", activity_path(@activity), class: "text-gray-500" %>
  <% end %>
<% end %>
```

### Lazy loading pattern

```erb
<%# Load content lazily when the frame scrolls into view %>
<%= turbo_frame_tag "recent_activities", src: activities_path(format: :html), loading: :lazy do %>
  <div class="animate-pulse bg-gray-200 h-24 rounded"></div>
<% end %>
```

---

## 4. Turbo Streams

Turbo Streams deliver real-time, targeted DOM updates from the server — over HTTP responses or via ActionCable WebSockets.

### Model broadcasts (real-time via ActionCable)

```ruby
# app/models/activity.rb
class Activity < ApplicationRecord
  belongs_to :plan

  # Broadcast changes to all subscribers of this plan's activities
  broadcasts_to ->(activity) { [activity.plan, :activities] },
                inserts_by: :prepend
end
```

```erb
<%# app/views/plans/show.html.erb %>
<%# Subscribe to the broadcast channel %>
<%= turbo_stream_from @plan, :activities %>

<div id="activities">
  <%= render @plan.activities %>
</div>
```

### Turbo Stream responses (over HTTP)

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  def create
    @activity = @plan.activities.build(activity_params)

    respond_to do |format|
      if @activity.save
        format.turbo_stream  # renders create.turbo_stream.erb
        format.html { redirect_to @plan }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @activity = @plan.activities.find(params[:id])
    @activity.destroy

    respond_to do |format|
      format.turbo_stream  # renders destroy.turbo_stream.erb
      format.html { redirect_to @plan }
    end
  end
end
```

```erb
<%# app/views/activities/create.turbo_stream.erb %>
<%= turbo_stream.prepend "activities", @activity %>

<%# Flash message via stream %>
<%= turbo_stream.update "flash" do %>
  <div class="bg-green-100 text-green-800 px-4 py-2 rounded">
    Activity added!
  </div>
<% end %>
```

```erb
<%# app/views/activities/destroy.turbo_stream.erb %>
<%= turbo_stream.remove dom_id(@activity) %>

<%= turbo_stream.update "flash" do %>
  <div class="bg-yellow-100 text-yellow-800 px-4 py-2 rounded">
    Activity removed.
  </div>
<% end %>
```

### Custom stream actions

```ruby
# Supported stream actions:
# append, prepend, replace, update, remove, before, after

# In a controller or background job:
Turbo::StreamsChannel.broadcast_replace_to(
  [@plan, :activities],
  target: dom_id(@activity),
  partial: "activities/activity",
  locals: { activity: @activity }
)
```

---

## 5. Stimulus Controllers

Stimulus adds lightweight JavaScript behavior to server-rendered HTML. Controllers live in `app/javascript/controllers/` and are auto-loaded via Importmap and `stimulus-loading`.

### Basic controller anatomy

```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Lifecycle: called when the controller's element enters the DOM
  connect() {
    console.log("Controller connected to", this.element)
  }

  // Lifecycle: called when the controller's element leaves the DOM
  disconnect() {
    // Always clean up: clear intervals, remove listeners, destroy instances
  }
}
```

```erb
<%# Attach the controller to an element %>
<div data-controller="example">
  <p>This element has a Stimulus controller.</p>
</div>
```

### Targets — referencing child elements

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "overlay"]

  open() {
    this.dialogTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.dialogTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
  }
}
```

```erb
<div data-controller="modal">
  <button data-action="click->modal#open">Open</button>

  <div data-modal-target="overlay" class="hidden fixed inset-0 bg-black/50"></div>
  <div data-modal-target="dialog" class="hidden fixed inset-0 flex items-center justify-center">
    <div class="bg-white rounded-lg p-6">
      <p>Modal content</p>
      <button data-action="click->modal#close">Close</button>
    </div>
  </div>
</div>
```

### Values — typed reactive state

```javascript
// app/javascript/controllers/plan_processor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    planId: Number,
    status: String
  }

  connect() {
    if (this.statusValue === "queued" || this.statusValue === "processing") {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollInterval = setInterval(() => this.checkStatus(), 3000)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  async checkStatus() {
    const response = await fetch(`/plans/${this.planIdValue}/processing_status.json`)
    const data = await response.json()

    if (data.processing_status === "completed") {
      this.stopPolling()
      window.location.reload()
    }
  }
}
```

```erb
<div data-controller="plan-processor"
     data-plan-processor-plan-id-value="<%= @plan.id %>"
     data-plan-processor-status-value="<%= @plan.processing_status %>">
  <p>Processing your training plan...</p>
</div>
```

### Actions and events

```javascript
// app/javascript/controllers/activity_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    // Save with Ctrl+S / Cmd+S
    if ((event.ctrlKey || event.metaKey) && event.key === "s") {
      event.preventDefault()
      this.save()
    }
  }

  save() {
    const submitButton = this.element.querySelector('input[type="submit"]')
    if (submitButton) submitButton.click()
  }
}
```

```erb
<%# Declarative action binding in HTML %>
<div data-controller="activity-editor">
  <%= form_with model: @activity do |f| %>
    <%= f.text_field :description,
        data: { action: "input->activity-editor#suggestDescription" } %>
    <%= f.submit "Save" %>
  <% end %>
</div>

<%# Multiple actions on one element %>
<input type="text"
       data-action="focus->form#highlight blur->form#unhighlight input->form#validate">

<%# Window and document events %>
<div data-controller="sidebar"
     data-action="resize@window->sidebar#adjustLayout">
</div>
```

### Controller communication via custom events

```javascript
// app/javascript/controllers/edit_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "cell"]
  static values = { mode: Boolean }

  connect() {
    this.modeValue = false
    this.updateUI()
  }

  toggle() {
    this.modeValue = !this.modeValue
    this.updateUI()
    this.updateCells()
  }

  updateCells() {
    this.cellTargets.forEach(cell => {
      const contentDiv = cell.querySelector("[data-cell-target='content']")
      contentDiv.setAttribute("contenteditable", this.modeValue.toString())

      // Dispatch custom event so other controllers (e.g., drag) can react
      cell.dispatchEvent(new CustomEvent("editModeChanged", {
        detail: { editMode: this.modeValue },
        bubbles: true
      }))
    })
  }

  updateUI() {
    this.buttonTarget.textContent = this.modeValue
      ? "Turn Edit Mode Off"
      : "Enable Edit Mode"
    this.buttonTarget.classList.toggle("bg-yellow-100", this.modeValue)
    this.buttonTarget.classList.toggle("bg-blue-100", !this.modeValue)
  }
}
```

### SortableJS integration with Stimulus

Lace uses SortableJS (via Importmap) for drag-and-drop activity reordering:

```javascript
// app/javascript/controllers/drag_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    if (this.hasContainerTarget) {
      this.sortables = this.containerTargets.map(container =>
        this.initializeSortable(container)
      )
    }
  }

  disconnect() {
    // Clean up all SortableJS instances to prevent memory leaks
    if (this.sortables) {
      this.sortables.forEach(sortable => sortable.destroy())
      this.sortables = null
    }
  }

  initializeSortable(container) {
    return new Sortable(container, {
      group: "activities",
      animation: 150,
      draggable: '[data-drag-target="item"]',
      handle: ".cursor-grab",
      delay: 100,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      forceFallback: true,
      fallbackClass: "opacity-50",
      onStart: (evt) => {
        evt.item.classList.add("scale-105", "shadow-lg", "ring-2", "ring-blue-400")
        document.querySelectorAll('[data-drag-target="container"]').forEach(zone => {
          zone.classList.add("border-blue-300", "bg-blue-50/50")
        })
      },
      onEnd: (evt) => {
        evt.item.classList.remove("scale-105", "shadow-lg", "ring-2", "ring-blue-400")
        document.querySelectorAll('[data-drag-target="container"]').forEach(zone => {
          zone.classList.remove("border-blue-300", "bg-blue-50/50")
        })

        const newDay = evt.to.dataset.day
        const activityId = evt.item.dataset.activityId

        if (newDay && activityId) {
          const csrfToken = document.querySelector("meta[name='csrf-token']").content
          fetch(`/activities/${activityId}`, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
              "X-CSRF-Token": csrfToken,
              "Accept": "application/json"
            },
            body: JSON.stringify({ activity: { start_date_local: newDay } })
          })
        }
      }
    })
  }
}
```

```erb
<%# Drag-and-drop activity containers in a plan view %>
<div data-controller="drag">
  <% @plan.weeks.each do |week| %>
    <% week.days.each do |day| %>
      <div data-drag-target="container" data-day="<%= day.date %>">
        <% day.activities.each do |activity| %>
          <div data-drag-target="item"
               data-activity-id="<%= activity.id %>"
               class="cursor-grab">
            <%= activity.description %>
          </div>
        <% end %>
      </div>
    <% end %>
  <% end %>
</div>
```

### Cleanup in disconnect() — essential pattern

Always clean up resources in `disconnect()` to prevent memory leaks when elements leave the DOM (e.g., Turbo navigation, Turbo Frame swaps):

```javascript
// ✅ Correct: full cleanup
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)

    this.refreshInterval = setInterval(() => this.refresh(), 5000)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)

    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
      this.refreshInterval = null
    }
  }

  handleResize() { /* ... */ }
  refresh() { /* ... */ }
}
```

---

## 6. Anti-Patterns

### ❌ Using Frames everywhere instead of Morph

```erb
<%# BAD: Wrapping every CRUD view in a Turbo Frame %>
<%= turbo_frame_tag "plan_details" do %>
  <h1><%= @plan.name %></h1>
  <%= render @plan.activities %>
<% end %>
```

```erb
<%# GOOD: Use Morph for CRUD — add to layout, redirect normally %>
<%= turbo_refreshes_with method: :morph, scroll: :preserve %>
```

Frames should be reserved for **independently updatable regions** (modals, inline edits, tabs, pagination, lazy loading). For standard create/update/delete, Morph preserves more state and requires less markup.

### ❌ Not cleaning up in disconnect()

```javascript
// BAD: leaks event listeners and intervals on Turbo navigation
export default class extends Controller {
  connect() {
    window.addEventListener("resize", this.handleResize)
    this.interval = setInterval(() => this.poll(), 3000)
  }
  // Missing disconnect() — memory leak!
}
```

```javascript
// GOOD: always clean up
export default class extends Controller {
  connect() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
    this.interval = setInterval(() => this.poll(), 3000)
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  }
}
```

### ❌ Bypassing Turbo with raw fetch for updates

```javascript
// BAD: manually fetching and swapping HTML
const response = await fetch("/plans/1")
const html = await response.text()
document.getElementById("plan").innerHTML = html
```

```ruby
# GOOD: let Turbo handle the update via Streams or Morph
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@plan), @plan) }
  format.html { redirect_to @plan }
end
```

---

## 7. Resources

- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Stimulus Reference](https://stimulus.hotwired.dev/reference/controllers)
- [Turbo Rails Gem](https://github.com/hotwired/turbo-rails)
- [Hotwire Discussion Forum](https://discuss.hotwired.dev/)
- [SortableJS Documentation](https://github.com/SortableJS/Sortable)
- [Importmap for Rails](https://github.com/rails/importmap-rails)
