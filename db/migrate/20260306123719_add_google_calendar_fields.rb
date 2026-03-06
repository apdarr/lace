class AddGoogleCalendarFields < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_calendar_id, :string
    add_column :plans, :calendar_sync_enabled, :boolean, default: false, null: false
    add_column :activities, :google_calendar_event_id, :string
  end
end
