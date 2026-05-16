class FixHypothecationDeedNumericPrecision < ActiveRecord::Migration[8.0]
  def change
    change_column :hypothecation_deeds, :interest_rate, :decimal, precision: 10, scale: 2
    change_column :hypothecation_deeds, :moratorium_period, :decimal, precision: 10, scale: 2
    change_column :hypothecation_deeds, :default_penalty_interest, :decimal, precision: 10, scale: 2
  end
end
