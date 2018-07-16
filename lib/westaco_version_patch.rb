module WestacoVersionPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            validates :start_date, :date => true
            validates :end_date, :date => true
            validate :validate_dates

            safe_attributes 'start_date', 'end_date'

            before_save :update_closed_on

            # This overrides a native method that uses earliest start date of version's issues
            alias_method :start_date, :version_start_date
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

    private

        def validate_dates
            if start_date && end_date && (start_date_changed? || end_date_changed?) && start_date > end_date
                errors.add(:end_date, :greater_than_start_date)
            end
        end

        def update_closed_on
            if closed?
                self.closed_on = Time.now if new_record? || status_changed?
            else
                self.closed_on = nil if closed_on
            end
        end

    end

end
