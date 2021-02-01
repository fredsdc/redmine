class CreateWorkspaces < ActiveRecord::Migration[4.2]
  def self.up
    create_table :workspaces do |t|
      t.string :name
      t.string :description
      t.integer :position, :default => nil, :null => true
    end

    # create default workspace
    unless Workspace.exists?(1)
      Workspace.create(:name => "Default", :description => "Default workspace", :position => 1)
    end
  end

  def self.down
    drop_table :workspaces
  end
end
