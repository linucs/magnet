class AddExceptionNotificationsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notify_exceptions, :boolean, default: true
  end
end
