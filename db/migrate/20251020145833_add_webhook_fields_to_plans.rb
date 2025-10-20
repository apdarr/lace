class AddWebhookFieldsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :webhook_enabled, :boolean, default: false, null: false
  end
end
