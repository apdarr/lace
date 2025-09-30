class AddPlanTypeToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :plan_type, :string, default: 'template', null: false
    add_index :plans, :plan_type
  end
end
