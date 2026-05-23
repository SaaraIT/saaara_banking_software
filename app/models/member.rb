class Member < ApplicationRecord
  has_many :accounts, dependent: :destroy
  validates :name, :father_or_husband_name, :mobile_number, :aadhaar_number, :age, :education, :occupation, :religion,
          :address_a_building,
          :address_a_village, :address_a_district, :address_a_pincode,
          :address_b_building, :address_b_village, :address_b_district,
          :address_b_pincode, :father_or_husband, presence: true
  validates :aadhaar_number, uniqueness: true

  has_many :memberships, inverse_of: :member, dependent: :destroy
  belongs_to :cooperative_branch
  belongs_to :creator, class_name: 'User', optional: true
  has_many :loan_applications
  has_many :family_members
  has_many :deposits_and_shares
  has_many :income_and_expenditures
  has_many :existing_loan_liabilities, dependent: :destroy
  has_one :business_detail, dependent: :destroy
  has_one :insurance_policy, dependent: :destroy
  has_one :vehicle, dependent: :destroy
  has_one :deposit, dependent: :destroy
  has_many :term_loan_agreements, dependent: :destroy

  has_one :gold_ornament, dependent: :destroy
  has_one :immovable_property, dependent: :destroy
  has_one :indirect_liability, dependent: :destroy
  has_one :tax_detail, dependent: :destroy
  has_many :pro_notes, dependent: :destroy
  has_many :demand_promissory_notes, dependent: :destroy
  has_many :hypothecation_deeds, dependent: :destroy
  has_many :co_obligants, dependent: :destroy
  
  has_one :income_declaration, dependent: :destroy
  has_one :guarantor_undertaking        # if the member is a borrower
  has_many :guaranteed_undertakings, foreign_key: :guarantor_id, class_name: 'GuarantorUndertaking' # if the member is a guarantor
  has_many :jewel_loans, dependent: :destroy
  has_many :additional_shares_applications

  has_many :loan_application_co_applicants, dependent: :destroy
  has_many :co_applied_loans, through: :loan_application_co_applicants, source: :loan_application

  accepts_nested_attributes_for :income_declaration

  accepts_nested_attributes_for :loan_applications, allow_destroy: true
  accepts_nested_attributes_for :memberships, allow_destroy: true
  accepts_nested_attributes_for :family_members, allow_destroy: true
  accepts_nested_attributes_for :deposits_and_shares, allow_destroy: true
  accepts_nested_attributes_for :income_and_expenditures, allow_destroy: true
  accepts_nested_attributes_for :existing_loan_liabilities, allow_destroy: true

  accepts_nested_attributes_for :business_detail, allow_destroy: true
  accepts_nested_attributes_for :insurance_policy, allow_destroy: true
  accepts_nested_attributes_for :vehicle, allow_destroy: true
  accepts_nested_attributes_for :deposit, allow_destroy: true

  accepts_nested_attributes_for :gold_ornament, allow_destroy: true
  accepts_nested_attributes_for :immovable_property, allow_destroy: true
  accepts_nested_attributes_for :indirect_liability, allow_destroy: true
  accepts_nested_attributes_for :tax_detail, allow_destroy: true

  def address
    "#{address_a_building}, #{address_a_village}, #{address_a_district}, #{address_a_pincode}"
  end

  def employer
    income_declaration.try(:company_name)
  end

  def profession
    income_declaration.try(:occupation)
  end

  def work_experience
    "#{income_declaration.try(:years_of_experience)} years"
  end

  def income
    "#{income_declaration.try(:income)}"
  end

  def name_and_address(br=false)
    name_address = name
    name_address = name_address + (father_or_husband == "Husband" ?  ", W/O " : ", S/O ")
    name_address = name_address + father_or_husband_name
    name_address = name_address + "<br />" if br
    name_address = name_address + "," unless br
    name_address = name_address + " " + address
    name_address
  end

  def sb_account_no
    deposits_and_shares.where(particular: "S.B. A/C No.").first.try(:account_no)
  end
end
