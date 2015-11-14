# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150921084541) do

  create_table "authentication_providers", force: true do |t|
    t.string   "name"
    t.string   "features"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentication_providers", ["name"], name: "index_authentication_providers_on_name", using: :btree

  create_table "boards", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "host"
    t.integer  "row_order"
    t.text     "description"
    t.string   "icon"
    t.string   "image"
    t.string   "cover"
    t.boolean  "include_text_only_cards",             default: true
    t.boolean  "discard_identical_images",            default: true
    t.boolean  "discard_obscene_contents",            default: true
    t.boolean  "enabled",                             default: true
    t.string   "label"
    t.boolean  "moderated"
    t.text     "banned_users"
    t.text     "banned_words"
    t.integer  "max_tags_per_card"
    t.text     "options"
    t.integer  "polling_interval",                    default: 3
    t.integer  "polling_count"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_street_address"
    t.float    "latitude",                 limit: 24
    t.float    "longitude",                limit: 24
    t.text     "trusted_users"
  end

  add_index "boards", ["category_id"], name: "index_boards_on_category_id", using: :btree
  add_index "boards", ["host"], name: "index_boards_on_host", using: :btree
  add_index "boards", ["label"], name: "index_boards_on_label", using: :btree
  add_index "boards", ["slug"], name: "index_boards_on_slug", using: :btree

  create_table "boards_users", id: false, force: true do |t|
    t.integer "board_id", null: false
    t.integer "user_id",  null: false
  end

  add_index "boards_users", ["user_id", "board_id"], name: "index_boards_users_on_user_id_and_board_id", unique: true, using: :btree

  create_table "campaigns", force: true do |t|
    t.string   "name"
    t.integer  "row_order"
    t.boolean  "enabled"
    t.integer  "threshold"
    t.text     "content"
    t.integer  "board_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaigns", ["board_id"], name: "index_campaigns_on_board_id", using: :btree
  add_index "campaigns", ["enabled", "threshold", "board_id"], name: "index_campaigns_on_enabled_and_threshold_and_board_id", using: :btree

  create_table "categories", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "ancestry"
    t.integer  "row_order"
    t.text     "description"
    t.string   "image"
    t.string   "cover"
    t.boolean  "enabled",     default: true
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories", ["ancestry"], name: "index_categories_on_ancestry", using: :btree
  add_index "categories", ["label"], name: "index_categories_on_label", using: :btree
  add_index "categories", ["slug"], name: "index_categories_on_slug", using: :btree

  create_table "feeds", force: true do |t|
    t.integer  "board_id"
    t.integer  "authentication_provider_id"
    t.integer  "user_id"
    t.string   "name"
    t.string   "label"
    t.text     "options"
    t.boolean  "enabled",                    default: true
    t.boolean  "polling",                    default: false
    t.datetime "polled_at"
    t.text     "last_exception"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "live_streaming",             default: false
  end

  add_index "feeds", ["authentication_provider_id"], name: "index_feeds_on_authentication_provider_id", using: :btree
  add_index "feeds", ["board_id"], name: "index_feeds_on_board_id", using: :btree
  add_index "feeds", ["user_id"], name: "index_feeds_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: true do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "shortened_urls", force: true do |t|
    t.integer  "owner_id"
    t.string   "owner_type", limit: 20
    t.string   "url",                               null: false
    t.string   "unique_key", limit: 10,             null: false
    t.integer  "use_count",             default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shortened_urls", ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type", using: :btree
  add_index "shortened_urls", ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true, using: :btree
  add_index "shortened_urls", ["url"], name: "index_shortened_urls_on_url", using: :btree

  create_table "user_authentications", force: true do |t|
    t.integer  "user_id"
    t.integer  "authentication_provider_id"
    t.string   "uid"
    t.string   "token"
    t.string   "token_secret"
    t.datetime "token_expires_at"
    t.text     "params"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "user_authentications", ["authentication_provider_id"], name: "index_user_authentications_on_authentication_provider_id", using: :btree
  add_index "user_authentications", ["user_id"], name: "index_user_authentications_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.boolean  "admin"
    t.integer  "max_feeds",              default: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
