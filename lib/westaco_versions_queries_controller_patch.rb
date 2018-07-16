module WestacoVersionsQueriesControllerPatch

    def redirect_to_version_query(options)
        redirect_to (@project ? roadmap_project_versions_path(@project, options) : roadmap_versions_path(options))
    end

end
