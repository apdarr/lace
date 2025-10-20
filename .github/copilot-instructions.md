# The Big Picture

This is a Ruby on Rails application, using Hotwire for front-end interactivity. The app is intended to be a training companion for runners as they follow a training plan for a race. Here's how the app works currently: 

## Current State of Lace

- Users sign in and sign up through Strava OAuth. 
- Once signed in, users can create a training plan by: 
  - Setting a future race date. 
  - Desired length of plan. 
  - Upload photos of their training plan. For example, if their training plan came from a book, they'd simply take a photo of the plan and upload it to the app. 
  - The app will then use OpenAI with `gpt-5-mini` and vision capabilities to parse the workouts and automatically add dates and details to each workout.
  - Users can then drag and drop workouts to different dates if they need to adjust their plan.
  - Users can edit workouts details. 
- Users can also import their Strava activities in one giant import. 
  - Athletes can then search through past import activities using semantic search.

## Future State and Plans

- Instead of importing all Strava activities, we rely on a webhook to automatically sync new activities as they are created on Strava.
  - The app will attempt to match new Strava activities to existing workouts in the user's plan based on date, distance, and description in the activity and the Strava activity. 
  - Users can link unmatched activities to existing workouts in their plan. They can also unlink matched activities.
- Calendar integration with Google Calendar. When the plan creates, users can chose to sync their plan to Google Calendar, to a particular calendar they've created (i.e. if they have a shared calendar with their spouse).
  - Moving a date in Lace will update the event in Google Calendar.
- UI polish and improvements. 
  - More responsive design for mobile users.
    - The viewport will adjust based on screen size. Right now the viewport "jumps" as users scroll left and right on smaller screens.
  - Better responsiveness.
  - Improved accessibility.
- Profiles
  - Users can set past races. On their profile screen, they'll have "badges". Most likely these badges will be stylized Tailwind circle icon, hopefully with some animation and / or gradient effect that roughly matches the color scheme of the race's logo. 
    - Maybe there's a way to intellligently pull race's color schemes from their websites. 
  - Eventually, investigate exploring social features, where users can share training plans with each others, follow each other, finding others running the same race and goal times, etc. 

# Ruby on Rails Coding Conventions and Guidelines

## General Guidelines

- Follow the RuboCop Style Guide and use tools like `rubocop`, `standardrb`, or `rufo` for consistent formatting.
- Use snake_case for variables/methods and CamelCase for classes/modules.
- Keep methods short and focused; use early returns, guard clauses, and private methods to reduce complexity.
- Favor meaningful names over short or generic ones.
- Comment only when necessary — avoid explaining the obvious.
- Apply the Single Responsibility Principle to classes, methods, and modules.
- Prefer composition over inheritance; extract reusable logic into modules or services.
- Keep controllers thin — move business logic into models, services, or command/query objects.
- Apply the “fat model, skinny controller” pattern thoughtfully and with clean abstractions.
- Extract business logic into service objects for reusability and testability.
- Use partials or view components to reduce duplication and simplify views.
- Use `unless` for negative conditions, but avoid it with `else` for clarity.
- Avoid deeply nested conditionals — favor guard clauses and method extractions.
- Use safe navigation (`&.`) instead of multiple `nil` checks.
- Prefer `.present?`, `.blank?`, and `.any?` over manual nil/empty checks.
- Follow RESTful conventions in routing and controller actions.
- Use Rails generators to scaffold resources consistently.
- Use strong parameters to whitelist attributes securely.
- Prefer enums and typed attributes for better model clarity and validations.
- Keep migrations database-agnostic; avoid raw SQL when possible.
- Always add indexes for foreign keys and frequently queried columns.
- Define `null: false` and `unique: true` at the DB level, not just in models.
- Use `find_each` for iterating over large datasets to reduce memory usage.
- Scope queries in models or use query objects for clarity and reuse.
- Use `before_action` callbacks sparingly — avoid business logic in them.
- Use `Rails.cache` to store expensive computations or frequently accessed data.
- Construct file paths with `Rails.root.join(...)` instead of hardcoding.
- Use `class_name` and `foreign_key` in associations for explicit relationships.
- Keep secrets and config out of the codebase using `Rails.application.credentials`.
- Write isolated unit tests for models, services, and helpers.
- Cover end-to-end logic with request/system tests.
- Use background jobs (ActiveJob) for non-blocking operations like sending emails or calling APIs.
- Use fixtures (Minitest) to set up test data cleanly.
- Avoid using `puts` — debug with the `debug` gem, or logger utilities.

## Commands

- Use `rails generate` to create new models, controllers, and migrations.
- Use `rails db:migrate` to apply database migrations.
- Use `rails db:seed` to populate the database with initial data.
- Use `rails db:rollback` to revert the last migration.
- Use `rails console` to interact with the Rails application in a REPL environment.
- Use `rails server` to start the development server.
- Use `rails test` to run the test suite.
- Use `rails routes` to list all defined routes in the application.
- Use `rails assets:precompile` to compile assets for production.


## API Development Best Practices

- Structure routes using Rails' `resources` to follow RESTful conventions.
- Use `before_action` filters to load and authorize resources, not business logic.
- Leverage pagination (e.g., `kaminari` or `pagy`) for endpoints returning large datasets.
- Sanitize and whitelist input parameters using strong parameters.
- Use custom serializers or presenters to decouple internal logic from response formatting.
- Avoid N+1 queries by using `includes` when eager loading related data.
- Implement background jobs for non-blocking tasks like sending emails or syncing with external APIs.
- Log request/response metadata for debugging, observability, and auditing.
- Ensure sensitive data is never exposed in API responses or error messages.

## Frontend Development Best Practices

- Use `app/javascript` as the main directory for managing JavaScript packs, modules, and frontend logic in Rails 6+ with Webpacker or esbuild.
- Structure your JavaScript by components or domains, not by file types, to keep things modular.
- Leverage Hotwire (Turbo + Stimulus) for real-time updates and minimal JavaScript in Rails-native apps.
- Use Stimulus controllers for binding behavior to HTML and managing UI logic declaratively.
- Organize styles using SCSS modules, Tailwind, or BEM conventions under `app/assets/stylesheets`.
- Keep view logic clean by extracting repetitive markup into partials or components.
- Use semantic HTML tags and follow accessibility (a11y) best practices across all views.
- Avoid inline JavaScript and styles; instead, move logic to separate `.js` or `.scss` files for clarity and reusability.
- Optimize assets (images, fonts, icons) using the asset pipeline or bundlers for caching and compression.
- Use `data-*` attributes to bridge frontend interactivity with Rails-generated HTML and Stimulus.
- Test frontend functionality using system tests (Capybara) or integration tests with tools like Cypress or Playwright.
- Use environment-specific asset loading to prevent unnecessary scripts or styles in production.
- Follow a design system or component library to keep UI consistent and scalable.
- Optimize time-to-first-paint (TTFP) and asset loading using lazy loading, Turbo Frames, and deferring JS.

## Testing Guidelines

- The app uses Minitest, NOT RSpec.
- Write unit tests for models using `test/models` (Minitest) to validate business logic.
- Use fixtures (Minitest) to manage test data cleanly and consistently.
- Organize controller specs under `test/controllers` to test RESTful API behavior.
- Use `setup` in Minitest to initialize common test data.
- Avoid hitting external APIs in tests — use `VCR` generally to record and replay HTTP interactions.
- Follow VCR best practices instead of creating custom mocks
- Use `system tests` in Minitest to simulate full user flows.
- Isolate slow and expensive tests (e.g., external services, file uploads) into separate test types or tags.
- Run test coverage tools like `SimpleCov` to ensure adequate code coverage.
- Avoid `sleep` in tests; use `perform_enqueued_jobs` (Minitest).
- Use database cleaning tools (`rails test:prepare`, `DatabaseCleaner`, or `transactional_fixtures`) to maintain clean state between tests.
- Test background jobs by enqueuing and performing jobs using `ActiveJob::TestHelper` or `have_enqueued_job` matchers.
- Ensure tests run consistently across environments using CI tools (e.g., GitHub Actions, CircleCI).
- Tag tests by type (e.g., `:model`, `:request`, `:feature`) for faster and targeted test runs.
- Avoid brittle tests — don’t rely on specific timestamps, randomized data, or order unless explicitly necessary.
- Write integration tests for end-to-end flows across multiple layers (model, view, controller).
- Keep tests fast, reliable, and as DRY as production code.