
class VersionChange < ApplicationRecord
  include Redmine::SafeAttributes

  belongs_to :version
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'updated_by_id'

  acts_as_event :title => Proc.new { |object|
                  if object.old_value.blank?
                    "#{Version.model_name.human}: #{object.version.name} has been created"
                  else
                    "#{Version.model_name.human}: #{object.version.name} has been changed from #{object.old_value} to #{object.value}"
                  end
                },
                :datetime => :created_on,
                :author => Proc.new { |o| o.author.name },
                :url => Proc.new { |object| { :controller => 'versions', :action => 'show', :id => object.version.id } },
                :type => Proc.new { |object| 'version-' + object.value }

  acts_as_activity_provider :type => 'versions',
                            :timestamp => "#{table_name}.created_on",
                            :author_key => "#{table_name}.updated_by_id",
                            :scope => proc {joins(:project)},
                            :permission => nil

  scope :status, lambda {where(:name => 'status')}
end