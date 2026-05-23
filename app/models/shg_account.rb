class ShgAccount < ApplicationRecord
  belongs_to :self_help_group, foreign_key: :self_help_group_id
end
