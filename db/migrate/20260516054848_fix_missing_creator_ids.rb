class FixMissingCreatorIds < ActiveRecord::Migration[8.0]
  def change
    tables = %w[
      branch_manager_reports additional_shares_applications branch_reports
      demand_promissory_notes guarantor_undertakings head_office_reports
      hypothecation_deeds jewel_appraisers_reports jewel_loan_promissory_notes
      jewel_loans loan_applications members pro_notes shg_demand_promissory_notes
      shg_loan_applications shg_loan_pro_notes shg_personal_agreements
      shg_term_loan_agreements term_loan_agreements
    ]
    tables.each do |t|
      next unless table_exists?(t)
      add_column t, :creator_id, :integer unless column_exists?(t, :creator_id)
    end
  end
end
