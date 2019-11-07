class AddWorkspaceToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :workspace_id, :integer, :default => 1
  end

  def self.down
    remove_column :projects, :workspace_id
  end
end
