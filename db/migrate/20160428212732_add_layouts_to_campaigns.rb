class AddLayoutsToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :activate_on_deck, :boolean, default: true
    add_column :campaigns, :activate_on_timeline, :boolean, default: true
    add_column :campaigns, :activate_on_wall, :boolean, default: true
  end
end
