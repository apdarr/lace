class AddStartDateLocalToActivity < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :start_date_local, :datetime
  end
end
