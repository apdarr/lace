RubyLLM.configure do |config|
  # In test environment, use a dummy key since VCR will intercept the actual API calls
  # In other environments, use the actual credentials
  if Rails.env.test?
    config.openai_api_key = "sk-test-dummy-key-for-vcr"
  else
    config.openai_api_key = Rails.application.credentials.dig(:open_ai, :token)
  end

  config.request_timeout = 240
end
