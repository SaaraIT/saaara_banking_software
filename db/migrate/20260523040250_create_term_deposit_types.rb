class CreateTermDepositTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :term_deposit_types do |t|
      t.string :name
      t.string :description
      t.boolean :active

      t.timestamps
    end
  end
end
