class FixWorkspacesAllowNullPosition < ActiveRecord::Migration
  def self.up
    # removes the 'not null' constraint on position fields
    change_column :workspaces, :position, :integer, :default => 1, :null => true
  end

  def self.down
    # nothing to do
  end
end
