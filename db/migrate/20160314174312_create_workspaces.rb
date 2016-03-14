class CreateWorkspaces < ActiveRecord::Migration
  class Workspace < ActiveRecord::Base; end

  def self.up
    unless ActiveRecord::Base.connection.table_exists?('workspaces')
      create_table :workspaces do |t|
        t.string :name
        t.string :description
        t.integer :position, :null => false
      end

      # create default workspace
      workspace = Workspace.new :name => "Default",
                                :description => "Default workspace",
                                :position => "1"
      workspace.save
    end
  end
end
