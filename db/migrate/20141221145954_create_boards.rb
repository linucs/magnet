class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.string :name
      t.string :slug
      t.string :host
      t.integer :row_order
      t.text :description
      t.string :icon
      t.string :image
      t.string :cover
      t.boolean :include_text_only_cards, default: true
      t.boolean :discard_identical_images, default: true
      t.boolean :discard_obscene_contents, default: true
      t.boolean :enabled, default: true
      t.string :label
      t.boolean :moderated
      t.text :banned_users
      t.text :banned_words
      t.integer :max_tags_per_card
      t.text :options
      t.integer :polling_interval, default: 3
      t.integer :polling_count
      t.references :category, index: true

      t.timestamps

      t.index :slug
      t.index :host
      t.index :label
    end
  end
end
