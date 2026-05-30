class ChangeKycListsToArrayAndAddMinBalance < ActiveRecord::Migration[7.0]
  def change
    change_column :accounts, :kyc_list1, :text
    change_column :accounts, :kyc_list2, :text
    add_column :accounts, :minimum_balance, :string unless column_exists?(:accounts, :minimum_balance)
  end
end
