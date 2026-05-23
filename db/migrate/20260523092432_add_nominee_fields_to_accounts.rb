class AddNomineeFieldsToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :nominee_name, :string
    add_column :accounts, :nominee_address, :text
    add_column :accounts, :nominee_same_address, :boolean
    add_column :accounts, :nominee_relationship, :string
    add_column :accounts, :nominee_mobile, :string
  end
end
