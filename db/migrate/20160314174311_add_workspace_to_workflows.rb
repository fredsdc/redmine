class AddWorkspaceToWorkflows < ActiveRecord::Migration[4.2]
  def self.up
    add_column :workflows, :workspace_id, :integer, :default => 1
  end

  def self.down
    remove_column :workflows, :workspace_id
  end
end
