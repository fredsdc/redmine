class AttributeGroup < ActiveRecord::Base
  belongs_to :project
  belongs_to :tracker
  has_many :attribute_group_fields
  has_many :custom_fields, :through => :attribute_group_fields
  acts_as_list

  scope :sorted, lambda { order(:position) }
end
