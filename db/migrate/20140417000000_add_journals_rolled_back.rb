class AddJournalsRolledBack < ActiveRecord::Migration
  def up
    add_column :journals, :rolled_back, :boolean, :default => false
  end

  def down
    remove_column :journals, :rolled_back
  end
end
