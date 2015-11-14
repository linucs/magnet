class AddLatitudeAndLongitudeToBoards < ActiveRecord::Migration
  def change
    add_column :boards, :full_street_address, :string
    add_column :boards, :latitude, :float
    add_column :boards, :longitude, :float
  end
end
