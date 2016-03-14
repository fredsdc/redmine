class AddWorkspaceToProjects < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.column_exists?(:projects, :workspace_id)
      add_column :projects, :workspace_id, :integer, :default => 1
    end
  end
end
