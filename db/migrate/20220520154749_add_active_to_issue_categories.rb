class AddActiveToIssueCategories < ActiveRecord::Migration[5.2]
  def change
    change_table :issue_categories do |t|
      t.boolean :active, default: true, null: false
    end
  end
end
