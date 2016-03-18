class AddTimespanToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :start_displaying_at, :datetime
    add_column :campaigns, :end_displaying_at, :datetime
  end
end
