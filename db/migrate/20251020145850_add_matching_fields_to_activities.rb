class AddMatchingFieldsToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :matched_workout_id, :integer
    add_column :activities, :match_confidence, :float
    add_column :activities, :matched_at, :datetime
    add_index :activities, :matched_workout_id
  end
end
