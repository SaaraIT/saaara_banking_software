class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :member, null: false, foreign_key: true
      t.string :account_number
      t.string :account_type
      t.date :date
      t.decimal :initial_deposit
      t.string :customer_type
      t.string :mode_of_operation
      t.string :marital_status
      t.string :religion
      t.string :education
      t.string :occupation
      t.string :organisation_name
      t.string :nature_of_business
      t.string :annual_income
      t.string :asset_ownership
      t.string :preferred_investment
      t.string :loans_info
      t.string :insurance

      t.timestamps
    end
  end
end
