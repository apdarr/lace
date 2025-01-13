# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_02_203521) do
  create_table "activities", force: :cascade do |t|
    t.float "distance"
    t.integer "elapsed_time"
    t.string "activity_type"
    t.integer "kudos_count"
    t.float "average_heart_rate"
    t.float "max_heart_rate"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "strava_id"
    t.datetime "start_date_local"
    t.binary "embedding"
  end
end
