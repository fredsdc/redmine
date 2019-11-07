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

class WorkflowRule < ActiveRecord::Base
  self.table_name = "#{table_name_prefix}workflows#{table_name_suffix}"

  belongs_to :role
  belongs_to :tracker
  belongs_to :old_status, :class_name => 'IssueStatus'
  belongs_to :new_status, :class_name => 'IssueStatus'
  belongs_to :workspace

  validates_presence_of :role, :tracker, :workspace

  # Copies workflows from source to targets
  def self.copy(source_tracker, source_role, source_workspace, target_trackers, target_roles, target_workspaces)
    unless source_tracker.is_a?(Tracker) || source_role.is_a?(Role) || source_workspace.is_a?(Workspace)
      raise ArgumentError.new("source_tracker, source_role or source_workspace must be specified, given: #{source_tracker.class.name}, #{source_role.class.name} and #{source_workspace.class.name}")
    end

    target_trackers = [target_trackers].flatten.compact
    target_roles = [target_roles].flatten.compact
    target_workspaces = [target_workspaces].flatten.compact

    target_trackers = Tracker.sorted.to_a if target_trackers.empty?
    target_roles = Role.all.select(&:consider_workflow?) if target_roles.empty?
    target_workspaces = Workspace.sorted.to_a if target_workspaces.empty?

    target_trackers.each do |target_tracker|
      target_roles.each do |target_role|
        target_workspaces.each do |target_workspace|
          copy_one(source_tracker || target_tracker,
                     source_role || target_role,
                     source_workspace || target_workspace,
                     target_tracker,
                     target_role,
                     target_workspace)
        end
      end
    end
  end

  # Copies a single set of workflows from source to target
  def self.copy_one(source_tracker, source_role, source_workspace, target_tracker, target_role, target_workspace)
    unless source_tracker.is_a?(Tracker) && !source_tracker.new_record? &&
      source_role.is_a?(Role) && !source_role.new_record? &&
      source_workspace.is_a?(Workspace) && !source_workspace.new_record? &&
      target_tracker.is_a?(Tracker) && !target_tracker.new_record? &&
      target_role.is_a?(Role) && !target_role.new_record? &&
      target_workspace.is_a?(Workspace) && !target_workspace.new_record?

      raise ArgumentError.new("arguments can not be nil or unsaved objects")
    end

    if source_tracker == target_tracker && source_role == target_role && source_workspace == target_workspace
      false
    else
      transaction do
        where(:tracker_id => target_tracker.id, :role_id => target_role.id, :workspace_id => target_workspace.id).delete_all
        connection.insert "INSERT INTO #{WorkflowRule.table_name} (tracker_id, role_id, old_status_id, new_status_id, author, assignee, field_name, #{connection.quote_column_name 'rule'}, type, workspace_id)" +
                          " SELECT #{target_tracker.id}, #{target_role.id}, old_status_id, new_status_id, author, assignee, field_name, #{connection.quote_column_name 'rule'}, type, #{target_workspace.id}" +
                          " FROM #{WorkflowRule.table_name}" +
                          " WHERE tracker_id = #{source_tracker.id} AND role_id = #{source_role.id} AND workspace_id = #{source_workspace.id}"
      end
      true
    end
  end
end
