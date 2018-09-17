class RoadmapController < ApplicationController
    menu_item :versions

    helper :queries
    include QueriesHelper
    helper :custom_fields
    include CustomFieldsHelper

    before_action :find_optional_project, :check_visibility

    def index
        retrieve_query(VersionQuery, false)
        if @query.valid?
            scope = @query.results_scope
            respond_to do |format|
                format.html {
                    @version_count = scope.count
                    @version_pages = Paginator.new(@version_count, per_page_option, params['page'])
                    @versions = scope.offset(@version_pages.offset).limit(@version_pages.per_page).to_a
                }
                format.atom {
                    versions = scope.limit(Setting.feeds_limit.to_i).to_a
                    render_feed(versions, :title => "#{@project || Setting.app_title}: #{l(:label_version_plural)}")
                }
                format.csv  {
                    send_data(query_to_csv(scope.to_a, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'versions.csv')
                }
                format.pdf  {
                    @versions = scope.to_a
                    send_file_headers!(:type => 'application/pdf', :filename => 'versions.pdf')
                }
            end
        else
            respond_to do |format|
                format.html
                format.any(:atom, :csv, :pdf) { head 422 }
            end
        end
    end

private

    def find_optional_project
        @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    rescue ActiveRecord::RecordNotFound
        render_404
    end

    def check_visibility
        render_403 unless User.current.allowed_to?(:view_issues, @project, :global => true)
    end

end
