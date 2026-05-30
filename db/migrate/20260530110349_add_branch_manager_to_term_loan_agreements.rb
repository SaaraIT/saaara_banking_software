class AddBranchManagerToTermLoanAgreements < ActiveRecord::Migration[8.0]
  def change
    add_column :term_loan_agreements, :branch_manager, :string
  end
end
