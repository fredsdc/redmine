class ChangeNameLimitInCustomFields < ActiveRecord::Migration[5.2]
  def change
    change_column :custom_fields, :name, :string, limit: 255
  end
end
