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

class WorkspacesController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    @workspaces = Workspace.sorted.to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
    end
  end

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new
    @workspace.safe_attributes = params[:workspace]
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
    @workspace.safe_attributes = params[:workspace]
    if @workspace.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to workspaces_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.js { head 422 }
      end
    end
  end

  def destroy
    unless Project.where(:workspace_id => params[:id]).any? || params[:id] == "1"
      Workspace.find(params[:id]).destroy
    else
      flash[:error] = l(:error_unable_delete_workspace)
    end
    redirect_to workspaces_path
  end
end
