class CreateProjectIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :project_identifiers do |t|
      t.column :project_id, :integer, :null => false
      t.column :identifier, :string, :null => false
      t.column :created_on, :datetime, :null => false
    end
  end
end
