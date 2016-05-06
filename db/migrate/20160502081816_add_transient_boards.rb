class AddTransientBoards < ActiveRecord::Migration
  def change
    add_column :boards, :hashtag, :string
    add_index :boards, :hashtag
  end
end
