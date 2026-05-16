class AddCreatorIdToLoanApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_applications, :creator_id, :integer
  end
end
