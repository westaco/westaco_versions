require 'redmine'

require File.dirname(__FILE__) + '/lib/westaco_versions_hook.rb'
require File.dirname(__FILE__) + '/lib/westaco_versions_issue_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_versions_queries_controller_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_version_patch.rb'

Rails.logger.info 'Starting Westaco Versions Plugin for Redmine'

Redmine::Plugin.register :westaco_versions do
    name 'Westaco Versions'
    author 'Westaco'
    author_url 'http://www.westaco.com/'
    description 'Adds global and per-project version lists'
    url 'https://github.com/westaco/westaco_versions'
    version '0.0.4'

    menu :application_menu, :versions, { :controller => 'roadmap', :action => 'index' },
                            :if => Proc.new { User.current.allowed_to?(:view_issues, nil, :global => true) },
                            :caption => :label_version_plural, :before => :issues
    menu :project_menu, :versions, { :controller => 'roadmap', :action => 'index' }, :param => :project_id,
                        :permission => :view_issues, :if => Proc.new { |project| project.shared_versions.any? },
                        :caption => :label_version_plural, :before => :issues
end
