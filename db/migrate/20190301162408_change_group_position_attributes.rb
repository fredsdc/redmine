class ChangeGroupPositionAttributes < ActiveRecord::Migration
  def change
    change_column_null :attribute_groups, :position, true
    change_column_default :attribute_groups, :position, nil
  end
end
