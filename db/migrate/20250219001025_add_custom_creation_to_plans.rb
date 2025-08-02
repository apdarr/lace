class AddCustomCreationToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :custom_creation, :boolean, default: false
  end
end