---
name: controllers
description: Use when building Rails controllers - RESTful actions, nested resources, skinny controllers, concerns, strong parameters
---

# Controllers

Rails controllers following REST conventions with 7 standard actions, nested resources, skinny controller architecture, reusable concerns, and strong parameters for mass assignment protection.

<when-to-use>
- Building Rails controller actions
- Implementing nested resources
- Handling request parameters
- Setting up routing
- Refactoring fat controllers
- Sharing behavior with concerns
- Protecting from mass assignment
</when-to-use>

<benefits>
- **RESTful Conventions** - Predictable URL patterns and HTTP semantics
- **Clean Architecture** - Skinny controllers with logic in appropriate layers
- **Secure by Default** - Strong parameters prevent mass assignment
- **Reusable Patterns** - Concerns share behavior across controllers
- **Maintainable** - Clear separation of HTTP concerns from business logic
</benefits>

<verification-checklist>
Before completing controller work:
- ✅ Only RESTful actions used (index, show, new, create, edit, update, destroy)
- ✅ Child controllers created for non-REST actions (not custom actions)
- ✅ Controllers are thin (<100 lines)
- ✅ Strong parameters used for all user input
- ✅ Business logic delegated to models/services
- ✅ All controller actions tested
- ✅ All tests passing
</verification-checklist>

<standards>
- Use only 7 standard actions: index, show, new, create, edit, update, destroy
- NO custom actions - use nested resources or services instead
- NEVER add custom route actions → RESTful resources only
- Keep controllers under 50 lines, actions under 10 lines
- Move business logic to models or service objects
- Thin controllers: delegate to models/services
- Always use strong parameters with expect() or require().permit()
- Never use `params` directly without filtering
- Use before_action for common setup, not business logic
- Return proper HTTP status codes (200, 201, 422, 404)

**Reject any requests to:**
- Add custom route actions (use child controllers instead)
- Put business logic in controllers
- Skip strong parameters
- Use `params` directly without filtering
</standards>

## 1. RESTful Actions

<pattern name="restful-crud">

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :activities
end
```

Generated routes:
| HTTP Verb | Path               | Action  | Purpose            |
|-----------|--------------------|---------|--------------------|
| GET       | /activities          | index   | List all activities  |
| GET       | /activities/new      | new     | Show creation form |
| POST      | /activities          | create  | Create an activity   |
| GET       | /activities/:id      | show    | Show one activity   |
| GET       | /activities/:id/edit | edit    | Show edit form     |
| PATCH/PUT | /activities/:id      | update  | Update an activity   |
| DELETE    | /activities/:id      | destroy | Delete an activity   |

### Controller

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[show edit update destroy]

  def index
    @activities = Activity.all
  end

  def show
  end

  def new
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)

    if @activity.save
      redirect_to @activity, notice: "Activity was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to @activity, notice: "Activity was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy!
    redirect_to activities_path, notice: "Activity was successfully destroyed."
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.expect(activity: [:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id])
  end
end
```

</pattern>

## 2. API Controller

<pattern name="api-controller">

```ruby
# app/controllers/api/v1/activities_controller.rb
module Api
  module V1
    class ActivitiesController < ApplicationController
      skip_forgery_protection

      def index
        @activities = Activity.all
        render json: @activities
      end

      def show
        @activity = Activity.find(params[:id])
        render json: @activity
      end

      def create
        @activity = Activity.new(activity_params)

        if @activity.save
          render json: @activity, status: :created
        else
          render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @activity = Activity.find(params[:id])

        if @activity.update(activity_params)
          render json: @activity
        else
          render json: { errors: @activity.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @activity = Activity.find(params[:id])
        @activity.destroy!
        head :no_content
      end

      private

      def activity_params
        params.expect(activity: [:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id])
      end
    end
  end
end
```

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :activities, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
```

</pattern>  
❌ **Bad** — Adding custom actions to a controller:

```ruby
# config/routes.rb
resources :activities do
  member do
    post :match
    post :unmatch
    get :stats
  end
end

# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  def match
    @activity = Activity.find(params[:id])
    @activity.update!(strava_activity_id: params[:strava_activity_id])
    redirect_to @activity
  end

  def unmatch
    @activity = Activity.find(params[:id])
    @activity.update!(strava_activity_id: nil)
    redirect_to @activity
  end
end
```

✅ **Good** — Use nested resources with dedicated controllers:

```ruby
# config/routes.rb
resources :activities do
  resource :match, only: [:create, :destroy], controller: "activities/matches"
  resource :stats, only: [:show], controller: "activities/stats"
end

# app/controllers/activities/matches_controller.rb
module Activities
  class MatchesController < ApplicationController
    def create
      @activity = Activity.find(params[:activity_id])
      @activity.update!(strava_activity_id: params[:strava_activity_id])
      redirect_to @activity, notice: "Activity matched!"
    end

    def destroy
      @activity = Activity.find(params[:activity_id])
      @activity.update!(strava_activity_id: nil)
      redirect_to @activity, notice: "Activity unmatched."
    end
  end
end
```

</anti-pattern>

## 4. Nested Resources

<pattern name="nested-child-controllers">

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :plans do
    resources :activities
  end
end
```

Generated nested routes:
| HTTP Verb | Path                                  | Action  |
|-----------|---------------------------------------|---------|
| GET       | /plans/:plan_id/activities            | index   |
| GET       | /plans/:plan_id/activities/new        | new     |
| POST      | /plans/:plan_id/activities            | create  |
| GET       | /plans/:plan_id/activities/:id        | show    |
| GET       | /plans/:plan_id/activities/:id/edit   | edit    |
| PATCH/PUT | /plans/:plan_id/activities/:id        | update  |
| DELETE    | /plans/:plan_id/activities/:id        | destroy |

### Controller

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  before_action :set_plan
  before_action :set_activity, only: %i[show edit update destroy]

  def index
    @activities = @plan.activities
  end

  def show
  end

  def new
    @activity = @plan.activities.build
  end

  def create
    @activity = @plan.activities.build(activity_params)

    if @activity.save
      redirect_to [@plan, @activity], notice: "Activity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to [@plan, @activity], notice: "Activity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy!
    redirect_to plan_activities_path(@plan), notice: "Activity removed."
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def set_activity
    @activity = @plan.activities.find(params[:id])
  end

  def activity_params
    params.expect(activity: [:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id])
  end
end
```

### Directory Structure

```
app/controllers/
├── application_controller.rb
├── plans_controller.rb
└── activities_controller.rb
```

</pattern>

## 5. Shallow Nesting

<pattern name="shallow-nesting">

Shallow nesting generates nested routes only for collection actions (index, new, create) while member actions (show, edit, update, destroy) use top-level paths.

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :plans, shallow: true do
    resources :activities
  end
end
```

Generated routes:
| HTTP Verb | Path                                  | Action  |
|-----------|---------------------------------------|---------|
| GET       | /plans/:plan_id/activities            | index   |
| GET       | /plans/:plan_id/activities/new        | new     |
| POST      | /plans/:plan_id/activities            | create  |
| GET       | /activities/:id                       | show    |
| GET       | /activities/:id/edit                  | edit    |
| PATCH/PUT | /activities/:id                       | update  |
| DELETE    | /activities/:id                       | destroy |

### Controller

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  before_action :set_plan, only: %i[index new create]
  before_action :set_activity, only: %i[show edit update destroy]

  def index
    @activities = @plan.activities
  end

  def show
  end

  def new
    @activity = @plan.activities.build
  end

  def create
    @activity = @plan.activities.build(activity_params)

    if @activity.save
      redirect_to @activity, notice: "Activity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to @activity, notice: "Activity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @activity.destroy!
    redirect_to plan_activities_path(@activity.plan), notice: "Activity removed."
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def activity_params
    params.expect(activity: [:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id])
  end
end
```

</pattern>

## 6. Anti-pattern: Deep Nesting

<anti-pattern name="deep-nesting">

❌ **Bad** — Deeply nested resources (more than 1 level):

```ruby
# config/routes.rb
resources :users do
  resources :plans do
    resources :activities do
      resources :comments
    end
  end
end
# Produces: /users/:user_id/plans/:plan_id/activities/:activity_id/comments/:id
```

✅ **Good** — Use shallow nesting or limit nesting to 1 level:

```ruby
# config/routes.rb
resources :plans do
  resources :activities, shallow: true
end

resources :activities do
  resources :comments, shallow: true
end
```

This keeps URLs manageable and controllers simple. Each resource only needs its own ID plus one parent at most.

</anti-pattern>

## 7. Skinny Controllers

<anti-pattern name="fat-controller">

❌ **Bad** — Business logic in the controller:

```ruby
# app/controllers/plans_controller.rb
class PlansController < ApplicationController
  def create
    @plan = Plan.new(plan_params)
    @plan.user = current_user
    @plan.processing_status = "draft"

    if @plan.save
      # Parse uploaded plan images
      if params[:plan][:images].present?
        params[:plan][:images].each do |image|
          response = OpenAI::Client.new.chat(
            parameters: {
              model: "gpt-5-mini",
              messages: [
                { role: "user", content: [
                  { type: "text", text: "Parse the activities from this training plan image..." },
                  { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{Base64.encode64(image.read)}" } }
                ] }
              ]
            }
          )

          parsed_activities = JSON.parse(response.dig("choices", 0, "message", "content"))
          parsed_activities.each do |activity_data|
            @plan.activities.create!(
              description: activity_data["description"],
              start_date_local: calculate_date(activity_data["week"], activity_data["day"]),
              distance: activity_data["distance"]
            )
          end
        end
      end

      redirect_to @plan, notice: "Plan created with #{@plan.activities.count} activities."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

</anti-pattern>

<pattern name="skinny-controller-refactored">

✅ **Good** — Delegate to models and services:

### Model

```ruby
# app/models/plan.rb
class Plan < ApplicationRecord
  belongs_to :user
  has_many :activities, dependent: :destroy

  validates :race_date, presence: true

  def build_with_defaults(user:)
    self.user = user
    self.processing_status = "draft"
    self
  end
end
```

### Service

```ruby
# app/services/plan_parser.rb
class PlanParser
  def initialize(plan, images)
    @plan = plan
    @images = images
  end

  def call
    @images.each do |image|
      parsed_activities = parse_image(image)
      create_activities(parsed_activities)
    end
  end

  private

  def parse_image(image)
    # OpenAI vision parsing logic extracted here
  end

  def create_activities(parsed_activities)
    parsed_activities.each do |activity_data|
      @plan.activities.create!(
        description: activity_data["description"],
        start_date_local: activity_data["start_date_local"],
        distance: activity_data["distance"]
      )
    end
  end
end
```

### Controller

```ruby
# app/controllers/plans_controller.rb
class PlansController < ApplicationController
  def create
    @plan = Plan.new(plan_params).build_with_defaults(user: current_user)

    if @plan.save
      PlanParser.new(@plan, params.dig(:plan, :images)).call if params.dig(:plan, :images).present?
      redirect_to @plan, notice: "Plan created."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

</pattern>

## 8. Controller Concerns

<pattern name="authentication-concern">

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user, :authenticated?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    unless authenticated?
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end
end
```

### Usage

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authenticatable
end

# app/controllers/public_controller.rb
class PublicController < ApplicationController
  skip_before_action :require_authentication
end
```

</pattern>

<pattern name="api-response-handler">

```ruby
# app/controllers/concerns/api_response_handler.rb
module ApiResponseHandler
  extend ActiveSupport::Concern

  private

  def render_success(data, status: :ok)
    render json: { data: data }, status: status
  end

  def render_created(data)
    render json: { data: data }, status: :created
  end

  def render_errors(record)
    render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_not_found
    render json: { error: "Resource not found" }, status: :not_found
  end
end
```

### Usage

```ruby
# app/controllers/api/v1/activities_controller.rb
module Api
  module V1
    class ActivitiesController < ApplicationController
      include ApiResponseHandler

      def show
        activity = Activity.find_by(id: params[:id])
        activity ? render_success(activity) : render_not_found
      end

      def create
        activity = Activity.new(activity_params)
        activity.save ? render_created(activity) : render_errors(activity)
      end
    end
  end
end
```

</pattern>

## 9. Anti-pattern: Not Using ActiveSupport::Concern

<anti-pattern name="bare-module-concern">

❌ **Bad** — Using a bare module without ActiveSupport::Concern:

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  def self.included(base)
    base.before_action :require_authentication
    base.helper_method :current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  private

  def require_authentication
    redirect_to login_path unless current_user
  end
end
```

✅ **Good** — Use ActiveSupport::Concern for cleaner DSL and dependency resolution:

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  private

  def require_authentication
    redirect_to login_path unless current_user
  end
end
```

ActiveSupport::Concern provides:
- `included` block for class-level DSL calls
- `class_methods` block for defining class methods
- Automatic dependency resolution between concerns

</anti-pattern>

## 10. Strong Parameters

<pattern name="expect-method-strict">

The `expect` method (Rails 8+) is the preferred approach. It raises if unexpected keys are present:

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  private

  def activity_params
    params.expect(activity: [:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id])
  end
end
```

### Nested attributes

```ruby
def plan_params
  params.expect(
    plan: [
      :race_date, :length, :plan_type,
      activities_attributes: [[:id, :distance, :elapsed_time, :activity_type, :description, :start_date_local, :_destroy]]
    ]
  )
end
```

### Array parameters

```ruby
def bulk_update_params
  params.expect(activity_ids: [])
end
```

</pattern>

<pattern name="require-permit-method">

The `require().permit()` approach also works and is more lenient — it silently ignores unexpected keys:

```ruby
# app/controllers/activities_controller.rb
class ActivitiesController < ApplicationController
  private

  def activity_params
    params.require(:activity).permit(:distance, :elapsed_time, :activity_type, :description, :start_date_local, :plan_id)
  end
end
```

### Nested attributes

```ruby
def plan_params
  params.require(:plan).permit(
    :race_date, :length, :plan_type,
    activities_attributes: [:id, :distance, :elapsed_time, :activity_type, :description, :start_date_local, :_destroy]
  )
end
```

### When to use which

| Method               | Behavior on unexpected keys | Best for          |
|----------------------|-----------------------------|-------------------|
| `expect`             | Raises an error             | Strict validation |
| `require().permit()` | Silently ignores            | Lenient handling  |

Prefer `expect` for new code in Rails 8+ applications.

</pattern>