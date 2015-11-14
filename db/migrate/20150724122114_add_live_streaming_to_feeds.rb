class AddLiveStreamingToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :live_streaming, :boolean, default: false
  end
end
