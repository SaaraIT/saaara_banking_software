class InterestRate < ApplicationRecord
  validates :loan_type, presence: true
  validates :loan_type_name, presence: true
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :min_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_amount, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  
  def self.matching_rate(loan_application_type, sanction_amount)
    return nil if loan_application_type.blank? || sanction_amount.blank?

    active
      .where("LOWER(TRIM(loan_type)) = LOWER(TRIM(:loan_type))", loan_type: loan_application_type)
      .where("(min_amount IS NULL OR min_amount <= :amount)", amount: sanction_amount)
      .where("(max_amount IS NULL OR max_amount >= :amount)", amount: sanction_amount)
      .order(Arel.sql("min_amount IS NULL ASC, min_amount DESC"))
      .first
  end

  # Get interest rate for a loan application
  def self.rate_for(loan_type, amount = nil)
    return nil if loan_type.blank?

    rates = active.where("LOWER(TRIM(loan_type)) = LOWER(TRIM(?))", loan_type).order(:min_amount)

    return rates.first&.rate if rates.count == 1

    # For amount-based rates (like HOUSING LOAN)
    if amount.present? && rates.count > 1
      rate_record = rates.find do |r|
        min_ok = r.min_amount.nil? || amount >= r.min_amount
        max_ok = r.max_amount.nil? || amount <= r.max_amount
        min_ok && max_ok
      end
      return rate_record&.rate
    end

    rates.first&.rate
  end

  # Predefined loan types for dropdown (legacy - kept for backwards compatibility)
  LOAN_TYPES = {
    'ML' => 'Mortgage Loan',
    'SE' => 'Self Employment Loan',
    'LICNSC' => 'LIC/NSC Loan',
    'VL' => 'Vehicle Loan',
    'SL' => 'Staff Loan',
    'EL' => 'Education Loan',
    'BL' => 'Business Loan',
    'OTHER' => 'Other Loan',
    'STL' => 'Short Term Loan',
    'DRPL' => 'DRPL Loan',
    'HOUSING LOAN' => 'Housing Loan'
  }.freeze

  def self.loan_type_options
    # Use dynamic LoanType model if it has active records, otherwise fall back to hardcoded
    if LoanType.active.any?
      LoanType.options_for_select
    else
      LOAN_TYPES.map { |code, name| [name, code] }
    end
  end

  def self.loan_type_hash
    # Use dynamic LoanType model if it has active records, otherwise fall back to hardcoded
    if LoanType.active.any?
      LoanType.code_name_hash
    else
      LOAN_TYPES
    end
  end

  # Seed default interest rates
  def self.seed_defaults
    defaults = [
      { loan_type: 'ML', loan_type_name: 'Mortgage Loan', rate: 15.5 },
      { loan_type: 'SE', loan_type_name: 'Self Employment Loan', rate: 15.5 },
      { loan_type: 'LICNSC', loan_type_name: 'LIC/NSC Loan', rate: 15.5 },
      { loan_type: 'VL', loan_type_name: 'Vehicle Loan', rate: 8.0 },
      { loan_type: 'SL', loan_type_name: 'Staff Loan', rate: 16.5 },
      { loan_type: 'EL', loan_type_name: 'Education Loan', rate: 14.0 },
      { loan_type: 'BL', loan_type_name: 'Business Loan', rate: 16.0 },
      { loan_type: 'OTHER', loan_type_name: 'Other Loan', rate: 13.0 },
      { loan_type: 'STL', loan_type_name: 'Short Term Loan', rate: 12.0 },
      { loan_type: 'DRPL', loan_type_name: 'DRPL Loan', rate: 18.5 },
      { loan_type: 'HOUSING LOAN', loan_type_name: 'Housing Loan (Up to 10 Lakhs)', rate: 10.5, min_amount: 0, max_amount: 1000000 },
      { loan_type: 'HOUSING LOAN', loan_type_name: 'Housing Loan (10-25 Lakhs)', rate: 12.0, min_amount: 1000001, max_amount: 2500000 },
      { loan_type: 'HOUSING LOAN', loan_type_name: 'Housing Loan (Above 25 Lakhs)', rate: 12.5, min_amount: 2500001, max_amount: nil }
    ]

    defaults.each do |attrs|
      find_or_create_by!(
        loan_type: attrs[:loan_type],
        min_amount: attrs[:min_amount],
        max_amount: attrs[:max_amount]
      ) do |record|
        record.loan_type_name = attrs[:loan_type_name]
        record.rate = attrs[:rate]
      end
    end
  end
end
