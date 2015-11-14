class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name
      t.integer :row_order
      t.boolean :enabled
      t.integer :threshold
      t.text :content
      t.references :board, index: true

      t.timestamps
    end

    add_index :campaigns, [:enabled, :threshold, :board_id]
  end
end
