class AddMemberIdToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :member_id, :integer
  end
end
