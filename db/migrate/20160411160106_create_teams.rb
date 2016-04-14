class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.boolean :enabled, default: true
      t.string :name

      t.timestamps null: false
    end
    add_column :users, :team_id, :integer
    add_column :categories, :team_id, :integer
    add_column :campaigns, :team_id, :integer
  end
end
