class SelfHelpGroup < ApplicationRecord
  belongs_to :cooperative_branch
  has_many :shg_members, dependent: :destroy
  has_many :shg_loan_applications, dependent: :destroy
  has_many :shg_accounts, dependent: :destroy
  accepts_nested_attributes_for :shg_members, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? }

  def name_with_address
    name + " " + address
  end
end
