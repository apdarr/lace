class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.integer :length
      t.date :race_date

      t.timestamps
    end
  end
end
