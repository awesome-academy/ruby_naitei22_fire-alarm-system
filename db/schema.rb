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

ActiveRecord::Schema[7.0].define(version: 2025_08_16_095443) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alerts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "message"
    t.integer "origin", default: 0
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.bigint "zone_id", null: false
    t.string "image_url"
    t.integer "status", default: 0
    t.boolean "via_email", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["owner_type", "owner_id"], name: "index_alerts_on_owner"
    t.index ["user_id"], name: "index_alerts_on_user_id"
    t.index ["zone_id"], name: "index_alerts_on_zone_id"
  end

  create_table "cameras", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.bigint "zone_id", null: false
    t.float "latitude"
    t.float "longitude"
    t.integer "status", default: 0
    t.boolean "is_detecting", default: false
    t.string "last_snapshot_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id", "name"], name: "index_cameras_on_zone_id_and_name", unique: true
    t.index ["zone_id"], name: "index_cameras_on_zone_id"
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.string "purpose", null: false
    t.boolean "used", default: false, null: false
    t.datetime "expires_at"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["code"], name: "index_invitations_on_code", unique: true
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "sensor_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "sensor_id", null: false
    t.float "temperature"
    t.float "humidity"
    t.datetime "detected_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_sensor_logs_on_deleted_at"
    t.index ["sensor_id"], name: "index_sensor_logs_on_sensor_id"
  end

  create_table "sensors", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.float "threshold"
    t.integer "sensitivity"
    t.integer "status", default: 0, null: false
    t.bigint "zone_id", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id"], name: "index_sensors_on_zone_id"
  end

  create_table "tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "refresh_token", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["refresh_token"], name: "index_tokens_on_refresh_token", unique: true
    t.index ["user_id"], name: "index_tokens_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "password_digest"
    t.string "email", null: false
    t.string "phone"
    t.string "address"
    t.bigint "admin_id"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["admin_id"], name: "index_users_on_admin_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
  end

  create_table "zones", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.text "description"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sensors_count", default: 0
    t.integer "cameras_count", default: 0
    t.index ["user_id"], name: "index_zones_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alerts", "users"
  add_foreign_key "alerts", "zones"
  add_foreign_key "cameras", "zones"
  add_foreign_key "invitations", "users"
  add_foreign_key "sensor_logs", "sensors"
  add_foreign_key "sensors", "zones"
  add_foreign_key "tokens", "users"
  add_foreign_key "users", "users", column: "admin_id"
  add_foreign_key "zones", "users"
end
