class VersionStatusesController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index

  def index
    @version_statuses = VersionStatus.sorted.to_a
    respond_to do |format|
      format.html {render :layout => false if request.xhr?}
      format.api
    end
  end

  def new
    @version_status = VersionStatus.new
  end

  def create
    @version_status = VersionStatus.new
    @version_status.safe_attributes = params[:version_status]
    if @version_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to version_statuses_path
    else
      render :action => 'new'
    end
  end

  def edit
    @version_status = VersionStatus.find(params[:id])
  end

  def update
    @version_status = VersionStatus.find(params[:id])
    @version_status.safe_attributes = params[:version_status]
    if @version_status.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to version_statuses_path(:page => params[:page])
        end
        format.js {head 200}
      end
    else
      respond_to do |format|
        format.html {render :action => 'edit'}
        format.js {head 422}
      end
    end
  end

  def destroy
    VersionStatus.find(params[:id]).destroy
    redirect_to version_statuses_path
  rescue => e
    flash[:error] = l(:error_unable_delete_version_status, ERB::Util.h(e.message))
    redirect_to version_statuses_path
  end
end