OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:open_ai, :token)
end
