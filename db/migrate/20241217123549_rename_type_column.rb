class RenameTypeColumn < ActiveRecord::Migration[8.0]
  def change
    rename_column :activities, :type, :activity_type
  end
end
