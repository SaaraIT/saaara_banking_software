class CreateShgAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :shg_accounts do |t|
      t.integer :shg_id
      t.string :branch
      t.date :date
      t.string :account_number
      t.string :gender_code
      t.string :shg_name
      t.date :date_of_formation
      t.integer :number_of_members
      t.text :shg_address
      t.string :president_name
      t.string :president_age
      t.string :president_designation
      t.text :president_address
      t.string :president_mobile
      t.string :president_kyc
      t.string :secretary_name
      t.string :secretary_age
      t.string :secretary_designation
      t.text :secretary_address
      t.string :secretary_mobile
      t.string :secretary_kyc
      t.string :officer_name
      t.date :account_opened_on

      t.timestamps
    end
  end
end
