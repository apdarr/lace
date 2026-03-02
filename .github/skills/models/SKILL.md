---
name: models
description: Use when designing Rails models - ActiveRecord patterns, validations, callbacks, scopes, associations, concerns, query objects, form objects
---

# Models

Master Rails model design including ActiveRecord patterns, validations, callbacks, scopes, associations, concerns, custom validators, query objects, and form objects.

<when-to-use>
- Designing database models and associations
- Writing validations and callbacks
- Implementing business logic in models
- Creating scopes and query methods
- Extracting complex queries to query objects
- Building form objects for multi-model operations
- Organizing shared behavior with concerns
- Creating custom validators
- Preventing N+1 queries
</when-to-use>

<benefits>
- **Convention Over Configuration** - Minimal setup for maximum functionality
- **Single Responsibility** - Each pattern handles one concern
- **Reusability** - Share behavior across models with concerns
- **Testability** - Test models, concerns, validators in isolation
- **Query Optimization** - Built-in N+1 prevention and eager loading
- **Type Safety** - ActiveModel::Attributes provides type casting
- **Database Agnostic** - Works with PostgreSQL, MySQL, SQLite
</benefits>

<verification-checklist>
Before completing model work:
- ✅ All validations tested
- ✅ All associations tested
- ✅ Database constraints added (NOT NULL, foreign keys, unique indexes)
- ✅ No N+1 queries (verified with bullet or manual check)
- ✅ Business logic in model (not controller)
- ✅ Strong parameters in controller for mass assignment
- ✅ All tests passing
</verification-checklist>

<standards>
- Define associations at the top of the model
- Use validations to enforce data integrity
- Minimize callback usage - prefer service objects
- Use scopes for reusable queries, not class methods
- Always eager load associations to prevent N+1 queries
- Use enums for status/state fields
- Extract concerns when models exceed 200 lines
- Place custom validators in `app/validators/`
- Place query objects in `app/queries/`
- Place form objects in `app/forms/`
- Use transactions for multi-model operations
- Prefer database constraints with validations for critical data
- Put business logic in models, not controllers
- Never skip model validations
- Never skip database constraints (NOT NULL, foreign keys)
- Never allow N+1 queries
</standards>

## Patterns

### Basic Associations

**Migration:**

```ruby
class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :body
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :articles, :status
    add_index :articles, [:user_id, :status]
  end
end
```

**Model:**

```ruby
class Article < ApplicationRecord
  # == Associations ==
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_one_attached :cover_image

  # == Validations ==
  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true
  validates :status, presence: true

  # == Enums ==
  enum :status, { draft: 0, published: 1, archived: 2 }

  # == Scopes ==
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(user) { where(user: user) }
  scope :published_since, ->(date) { published.where("created_at >= ?", date) }

  # == Instance Methods ==
  def publish!
    update!(status: :published)
  end

  def authored_by?(user)
    self.user == user
  end
end
```

**Anti-pattern — missing constraints:**

```ruby
# ❌ BAD: No database constraints
create_table :articles do |t|
  t.string :title           # Missing null: false
  t.references :user        # Missing foreign_key: true
end

# ✅ GOOD: Proper constraints
create_table :articles do |t|
  t.string :title, null: false
  t.references :user, null: false, foreign_key: true
end
```

### Polymorphic Associations

```ruby
# Migration
class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :comments, [:commentable_type, :commentable_id]
  end
end

# Model
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  validates :body, presence: true
end

# Usage in other models
class Article < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable, dependent: :destroy
end
```

### Comprehensive Validations

```ruby
class User < ApplicationRecord
  # == Associations ==
  has_many :articles, dependent: :destroy
  has_many :comments, dependent: :destroy

  # == Validations ==
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true,
                       uniqueness: true,
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "only allows letters, numbers, and underscores" }
  validates :bio, length: { maximum: 500 }
  validates :age, numericality: { greater_than_or_equal_to: 13,
                                   less_than: 150 },
                  allow_nil: true

  # Custom validation
  validate :acceptable_avatar

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.byte_size <= 1.megabyte
      errors.add(:avatar, "is too big (max 1MB)")
    end

    acceptable_types = ["image/jpeg", "image/png", "image/webp"]
    unless acceptable_types.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or WebP")
    end
  end
end
```

**Anti-pattern — validation without database constraint:**

```ruby
# ❌ BAD: Only model validation, no DB constraint
validates :email, uniqueness: true

# ✅ GOOD: Both model validation AND DB constraint
# Migration: add_index :users, :email, unique: true
validates :email, uniqueness: { case_sensitive: false }
```

### Minimal Callbacks

```ruby
class Article < ApplicationRecord
  # ✅ GOOD: Simple data normalization callbacks
  before_validation :normalize_title
  before_save :generate_slug

  private

  def normalize_title
    self.title = title&.strip&.titleize
  end

  def generate_slug
    self.slug = title&.parameterize
  end
end
```

**Anti-pattern — heavy callbacks:**

```ruby
# ❌ BAD: Side effects in callbacks
class Article < ApplicationRecord
  after_create :send_notification_email
  after_create :update_analytics
  after_create :sync_to_external_service
  after_save :reindex_search

  # These should be in a service object or background job
end

# ✅ GOOD: Use a service object instead
class ArticleCreator
  def initialize(article_params, user:)
    @article_params = article_params
    @user = user
  end

  def call
    article = @user.articles.build(@article_params)

    if article.save
      NotificationJob.perform_later(article)
      AnalyticsJob.perform_later(:article_created, article.id)
      Result.new(success: true, article: article)
    else
      Result.new(success: false, errors: article.errors)
    end
  end
end
```

### Effective Scopes

```ruby
class Article < ApplicationRecord
  # Simple scopes
  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }
  scope :recent, -> { order(created_at: :desc) }
  scope :featured, -> { where(featured: true) }

  # Parameterized scopes
  scope :by_author, ->(user) { where(user: user) }
  scope :created_after, ->(date) { where("created_at >= ?", date) }
  scope :search, ->(query) {
    where("title ILIKE :q OR body ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  # Scopes with joins
  scope :with_comments, -> { joins(:comments).distinct }
  scope :with_tag, ->(tag_name) {
    joins(:tags).where(tags: { name: tag_name })
  }

  # Eager loading scopes
  scope :with_associations, -> {
    includes(:user, :tags, :comments)
  }
end

# Usage - scopes are chainable
Article.published.recent.with_associations.limit(10)
Article.by_author(current_user).draft
Article.published.search("rails").with_tag("ruby")
```

**Anti-pattern — class methods instead of scopes:**

```ruby
# ❌ BAD: Class method returns nil when no results
def self.published
  where(status: :published) if some_condition
  # Returns nil if condition is false — breaks chaining!
end

# ✅ GOOD: Scope always returns a relation
scope :published, -> { where(status: :published) }
```

### Enum Usage

```ruby
class Article < ApplicationRecord
  # Rails 8 enum syntax
  enum :status, { draft: 0, published: 1, archived: 2 }
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }

  # Enums provide:
  # - Scopes: Article.draft, Article.published
  # - Predicates: article.draft?, article.published?
  # - Setters: article.published!
  # - Validation: validates inclusion automatically
end

# Migration
class AddPriorityToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :priority, :integer, default: 0, null: false
    add_index :articles, :priority
  end
end
```

**Anti-pattern — string enums without mapping:**

```ruby
# ❌ BAD: String values waste space and are error-prone
enum :status, { draft: "draft", published: "published" }

# ✅ GOOD: Integer values are efficient
enum :status, { draft: 0, published: 1, archived: 2 }
```

### Model Concerns

**Concern anatomy:**

```ruby
# app/models/concerns/taggable.rb
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings

    scope :tagged_with, ->(tag_name) {
      joins(:tags).where(tags: { name: tag_name })
    }

    scope :untagged, -> {
      left_joins(:taggings).where(taggings: { id: nil })
    }
  end

  # Instance methods
  def tag_list
    tags.pluck(:name)
  end

  def tag_list=(names)
    self.tags = names.split(",").map(&:strip).uniq.map { |name|
      Tag.find_or_create_by!(name: name)
    }
  end

  def tagged_with?(tag_name)
    tags.exists?(name: tag_name)
  end

  # Class methods
  class_methods do
    def popular_tags(limit: 10)
      Tag.joins(:taggings)
         .where(taggings: { taggable_type: name })
         .group(:id)
         .order("COUNT(taggings.id) DESC")
         .limit(limit)
    end
  end
end

# Usage
class Article < ApplicationRecord
  include Taggable
end

class Photo < ApplicationRecord
  include Taggable
end
```

### Custom Validators

**Email validator:**

```ruby
# app/validators/email_validator.rb
class EmailValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.[a-zA-Z]{2,}\z/

  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    unless value&.match?(EMAIL_REGEX)
      record.errors.add(attribute, options[:message] || "is not a valid email address")
    end

    if options[:disposable] == false
      check_disposable(record, attribute, value)
    end
  end

  private

  def check_disposable(record, attribute, value)
    domain = value&.split("@")&.last&.downcase
    disposable_domains = %w[tempmail.com throwaway.com mailinator.com]

    if disposable_domains.include?(domain)
      record.errors.add(attribute, "cannot be a disposable email address")
    end
  end
end

# Usage
class User < ApplicationRecord
  validates :email, email: { disposable: false }
end
```

**Content length validator:**

```ruby
# app/validators/content_length_validator.rb
class ContentLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    min = options[:minimum]
    max = options[:maximum]
    word_count = value.split(/\s+/).size

    if min && word_count < min
      record.errors.add(attribute, "must have at least #{min} words (has #{word_count})")
    end

    if max && word_count > max
      record.errors.add(attribute, "must have at most #{max} words (has #{word_count})")
    end
  end
end

# Usage
class Article < ApplicationRecord
  validates :body, content_length: { minimum: 50, maximum: 5000 }
end
```

### Query Objects

**Basic chainable query:**

```ruby
# app/queries/feedback_query.rb
class FeedbackQuery
  attr_reader :relation

  def initialize(relation = Feedback.all)
    @relation = relation
  end

  def call(params = {})
    result = relation
    result = filter_by_status(result, params[:status])
    result = filter_by_category(result, params[:category])
    result = filter_by_date_range(result, params[:start_date], params[:end_date])
    result = search(result, params[:query])
    result = sort_by(result, params[:sort], params[:direction])
    result
  end

  private

  def filter_by_status(relation, status)
    return relation if status.blank?
    relation.where(status: status)
  end

  def filter_by_category(relation, category)
    return relation if category.blank?
    relation.where(category: category)
  end

  def filter_by_date_range(relation, start_date, end_date)
    relation = relation.where("created_at >= ?", start_date) if start_date.present?
    relation = relation.where("created_at <= ?", end_date) if end_date.present?
    relation
  end

  def search(relation, query)
    return relation if query.blank?
    relation.where(
      "title LIKE :q OR description LIKE :q",
      q: "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    )
  end

  def sort_by(relation, field, direction)
    return relation.order(created_at: :desc) if field.blank?
    direction = %w[asc desc].include?(direction) ? direction : "desc"
    relation.order(field => direction)
  end
end

# Usage
FeedbackQuery.new.call(status: :open, category: :bug, sort: :priority)
FeedbackQuery.new(current_user.feedbacks).call(params.permit(:status, :query))
```

**Aggregation query:**

```ruby
# app/queries/feedback_stats_query.rb
class FeedbackStatsQuery
  def initialize(scope = Feedback.all)
    @scope = scope
  end

  def call
    {
      total: @scope.count,
      by_status: count_by(:status),
      by_category: count_by(:category),
      avg_resolution_time: average_resolution_time,
      recent_trend: recent_trend
    }
  end

  private

  def count_by(field)
    @scope.group(field).count
  end

  def average_resolution_time
    @scope.resolved
          .where.not(resolved_at: nil)
          .average("julianday(resolved_at) - julianday(created_at)")
          &.round(1)
  end

  def recent_trend
    @scope.where("created_at >= ?", 30.days.ago)
          .group_by_day(:created_at)
          .count
  end
end

# Usage
stats = FeedbackStatsQuery.new.call
stats = FeedbackStatsQuery.new(Feedback.where(user: current_user)).call
```

### Form Objects

**Contact form:**

```ruby
# app/forms/contact_form.rb
class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :subject, :string
  attribute :message, :string
  attribute :priority, :string, default: "normal"

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true, length: { maximum: 200 }
  validates :message, presence: true, length: { minimum: 10, maximum: 5000 }
  validates :priority, inclusion: { in: %w[low normal high urgent] }

  def submit
    return false unless valid?

    ContactMailer.new_message(
      name: name,
      email: email,
      subject: subject,
      message: message,
      priority: priority
    ).deliver_later

    true
  end
end

# Controller usage
class ContactsController < ApplicationController
  def new
    @form = ContactForm.new
  end

  def create
    @form = ContactForm.new(contact_params)

    if @form.submit
      redirect_to root_path, notice: "Message sent!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_form).permit(:name, :email, :subject, :message, :priority)
  end
end
```

**Multi-model form:**

```ruby
# app/forms/user_registration_form.rb
class UserRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # User attributes
  attribute :email, :string
  attribute :username, :string
  attribute :password, :string

  # Profile attributes
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :bio, :string

  # Preferences
  attribute :newsletter, :boolean, default: false
  attribute :terms_accepted, :boolean, default: false

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, length: { minimum: 3, maximum: 30 }
  validates :password, presence: true, length: { minimum: 8 }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      user = User.create!(
        email: email,
        username: username,
        password: password
      )

      user.create_profile!(
        first_name: first_name,
        last_name: last_name,
        bio: bio
      )

      if newsletter
        NewsletterSubscription.create!(user: user)
      end

      @user = user
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  def user
    @user
  end
end

# Controller usage
class RegistrationsController < ApplicationController
  def new
    @form = UserRegistrationForm.new
  end

  def create
    @form = UserRegistrationForm.new(registration_params)

    if @form.save
      redirect_to root_path, notice: "Welcome!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user_registration_form).permit(
      :email, :username, :password,
      :first_name, :last_name, :bio,
      :newsletter, :terms_accepted
    )
  end
end
```

<resources>
- [Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html)
- [Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Active Record Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html)
- [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)
- [Active Model Basics](https://guides.rubyonrails.org/active_model_basics.html)
</resources>
