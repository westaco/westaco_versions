class RoadmapController < ApplicationController
    menu_item :versions

    helper :queries
    include QueriesHelper

    before_action :find_optional_project, :check_visibility

    def index
        retrieve_query(VersionQuery, false)
        scope = @query.results_scope
        @version_count = scope.count
        @version_pages = Paginator.new(@version_count, per_page_option, params['page'])
        @versions = scope.offset(@version_pages.offset).limit(@version_pages.per_page).to_a
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
