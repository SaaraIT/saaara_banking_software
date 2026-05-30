class AddKycNumbersToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :kyc_list1_number, :string
    add_column :accounts, :kyc_list2_number, :string
  end
end
