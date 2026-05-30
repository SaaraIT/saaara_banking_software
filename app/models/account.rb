class Account < ApplicationRecord
def kyc_list1
  val = self[:kyc_list1]
  return [] if val.blank?
  begin
    parsed = JSON.parse(val)
    parsed.is_a?(Array) ? parsed : [parsed]
  rescue
    val.split(',').map(&:strip)
  end
end

def kyc_list2
  val = self[:kyc_list2]
  return [] if val.blank?
  begin
    parsed = JSON.parse(val)
    parsed.is_a?(Array) ? parsed : [parsed]
  rescue
    val.split(',').map(&:strip)
  end
end

def kyc_list1=(val)
  self[:kyc_list1] = val.is_a?(Array) ? val.to_json : val.to_s
end

def kyc_list2=(val)
  self[:kyc_list2] = val.is_a?(Array) ? val.to_json : val.to_s
end

  belongs_to :member
end
