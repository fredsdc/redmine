# Redmine - project management software
# Copyright (C) 2006-2015  Jean-Philippe Lang
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

class WorkspacesController < ApplicationController
  layout 'admin'

  before_filter :require_admin, :except => :index
  before_filter :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    respond_to do |format|
      format.html {
        @workspace_pages, @workspaces = paginate Workspace.sorted, :per_page => 25
        render :action => "index", :layout => false if request.xhr?
      }
      format.api {
        @workspaces = Workspace.order('position').to_a
      }
    end
  end

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(params[:workspace])
    if @workspace.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to workspaces_path
    else
      render :action => 'new'
    end
  end

  def edit
    @workspace = Workspace.find(params[:id])
  end

  def update
    @workspace = Workspace.find(params[:id])
    if @workspace.update_attributes(params[:workspace])
      flash[:notice] = l(:notice_successful_update)
      redirect_to workspaces_path(:page => params[:page])
    else
      render :action => 'edit'
    end
  end

  def destroy
    unless Project.where(:workspace_id => params[:id]).any? || params[:id] == "1"
      Workspace.find(params[:id]).destroy
      redirect_to workspaces_path
    else
      flash[:error] = l(:error_unable_delete_workspace)
      redirect_to workspaces_path
    end
  end
end
