module WestacoVersionsIssuePatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            after_save :update_version_start_date, :if => Proc.new { |issue| issue.start_date_changed? || issue.fixed_version_id_changed? }
        end
    end

    module InstanceMethods
    private

        def update_version_start_date
            if start_date && fixed_version && fixed_version.start_date.blank?
                fixed_version.update_attribute(:start_date, start_date)
            end
        end

    end

end
