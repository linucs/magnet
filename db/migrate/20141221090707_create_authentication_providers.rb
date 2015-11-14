class CreateAuthenticationProviders < ActiveRecord::Migration
  def change
    create_table :authentication_providers, :force => true do |t|
      t.string :name
      t.string :features
      t.timestamps
    end

    add_index :authentication_providers, :name
  end
end
