class VersionChange < ActiveRecord::Base
    self.table_name = 'version_changes'

    belongs_to :project
    belongs_to :version
    belongs_to :author, :class_name => 'User'

    scope :status, -> { where(:name => 'status') }

    acts_as_event :title => Proc.new { |object| "#{Version.model_name.human}: #{object.version.try(:name)}" },
                  :datetime => :created_on,
                  :author => :author,
                  :group => :project,
                  :type => Proc.new { |object| 'version-' + object.value.to_s }

    acts_as_activity_provider :scope => proc { joins(:project, :author, :version) },
                              :author_key => :author_id,
                              :find_options => { :include => [:project, :author, :version] },
                              :permission => nil
end
