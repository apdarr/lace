class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.float :distance
      t.integer :elapsed_time
      t.string :type
      t.integer :kudos_count
      t.integer :average_heart_rate
      t.integer :max_heart_rate
      t.string :description

      t.timestamps
    end
  end
end
