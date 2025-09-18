RubyLLM.configure do |config|
  config.openai_api_key = Rails.application.credentials.dig(:open_ai, :token)

  config.request_timeout = 240
end
