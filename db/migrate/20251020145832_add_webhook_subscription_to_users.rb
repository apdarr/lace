class AddWebhookSubscriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :strava_webhook_subscription_id, :string
    add_column :users, :webhook_verify_token, :string
  end
end
