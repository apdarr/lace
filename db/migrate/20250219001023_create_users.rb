class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address
      t.string :firstname
      t.string :lastname
      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.integer :strava_id
      t.string :profile_picture_url

      t.timestamps
    end
    add_index :users, :strava_id, unique: true
  end
end
