class AttributeGroupField < ActiveRecord::Base
  belongs_to :attribute_group
  belongs_to :custom_field
  acts_as_list

  scope :sorted, lambda { order(:position) }
end
