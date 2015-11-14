class AddTrustedUsersToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :trusted_users, :text
  end
end
