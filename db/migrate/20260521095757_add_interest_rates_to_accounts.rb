class AddInterestRatesToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :term_interest_rate, :decimal
    add_column :accounts, :rd_interest_rate, :decimal
  end
end
