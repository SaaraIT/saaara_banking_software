class AddKycOtherToShgAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :shg_accounts, :president_kyc_other, :string
    add_column :shg_accounts, :secretary_kyc_other, :string
  end
end
