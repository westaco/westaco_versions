require 'redmine'

require_dependency 'westaco_versions_hook'

Rails.logger.info 'Starting Westaco Versions Plugin for Redmine'

Rails.configuration.to_prepare do
    unless QueriesController.included_modules.include?(WestacoVersionsQueriesControllerPatch)
        QueriesController.send(:include, WestacoVersionsQueriesControllerPatch)
    end
    unless Version.included_modules.include?(WestacoVersionPatch)
        Version.send(:include, WestacoVersionPatch)
    end
    unless Issue.included_modules.include?(WestacoVersionsIssuePatch)
        Issue.send(:include, WestacoVersionsIssuePatch)
    end
end

Redmine::Plugin.register :westaco_versions do
    name 'Westaco Versions'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Adds global and per-project version lists'
    url 'https://github.com/westaco/westaco_versions'
    version '0.0.2'

    menu :application_menu, :versions, { :controller => 'roadmap', :action => 'index' },
                            :if => Proc.new { User.current.allowed_to?(:view_issues, nil, :global => true) },
                            :caption => :label_version_plural, :before => :issues
    menu :project_menu, :versions, { :controller => 'roadmap', :action => 'index' }, :param => :project_id,
                        :permission => :view_issues, :if => Proc.new { |project| project.shared_versions.any? },
                        :caption => :label_version_plural, :before => :issues
end
