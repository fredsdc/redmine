# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class Workspace < ActiveRecord::Base
  include Redmine::SafeAttributes

  before_destroy :check_integrity
  has_many :projects
  has_many :workflow_rules, :dependent => :delete_all
  acts_as_positioned

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  scope :sorted, lambda { order(:position) }

  safe_attributes 'name',
    'description',
    'position'

  # Returns an array of IssueStatus that are used in the tracker's workflows
  def issue_statuses
    if @issue_statuses
      return @issue_statuses
    elsif new_record?
      return []
    end

    ids = WorkflowTransition.where(workspace_id: id).map{|w| [w.old_status_id, w.new_status_id]}.flatten.uniq
    @issue_statuses = IssueStatus.where(:id => ids).all.sort
  end

  def <=>(workspace)
    position <=> workspace.position
  end

  def to_s; name end

private
  def check_integrity
    raise Exception.new("Cannot delete workspace") if Project.where(:workspace_id => self.id).any?
  end
end
