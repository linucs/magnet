class AddTimespanToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :start_polling_at, :datetime
    add_column :boards, :end_polling_at, :datetime
  end
end
