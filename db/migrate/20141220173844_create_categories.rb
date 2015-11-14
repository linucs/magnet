class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.string :ancestry
      t.integer :row_order
      t.text :description
      t.string :image
      t.string :cover
      t.boolean :enabled, default: true
      t.string :label

      t.timestamps

      t.index :slug
      t.index :ancestry
      t.index :label
    end
  end
end
