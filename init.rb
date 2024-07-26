require 'redmine'

require File.dirname(__FILE__) + '/lib/westaco_versions_hook.rb'
require File.dirname(__FILE__) + '/lib/westaco_versions_issue_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_versions_queries_controller_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_versions_controller_patch.rb'
require File.dirname(__FILE__) + '/lib/westaco_version_patch.rb'

Rails.logger.info 'Starting Westaco Versions Plugin for Redmine'

Redmine::Plugin.register :westaco_versions do
    name 'Westaco Versions'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Adds global and per-project version lists'
    url 'https://github.com/westaco/westaco_versions'
    version '0.0.5'

    menu :application_menu, :versions, { :controller => 'roadmap', :action => 'index' },
                            :if => Proc.new { User.current.allowed_to?(:view_issues, nil, :global => true) },
                            :caption => :label_version_plural, :before => :issues
    menu :project_menu, :versions, { :controller => 'roadmap', :action => 'index' }, :param => :project_id,
                        :permission => :view_issues, :if => Proc.new { |project| project.shared_versions.any? },
                        :caption => :label_version_plural, :before => :issues
    menu :admin_menu, :version_statuses, { :controller => 'version_statuses', :action => 'index' },
                      :caption => :label_version_status_plural,
                      :after => :issue_statuses,
                      :html => { :class => 'icon' }
end

Redmine::Activity.register :versions, :class_name => 'VersionChange'
