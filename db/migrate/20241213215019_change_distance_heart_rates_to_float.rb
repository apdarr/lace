class ChangeDistanceHeartRatesToFloat < ActiveRecord::Migration[8.0]
  def change
    change_table :activities do |t|
      t.change :distance, :float
      t.change :average_heart_rate, :float
      t.change :max_heart_rate, :float
    end
  end
end
