class AddNewFieldsToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :caste, :string
    add_column :accounts, :nationality, :string
    add_column :accounts, :aadhaar_no, :string
    add_column :accounts, :pan_no, :string
    add_column :accounts, :phone_no, :string
  end
end
