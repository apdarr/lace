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

    # Add more helper methods to be used by all tests here...
  end
end

VCR.configure do |config|
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
end
