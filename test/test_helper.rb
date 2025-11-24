ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end


module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

# Add authentication helpers for different test types
module AuthenticationHelpers
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies[:session_id] = cookie_jar[:session_id]
    end
  end
end

# Include the helpers in controller tests
class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end

VCR.configure do |config|
  config.ignore_request do |request|
    uri = request.uri.to_s
    uri.include?("127.0.0.1") || uri.include?("localhost")
  end

  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock

  # Remove the Bearer token from the request headers
  config.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header&.match(/Bearer (.+)/)&.[](1)
  end

  # Remove the input string from the request body
  config.filter_sensitive_data("<OPENAI_REQUEST_BODY>") do |interaction|
    if interaction.request.uri.include?("openai")
      body = interaction.request.body
      if body.match?(/\{"model":"text-embedding.*"input":".*"\}/)
        body
      end
    end
  end

  # Filter Strava credentials from cassettes
  config.filter_sensitive_data("<STRAVA_CLIENT_ID>") do |interaction|
    Rails.application.credentials.dig(:strava, :client_id)&.to_s
  end

  config.filter_sensitive_data("<STRAVA_CLIENT_SECRET>") do |interaction|
    Rails.application.credentials.dig(:strava, :client_secret)&.to_s
  end
end
