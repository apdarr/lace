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

ActiveRecord::Schema[8.0].define(version: 2025_02_19_001024) do
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
    t.integer "plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "length"
    t.date "race_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.string "firstname"
    t.string "lastname"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "token_expires_at"
    t.integer "strava_id"
    t.string "profile_picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strava_id"], name: "index_users_on_strava_id", unique: true
  end

  add_foreign_key "sessions", "users"
end
