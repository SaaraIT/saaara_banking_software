class ShgAccount < ApplicationRecord
  belongs_to :self_help_group, foreign_key: :self_help_group_id

  def president_kyc
    val = super
    val.is_a?(String) ? (JSON.parse(val) rescue []) : Array(val)
  end

  def secretary_kyc
    val = super
    val.is_a?(String) ? (JSON.parse(val) rescue []) : Array(val)
  end

end