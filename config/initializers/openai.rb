OpenAI.configure do |config|
  Rails.application.credentials.dig(:open_ai, :token)
end
