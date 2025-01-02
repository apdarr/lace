class AddEmbeddingToActivity < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :embedding, :binary
  end
end
