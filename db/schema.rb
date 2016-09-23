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

ActiveRecord::Schema.define(version: 20160916082748) do

  create_table "authentication_providers", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "features",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentication_providers", ["name"], name: "index_authentication_providers_on_name", using: :btree

  create_table "boards", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.string   "slug",                     limit: 255
    t.string   "host",                     limit: 255
    t.integer  "row_order",                limit: 4
    t.text     "description",              limit: 65535
    t.string   "icon",                     limit: 255
    t.string   "image",                    limit: 255
    t.string   "cover",                    limit: 255
    t.boolean  "include_text_only_cards",                default: true
    t.boolean  "discard_identical_images",               default: true
    t.boolean  "discard_obscene_contents",               default: true
    t.boolean  "enabled",                                default: true
    t.string   "label",                    limit: 255
    t.boolean  "moderated"
    t.text     "banned_users",             limit: 65535
    t.text     "banned_words",             limit: 65535
    t.integer  "max_tags_per_card",        limit: 4
    t.text     "options",                  limit: 65535
    t.integer  "polling_interval",         limit: 4,     default: 3
    t.integer  "polling_count",            limit: 4
    t.integer  "category_id",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_street_address",      limit: 255
    t.float    "latitude",                 limit: 24
    t.float    "longitude",                limit: 24
    t.text     "trusted_users",            limit: 65535
    t.datetime "start_polling_at"
    t.datetime "end_polling_at"
    t.string   "hashtag",                  limit: 255
  end

  add_index "boards", ["category_id"], name: "index_boards_on_category_id", using: :btree
  add_index "boards", ["hashtag"], name: "index_boards_on_hashtag", using: :btree
  add_index "boards", ["host"], name: "index_boards_on_host", using: :btree
  add_index "boards", ["label"], name: "index_boards_on_label", using: :btree
  add_index "boards", ["slug"], name: "index_boards_on_slug", using: :btree

  create_table "boards_users", id: false, force: :cascade do |t|
    t.integer "board_id", limit: 4, null: false
    t.integer "user_id",  limit: 4, null: false
  end

  add_index "boards_users", ["user_id", "board_id"], name: "index_boards_users_on_user_id_and_board_id", unique: true, using: :btree

  create_table "bootsy_image_galleries", force: :cascade do |t|
    t.integer  "bootsy_resource_id",   limit: 4
    t.string   "bootsy_resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bootsy_images", force: :cascade do |t|
    t.string   "image_file",       limit: 255
    t.integer  "image_gallery_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  "row_order",            limit: 4
    t.boolean  "enabled",                            default: true
    t.integer  "threshold",            limit: 4
    t.text     "content",              limit: 65535
    t.integer  "board_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start_displaying_at"
    t.datetime "end_displaying_at"
    t.integer  "team_id",              limit: 4
    t.boolean  "activate_on_deck",                   default: true
    t.boolean  "activate_on_timeline",               default: true
    t.boolean  "activate_on_wall",                   default: true
  end

  add_index "campaigns", ["board_id"], name: "index_campaigns_on_board_id", using: :btree
  add_index "campaigns", ["enabled", "threshold", "board_id"], name: "index_campaigns_on_enabled_and_threshold_and_board_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "slug",        limit: 255
    t.string   "ancestry",    limit: 255
    t.integer  "row_order",   limit: 4
    t.text     "description", limit: 65535
    t.string   "image",       limit: 255
    t.string   "cover",       limit: 255
    t.boolean  "enabled",                   default: true
    t.string   "label",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "team_id",     limit: 4
  end

  add_index "categories", ["ancestry"], name: "index_categories_on_ancestry", using: :btree
  add_index "categories", ["label"], name: "index_categories_on_label", using: :btree
  add_index "categories", ["slug"], name: "index_categories_on_slug", using: :btree

  create_table "feeds", force: :cascade do |t|
    t.integer  "board_id",                   limit: 4
    t.integer  "authentication_provider_id", limit: 4
    t.integer  "user_id",                    limit: 4
    t.string   "name",                       limit: 255
    t.string   "label",                      limit: 255
    t.text     "options",                    limit: 65535
    t.boolean  "enabled",                                  default: true
    t.boolean  "polling",                                  default: false
    t.datetime "polled_at"
    t.text     "last_exception",             limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "live_streaming",                           default: false
  end

  add_index "feeds", ["authentication_provider_id"], name: "index_feeds_on_authentication_provider_id", using: :btree
  add_index "feeds", ["board_id"], name: "index_feeds_on_board_id", using: :btree
  add_index "feeds", ["user_id"], name: "index_feeds_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "shortened_urls", force: :cascade do |t|
    t.integer  "owner_id",   limit: 4
    t.string   "owner_type", limit: 20
    t.string   "url",        limit: 255,             null: false
    t.string   "unique_key", limit: 10,              null: false
    t.integer  "use_count",  limit: 4,   default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expires_at"
  end

  add_index "shortened_urls", ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type", using: :btree
  add_index "shortened_urls", ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true, using: :btree
  add_index "shortened_urls", ["url"], name: "index_shortened_urls_on_url", using: :btree

  create_table "teams", force: :cascade do |t|
    t.boolean  "enabled",                default: true
    t.string   "name",       limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "user_authentications", force: :cascade do |t|
    t.integer  "user_id",                    limit: 4
    t.integer  "authentication_provider_id", limit: 4
    t.string   "uid",                        limit: 255
    t.string   "token",                      limit: 255
    t.string   "token_secret",               limit: 255
    t.datetime "token_expires_at"
    t.text     "params",                     limit: 65535
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "user_authentications", ["authentication_provider_id"], name: "index_user_authentications_on_authentication_provider_id", using: :btree
  add_index "user_authentications", ["user_id"], name: "index_user_authentications_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",   null: false
    t.string   "encrypted_password",     limit: 255, default: "",   null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",        limit: 4,   default: 0,    null: false
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",   limit: 255
    t.boolean  "admin"
    t.integer  "max_feeds",              limit: 4,   default: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notify_exceptions",                  default: true
    t.datetime "expires_at"
    t.integer  "team_id",                limit: 4
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
