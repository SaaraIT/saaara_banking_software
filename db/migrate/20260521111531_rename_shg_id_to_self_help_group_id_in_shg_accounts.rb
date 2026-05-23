class RenameShgIdToSelfHelpGroupIdInShgAccounts < ActiveRecord::Migration[8.0]
  def change
    rename_column :shg_accounts, :shg_id, :self_help_group_id
  end
end
