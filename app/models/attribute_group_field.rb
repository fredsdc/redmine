class AttributeGroupField < ActiveRecord::Base
  belongs_to :attribute_group
  belongs_to :custom_field
  has_one :tracker, :through => :attribute_group
  acts_as_list

  scope :sorted, lambda { order(:position) }
end
