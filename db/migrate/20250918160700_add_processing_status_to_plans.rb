class AddProcessingStatusToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :processing_status, :string, default: 'idle'
    add_column :plans, :job_id, :string
    add_index :plans, :processing_status
  end
end
