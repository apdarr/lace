class AddPlanIndexToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :plan_id, :integer
  end
end
