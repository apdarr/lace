class AddStravaIdToActivity < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :strava_id, :integer
  end
end
