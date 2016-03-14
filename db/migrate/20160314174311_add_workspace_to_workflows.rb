class AddWorkspaceToWorkflows < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.column_exists?(:workflows, :workspace_id)
      add_column :workflows, :workspace_id, :integer, :default => 1
    end
  end
end
