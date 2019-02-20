class CreateAttributeGroups < ActiveRecord::Migration
  def change
    create_table :attribute_groups do |t|
      t.references :project, index: true, foreign_key: true
      t.references :tracker, index: true, foreign_key: true
      t.string :name
      t.integer :position, :default => 1, :null => false

      t.timestamps null: false
    end
  end
end
