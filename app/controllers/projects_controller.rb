# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2019  Jean-Philippe Lang
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

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :settings, :only => :settings
  menu_item :projects, :only => [:index, :new, :copy, :create]

  before_action :find_project, :except => [ :index, :autocomplete, :list, :new, :create, :copy ]
  before_action :authorize, :except => [ :index, :autocomplete, :list, :new, :create, :copy, :archive, :unarchive, :destroy]
  before_action :authorize_global, :only => [:new, :create]
  before_action :require_admin, :only => [ :copy, :archive, :unarchive, :destroy ]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy
  require_sudo_mode :destroy

  helper :custom_fields
  helper :issues
  helper :queries
  include QueriesHelper
  helper :projects_queries
  include ProjectsQueriesHelper
  helper :repositories
  helper :members
  helper :trackers

  # Lists visible projects
  def index
    # try to redirect to the requested menu item
    if params[:jump] && redirect_to_menu_item(params[:jump])
      return
    end

    retrieve_project_query
    scope = project_scope

    respond_to do |format|
      format.html {
        # TODO: see what to do with the board view and pagination
        if @query.display_type == 'board'
          @entries = scope.to_a
        else
          @entry_count = scope.count
          @entry_pages = Paginator.new @entry_count, per_page_option, params['page']
          @entries = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).to_a
        end
      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = scope.count
        @projects = scope.offset(@offset).limit(@limit).to_a
      }
      format.atom {
        projects = scope.reorder(:created_on => :desc).limit(Setting.feeds_limit.to_i).to_a
        render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
      format.csv {
        # Export all entries
        @entries = scope.to_a
        send_data(query_to_csv(@entries, @query, params), :type => 'text/csv; header=present', :filename => 'projects.csv')
      }
    end
  end

  def autocomplete
    respond_to do |format|
      format.js {
        if params[:q].present?
          @projects = Project.visible.like(params[:q]).to_a
        else
          @projects = User.current.projects.to_a
        end
      }
    end
  end

  def new
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @project = Project.new
    @project.safe_attributes = params[:project]
  end

  def create
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @project = Project.new
    @project.safe_attributes = params[:project]

    if @project.save
      unless User.current.admin?
        @project.add_default_member(User.current)
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:continue]
            attrs = {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}
            redirect_to new_project_path(attrs)
          else
            redirect_to settings_project_path(@project)
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@project) }
      end
    end
  end

  def copy
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @source_project = Project.find(params[:id])
    if request.get?
      @project = Project.copy_from(@source_project)
      @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
    else
      Mailer.with_deliveries(params[:notifications] == '1') do
        @project = Project.new
        @project.safe_attributes = params[:project]
        if @project.copy(@source_project, :only => params[:only])
          flash[:notice] = l(:notice_successful_create)
          redirect_to settings_project_path(@project)
        elsif !@project.new_record?
          # Project was created
          # But some objects were not copied due to validation failures
          # (eg. issues from disabled trackers)
          # TODO: inform about that
          redirect_to settings_project_path(@project)
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    # source_project not found
    render_404
  end

  # Show @project
  def show
    # try to redirect to the requested menu item
    if params[:jump] && redirect_to_project_menu_item(@project, params[:jump])
      return
    end

    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.to_a
    @news = @project.news.limit(5).includes(:author, :project).reorder("#{News.table_name}.created_on DESC").to_a
    @trackers = @project.rolled_up_trackers.visible

    cond = @project.project_condition(Setting.display_subprojects_issues?)

    @open_issues_by_tracker = Issue.visible.open.where(cond).group(:tracker).count
    @total_issues_by_tracker = Issue.visible.where(cond).group(:tracker).count

    if User.current.allowed_to_view_all_time_entries?(@project)
      @total_hours = TimeEntry.visible.where(cond).sum(:hours).to_f
      @total_estimated_hours = Issue.visible.where(cond).sum(:estimated_hours).to_f
    end

    @key = User.current.rss_key

    respond_to do |format|
      format.html
      format.api
    end
  end

  def settings
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.sorted.to_a
    @cfs=AttributeGroup.joins(:custom_fields).joins(:tracker).
      where(project_id: @project, tracker_id: @trackers, :custom_fields => {id: @project.all_issue_custom_fields.pluck(:id)}).
      pluck("trackers.id", "id", "name", "position","attribute_group_fields.id", "attribute_group_fields.position",
        "custom_fields.id", "custom_fields.name", "custom_fields.position").sort_by{|x| [x[3], x[5]]}

    @version_status = params[:version_status] || 'open'
    @version_name = params[:version_name]
    @versions = @project.shared_versions.status(@version_status).like(@version_name).sorted
  end

  def edit
  end

  def update
    @project.safe_attributes = params[:project]
    identifier_was = Project.find(params[:id]).identifier
    if @project.save
      @project.keep_old_identifier(identifier_was, @project.identifier)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to settings_project_path(@project, params[:tab])
        }
        format.api  { render_api_ok }
      end
    else
      @identifier_was = @project.identifier
      @project.identifier = identifier_was
      respond_to do |format|
        format.html {
          settings
          render :action => 'settings'
        }
        format.api  { render_validation_errors(@project) }
      end
    end
  end

  def groupissuescustomfields
    # clean invalid values: invalid cfs, empty cf lists, empty groups
    group_issues_custom_fields = (JSON.parse params[:group_issues_custom_fields]).
      each{|tid,v| v.replace(v.select{|k,v| v["cfs"] ? v["cfs"].delete_if{|k,v| @project.all_issue_custom_fields.pluck(:id).include?(v)} : v})}.
      each{|tid,v| v.delete_if{|k,v| v["cfs"].blank?}}.
      delete_if{|k,v| v.blank?}

    groups = AttributeGroup.where(project_id: @project.id).collect(&:id)
    fields = AttributeGroupField.where(attribute_group_id: groups).collect(&:id)
    group_issues_custom_fields.each do |tid,v|
      v.each do |gp, g|
        gid = groups.shift
        if gid.nil?
          gid=AttributeGroup.create(project_id: @project.id, tracker_id: tid, name: g["name"].nil? ? nil : g["name"], position: gp).id
        else
          AttributeGroup.update(gid, project_id: @project.id, tracker_id: tid, name: g["name"].nil? ? nil : g["name"], position: gp)
        end
        g['cfs'].each do |cfp, cf|
          cfid = fields.shift
          if cfid.nil?
            AttributeGroupField.create(attribute_group_id: gid, custom_field_id: cf, position: cfp)
          else
            AttributeGroupField.update(cfid, attribute_group_id: gid, custom_field_id: cf, position: cfp)
          end
        end
      end
    end
    AttributeGroupField.where(id: fields).delete_all
    AttributeGroup.where(id: groups).destroy_all
    flash[:notice] = l(:notice_successful_update)
    redirect_to settings_project_path(@project, :tab => 'groupissuescustomfields')
  end

  def archive
    unless @project.archive
      flash[:error] = l(:error_can_not_archive_project)
    end
    redirect_to_referer_or admin_projects_path(:status => params[:status])
  end

  def unarchive
    unless @project.active?
      @project.unarchive
    end
    redirect_to_referer_or admin_projects_path(:status => params[:status])
  end

  def bookmark
    jump_box = Redmine::ProjectJumpBox.new User.current
    if request.delete?
      jump_box.delete_project_bookmark @project
    elsif request.post?
      jump_box.bookmark_project @project
    end
    respond_to do |format|
      format.js
      format.html { redirect_to project_path(@project) }
    end
  end

  def close
    @project.close
    redirect_to project_path(@project)
  end

  def reopen
    @project.reopen
    redirect_to project_path(@project)
  end

  # Delete @project
  def destroy
    @project_to_destroy = @project
    if api_request? || params[:confirm]
      @project_to_destroy.destroy
      respond_to do |format|
        format.html { redirect_to admin_projects_path }
        format.api  { render_api_ok }
      end
    end
    # hide project in layout
    @project = nil
  end

  private

  # Returns the ProjectEntry scope for index
  def project_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_project_query
    retrieve_query(ProjectQuery, false, :defaults => @default_columns_names)
  end
end
