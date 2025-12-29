class ProfileController < ApplicationController
  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    enable_webhooks = profile_settings_params[:enable_strava_webhooks] == "1"

    begin
      if enable_webhooks
        StravaWebhookService.create_subscription(@user, strava_webhook_callback_url)
        flash[:notice] = "Strava live sync enabled. We'll start matching new activities automatically."
      else
        StravaWebhookService.delete_subscription(@user)
        flash[:notice] = "Strava live sync disabled."
      end

      redirect_to profile_path
    rescue RegisterStravaWebhookJob::SubscriptionError, DeleteStravaWebhookJob::SubscriptionError, StravaWebhookService::SubscriptionError => e
      flash.now[:alert] = e.message
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_settings_params
    params.fetch(:profile_settings, {}).permit(:enable_strava_webhooks)
  end

  def strava_webhook_callback_url
    ngrok_url = Rails.application.credentials.dig(:ngrok, :url)
    return "#{ngrok_url}/webhooks/strava" if ngrok_url.present?

    default_options = Rails.application.config.action_mailer.default_url_options || {}
    host = default_options[:host] || "localhost"
    port = default_options[:port]

    Rails.application.routes.url_helpers.webhooks_strava_url(host: host, port: port)
  end
end
