OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:open_ai, :token)
  config.request_timeout = 120 # 2 minutes for vision API calls with images
end
