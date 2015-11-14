class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.references :board, index: true
      t.references :authentication_provider, index: true
      t.references :user, index: true
      t.string :name
      t.string :label
      t.text :options
      t.boolean :enabled, default: true
      t.boolean :polling, default: false
      t.datetime :polled_at
      t.text :last_exception

      t.timestamps
    end
  end
end
