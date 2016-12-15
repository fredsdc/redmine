class AddAttachmentsPermissions < ActiveRecord::Migration
  def self.up
    Role.all.each do |r|
      r.add_permission!(:view_attachments) if r.has_permission?(:view_issues)
      r.add_permission!(:edit_attachments) if r.has_permission?(:edit_issues)
      r.add_permission!(:delete_attachments) if r.has_permission?(:edit_issues)
    end
  end

  def self.down
    Role.all.each do |r|
      r.remove_permission!(:view_attachments)
      r.remove_permission!(:edit_attachments)
      r.remove_permission!(:delete_attachments)
    end
  end
end
