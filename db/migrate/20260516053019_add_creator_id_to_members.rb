class AddCreatorIdToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :creator_id, :integer
  end
end
