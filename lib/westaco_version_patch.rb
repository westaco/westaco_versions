module WestacoVersionPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            belongs_to :version_status, :foreign_key => :status, :primary_key => :key
            has_many :version_changes, :dependent => :delete_all

            acts_as_event :title => Proc.new { |object| "#{Version.model_name.human}: #{object.name}" },
                          :author => nil,
                          :group => :project,
                          :url => Proc.new { |object| { :controller => 'versions', :action => 'show', :id => object.id } },
                          :type => Proc.new { |object| 'version-' + object.status }

            acts_as_activity_provider :scope => proc {joins(:project)},
                                      :permission => nil

            clear_validators!
            validates_presence_of :name
            validates_uniqueness_of :name, :scope => [:project_id], :case_sensitive => true
            validates_length_of :name, :maximum => 60
            validates_length_of :description, :wiki_page_title, :maximum => 255
            validates :effective_date, :date => true
            # validates_inclusion_of :status, :in => Version::VERSION_STATUSES
            validates_inclusion_of :sharing, :in => Version::VERSION_SHARINGS
            validates :start_date, :date => true
            validates :end_date, :date => true
            validate :validate_dates

            safe_attributes 'start_date', 'end_date'

            before_save :update_closed_on
            after_save :create_version_change
            after_create do |version|
                time_now = Time.now

                version.version_changes.create(
                    :project => version.project,
                    :author => User.current,
                    :name => 'status',
                    :old_value => '',
                    :value => version.status,
                    :created_on => time_now,
                    :updated_on => time_now
                )
            end

            alias :done_ratio :completed_percent

            # This overrides a native method that uses earliest start date of version's issues
            alias_method :start_date, :version_start_date

            attr_accessor :status_has_been_changed, :old_value, :value
        end
    end

    module InstanceMethods

        def version_start_date
            read_attribute(:start_date)
        end

        def estimated_duration
            date = start_date || created_on.to_date
            (effective_date && date && effective_date >= date) ? (effective_date - date).to_i : nil
        end

        def duration
            (start_date && end_date) ? (end_date - start_date).to_i : nil
        end

        def remaining_duration
            return nil if start_date && start_date > Date.today
            date = end_date || effective_date
            date && date >= Date.today ? (date - Date.today).to_i : nil
        end

        def extra_duration
            (effective_date && end_date) ? (end_date - effective_date).to_i : nil
        end

        def default_version
            self == project.default_version
        end

        def status_name
            self.version_status.try(:name) || self.status
        end

        def status_is_closed
            self.version_status.try(:is_closed)
        end

        def version_status_changes
            self.version_changes.status.to_a
        end

        def last_version_status_change
            self.version_status_changes.last
        end

        def last_version_status_change_in_time
            last_version_status_change.try(:updated_on) || self.updated_on
        end

        def version_status_changes_timeline
            diffs = []
            version_status_changes.each_with_index.map do |status, index|
                diff = (version_status_changes[index].updated_on - version_status_changes[index - 1].updated_on)/3600
                diffs << diff if diff > 0
            end
            diffs
        end

        def version_status_changes_timetotal
            version_status_changes_timeline.sum
        end

    private

        def validate_dates
            if start_date && end_date && (start_date_changed? || end_date_changed?) && start_date > end_date
                errors.add(:end_date, :greater_than_start_date)
            end
        end

        def update_closed_on
            self.status_has_been_changed = self.status_changed?

            if self.status_has_been_changed
                self.old_value = self.changes[:status][0]
                self.value = self.changes[:status][1]
            end

            if closed?
                self.closed_on = Time.now if new_record? || status_changed?
            else
                self.closed_on = nil if closed_on
            end
        end

        def create_version_change
            if self.status_has_been_changed
                time_now = Time.now

                self.version_changes.create(
                    :project => project,
                    :author => User.current,
                    :name => 'status',
                    :old_value => self.old_value,
                    :value => self.value,
                    :created_on => time_now,
                    :updated_on => time_now
                )
            end
        end

    end

end

unless Version.included_modules.include?(WestacoVersionPatch)
    Version.send(:include, WestacoVersionPatch)
end
