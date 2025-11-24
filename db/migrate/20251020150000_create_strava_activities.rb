class CreateStravaActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :strava_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :strava_id, null: false
      t.integer :strava_athlete_id, null: false
      t.string :activity_type
      t.float :distance
      t.datetime :start_date_local
      t.json :webhook_payload
      t.string :match_status, default: "unmatched", null: false
      t.references :activity, foreign_key: true, null: true

      t.timestamps
    end

    # Index for quick lookups by strava_id and user
    add_index :strava_activities, [ :user_id, :strava_id ], unique: true
    # Index for finding unmatched activities
    add_index :strava_activities, [ :user_id, :match_status ]
  end
end
